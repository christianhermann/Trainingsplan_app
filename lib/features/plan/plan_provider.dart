import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/workout_repository.dart';

class PlanDaySummary {
  const PlanDaySummary({
    required this.dayNumber,
    required this.exercises,
  });

  final int dayNumber;
  final List<PlanExerciseSummary> exercises;
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
  final program = await ref.read(programRepositoryProvider).getActiveProgram();
  if (program == null) return null;

  final programRepo = ref.read(programRepositoryProvider);
  final workoutRepo = ref.read(workoutRepositoryProvider);
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
    summaries.add(PlanDaySummary(
      dayNumber: day.dayIndex + 1,
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
