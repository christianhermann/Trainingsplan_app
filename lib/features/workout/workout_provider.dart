import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/workout_repository.dart';

// ── State ───────────────────────────────────────────────────────────────────

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

// ── Notifier ─────────────────────────────────────────────────────────────────

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
      (d) => d.status == 'planned' || d.status == 'inProgress',
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
      isCompleted: todayDay.status == 'completed',
    );
  }

  Future<void> updateLog(ExerciseLogsCompanion companion) async {
    await ref.read(workoutRepositoryProvider).saveLog(companion);
    ref.invalidateSelf();
  }

  /// Mark current day completed; auto-advance program week when all days done.
  Future<void> completeWorkout() async {
    final current = state.valueOrNull;
    if (current == null) return;

    final programRepo = ref.read(programRepositoryProvider);

    // 1. Mark day completed
    await programRepo.updateDay(WorkoutDaysCompanion(
      id: Value(current.workoutDayId),
      status: const Value('completed'),
      completedAt: Value(DateTime.now()),
    ));

    // 2. Re-fetch all days for current week and check if all are done
    final program = await programRepo.getActiveProgram();
    if (program != null) {
      final weeks = await programRepo.getWeeksForProgram(program.id);
      final currentWeek = weeks.firstWhere(
        (w) => w.weekNumber == program.currentWeek,
        orElse: () => weeks.first,
      );
      final updatedDays = await programRepo.getDaysForWeek(currentWeek.id);
      final allDone = updatedDays.every(
        (d) => d.id == current.workoutDayId || d.status == 'completed',
      );

      if (allDone && program.currentWeek < program.totalWeeks) {
        await programRepo.updateProgram(ProgramsCompanion(
          id: Value(program.id),
          currentWeek: Value(program.currentWeek + 1),
          updatedAt: Value(DateTime.now()),
        ));
      }
    }

    ref.invalidateSelf();
  }
}

final todayWorkoutProvider =
    AsyncNotifierProvider<TodayWorkoutNotifier, TodayWorkoutState?>(
        TodayWorkoutNotifier.new);
