import '../../domain/models/intensity_point.dart';

/// Seed data for the 21-week intensity lookup table.
///
/// Source of truth: "SBS Linear Progression.xlsx", Quick Setup tab,
/// rows labelled "Intensity / Week 1-21" (columns C58:W70).
///
/// The SBS Linear Progression is NOT a periodised/wave program.
/// Intensity stays constant every week; training load grows via
/// training-max autoregulation (RIR feedback).
///
/// Three intensity tiers exist:
///   Main lifts            : 87.5 % → 0.875  (Squat, Bench, Deadlift, Push Press)
///   Auxiliary tier 1      : 82.5 % → 0.825  (Front Squat, Close Grip Bench)
///   Auxiliary tier 2      : 75.0 % → 0.750  (all remaining auxiliaries)
///
/// All values taken verbatim from the spreadsheet; no interpolation applied.

class IntensitySeeder {
  /// Generate all intensity lookup points for all lifts.
  static List<IntensityPoint> generateIntensityPoints() {
    final points = <IntensityPoint>[];

    // ── Main lifts (87.5 % / 0.875 for all 21 weeks) ──────────────────────
    const mainLifts = ['squat', 'bench_press', 'deadlift', 'overhead_press'];
    final mainIntensities = _mainLiftIntensities();

    for (final liftId in mainLifts) {
      for (int week = 1; week <= 21; week++) {
        points.add(IntensityPoint(
          id: '${liftId}_w$week',
          liftId: liftId,
          weekNumber: week,
          intensity: mainIntensities[week - 1],
        ));
      }
    }

    // ── Auxiliary tier-1 lifts (82.5 % / 0.825 for all 21 weeks) ──────────
    const auxTier1Lifts = [
      'front_squat',        // Squat auxiliary 1 default
      'close_grip_bench',   // Bench auxiliary 1 default
    ];
    final auxTier1Intensities = _auxiliaryTier1Intensities();

    for (final liftId in auxTier1Lifts) {
      for (int week = 1; week <= 21; week++) {
        points.add(IntensityPoint(
          id: '${liftId}_w$week',
          liftId: liftId,
          weekNumber: week,
          intensity: auxTier1Intensities[week - 1],
        ));
      }
    }

    // ── Auxiliary tier-2 lifts (75.0 % / 0.750 for all 21 weeks) ──────────
    const auxTier2Lifts = [
      'squat_aux2',              // Squat auxiliary 2 default
      'bench_aux2',              // Bench auxiliary 2 default
      'deadlift_aux',            // Deadlift auxiliary default
      'ohp_aux',                 // OHP auxiliary default
      'barbell_rows',            // Back exercise 1 default
      'dumbbell_rows',           // Back exercise 2 default
      'pulldowns',               // Back exercise 3 default
    ];
    final auxTier2Intensities = _auxiliaryTier2Intensities();

    for (final liftId in auxTier2Lifts) {
      for (int week = 1; week <= 21; week++) {
        points.add(IntensityPoint(
          id: '${liftId}_w$week',
          liftId: liftId,
          weekNumber: week,
          intensity: auxTier2Intensities[week - 1],
        ));
      }
    }

    return points;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Main lifts — workbook: 87.5 % flat, weeks 1-21
  // Source: Quick Setup C58:W61 (Squat / Bench / Deadlift / Push Press rows)
  // ──────────────────────────────────────────────────────────────────────────
  static List<double> _mainLiftIntensities() {
    return [
      0.875, // week  1 — workbook: 87.5
      0.875, // week  2 — workbook: 87.5
      0.875, // week  3 — workbook: 87.5
      0.875, // week  4 — workbook: 87.5
      0.875, // week  5 — workbook: 87.5
      0.875, // week  6 — workbook: 87.5
      0.875, // week  7 — workbook: 87.5
      0.875, // week  8 — workbook: 87.5
      0.875, // week  9 — workbook: 87.5
      0.875, // week 10 — workbook: 87.5
      0.875, // week 11 — workbook: 87.5
      0.875, // week 12 — workbook: 87.5
      0.875, // week 13 — workbook: 87.5
      0.875, // week 14 — workbook: 87.5
      0.875, // week 15 — workbook: 87.5
      0.875, // week 16 — workbook: 87.5
      0.875, // week 17 — workbook: 87.5
      0.875, // week 18 — workbook: 87.5
      0.875, // week 19 — workbook: 87.5
      0.875, // week 20 — workbook: 87.5
      0.875, // week 21 — workbook: 87.5
    ];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Auxiliary tier-1 — workbook: 82.5 % flat, weeks 1-21
  // Source: Quick Setup C62:W63 (Front Squat / Close Grip Bench rows)
  // ──────────────────────────────────────────────────────────────────────────
  static List<double> _auxiliaryTier1Intensities() {
    return [
      0.825, // week  1 — workbook: 82.5
      0.825, // week  2 — workbook: 82.5
      0.825, // week  3 — workbook: 82.5
      0.825, // week  4 — workbook: 82.5
      0.825, // week  5 — workbook: 82.5
      0.825, // week  6 — workbook: 82.5
      0.825, // week  7 — workbook: 82.5
      0.825, // week  8 — workbook: 82.5
      0.825, // week  9 — workbook: 82.5
      0.825, // week 10 — workbook: 82.5
      0.825, // week 11 — workbook: 82.5
      0.825, // week 12 — workbook: 82.5
      0.825, // week 13 — workbook: 82.5
      0.825, // week 14 — workbook: 82.5
      0.825, // week 15 — workbook: 82.5
      0.825, // week 16 — workbook: 82.5
      0.825, // week 17 — workbook: 82.5
      0.825, // week 18 — workbook: 82.5
      0.825, // week 19 — workbook: 82.5
      0.825, // week 20 — workbook: 82.5
      0.825, // week 21 — workbook: 82.5
    ];
  }

  // ──────────────────────────────────────────────────────────────────────────
  // Auxiliary tier-2 — workbook: 75.0 % flat, weeks 1-21
  // Source: Quick Setup C64:W70 (Squat aux2 / Bench aux2 / DL aux /
  //         OHP aux / Barbell rows / DB rows / Pull-downs rows)
  // ──────────────────────────────────────────────────────────────────────────
  static List<double> _auxiliaryTier2Intensities() {
    return [
      0.750, // week  1 — workbook: 75.0
      0.750, // week  2 — workbook: 75.0
      0.750, // week  3 — workbook: 75.0
      0.750, // week  4 — workbook: 75.0
      0.750, // week  5 — workbook: 75.0
      0.750, // week  6 — workbook: 75.0
      0.750, // week  7 — workbook: 75.0
      0.750, // week  8 — workbook: 75.0
      0.750, // week  9 — workbook: 75.0
      0.750, // week 10 — workbook: 75.0
      0.750, // week 11 — workbook: 75.0
      0.750, // week 12 — workbook: 75.0
      0.750, // week 13 — workbook: 75.0
      0.750, // week 14 — workbook: 75.0
      0.750, // week 15 — workbook: 75.0
      0.750, // week 16 — workbook: 75.0
      0.750, // week 17 — workbook: 75.0
      0.750, // week 18 — workbook: 75.0
      0.750, // week 19 — workbook: 75.0
      0.750, // week 20 — workbook: 75.0
      0.750, // week 21 — workbook: 75.0
    ];
  }
}
