import 'enums.dart';

/// Progression adjustment rule.
class ProgressAdjustment {
  final String id;
  final String liftId;
  final ProgressOutcome outcome;
  final double delta;
  final bool appliesToCycle;
  final bool appliesToTrainingMax;

  const ProgressAdjustment({
    required this.id,
    required this.liftId,
    required this.outcome,
    required this.delta,
    required this.appliesToCycle,
    required this.appliesToTrainingMax,
  });
}
