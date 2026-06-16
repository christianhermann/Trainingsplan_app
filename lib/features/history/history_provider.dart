import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/seeders/progression_adjustment_seeder.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/progression_service.dart';

// ── Cached seeder data (generated once per app run) ──────────────────────────────

final _adjustments =
    ProgressionAdjustmentSeeder.generateProgressionAdjustments();

// ── Models ────────────────────────────────────────────────────────────────────

class HistorySession {
  const HistorySession({
    required this.day,
    required this.week,
    required this.prescriptions,
    required this.logs,
    required this.lifts,
  });

  final WorkoutDay                  day;
  final WorkoutWeek                 week;
  final List<ExercisePrescription>  prescriptions;
  final Map<int, ExerciseLog>       logs;   // prescriptionId → log
  final Map<int, Lift>              lifts;  // liftId → lift

  DateTime? get completedAt => day.completedAt;

  String get title =>
      'Week ${week.weekNumber} \u2022 Day ${day.dayIndex + 1}';

  int get loggedCount => logs.length;
  int get totalCount  => prescriptions.length;

  // ── Progression helpers ──────────────────────────────────────────────

  /// Returns the [ProgressOutcome] for a prescription's log, or null if
  /// the prescription has no log or no repsOnLastSet recorded.
  ///
  /// Re-derives the outcome from repsOnLastSet vs repOutTarget — same
  /// logic as [ProgressionService.determineOutcome], pure and free.
  ProgressOutcome? outcomeFor(int prescriptionId) {
    final log = logs[prescriptionId];
    final reps = log?.repsOnLastSet;
    if (reps == null) return null;

    final presc = prescriptions.firstWhere(
      (p) => p.id == prescriptionId,
      orElse: () => throw StateError(
          'Prescription $prescriptionId not in session'),
    );

    return const ProgressionService().determineOutcome(
      repsOnLastSet: reps,
      repOutTarget:  presc.repOutTarget,
    );
  }

  /// Returns the TM delta fraction (e.g. 0.01 = +1.0%) for a prescription,
  /// or null if no log / outcome exists.
  ///
  /// Looks up the delta from the seeder using the lift's canonical name as
  /// liftId, with 'all_lifts' as fallback — same lookup order as
  /// [ProgressionService._lookupDelta].
  double? deltaFor(int prescriptionId) {
    final outcome = outcomeFor(prescriptionId);
    if (outcome == null) return null;

    final presc = prescriptions.firstWhere(
      (p) => p.id == prescriptionId,
      orElse: () => throw StateError(
          'Prescription $prescriptionId not in session'),
    );

    // Resolve string liftId from the Lift row (same as workout_provider.dart).
    final liftName = lifts[presc.liftId]?.name;

    // Lift-specific match first, then 'all_lifts' fallback.
    final specific = _adjustments.where(
      (a) =>
          a.liftId == liftName &&
          a.outcome == outcome &&
          a.appliesToTrainingMax,
    );
    if (specific.isNotEmpty) return specific.first.delta;

    final fallback = _adjustments.where(
      (a) =>
          a.liftId == 'all_lifts' &&
          a.outcome == outcome &&
          a.appliesToTrainingMax,
    );
    if (fallback.isNotEmpty) return fallback.first.delta;

    return null; // no rule found — should not happen with seeded data
  }
}

// ── List provider ──────────────────────────────────────────────────────────────────

final historySessionsProvider =
    FutureProvider<List<HistorySession>>((ref) async {
  final programRepo = ref.watch(programRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final liftRepo    = ref.watch(liftRepositoryProvider);

  final allLifts = await liftRepo.getAllLifts();
  final liftMap  = {for (final l in allLifts) l.id: l};

  final programs = await programRepo.getAllPrograms();
  final sessions = <HistorySession>[];

  for (final program in programs) {
    final weeks = await programRepo.getWeeksForProgram(program.id);
    for (final week in weeks) {
      final days = await programRepo.getDaysForWeek(week.id);
      for (final day in days) {
        if (day.status != 'completed') continue;
        final prescriptions = await workoutRepo.getPrescriptionsForDay(day.id);
        final logs          = await workoutRepo.getLogsForDay(day.id);
        final logMap        = {for (final l in logs) l.prescriptionId: l};
        sessions.add(HistorySession(
          day:           day,
          week:          week,
          prescriptions: prescriptions,
          logs:          logMap,
          lifts:         liftMap,
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

// ── Detail provider ─────────────────────────────────────────────────────────────────

final historySessionDetailProvider =
    FutureProvider.family<HistorySession?, int>((ref, dayId) async {
  final sessions = await ref.watch(historySessionsProvider.future);
  try {
    return sessions.firstWhere((s) => s.day.id == dayId);
  } catch (_) {
    return null;
  }
});
