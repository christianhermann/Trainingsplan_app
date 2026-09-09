import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/progression_adjustment_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/exercise_log.dart' as domain;
import '../../domain/models/exercise_prescription.dart' as domain;
import '../../domain/services/progression_service.dart';
import '../../domain/services/workout_generator_service.dart';

// ---------------------------------------------------------------------------
// toDomain extensions
// ---------------------------------------------------------------------------
// Convert Drift-generated row types to domain models in one place.
// Used in completeWorkout() and can be reused by any future caller.

extension ExerciseLogToDomain on ExerciseLog {
  domain.ExerciseLog toDomain() => domain.ExerciseLog(
        id: id.toString(),
        prescriptionId: prescriptionId.toString(),
        completedSets: completedSets,
        repsOnLastSet: repsOnLastSet,
        notes: notes,
        videoUrl: videoUrl,
        completedAt: completedAt,
      );
}

extension ExercisePrescriptionToDomain on ExercisePrescription {
  /// Converts a Drift [ExercisePrescription] row to a domain model.
  /// [liftName] must be the canonical slot key (e.g. 'squat'), not the
  /// display name — it is used as liftId for progression lookup.
  domain.ExercisePrescription toDomain(String liftName) =>
      domain.ExercisePrescription(
        id: id.toString(),
        workoutDayId: workoutDayId.toString(),
        liftId: liftName,
        trainingMaxSnapshot: trainingMaxSnapshot,
        intensity: intensity,
        workingWeight: workingWeight,
        repsPerNormalSet: repsPerNormalSet,
        repOutTarget: repOutTarget,
        setGoal: setGoal,
        displayOrder: displayOrder,
        isPrimaryBlock: isPrimaryBlock,
      );
}

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
    await ref.read(workoutRepositoryProvider).saveLog(companion);
    ref.invalidateSelf();
  }

  Future<void> completeWorkout() async {
    final current = state.value;
    if (current == null) return;

    final programRepo = ref.read(programRepositoryProvider);
    final tmRepo = ref.read(trainingMaxRepositoryProvider);
    final adjustmentRepo = ref.read(progressionAdjustmentRepositoryProvider);
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
    final adjustments = await adjustmentRepo.getAdjustments();

    for (final driftPresc in current.prescriptions) {
      final driftLog = current.logs[driftPresc.id];
      if (driftLog == null || driftLog.repsOnLastSet == null) continue;

      final liftRow = current.lifts[driftPresc.liftId];
      if (liftRow == null) continue;

      final tmRow = await tmRepo.getMaxForLift(liftRow.id);
      if (tmRow == null) continue;

      try {
        final result = progressionSvc.evaluate(
          log: driftLog.toDomain(),
          prescription: driftPresc.toDomain(liftRow.name),
          adjustments: adjustments,
          currentTrainingMax: tmRow.value,
        );

        if (result.newTrainingMax != tmRow.value) {
          // Insert a new history row — do NOT upsert on liftId so every
          // progression step is preserved in the training-max history.
          await tmRepo.saveMax(TrainingMaxesCompanion.insert(
            liftId: liftRow.id,
            value: result.newTrainingMax,
            effectiveDate: now,
          ));
        }
      } on ArgumentError {
        // Adjustment rule missing — skip this lift and continue.
        continue;
      }
    }

    // Rebuild only future, incomplete days so new training maxes are reflected
    // without changing the completed workout that produced them.
    final program = await programRepo.getActiveProgram();
    if (program != null) {
      final trainingMaxes = <String, double>{};
      for (final lift in current.lifts.values) {
        final tm = await tmRepo.getMaxForLift(lift.id);
        if (tm != null) trainingMaxes[lift.name] = tm.value;
      }

      await ref.read(workoutGeneratorServiceProvider).regenerateFromWeek(
        programId: program.id,
        fromWeek: current.weekNumber,
        frequency: ProgramFrequency.fromString(program.frequency),
        trainingMaxes: trainingMaxes,
        liftDbIds: {
          for (final lift in current.lifts.values) lift.name: lift.id
        },
      );
    }

    // 3. Auto-advance week when all days in the current week are done.
    if (program != null) {
      final weeks = await programRepo.getWeeksForProgram(program.id);
      final currentWeek = weeks.firstWhere(
        (w) => w.weekNumber == current.weekNumber,
        orElse: () => weeks.first,
      );
      final updatedDays = await programRepo.getDaysForWeek(currentWeek.id);
      final allDone = updatedDays.every(
        (d) => WorkoutStatus.fromString(d.status) == WorkoutStatus.completed,
      );

      // Rebuild only future, incomplete days so new training maxes are reflected.
      // Never regenerate the week whose final day was just completed.
      final regenerationWeek =
          allDone ? current.weekNumber + 1 : current.weekNumber;
      final trainingMaxes = <String, double>{};
      for (final lift in current.lifts.values) {
        final tm = await tmRepo.getMaxForLift(lift.id);
        if (tm != null) trainingMaxes[lift.name] = tm.value;
      }

      if (regenerationWeek <= program.totalWeeks) {
        await ref.read(workoutGeneratorServiceProvider).regenerateFromWeek(
          programId: program.id,
          fromWeek: regenerationWeek,
          frequency: ProgramFrequency.fromString(program.frequency),
          trainingMaxes: trainingMaxes,
          liftDbIds: {
            for (final lift in current.lifts.values) lift.name: lift.id
          },
        );
      }

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

    ref.invalidateSelf();
  }
}

final todayWorkoutProvider =
    AsyncNotifierProvider<TodayWorkoutNotifier, TodayWorkoutState?>(
        TodayWorkoutNotifier.new);
