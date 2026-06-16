import '../../domain/models/enums.dart';
import '../../domain/models/progress_adjustment.dart';

/// Seed data for progression adjustment lookup rules.
///
/// Source of truth: "SBS Linear Progression.xlsx" progression table.
///
/// Delta values are percentage adjustments to the training max:
///   newMax = currentMax + (currentMax × delta)
///
/// The same 8 outcome deltas apply to every lift. Entries are generated
/// for all 13 canonical lift IDs plus the 'all_lifts' fallback key used
/// by [ProgressionService] when no lift-specific entry is found.
///
/// Outcomes and workbook deltas:
///   belowBy2 : -0.050  (2+ sets missed)
///   belowBy1 : -0.020  (1 set missed, or last set stopped before failure)
///   hit      :  0.000  (all sets done; last set at RIR 0)
///   plus1    : +0.010  (beat rep goal by 1 on last set)
///   plus2    : +0.030  (beat rep goal by 2 on last set)
///   plus3    : +0.050  (beat rep goal by 3 on last set)
///   plus4    : +0.050  (beat rep goal by 4 on last set)
///   plus5    : +0.050  (beat rep goal by ≥5 on last set)
class ProgressionAdjustmentSeeder {
  static const _adjustments = [
    (outcome: ProgressOutcome.belowBy2, delta: -0.050),
    (outcome: ProgressOutcome.belowBy1, delta: -0.020),
    (outcome: ProgressOutcome.hit,      delta:  0.000),
    (outcome: ProgressOutcome.plus1,    delta:  0.010),
    (outcome: ProgressOutcome.plus2,    delta:  0.030),
    (outcome: ProgressOutcome.plus3,    delta:  0.050),
    (outcome: ProgressOutcome.plus4,    delta:  0.050),
    (outcome: ProgressOutcome.plus5,    delta:  0.050),
  ];

  /// Canonical 13 workbook lift IDs + global fallback key.
  static const _liftIds = [
    // Main lifts
    'squat',
    'bench_press',
    'deadlift',
    'overhead_press',
    // Auxiliary tier 1
    'front_squat',
    'close_grip_bench',
    // Auxiliary tier 2
    'squat_aux2',
    'bench_aux2',
    'deadlift_aux',
    'ohp_aux',
    // Back exercises
    'barbell_rows',
    'dumbbell_rows',
    'pulldowns',
    // Global fallback — used by ProgressionService when no lift-specific entry exists
    'all_lifts',
  ];

  static List<ProgressAdjustment> generateProgressionAdjustments() {
    return [
      for (final liftId in _liftIds)
        for (final adj in _adjustments)
          ProgressAdjustment(
            id: '${liftId}_${adj.outcome.name}',
            liftId: liftId,
            outcome: adj.outcome,
            delta: adj.delta,
            appliesToCycle: true,
            appliesToTrainingMax: true,
          ),
    ];
  }
}
