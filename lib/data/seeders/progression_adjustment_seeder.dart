import '../../domain/models/enums.dart';
import '../../domain/models/progress_adjustment.dart';

/// Seed data for progression adjustment lookup rules.
///
/// Per workbook-logic.md:
/// The workbook defines these adjustment columns and values:
/// - Below rep target by 2 reps: -0.05
/// - Below rep target by 1 rep: -0.02
/// - Hit rep target: 0
/// - Beat by 1 rep: 0.005
/// - Beat by 2 reps: 0.01
/// - Beat by 3 reps: 0.015
/// - Beat by 4 reps: 0.02
/// - Beat by 5 reps: 0.03
///
/// These values represent percentage adjustments to the training max:
/// newMax = currentMax + (currentMax * delta)
///
/// TODO: Clarify if these adjustments apply universally to all lifts,
/// or if they vary by lift category (main vs. auxiliary).
/// The model has liftId field, but the workbook only shows one set of values.
/// Currently implementing as global rules applied to all lifts.

class ProgressionAdjustmentSeeder {
  /// Generate all progression adjustment lookup rules.
  static List<ProgressAdjustment> generateProgressionAdjustments() {
    final points = <ProgressAdjustment>[];

    // All lifts (main and auxiliary)
    const allLifts = [
      'squat',
      'bench_press',
      'deadlift',
      'overhead_press',
      'leg_press',
      'wider_stance_squat',
      'dumbbell_bench',
      'incline_dumbbell_press',
      'trap_bar_deadlift',
      'dumbbell_overhead_press',
    ];

    final adjustments = [
      (outcome: ProgressOutcome.belowBy2, delta: -0.05),
      (outcome: ProgressOutcome.belowBy1, delta: -0.02),
      (outcome: ProgressOutcome.hit, delta: 0.0),
      (outcome: ProgressOutcome.plus1, delta: 0.005),
      (outcome: ProgressOutcome.plus2, delta: 0.01),
      (outcome: ProgressOutcome.plus3, delta: 0.015),
      (outcome: ProgressOutcome.plus4, delta: 0.02),
      (outcome: ProgressOutcome.plus5, delta: 0.03),
    ];

    for (final lift in allLifts) {
      for (final adjustment in adjustments) {
        points.add(ProgressAdjustment(
          id: '${lift}_${adjustment.outcome}',
          liftId: lift,
          outcome: adjustment.outcome,
          delta: adjustment.delta,
          appliesToCycle: true,
          appliesToTrainingMax: true,
        ));
      }
    }

    return points;
  }
}
