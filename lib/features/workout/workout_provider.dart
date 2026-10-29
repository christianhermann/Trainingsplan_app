import '../../data/repositories/settings_repository.dart';
import '../history/history_provider.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/progression_service.dart';

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class TodayWorkoutState {
  const TodayWorkoutState({
    required this.programId,
    required this.workoutDayId,
    required this.weekNumber,
    required this.dayIndex,
    required this.prescriptions,
    required this.logs,
    required this.lifts,
    required this.isCompleted,
  });

  final int programId;
  final int workoutDayId;
  final int weekNumber;
  final int dayIndex;
  final List<ExercisePrescription> prescriptions;
  final Map<int, ExerciseLog> logs;
  final Map<int, Lift> lifts;
  final bool isCompleted;
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

class TodayWorkoutNotifier extends AsyncNotifier<TodayWorkoutState?> {
  @override
  Future<TodayWorkoutState?> build() => _load();

  Future<TodayWorkoutState?> _load() async {
    final programRepo = ref.read(programRepositoryProvider);
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final liftRepo = ref.read(liftRepositoryProvider);

    final program = await programRepo.getActiveProgram();
    if (program == null) return null;

    await programRepo.deduplicateDaysForProgram(program.id);

    final weeks = await programRepo.getWeeksForProgram(program.id);
    if (weeks.isEmpty) return null;

    final currentWeek = weeks.firstWhere(
      (w) => w.weekNumber == program.currentWeek,
      orElse: () => weeks.first,
    );

    final days = await programRepo.getDaysForWeek(currentWeek.id);
    if (days.isEmpty) return null;

    final todayDay = days.firstWhere(
      (d) {
        final status = WorkoutStatus.fromString(d.status);
        return status == WorkoutStatus.planned ||
            status == WorkoutStatus.inProgress;
      },
      orElse: () => days.last,
    );

    final prescriptions = await workoutRepo.getPrescriptionsForDay(todayDay.id);
    final logs = await workoutRepo.getLogsForDay(todayDay.id);
    final allLifts = await liftRepo.getAllLifts();

    return TodayWorkoutState(
      programId: program.id,
      workoutDayId: todayDay.id,
      weekNumber: currentWeek.weekNumber,
      dayIndex: todayDay.dayIndex,
      prescriptions: prescriptions,
      logs: {for (final l in logs) l.prescriptionId: l},
      lifts: {for (final l in allLifts) l.id: l},
      isCompleted:
          WorkoutStatus.fromString(todayDay.status) == WorkoutStatus.completed,
    );
  }

  Future<void> updateLog(ExerciseLogsCompanion companion) async {
    final savedId =
        await ref.read(workoutRepositoryProvider).saveLog(companion);

    // Optimistic state update without ref.invalidateSelf() to prevent UI thrashing
    final current = state.value;
    if (current != null && companion.prescriptionId.present) {
      final pid = companion.prescriptionId.value;
      final existingLog = current.logs[pid];
      final updatedLog = ExerciseLog(
        id: companion.id.present
            ? companion.id.value
            : (existingLog?.id ?? savedId),
        prescriptionId: pid,
        completedSets: companion.completedSets.present
            ? companion.completedSets.value
            : (existingLog?.completedSets ?? 0),
        repsOnLastSet: companion.repsOnLastSet.present
            ? companion.repsOnLastSet.value
            : existingLog?.repsOnLastSet,
        notes: companion.notes.present
            ? companion.notes.value
            : existingLog?.notes,
        videoUrl: companion.videoUrl.present
            ? companion.videoUrl.value
            : existingLog?.videoUrl,
        completedAt: companion.completedAt.present
            ? companion.completedAt.value
            : (existingLog?.completedAt ?? DateTime.now()),
      );
      final newLogs = Map<int, ExerciseLog>.from(current.logs);
      newLogs[pid] = updatedLog;
      state = AsyncData(TodayWorkoutState(
        programId: current.programId,
        workoutDayId: current.workoutDayId,
        weekNumber: current.weekNumber,
        dayIndex: current.dayIndex,
        prescriptions: current.prescriptions,
        logs: newLogs,
        lifts: current.lifts,
        isCompleted: current.isCompleted,
      ));
    }
  }

  Future<void> completeWorkout() async {
    final current = state.value;
    if (current == null) return;

    final programRepo = ref.read(programRepositoryProvider);
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final tmRepo = ref.read(trainingMaxRepositoryProvider);
    final now = DateTime.now();

    // 1. Mark the day completed using a partial update (patchDay) so that
    //    required columns workoutWeekId and dayIndex are not overwritten.
    await programRepo.patchDay(
      current.workoutDayId,
      WorkoutDaysCompanion(
        status: Value(WorkoutStatus.completed.name),
        completedAt: Value(now),
      ),
    );

    // 2. Run progression for every prescription with a recorded repsOnLastSet.
    const progressionSvc = ProgressionService();
    final settingsRepo = ref.read(settingsRepositoryProvider);
    final settings = await settingsRepo.getSettings();
    final roundingIncrement = settings?.roundingIncrement ?? 2.5;
    final roundingMode = RoundingMode.fromString(settings?.roundingMode);

    for (final driftPresc in current.prescriptions) {
      final driftLog = current.logs[driftPresc.id];
      if (driftLog == null || driftLog.repsOnLastSet == null) continue;

      final liftRow = current.lifts[driftPresc.liftId];
      if (liftRow == null) continue;

      final tmRow = await tmRepo.getMaxForLift(liftRow.id);
      if (tmRow == null) continue;

      final outcome = progressionSvc.determineOutcome(
        completedSets: driftLog.completedSets,
        setGoal: driftPresc.setGoal,
        repsOnLastSet: driftLog.repsOnLastSet!,
        repOutTarget: driftPresc.repOutTarget,
      );
      final delta = outcome.defaultDelta;
      final newTrainingMax = tmRow.value + (tmRow.value * delta);

      if (newTrainingMax != tmRow.value) {
        // Insert a new history row — do NOT upsert on liftId so every
        // progression step is preserved in the training-max history.
        await tmRepo.saveMax(TrainingMaxesCompanion.insert(
          liftId: liftRow.id,
          value: newTrainingMax,
          effectiveDate: now,
        ));

        // Directly update future prescriptions for this lift so new TM is reflected
        // without deleting days or thrashing the main thread!
        await workoutRepo.updateFuturePrescriptionsForLift(
          liftId: liftRow.id,
          newTrainingMax: newTrainingMax,
          roundingIncrement: roundingIncrement,
          roundingMode: roundingMode,
        );
      }
    }

    // 3. Auto-advance week when all days in the current week are done.
    final program = await programRepo.getActiveProgram();
    if (program != null) {
      final weeks = await programRepo.getWeeksForProgram(program.id);
      final currentWeek = weeks.firstWhere(
        (w) => w.weekNumber == current.weekNumber,
        orElse: () => weeks.first,
      );
      final updatedDays = await programRepo.getDaysForWeek(currentWeek.id);
      final allDone = updatedDays.every((d) {
        final s = WorkoutStatus.fromString(d.status);
        return s == WorkoutStatus.completed || s == WorkoutStatus.skipped;
      });

      if (allDone && program.currentWeek < program.totalWeeks) {
        await programRepo.patchProgram(
          program.id,
          ProgramsCompanion(
            currentWeek: Value(program.currentWeek + 1),
            updatedAt: Value(now),
          ),
        );
      }
    }

    ref.invalidate(historySessionsProvider);
    ref.invalidateSelf();
  }

  Future<void> skipDay() async {
    final current = state.value;
    if (current == null) return;

    final programRepo = ref.read(programRepositoryProvider);
    final now = DateTime.now();

    await programRepo.patchDay(
      current.workoutDayId,
      WorkoutDaysCompanion(
        status: Value(WorkoutStatus.skipped.name),
        completedAt: Value(now),
      ),
    );

    final program = await programRepo.getActiveProgram();
    if (program != null) {
      final weeks = await programRepo.getWeeksForProgram(program.id);
      final currentWeek = weeks.firstWhere(
        (w) => w.weekNumber == current.weekNumber,
        orElse: () => weeks.first,
      );
      final updatedDays = await programRepo.getDaysForWeek(currentWeek.id);
      final allDone = updatedDays.every((d) {
        final s = WorkoutStatus.fromString(d.status);
        return s == WorkoutStatus.completed || s == WorkoutStatus.skipped;
      });

      if (allDone && program.currentWeek < program.totalWeeks) {
        await programRepo.patchProgram(
          program.id,
          ProgramsCompanion(
            currentWeek: Value(program.currentWeek + 1),
            updatedAt: Value(now),
          ),
        );
      }
    }

    ref.invalidate(historySessionsProvider);
    ref.invalidateSelf();
  }

  Future<void> repeatWeek() async {
    final current = state.value;
    if (current == null) return;

    final programRepo = ref.read(programRepositoryProvider);
    final workoutRepo = ref.read(workoutRepositoryProvider);

    final program = await programRepo.getActiveProgram();
    if (program == null) return;

    final weeks = await programRepo.getWeeksForProgram(program.id);
    final currentWeek = weeks.firstWhere(
      (w) => w.weekNumber == current.weekNumber,
      orElse: () => weeks.first,
    );

    final days = await programRepo.getDaysForWeek(currentWeek.id);
    final dayIds = days.map((d) => d.id).toList();
    final prescriptions = await workoutRepo.getPrescriptionsForDays(dayIds);
    final prescriptionIds = prescriptions.map((p) => p.id).toList();

    await workoutRepo.deleteLogsForPrescriptions(prescriptionIds);

    for (final day in days) {
      await programRepo.patchDay(
        day.id,
        const WorkoutDaysCompanion(
          status: Value('planned'),
          completedAt: Value(null),
        ),
      );
    }

    ref.invalidate(historySessionsProvider);
    ref.invalidateSelf();
  }

  Future<void> applyDeloadToCurrentWeek() async {
    final current = state.value;
    if (current == null) return;

    final programRepo = ref.read(programRepositoryProvider);
    final workoutRepo = ref.read(workoutRepositoryProvider);

    final program = await programRepo.getActiveProgram();
    if (program == null) return;

    final weeks = await programRepo.getWeeksForProgram(program.id);
    final currentWeek = weeks.firstWhere(
      (w) => w.weekNumber == current.weekNumber,
      orElse: () => weeks.first,
    );

    final days = await programRepo.getDaysForWeek(currentWeek.id);
    final incompleteDays = days.where((d) {
      final s = WorkoutStatus.fromString(d.status);
      return s == WorkoutStatus.planned || s == WorkoutStatus.inProgress;
    }).toList();

    if (incompleteDays.isEmpty) return;

    final incompleteDayIds = incompleteDays.map((d) => d.id).toList();
    final prescriptions =
        await workoutRepo.getPrescriptionsForDays(incompleteDayIds);

    final updatedCompanions = <ExercisePrescriptionsCompanion>[];
    for (final p in prescriptions) {
      var deloadWeight = (p.workingWeight * 0.70 / 2.5).round() * 2.5;
      if (deloadWeight < 20.0) deloadWeight = 20.0;
      final deloadSets = p.setGoal > 3 ? 3 : 2;

      updatedCompanions.add(ExercisePrescriptionsCompanion(
        id: Value(p.id),
        workoutDayId: Value(p.workoutDayId),
        liftId: Value(p.liftId),
        trainingMaxSnapshot: Value(p.trainingMaxSnapshot),
        intensity: Value(p.intensity * 0.70),
        workingWeight: Value(deloadWeight),
        repsPerNormalSet: Value(p.repsPerNormalSet),
        repOutTarget: Value(p.repsPerNormalSet),
        setGoal: Value(deloadSets),
        displayOrder: Value(p.displayOrder),
        isPrimaryBlock: Value(p.isPrimaryBlock),
      ));
    }

    await workoutRepo.savePrescriptions(updatedCompanions);
    ref.invalidateSelf();
  }
}

final todayWorkoutProvider =
    AsyncNotifierProvider<TodayWorkoutNotifier, TodayWorkoutState?>(
        TodayWorkoutNotifier.new);
