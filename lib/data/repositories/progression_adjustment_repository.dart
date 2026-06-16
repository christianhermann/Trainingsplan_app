import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/database.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/progress_adjustment.dart';

/// Reads [ProgressAdjustment] rules from the [ProgressAdjustments] Drift table.
///
/// The database is the single source of truth for adjustment rules.
/// Rows are seeded on install / schema upgrade by [AppDatabase._seedProgressionAdjustments]
/// and can be overridden at runtime without code changes.
class ProgressionAdjustmentRepository {
  ProgressionAdjustmentRepository(this._db);
  final AppDatabase _db;

  /// Returns every adjustment row mapped to the domain [ProgressAdjustment] model.
  Future<List<ProgressAdjustment>> getAdjustments() async {
    final rows = await _db.select(_db.progressAdjustments).get();
    return rows.map(_toDomain).toList();
  }

  /// Returns adjustments for a specific lift ID (including 'all_lifts' fallback rows).
  Future<List<ProgressAdjustment>> getAdjustmentsForLift(String liftId) async {
    final rows = await (_db.select(_db.progressAdjustments)
          ..where(
            (t) => t.liftId.equals(liftId) | t.liftId.equals('all_lifts'),
          ))
        .get();
    return rows.map(_toDomain).toList();
  }

  ProgressAdjustment _toDomain(ProgressAdjustment row) {
    return ProgressAdjustment(
      id:                  row.id,
      liftId:              row.liftId,
      outcome:             ProgressOutcome.values.byName(row.outcome),
      delta:               row.delta,
      appliesToCycle:      row.appliesToCycle,
      appliesToTrainingMax: row.appliesToTrainingMax,
    );
  }
}

final progressionAdjustmentRepositoryProvider =
    Provider<ProgressionAdjustmentRepository>((ref) {
  return ProgressionAdjustmentRepository(ref.watch(databaseProvider));
});
