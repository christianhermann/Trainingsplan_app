import '../models/enums.dart';
import '../models/progress_adjustment.dart';

/// Calculates training max adjustments based on logged performance.
/// Maps ProgressOutcome values to delta adjustments per the workbook rules.
abstract class ProgressionAdjustmentService {
  /// Calculates the delta adjustment for a training max based on performance outcome.
  /// 
  /// The workbook defines fixed delta values:
  /// - Below by 2 reps: -0.05
  /// - Below by 1 rep: -0.02
  /// - Hit target: 0.00
  /// - Beat by 1 rep: +0.005
  /// - Beat by 2 reps: +0.01
  /// - Beat by 3 reps: +0.015
  /// - Beat by 4 reps: +0.02
  /// - Beat by 5 reps: +0.03
  /// 
  /// Parameters:
  ///   - outcome: The ProgressOutcome from logged performance
  ///   - progressAdjustments: The complete set of ProgressAdjustment records
  ///   - liftId: The ID of the lift being adjusted
  /// 
  /// Returns the delta to apply to the training max (may be 0).
  double getDelta(
    ProgressOutcome outcome,
    String liftId,
    List<ProgressAdjustment> progressAdjustments,
  );

  /// Applies a delta to a current training max to produce the new value.
  /// 
  /// Parameters:
  ///   - currentMax: The current training maximum value
  ///   - delta: The delta adjustment (typically from getDelta)
  /// 
  /// Returns the new training max after applying the delta.
  /// The delta is treated as a percentage: newMax = currentMax + (currentMax * delta)
  double applyAdjustment(double currentMax, double delta);
}

/// Default implementation of ProgressionAdjustmentService.
class DefaultProgressionAdjustmentService
    implements ProgressionAdjustmentService {
  @override
  double getDelta(
    ProgressOutcome outcome,
    String liftId,
    List<ProgressAdjustment> progressAdjustments,
  ) {
    try {
      final adjustment = progressAdjustments.firstWhere(
        (a) => a.outcome == outcome && a.liftId == liftId,
      );
      return adjustment.delta;
    } catch (e) {
      throw Exception(
        'Progression adjustment not found for lift: $liftId, outcome: $outcome',
      );
    }
  }

  @override
  double applyAdjustment(double currentMax, double delta) {
    return currentMax + (currentMax * delta);
  }
}

