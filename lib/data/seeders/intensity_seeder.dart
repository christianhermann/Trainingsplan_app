import '../../domain/models/intensity_point.dart';

/// Seed data for the 21-week intensity lookup table.
///
/// Per workbook-logic.md:
/// - Main lifts: "0.70, 0.725, 0.75, 0.725, 0.75, 0.775, 0.60, then later waves repeat
///   and eventually reach 0.825 before returning to 0.60 in week 21"
/// - Auxiliary lifts: "0.65, 0.675, 0.70, 0.675, 0.70, 0.725, 0.55 and later climbs
///   to 0.775 before returning to 0.55 in week 21"
///
/// TODO: The exact weeks 8-21 pattern is not fully specified in the workbook.
/// Clarify whether the pattern repeats exactly (3 identical 7-week waves) or varies.
/// See docs/open-questions.md - this affects all intensity-dependent calculations.

class IntensitySeeder {
  /// Generate all intensity lookup points for all lifts.
  static List<IntensityPoint> generateIntensityPoints() {
    final points = <IntensityPoint>[];

    // Main lifts
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

    // Auxiliary lifts
    const auxiliaryLifts = [
      'leg_press',
      'wider_stance_squat',
      'dumbbell_bench',
      'incline_dumbbell_press',
      'trap_bar_deadlift',
      'dumbbell_overhead_press',
    ];
    final auxIntensities = _auxiliaryLiftIntensities();

    for (final liftId in auxiliaryLifts) {
      for (int week = 1; week <= 21; week++) {
        points.add(IntensityPoint(
          id: '${liftId}_w$week',
          liftId: liftId,
          weekNumber: week,
          intensity: auxIntensities[week - 1],
        ));
      }
    }

    return points;
  }

  /// Main lift intensity progression for 21 weeks.
  /// 
  /// Weeks 1-7 are documented explicitly:
  /// 0.70, 0.725, 0.75, 0.725, 0.75, 0.775, 0.60
  /// 
  /// Weeks 8-21 pattern is implicit. Currently assuming the pattern repeats.
  /// TODO: Verify exact intensities for weeks 8-21 from actual workbook.
  /// The workbook mentions "later waves repeat" and "eventually reach 0.825"
  /// but the exact sequence is not fully transcribed.
  static List<double> _mainLiftIntensities() {
    return [
      // Wave 1 (weeks 1-7)
      0.70,   // week 1
      0.725,  // week 2
      0.75,   // week 3
      0.725,  // week 4
      0.75,   // week 5
      0.775,  // week 6
      0.60,   // week 7 (deload)

      // Wave 2 (weeks 8-14)
      // TODO: Clarify if wave 2 is identical to wave 1 or varies
      0.70,   // week 8
      0.725,  // week 9
      0.75,   // week 10
      0.725,  // week 11
      0.75,   // week 12
      0.775,  // week 13
      0.60,   // week 14 (deload)

      // Wave 3 (weeks 15-21)
      // TODO: Workbook mentions "reach 0.825 before returning to 0.60 in week 21"
      // Current guess: similar to waves 1-2 with week 15 at 0.825
      0.825,  // week 15 (peaking wave)
      0.725,  // week 16
      0.75,   // week 17
      0.725,  // week 18
      0.75,   // week 19
      0.775,  // week 20
      0.60,   // week 21 (deload/reset)
    ];
  }

  /// Auxiliary lift intensity progression for 21 weeks.
  ///
  /// Weeks 1-7 documented explicitly:
  /// 0.65, 0.675, 0.70, 0.675, 0.70, 0.725, 0.55
  ///
  /// Weeks 8-21: "climbs to 0.775 before returning to 0.55 in week 21"
  /// This is also ambiguous.
  static List<double> _auxiliaryLiftIntensities() {
    return [
      // Wave 1 (weeks 1-7)
      0.65,   // week 1
      0.675,  // week 2
      0.70,   // week 3
      0.675,  // week 4
      0.70,   // week 5
      0.725,  // week 6
      0.55,   // week 7 (deload)

      // Wave 2 (weeks 8-14)
      // TODO: Clarify if wave 2 is identical to wave 1 or varies
      0.65,   // week 8
      0.675,  // week 9
      0.70,   // week 10
      0.675,  // week 11
      0.70,   // week 12
      0.725,  // week 13
      0.55,   // week 14 (deload)

      // Wave 3 (weeks 15-21)
      // TODO: "climbs to 0.775" suggests variation from earlier waves
      0.775,  // week 15 (peaking)
      0.675,  // week 16
      0.70,   // week 17
      0.675,  // week 18
      0.70,   // week 19
      0.725,  // week 20
      0.55,   // week 21 (deload/reset)
    ];
  }
}
