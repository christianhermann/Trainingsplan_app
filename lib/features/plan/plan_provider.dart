import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/workout_duration_service.dart';

class PlanDaySummary {
  const PlanDaySummary({
    required this.dayNumber,
    required this.exercises,
    this.isCompleted = false,
    this.estimatedDurationMinutes = 0,
  });

  final int dayNumber;
  final List<PlanExerciseSummary> exercises;
  final bool isCompleted;
  final int estimatedDurationMinutes;
}

class PlanExerciseSummary {
  const PlanExerciseSummary({
    required this.name,
    required this.weight,
    required this.reps,
    required this.sets,
  });

  final String name;
  final double weight;
  final int reps;
  final int sets;
}

class PlanSummary {
  const PlanSummary({
    required this.frequency,
    required this.weekNumber,
    required this.totalWeeks,
    required this.days,
  });

  final String frequency;
  final int weekNumber;
  final int totalWeeks;
  final List<PlanDaySummary> days;
}

final planSummaryProvider =
    FutureProvider.family<PlanSummary?, int>((ref, selectedWeek) async {
  final programRepo = ref.watch(programRepositoryProvider);
  final program = await programRepo.getActiveProgram();
  if (program == null) return null;
  final workoutRepo = ref.read(workoutRepositoryProvider);
  final settingsRepo = ref.read(settingsRepositoryProvider);
  final settings = await settingsRepo.getSettings();
  final defaultRestSeconds = settings?.restTimerSeconds ?? 180;
  const durationSvc = WorkoutDurationService();

  final lifts = {
    for (final lift in await ref.read(allLiftsProvider.future)) lift.id: lift,
  };
  final weeks = await programRepo.getWeeksForProgram(program.id);
  if (weeks.isEmpty) return null;

  final week = weeks.firstWhere(
    (item) => item.weekNumber == selectedWeek,
    orElse: () => weeks.first,
  );
  final days = await programRepo.getDaysForWeek(week.id);
  final summaries = <PlanDaySummary>[];

  for (final day in days) {
    final prescriptions = await workoutRepo.getPrescriptionsForDay(day.id);
    final isCompleted =
        WorkoutStatus.fromString(day.status) == WorkoutStatus.completed ||
        day.completedAt != null;
    final durationMinutes = durationSvc.estimateDurationMinutes(
      prescriptions: prescriptions,
      lifts: lifts,
      defaultRestSeconds: defaultRestSeconds,
    );

    summaries.add(PlanDaySummary(
      dayNumber: day.dayIndex + 1,
      isCompleted: isCompleted,
      estimatedDurationMinutes: durationMinutes,
      exercises: [
        for (final prescription in prescriptions)
          PlanExerciseSummary(
            name: lifts[prescription.liftId]?.displayName ??
                'Exercise ${prescription.liftId}',
            weight: prescription.workingWeight,
            reps: prescription.repsPerNormalSet,
            sets: prescription.setGoal,
          ),
      ],
    ));
  }

  return PlanSummary(
    frequency: program.frequency,
    weekNumber: week.weekNumber,
    totalWeeks: program.totalWeeks,
    days: summaries,
  );
});
