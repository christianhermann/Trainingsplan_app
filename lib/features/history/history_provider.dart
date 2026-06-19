import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/seeders/progression_adjustment_seeder.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/progression_service.dart';

// Cached seeder data - generated once per app run.
final _adjustments =
    ProgressionAdjustmentSeeder.generateProgressionAdjustments();

const _progressionSvc = ProgressionService();

// -- Model ------------------------------------------------------------------

class HistorySession {
  const HistorySession({
    required this.day,
    required this.week,
    required this.prescriptions,
    required this.logs,
    required this.lifts,
  });

  final WorkoutDay                 day;
  final WorkoutWeek                week;
  final List<ExercisePrescription> prescriptions;
  final Map<int, ExerciseLog>      logs;   // prescriptionId -> log
  final Map<int, Lift>             lifts;  // liftId -> lift

  DateTime? get completedAt => day.completedAt;
  String    get title       => 'Week ${week.weekNumber} - Day ${day.dayIndex + 1}';
  int       get loggedCount => logs.length;
  int       get totalCount  => prescriptions.length;

  // -- Progression helpers --------------------------------------------------

  ExercisePrescription _prescFor(int prescriptionId) =>
      prescriptions.firstWhere(
        (p) => p.id == prescriptionId,
        orElse: () =>
            throw StateError('Prescription $prescriptionId not in session'),
      );

  /// [ProgressOutcome] for a prescription, or null if no reps recorded.
  ProgressOutcome? outcomeFor(int prescriptionId) {
    final reps = logs[prescriptionId]?.repsOnLastSet;
    if (reps == null) return null;
    return _progressionSvc.determineOutcome(
      repsOnLastSet: reps,
      repOutTarget:  _prescFor(prescriptionId).repOutTarget,
    );
  }

  /// TM delta fraction (e.g. 0.01 = +1.0%) for a prescription, or null.
  double? deltaFor(int prescriptionId) {
    final outcome = outcomeFor(prescriptionId);
    if (outcome == null) return null;
    final liftName = lifts[_prescFor(prescriptionId).liftId]?.name;

    // Lift-specific match first, then global fallback.
    return _adjustments
            .where((a) =>
                a.liftId == liftName &&
                a.outcome == outcome &&
                a.appliesToTrainingMax)
            .firstOrNull
            ?.delta ??
        _adjustments
            .where((a) =>
                a.liftId == 'all_lifts' &&
                a.outcome == outcome &&
                a.appliesToTrainingMax)
            .firstOrNull
            ?.delta;
  }
}

// -- List provider ----------------------------------------------------------

final historySessionsProvider =
    FutureProvider<List<HistorySession>>((ref) async {
  final programRepo = ref.watch(programRepositoryProvider);
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final liftRepo    = ref.watch(liftRepositoryProvider);

  final liftMap  = {for (final l in await liftRepo.getAllLifts()) l.id: l};
  final programs = await programRepo.getAllPrograms();
  final sessions = <HistorySession>[];

  for (final program in programs) {
    for (final week in await programRepo.getWeeksForProgram(program.id)) {
      for (final day in await programRepo.getDaysForWeek(week.id)) {
        if (WorkoutStatus.fromString(day.status) != WorkoutStatus.completed)
          continue;
        final prescriptions =
            await workoutRepo.getPrescriptionsForDay(day.id);
        final logs = await workoutRepo.getLogsForDay(day.id);
        sessions.add(HistorySession(
          day:           day,
          week:          week,
          prescriptions: prescriptions,
          logs:          {for (final l in logs) l.prescriptionId: l},
          lifts:         liftMap,
        ));
      }
    }
  }

  // Most-recent first; null completedAt sorts to the end.
  sessions.sort((a, b) {
    final aDate = a.completedAt;
    final bDate = b.completedAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return  1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  });

  return sessions;
});

// -- Detail provider --------------------------------------------------------

final historySessionDetailProvider =
    FutureProvider.family<HistorySession?, int>((ref, dayId) async {
  final sessions = await ref.watch(historySessionsProvider.future);
  return sessions.where((s) => s.day.id == dayId).firstOrNull;
});
