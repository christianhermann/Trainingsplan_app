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
  final List<String> exercises;
}

class PlanSummary {
  const PlanSummary({
    required this.frequency,
    required this.weekNumber,
    required this.days,
  });

  final String frequency;
  final int weekNumber;
  final List<PlanDaySummary> days;
}

final planSummaryProvider = FutureProvider<PlanSummary?>((ref) async {
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
    (item) => item.weekNumber == program.currentWeek,
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
          lifts[prescription.liftId]?.displayName ??
              'Exercise ${prescription.liftId}',
      ],
    ));
  }

  return PlanSummary(
    frequency: program.frequency,
    weekNumber: week.weekNumber,
    days: summaries,
  );
});
