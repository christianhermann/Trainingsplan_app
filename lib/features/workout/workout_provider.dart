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

// ── State ─────────────────────────────────────────────────────────────────────

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
  final Map<int, ExerciseLog>      logs;
  final Map<int, Lift>             lifts;
  final bool                       isCompleted;
}

// ── Notifier ──────────────────────────────────────────────────────────────────

class TodayWorkoutNotifier extends AsyncNotifier<TodayWorkoutState?> {
  @override
  Future<TodayWorkoutState?> build() => _load();

  Future<TodayWorkoutState?> _load() async {
    final programRepo = ref.read(programRepositoryProvider);
    final workoutRepo = ref.read(workoutRepositoryProvider);
    final liftRepo    = ref.read(liftRepositoryProvider);

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

    // Use enum comparison instead of raw strings.
    final todayDay = days.firstWhere(
      (d) {
        final status = WorkoutStatus.fromString(d.status);
        return status == WorkoutStatus.planned || status == WorkoutStatus.inProgress;
      },
      orElse: () => days.last,
    );

    final prescriptions = await workoutRepo.getPrescriptionsForDay(todayDay.id);
    final logs          = await workoutRepo.getLogsForDay(todayDay.id);
    final allLifts      = await liftRepo.getAllLifts();

    return TodayWorkoutState(
      programId:     program.id,
      workoutDayId:  todayDay.id,
      weekNumber:    currentWeek.weekNumber,
      dayIndex:      todayDay.dayIndex,
      prescriptions: prescriptions,
      logs:   {for (final l in logs)     l.prescriptionId: l},
      lifts:  {for (final l in allLifts) l.id:             l},
      isCompleted: WorkoutStatus.fromString(todayDay.status) == WorkoutStatus.completed,
    );
  }

  Future<void> updateLog(ExerciseLogsCompanion companion) async {
    await ref.read(workoutRepositoryProvider).saveLog(companion);
    ref.invalidateSelf();
  }

  Future<void> completeWorkout() async {
    final current = state.value;
    if (current == null) return;

    final programRepo    = ref.read(programRepositoryProvider);
    final tmRepo         = ref.read(trainingMaxRepositoryProvider);
    final adjustmentRepo = ref.read(progressionAdjustmentRepositoryProvider);
    final now            = DateTime.now();

    // 1. Mark the day completed.
    await programRepo.updateDay(WorkoutDaysCompanion(
      id:          Value(current.workoutDayId),
      status:      Value(WorkoutStatus.completed.name),
      completedAt: Value(now),
    ));

    // 2. Run progression for every prescription that has a completed log
    //    with a recorded repsOnLastSet value.
    const progressionSvc = ProgressionService();
    final adjustments    = await adjustmentRepo.getAdjustments();

    for (final driftPresc in current.prescriptions) {
      final driftLog = current.logs[driftPresc.id];
      // Skip if no log or reps not recorded — avoids false TM penalty.
      if (driftLog == null || driftLog.repsOnLastSet == null) continue;

      final liftRow = current.lifts[driftPresc.liftId];
      if (liftRow == null) continue;

      final tmRow = await tmRepo.getMaxForLift(liftRow.id);
      if (tmRow == null) continue;

      final domainLog = domain.ExerciseLog(
        id:             driftLog.id.toString(),
        prescriptionId: driftLog.prescriptionId.toString(),
        completedSets:  driftLog.completedSets,
        repsOnLastSet:  driftLog.repsOnLastSet,
        notes:          driftLog.notes,
        videoUrl:       driftLog.videoUrl,
        completedAt:    driftLog.completedAt,
      );

      final domainPresc = domain.ExercisePrescription(
        id:                  driftPresc.id.toString(),
        workoutDayId:        driftPresc.workoutDayId.toString(),
        liftId:              liftRow.name,
        trainingMaxSnapshot: driftPresc.trainingMaxSnapshot,
        intensity:           driftPresc.intensity,
        workingWeight:       driftPresc.workingWeight,
        repsPerNormalSet:    driftPresc.repsPerNormalSet,
        repOutTarget:        driftPresc.repOutTarget,
        setGoal:             driftPresc.setGoal,
        displayOrder:        driftPresc.displayOrder,
        isPrimaryBlock:      driftPresc.isPrimaryBlock,
      );

      try {
        final result = progressionSvc.evaluate(
          log:                domainLog,
          prescription:       domainPresc,
          adjustments:        adjustments,
          currentTrainingMax: tmRow.value,
        );

        if (result.newTrainingMax != tmRow.value) {
          await tmRepo.saveMax(TrainingMaxesCompanion.insert(
            liftId:        liftRow.id,
            value:         result.newTrainingMax,
            effectiveDate: now,
          ));
        }
      } on ArgumentError {
        continue;
      }
    }

    // 3. Auto-advance week when all days are done.
    //    Re-query after the status update above has been flushed to DB.
    final program = await programRepo.getActiveProgram();
    if (program != null) {
      final weeks = await programRepo.getWeeksForProgram(program.id);
      final currentWeek = weeks.firstWhere(
        (w) => w.weekNumber == program.currentWeek,
        orElse: () => weeks.first,
      );

      final updatedDays = await programRepo.getDaysForWeek(currentWeek.id);
      final allDone = updatedDays.every(
        (d) => WorkoutStatus.fromString(d.status) == WorkoutStatus.completed,
      );

      if (allDone && program.currentWeek < program.totalWeeks) {
        await programRepo.updateProgram(ProgramsCompanion(
          id:          Value(program.id),
          currentWeek: Value(program.currentWeek + 1),
          updatedAt:   Value(now),
        ));
      }
    }

    ref.invalidateSelf();
  }
}

final todayWorkoutProvider =
    AsyncNotifierProvider<TodayWorkoutNotifier, TodayWorkoutState?>(
        TodayWorkoutNotifier.new);
