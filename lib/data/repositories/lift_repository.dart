import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/database.dart';

class LiftRepository {
  LiftRepository(this._db);
  final AppDatabase _db;

  Future<List<Lift>> getAllLifts() => _db.select(_db.lifts).get();

  Future<List<Lift>> getMainLifts() =>
      (_db.select(_db.lifts)..where((t) => t.isMainLift.equals(true))).get();

  Future<List<Lift>> getAuxiliaryLifts() =>
      (_db.select(_db.lifts)..where((t) => t.isAuxiliaryLift.equals(true)))
          .get();

  Future<Lift?> getLiftByName(String name) =>
      (_db.select(_db.lifts)..where((t) => t.name.equals(name)))
          .getSingleOrNull();

  Future<Lift> getLiftById(int id) =>
      (_db.select(_db.lifts)..where((t) => t.id.equals(id))).getSingle();

  Future<int> upsertLift(LiftsCompanion companion) =>
      _db.into(_db.lifts).insertOnConflictUpdate(companion);
}

final liftRepositoryProvider = Provider<LiftRepository>((ref) {
  return LiftRepository(ref.watch(databaseProvider));
});
