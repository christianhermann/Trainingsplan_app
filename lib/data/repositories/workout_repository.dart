import '../../domain/models/enums.dart';
import '../../domain/services/rounding_service.dart';
import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/database.dart';

class WorkoutRepository {
  WorkoutRepository(this._db);
  final AppDatabase _db;

  // ── Prescriptions ──

  Future<List<ExercisePrescription>> getPrescriptionsForDay(
      int workoutDayId) =>
      (_db.select(_db.exercisePrescriptions)
            ..where((t) => t.workoutDayId.equals(workoutDayId))
            ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
          .get();

  /// Returns every [ExercisePrescription] that references [liftId],
  /// ordered by workoutDayId ascending so callers can correlate with days.
  Future<List<ExercisePrescription>> getPrescriptionsForLift(
      int liftId) =>
      (_db.select(_db.exercisePrescriptions)
            ..where((t) => t.liftId.equals(liftId))
            ..orderBy([(t) => OrderingTerm.asc(t.workoutDayId)]))
          .get();

  Future<int> savePrescription(ExercisePrescriptionsCompanion companion) =>
      _db
          .into(_db.exercisePrescriptions)
          .insertOnConflictUpdate(companion);

  Future<void> savePrescriptions(
      List<ExercisePrescriptionsCompanion> companions) async {
    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(
          _db.exercisePrescriptions, companions);
    });
  }

  // ── Exercise logs ──

  Future<List<ExercisePrescription>> getPrescriptionsForDays(
      List<int> dayIds) =>
      dayIds.isEmpty
          ? Future.value([])
          : (_db.select(_db.exercisePrescriptions)
                ..where((t) => t.workoutDayId.isIn(dayIds))
                ..orderBy([(t) => OrderingTerm.asc(t.displayOrder)]))
              .get();

  Future<List<ExerciseLog>> getLogsForPrescriptions(
      List<int> prescriptionIds) =>
      prescriptionIds.isEmpty
          ? Future.value([])
          : (_db.select(_db.exerciseLogs)
                ..where((t) => t.prescriptionId.isIn(prescriptionIds)))
              .get();

  Future<ExerciseLog?> getLogForPrescription(int prescriptionId) =>
      (_db.select(_db.exerciseLogs)
            ..where((t) => t.prescriptionId.equals(prescriptionId)))
          .getSingleOrNull();

  Future<List<ExerciseLog>> getLogsForDay(int workoutDayId) async {
    final prescriptions = await getPrescriptionsForDay(workoutDayId);
    final ids = prescriptions.map((p) => p.id).toList();
    if (ids.isEmpty) return [];
    return (_db.select(_db.exerciseLogs)
          ..where((t) => t.prescriptionId.isIn(ids)))
        .get();
  }

  Future<List<ExerciseLog>> getAllLogsForLift(int liftId) async {
    final prescriptions = await (_db.select(_db.exercisePrescriptions)
          ..where((t) => t.liftId.equals(liftId)))
        .get();
    final ids = prescriptions.map((p) => p.id).toList();
    if (ids.isEmpty) return [];
    return (_db.select(_db.exerciseLogs)
          ..where((t) => t.prescriptionId.isIn(ids))
          ..orderBy([(t) => OrderingTerm.desc(t.completedAt)]))
        .get();
  }

  Future<int> saveLog(ExerciseLogsCompanion companion) =>
      _db.into(_db.exerciseLogs).insertOnConflictUpdate(companion);

  Future<bool> updateLog(ExerciseLogsCompanion companion) =>
      _db.update(_db.exerciseLogs).replace(companion);

  Future<int> deleteLogsForPrescriptions(List<int> prescriptionIds) {
    if (prescriptionIds.isEmpty) return Future.value(0);
    return (_db.delete(_db.exerciseLogs)
          ..where((t) => t.prescriptionId.isIn(prescriptionIds)))
        .go();
  }

  /// Fast surgical update of future prescriptions for a specific lift when its TM updates.
  /// Does NOT touch any WorkoutDay, does NOT recreate days, runs in 1-2 ms.
  Future<void> updateFuturePrescriptionsForLift({
    required int liftId,
    required double newTrainingMax,
    required double roundingIncrement,
    required RoundingMode roundingMode,
  }) async {
    final activeDays = await (_db.select(_db.workoutDays)
          ..where((t) => t.status.isIn(['planned', 'inProgress', 'inprogress'])))
        .get();
    if (activeDays.isEmpty) return;

    final activeDayIds = activeDays.map((d) => d.id).toList();

    final prescriptions = await (_db.select(_db.exercisePrescriptions)
          ..where((t) =>
              t.liftId.equals(liftId) & t.workoutDayId.isIn(activeDayIds)))
        .get();
    if (prescriptions.isEmpty) return;

    const roundingSvc = RoundingService();
    final updated = <ExercisePrescriptionsCompanion>[];

    for (final p in prescriptions) {
      final newWorkingWeight = roundingSvc.round(
        newTrainingMax * p.intensity,
        roundingMode,
        roundingIncrement,
      );

      updated.add(ExercisePrescriptionsCompanion(
        id: Value(p.id),
        workoutDayId: Value(p.workoutDayId),
        liftId: Value(p.liftId),
        trainingMaxSnapshot: Value(newTrainingMax),
        intensity: Value(p.intensity),
        workingWeight: Value(newWorkingWeight),
        repsPerNormalSet: Value(p.repsPerNormalSet),
        repOutTarget: Value(p.repOutTarget),
        setGoal: Value(p.setGoal),
        displayOrder: Value(p.displayOrder),
        isPrimaryBlock: Value(p.isPrimaryBlock),
      ));
    }

    await _db.batch((batch) {
      batch.insertAllOnConflictUpdate(_db.exercisePrescriptions, updated);
    });
  }
}

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});
