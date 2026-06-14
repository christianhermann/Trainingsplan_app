import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/lift_repository.dart';

class TodayWorkoutState {
  TodayWorkoutState({
    required this.workoutDayId,
    required this.weekNumber,
    required this.dayIndex,
    required this.prescriptions,
    required this.logs,
    required this.lifts,
    required this.isCompleted,
  });

  final int workoutDayId;
  final int weekNumber;
  final int dayIndex;
  final List<ExercisePrescription> prescriptions;
  final Map<int, ExerciseLog> logs;
  final Map<int, Lift> lifts;
  final bool isCompleted;
}

class TodayWorkoutNotifier extends AsyncNotifier<TodayWorkoutState?> {
  @override
  Future<TodayWorkoutState?> build() async {
    return _load();
  }

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

    final prescriptions =
        await workoutRepo.getPrescriptionsForDay(todayDay.id);
    final logs = await workoutRepo.getLogsForDay(todayDay.id);
    final logMap = {for (final l in logs) l.prescriptionId: l};
    final allLifts = await liftRepo.getAllLifts();
    final liftMap = {for (final l in allLifts) l.id: l};

    return TodayWorkoutState(
      workoutDayId: todayDay.id,
      weekNumber: currentWeek.weekNumber,
      dayIndex: todayDay.dayIndex,
      prescriptions: prescriptions,
      logs: logMap,
      lifts: liftMap,
      isCompleted: todayDay.status == 'completed',
    );
  }

  Future<void> updateLog(ExerciseLogsCompanion companion) async {
    await ref.read(workoutRepositoryProvider).saveLog(companion);
    ref.invalidateSelf();
  }

  Future<void> completeWorkout() async {
    final current = state.valueOrNull;
    if (current == null) return;
    await ref.read(programRepositoryProvider).updateDay(
          WorkoutDaysCompanion(
            id: Value(current.workoutDayId),
            status: const Value('completed'),
            completedAt: Value(DateTime.now()),
          ),
        );
    ref.invalidateSelf();
  }
}

final todayWorkoutProvider =
    AsyncNotifierProvider<TodayWorkoutNotifier, TodayWorkoutState?>(
        TodayWorkoutNotifier.new);
