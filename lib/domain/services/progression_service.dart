import '../models/enums.dart';
import '../models/exercise_log.dart';
import '../models/exercise_prescription.dart';
import '../models/progress_adjustment.dart';

class ProgressionResult {
  const ProgressionResult({
    required this.outcome,
    required this.newTrainingMax,
  });

  final ProgressOutcome outcome;
  final double newTrainingMax;

  @override
  String toString() =>
      'ProgressionResult(outcome: $outcome, newTrainingMax: $newTrainingMax)';
}

class ProgressionService {
  const ProgressionService();

  ProgressionResult evaluate({
    required ExerciseLog log,
    required ExercisePrescription prescription,
    required List<ProgressAdjustment> adjustments,
    required double currentTrainingMax,
  }) {
    final outcome = _mapOutcome(
      repsOnLastSet: log.repsOnLastSet ?? 0,
      repOutTarget: prescription.repOutTarget,
      completedSets: log.completedSets,
      setGoal: prescription.setGoal,
    );
    
    final delta = _lookupDelta(
      liftId: prescription.liftId,
      outcome: outcome,
      adjustments: adjustments,
    );
    
    return ProgressionResult(
      outcome: outcome,
      newTrainingMax: currentTrainingMax + (currentTrainingMax * delta),
    );
  }

  ProgressOutcome determineOutcome({
    required int repsOnLastSet,
    required int repOutTarget,
    required int completedSets,
    required int setGoal,
  }) =>
      _mapOutcome(
        repsOnLastSet: repsOnLastSet,
        repOutTarget: repOutTarget,
        completedSets: completedSets,
        setGoal: setGoal,
      );

  ProgressOutcome _mapOutcome({
    required int repsOnLastSet,
    required int repOutTarget,
    required int completedSets,
    required int setGoal,
  }) {
    final setsMissed = setGoal - completedSets;
    if (setsMissed >= 2) return ProgressOutcome.belowBy2;
    if (setsMissed == 1) return ProgressOutcome.belowBy1;

    final diff = repsOnLastSet - repOutTarget;
    if (diff <= -2) return ProgressOutcome.belowBy2;
    if (diff == -1) return ProgressOutcome.belowBy1;
    if (diff == 0)  return ProgressOutcome.hit;
    if (diff == 1)  return ProgressOutcome.plus1;
    if (diff == 2)  return ProgressOutcome.plus2;
    if (diff == 3)  return ProgressOutcome.plus3;
    if (diff == 4)  return ProgressOutcome.plus4;
    return ProgressOutcome.plus5;
  }

  double _lookupDelta({
    required String liftId,
    required ProgressOutcome outcome,
    required List<ProgressAdjustment> adjustments,
  }) {
    final specific = adjustments.where(
      (a) => a.liftId == liftId && a.outcome == outcome && a.appliesToTrainingMax,
    ).firstOrNull;
    
    if (specific != null) return specific.delta;

    final fallback = adjustments.where(
      (a) => a.liftId == 'all_lifts' && a.outcome == outcome && a.appliesToTrainingMax,
    ).firstOrNull;
    
    if (fallback != null) return fallback.delta;

    throw ArgumentError(
      'No ProgressAdjustment for liftId: $liftId, outcome: $outcome',
    );
  }
}
