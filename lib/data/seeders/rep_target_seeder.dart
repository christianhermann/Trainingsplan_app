import '../../domain/models/rep_target_point.dart';

/// Seed data for rep target lookup tables (normal set and last set targets).
///
/// Per workbook-logic.md:
/// 
/// Main lift normal set targets (visible examples):
/// - 10 reps at 0.70
/// - 9 reps at 0.725
/// - 8 reps at 0.75
/// - 7 reps at 0.775
/// - 6 reps at 0.80
/// - 5 reps at 0.825
///
/// Main lift last set targets (visible examples):
/// - 12 reps at 0.70
/// - 11 reps at 0.725
/// - 10 reps at 0.75
/// - 9 reps at 0.775
/// - 8 reps at 0.80
/// - 6 reps at 0.825
///
/// Auxiliary lift normal set targets (visible examples):
/// - 12 reps at 0.65
/// - 11 reps at 0.675
/// - 10 reps at 0.70
/// - 9 reps at 0.725
/// - 8 reps at 0.75
/// - 7 reps at 0.775
///
/// Auxiliary lift last set targets (visible examples):
/// - 15 reps at 0.65
/// - 13 reps at 0.675
/// - 12 reps at 0.70
/// - 11 reps at 0.725
/// - 10 reps at 0.75
/// - 9 reps at 0.775
///
/// TODOs:
/// - Deload weeks use intensity 0.60 (main) and 0.55 (auxiliary).
///   The workbook does not specify rep targets for these deload intensities.
///   Should deload weeks have rep targets, or should rep-out logging be optional?
///   See docs/open-questions.md #4.
///
/// - No intensity values between existing points (e.g., 0.755, 0.775).
///   If rounded calculations produce intermediate values, clarify rounding behavior.
///
/// - Only the visible examples from the workbook are hardcoded.
///   Other intensity values may be needed but are not documented.

class RepTargetSeeder {
  /// Generate all rep target lookup points for all lifts.
  static List<RepTargetPoint> generateRepTargetPoints() {
    final points = <RepTargetPoint>[];

    // Main lifts: Squat, Bench Press, Deadlift, Overhead Press
    points.addAll(_mainLiftRepTargets());

    // Auxiliary lifts
    points.addAll(_auxiliaryLiftRepTargets());

    return points;
  }

  /// Main lift rep targets (normal set and last set).
  static List<RepTargetPoint> _mainLiftRepTargets() {
    const mainLifts = ['squat', 'bench_press', 'deadlift', 'overhead_press'];
    final points = <RepTargetPoint>[];

    final targets = [
      (intensity: 0.70, normal: 10, lastSet: 12),
      (intensity: 0.725, normal: 9, lastSet: 11),
      (intensity: 0.75, normal: 8, lastSet: 10),
      (intensity: 0.775, normal: 7, lastSet: 9),
      (intensity: 0.80, normal: 6, lastSet: 8),
      (intensity: 0.825, normal: 5, lastSet: 6),
    ];

    for (final lift in mainLifts) {
      for (final target in targets) {
        points.add(RepTargetPoint(
          id: '${lift}_${(target.intensity * 1000).toStringAsFixed(0)}',
          liftId: lift,
          intensity: target.intensity,
          normalSetTarget: target.normal,
          lastSetTarget: target.lastSet,
        ));
      }
    }

    // TODO: Add deload week rep targets (intensity 0.60).
    // The workbook does not specify targets for 0.60.
    // Should we infer them (e.g., 12 normal, 14 last), suppress logging, or use closest match?
    // See docs/open-questions.md #4.

    return points;
  }

  /// Auxiliary lift rep targets (normal set and last set).
  static List<RepTargetPoint> _auxiliaryLiftRepTargets() {
    const auxiliaryLifts = [
      'leg_press',
      'wider_stance_squat',
      'dumbbell_bench',
      'incline_dumbbell_press',
      'trap_bar_deadlift',
      'dumbbell_overhead_press',
    ];
    final points = <RepTargetPoint>[];

    final targets = [
      (intensity: 0.65, normal: 12, lastSet: 15),
      (intensity: 0.675, normal: 11, lastSet: 13),
      (intensity: 0.70, normal: 10, lastSet: 12),
      (intensity: 0.725, normal: 9, lastSet: 11),
      (intensity: 0.75, normal: 8, lastSet: 10),
      (intensity: 0.775, normal: 7, lastSet: 9),
    ];

    for (final lift in auxiliaryLifts) {
      for (final target in targets) {
        points.add(RepTargetPoint(
          id: '${lift}_${(target.intensity * 1000).toStringAsFixed(0)}',
          liftId: lift,
          intensity: target.intensity,
          normalSetTarget: target.normal,
          lastSetTarget: target.lastSet,
        ));
      }
    }

    // TODO: Add deload week rep targets (intensity 0.55).
    // Similar to main lifts, 0.55 is used but targets are not specified.

    return points;
  }
}
