import '../../domain/models/rep_target_point.dart';

/// Seed data for the rep-target lookup table.
///
/// Source of truth: "SBS Linear Progression.xlsx", Quick Setup tab.
///
/// Rep target row  (C24:W36) — reps per set at each intensity percentage.
/// Last set RIR target row (C41:W53) — RIR target on the final set.
///
/// Both rows are identical for every lift (Squat, Bench, Deadlift,
/// Push Press, Front Squat, Squat aux2, Close Grip Bench, Bench aux2,
/// Deadlift aux, OHP aux, Barbell rows, DB rows, Pull-downs).
///
/// The workbook contains ONE shared lookup table — there is no separate
/// "last-set rep count".  The last-set distinction is handled by the
/// RIR target (0 by default = work to technical limit), which is stored
/// in [RepTargetPoint.lastSetRirTarget].
///
/// Intensity steps: 50.0 → 100.0 % in 2.5 % increments (21 entries).

class RepTargetSeeder {
  /// All rep-target lookup points (shared across every lift).
  static List<RepTargetPoint> generateRepTargetPoints() {
    final points = <RepTargetPoint>[];

    // All lift IDs that need a rep-target entry.
    // Must match IDs used in intensity_seeder.dart and the lifts table.
    const allLiftIds = [
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
      'barbell_rows',
      'dumbbell_rows',
      'pulldowns',
    ];

    for (final liftId in allLiftIds) {
      points.addAll(_repTargetsForLift(liftId));
    }

    return points;
  }

  /// Builds the 21-entry rep-target list for a single lift.
  ///
  /// Workbook columns (Quick Setup C24:W24 / C41:W41):
  ///   Intensity % : 50.0  52.5  55.0  57.5  60.0  62.5  65.0  67.5
  ///                 70.0  72.5  75.0  77.5  80.0  82.5  85.0  87.5
  ///                 90.0  92.5  95.0  97.5 100.0
  ///   Reps/set    :   20    18    16    15    14    13    12    11
  ///                   10     9     8     7     6     5     4     3
  ///                    2     2     1     1     1
  ///   Last-set RIR:    0     0     0     0     0     0     0     0
  ///                    0     0     0     0     0     0     0     0
  ///                    0     0     0     0     0
  static List<RepTargetPoint> _repTargetsForLift(String liftId) {
    // Each record: (intensityPct, repsPerSet, lastSetRirTarget)
    // intensityPct is the workbook percentage value (e.g. 87.5).
    // intensity stored as decimal (e.g. 0.875).
    const entries = [
      ( 50.0, 20, 0), // workbook: 50.0 % → 20 reps, RIR target 0
      ( 52.5, 18, 0), // workbook: 52.5 % → 18 reps, RIR target 0
      ( 55.0, 16, 0), // workbook: 55.0 % → 16 reps, RIR target 0
      ( 57.5, 15, 0), // workbook: 57.5 % → 15 reps, RIR target 0
      ( 60.0, 14, 0), // workbook: 60.0 % → 14 reps, RIR target 0
      ( 62.5, 13, 0), // workbook: 62.5 % → 13 reps, RIR target 0
      ( 65.0, 12, 0), // workbook: 65.0 % → 12 reps, RIR target 0
      ( 67.5, 11, 0), // workbook: 67.5 % → 11 reps, RIR target 0
      ( 70.0, 10, 0), // workbook: 70.0 % → 10 reps, RIR target 0
      ( 72.5,  9, 0), // workbook: 72.5 % →  9 reps, RIR target 0
      ( 75.0,  8, 0), // workbook: 75.0 % →  8 reps, RIR target 0
      ( 77.5,  7, 0), // workbook: 77.5 % →  7 reps, RIR target 0
      ( 80.0,  6, 0), // workbook: 80.0 % →  6 reps, RIR target 0
      ( 82.5,  5, 0), // workbook: 82.5 % →  5 reps, RIR target 0
      ( 85.0,  4, 0), // workbook: 85.0 % →  4 reps, RIR target 0
      ( 87.5,  3, 0), // workbook: 87.5 % →  3 reps, RIR target 0
      ( 90.0,  2, 0), // workbook: 90.0 % →  2 reps, RIR target 0
      ( 92.5,  2, 0), // workbook: 92.5 % →  2 reps, RIR target 0
      ( 95.0,  1, 0), // workbook: 95.0 % →  1 rep,  RIR target 0
      ( 97.5,  1, 0), // workbook: 97.5 % →  1 rep,  RIR target 0
      (100.0,  1, 0), // workbook: 100.0% →  1 rep,  RIR target 0
    ];

    return entries.map((e) {
      final pctKey = (e.$1 * 10).toStringAsFixed(0); // e.g. "875"
      return RepTargetPoint(
        id: '${liftId}_$pctKey',
        liftId: liftId,
        intensity: e.$1 / 100.0,
        repsPerSet: e.$2,
        lastSetRirTarget: e.$3,
      );
    }).toList();
  }
}
