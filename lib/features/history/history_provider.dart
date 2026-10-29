import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/progress_adjustment.dart' as domain;
import '../../domain/services/progression_service.dart';

const _progressionSvc = ProgressionService();

// ---------------------------------------------------------------------------
// Model
// ---------------------------------------------------------------------------

class HistorySession {
  const HistorySession({
    required this.day,
    required this.week,
    required this.prescriptions,
    required this.logs,
    required this.lifts,
    this.adjustments = const [],
  });

  final WorkoutDay day;
  final WorkoutWeek week;
  final List<ExercisePrescription> prescriptions;
  final Map<int, ExerciseLog> logs; // prescriptionId -> log
  final Map<int, Lift> lifts; // liftId -> lift
  final List<domain.ProgressAdjustment> adjustments;

  DateTime? get completedAt => day.completedAt;
  String get title => 'Week ${week.weekNumber} - Day ${day.dayIndex + 1}';
  int get loggedCount => logs.length;
  int get totalCount => prescriptions.length;

  /// Total volume moved during the workout in kg (tonnage).
  double get totalVolumeKg {
    double total = 0.0;
    for (final p in prescriptions) {
      final log = logs[p.id];
      if (log == null || log.completedSets <= 0) continue;
      final normalSets = (log.completedSets - 1).clamp(0, 999);
      final normalReps = normalSets * p.repsPerNormalSet;
      final lastReps = log.repsOnLastSet ?? p.repsPerNormalSet;
      total += (normalReps + lastReps) * p.workingWeight;
    }
    return total;
  }

  /// Estimated duration in minutes based on timestamps or completed sets.
  int get durationMinutes {
    final logTimes = logs.values.map((l) => l.completedAt).toList();
    if (logTimes.isEmpty) return 0;
    logTimes.sort();
    final first = logTimes.first;
    final last = day.completedAt ?? logTimes.last;
    final diff = last.difference(first).inMinutes;
    if (diff > 0) return diff;

    // Fallback: estimate 3 minutes per completed set
    final totalSets = logs.values.fold<int>(0, (sum, l) => sum + l.completedSets);
    return totalSets * 3;
  }

  /// Density in kg/min (tonnage moved per minute of session duration).
  double get densityKgPerMin {
    final mins = durationMinutes;
    if (mins <= 0) return 0.0;
    return totalVolumeKg / mins;
  }

  double get densityKgPerMinute => densityKgPerMin;

  ExercisePrescription _prescFor(int prescriptionId) =>
      prescriptions.firstWhere((p) => p.id == prescriptionId);

  ExerciseLog? logFor(int prescriptionId) => logs[prescriptionId];

  /// Outcome for a prescription, or null if repsOnLastSet was not logged.
  ProgressOutcome? outcomeFor(int prescriptionId) {
    final presc = _prescFor(prescriptionId);
    final log = logs[prescriptionId];
    if (log == null || log.repsOnLastSet == null) return null;
    return _progressionSvc.determineOutcome(
      completedSets: log.completedSets,
      setGoal: presc.setGoal,
      repsOnLastSet: log.repsOnLastSet ?? 0,
      repOutTarget: presc.repOutTarget,
    );
  }

  /// TM delta fraction (e.g. 0.01 = +1.0%) for a prescription, or null.
  double? deltaFor(int prescriptionId) {
    final outcome = outcomeFor(prescriptionId);
    return outcome?.defaultDelta;
  }
}

// ---------------------------------------------------------------------------
// List provider - Optimized batch fetch (5 bulk queries instead of 200+ loops)
// ---------------------------------------------------------------------------

final historySessionsProvider =
    FutureProvider<List<HistorySession>>((ref) async {
  final programRepo = ref.watch(programRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final liftRepo = ref.watch(liftRepositoryProvider);

  final completedDays = await programRepo.getCompletedDays();
  if (completedDays.isEmpty) return [];

  // Bulk query 1: Fetch all unique weeks in one batch
  final weekIds = completedDays.map((d) => d.workoutWeekId).toSet().toList();
  final weekMap = await programRepo.getWeeksMap(weekIds);

  // Bulk query 2: Fetch all prescriptions for all completed days in one batch
  final dayIds = completedDays.map((d) => d.id).toList();
  final allPrescriptions = await workoutRepo.getPrescriptionsForDays(dayIds);

  // Group prescriptions by dayId
  final prescriptionsByDay = <int, List<ExercisePrescription>>{};
  final prescriptionIds = <int>[];
  for (final p in allPrescriptions) {
    (prescriptionsByDay[p.workoutDayId] ??= []).add(p);
    prescriptionIds.add(p.id);
  }

  // Bulk query 3: Fetch all logs for all prescriptions in one batch
  final allLogs = await workoutRepo.getLogsForPrescriptions(prescriptionIds);
  final logsByPrescription = {for (final l in allLogs) l.prescriptionId: l};

  // Bulk query 4: Cache all lifts
  final liftMap = {for (final l in await liftRepo.getAllLifts()) l.id: l};

  // Assemble sessions in memory with zero extra queries
  final sessions = <HistorySession>[];
  for (final day in completedDays) {
    final week = weekMap[day.workoutWeekId];
    if (week == null) continue;

    final dayPrescriptions = prescriptionsByDay[day.id] ?? [];
    sessions.add(HistorySession(
      day: day,
      week: week,
      prescriptions: dayPrescriptions,
      logs: {
        for (final p in dayPrescriptions)
          if (logsByPrescription.containsKey(p.id))
            p.id: logsByPrescription[p.id]!,
      },
      lifts: liftMap,
    ));
  }

  return sessions;
});

// ---------------------------------------------------------------------------
// Detail provider - O(1) direct repo lookup
// ---------------------------------------------------------------------------

final historySessionDetailProvider =
    FutureProvider.family<HistorySession?, int>((ref, dayId) async {
  final programRepo = ref.watch(programRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final liftRepo = ref.watch(liftRepositoryProvider);

  // Fetch the specific day directly.
  final day = await programRepo.getDayById(dayId);
  if (day == null) return null;
  if (WorkoutStatus.fromString(day.status) != WorkoutStatus.completed) {
    return null;
  }

  // Fetch the parent week to get weekNumber.
  final week = await programRepo.getWeekById(day.workoutWeekId);
  if (week == null) return null;

  final prescriptions = await workoutRepo.getPrescriptionsForDay(dayId);
  final logs = await workoutRepo.getLogsForDay(dayId);
  final liftMap = {for (final l in await liftRepo.getAllLifts()) l.id: l};

  return HistorySession(
    day: day,
    week: week,
    prescriptions: prescriptions,
    logs: {for (final l in logs) l.prescriptionId: l},
    lifts: liftMap,
  );
});
