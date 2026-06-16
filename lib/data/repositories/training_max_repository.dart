import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:drift/drift.dart';

import '../persistence/database.dart';

class TrainingMaxRepository {
  TrainingMaxRepository(this._db);
  final AppDatabase _db;

  Future<List<TrainingMaxe>> getAllMaxes() =>
      _db.select(_db.trainingMaxes).get();

  Future<TrainingMaxe?> getMaxForLift(int liftId) =>
      (_db.select(_db.trainingMaxes)
            ..where((t) => t.liftId.equals(liftId))
            ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)])
            ..limit(1))
          .getSingleOrNull();

  Future<List<TrainingMaxe>> getMaxHistoryForLift(int liftId) =>
      (_db.select(_db.trainingMaxes)
            ..where((t) => t.liftId.equals(liftId))
            ..orderBy([(t) => OrderingTerm.desc(t.effectiveDate)]))
          .get();

  Future<int> saveMax(TrainingMaxesCompanion companion) =>
      _db.into(_db.trainingMaxes).insertOnConflictUpdate(companion);

  Future<bool> updateMax(TrainingMaxesCompanion companion) =>
      _db.update(_db.trainingMaxes).replace(companion);

  Future<int> deleteMax(int id) =>
      (_db.delete(_db.trainingMaxes)
            ..where((t) => t.id.equals(id)))
          .go();
}

final trainingMaxRepositoryProvider =
    Provider<TrainingMaxRepository>((ref) {
  return TrainingMaxRepository(ref.watch(databaseProvider));
});
