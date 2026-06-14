import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/repositories/lift_repository.dart';

// ── Models ───────────────────────────────────────────────────────────────

class HistorySession {
  const HistorySession({
    required this.day,
    required this.week,
    required this.prescriptions,
    required this.logs,
    required this.lifts,
  });

  final WorkoutDay day;
  final WorkoutWeek week;
  final List<ExercisePrescription> prescriptions;
  final Map<int, ExerciseLog> logs;
  final Map<int, Lift> lifts;

  DateTime? get completedAt => day.completedAt;

  String get title =>
      'Week ${week.weekNumber} • Day ${day.dayIndex + 1}';

  int get loggedCount => logs.length;
  int get totalCount => prescriptions.length;
}

// ── List provider ──────────────────────────────────────────────────────────

final historySessionsProvider =
    FutureProvider<List<HistorySession>>((ref) async {
  final programRepo = ref.watch(programRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final liftRepo = ref.watch(liftRepositoryProvider);

  final allLifts = await liftRepo.getAllLifts();
  final liftMap = {for (final l in allLifts) l.id: l};

  final programs = await programRepo.getAllPrograms();
  final sessions = <HistorySession>[];

  for (final program in programs) {
    final weeks = await programRepo.getWeeksForProgram(program.id);
    for (final week in weeks) {
      final days = await programRepo.getDaysForWeek(week.id);
      for (final day in days) {
        if (day.status != 'completed') continue;
        final prescriptions =
            await workoutRepo.getPrescriptionsForDay(day.id);
        final logs = await workoutRepo.getLogsForDay(day.id);
        final logMap = {for (final l in logs) l.prescriptionId: l};
        sessions.add(HistorySession(
          day: day,
          week: week,
          prescriptions: prescriptions,
          logs: logMap,
          lifts: liftMap,
        ));
      }
    }
  }

  sessions.sort((a, b) {
    final aDate = a.completedAt;
    final bDate = b.completedAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  });

  return sessions;
});

// ── Detail provider ──────────────────────────────────────────────────────────

final historySessionDetailProvider =
    FutureProvider.family<HistorySession?, int>((ref, dayId) async {
  final sessions = await ref.watch(historySessionsProvider.future);
  try {
    return sessions.firstWhere((s) => s.day.id == dayId);
  } catch (_) {
    return null;
  }
});
