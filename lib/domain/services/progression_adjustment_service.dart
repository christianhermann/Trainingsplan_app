import '../models/enums.dart';
import '../models/progress_adjustment.dart';

class ProgressionAdjustmentService {
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

  double applyAdjustment(double currentMax, double delta) =>
      currentMax + (currentMax * delta);
}
