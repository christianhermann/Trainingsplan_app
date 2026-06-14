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
}

final workoutRepositoryProvider = Provider<WorkoutRepository>((ref) {
  return WorkoutRepository(ref.watch(databaseProvider));
});
