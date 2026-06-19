import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/database.dart';

class LiftRepository {
  LiftRepository(this._db);
  final AppDatabase _db;

  Future<List<Lift>> getAllLifts() => _db.select(_db.lifts).get();

  Future<Lift?> getLiftByName(String name) =>
      (_db.select(_db.lifts)..where((l) => l.name.equals(name)))
          .getSingleOrNull();

  Future<int> saveLift(LiftsCompanion companion) =>
      _db.into(_db.lifts).insertOnConflictUpdate(companion);

  /// Partial update — only writes [displayName], leaves all other columns
  /// untouched. Safe to call with just an id + new name.
  Future<int> updateDisplayName(int id, String displayName) =>
      (_db.update(_db.lifts)..where((l) => l.id.equals(id)))
          .write(LiftsCompanion(displayName: Value(displayName)));

  /// Full-row replace. Caller must supply ALL non-nullable columns or
  /// Drift will throw [InvalidDataException].
  Future<bool> updateLift(LiftsCompanion companion) =>
      _db.update(_db.lifts).replace(companion);

  Future<int> deleteLift(int id) =>
      (_db.delete(_db.lifts)..where((l) => l.id.equals(id))).go();
}

final liftRepositoryProvider = Provider<LiftRepository>((ref) {
  return LiftRepository(ref.watch(databaseProvider));
});

final allLiftsProvider = FutureProvider<List<Lift>>((ref) {
  return ref.watch(liftRepositoryProvider).getAllLifts();
});

final liftByIdProvider = FutureProvider.family<Lift?, int>((ref, id) async {
  final repo = ref.watch(liftRepositoryProvider);
  final lifts = await repo.getAllLifts();
  return lifts.where((l) => l.id == id).firstOrNull;
});
