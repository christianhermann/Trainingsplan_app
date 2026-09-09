import '../models/enums.dart';
import '../models/exercise_log.dart';
import '../models/exercise_prescription.dart';
import '../models/progress_adjustment.dart';

/// Result returned by [ProgressionService.evaluate].
class ProgressionResult {
  const ProgressionResult({
    required this.outcome,
    required this.newTrainingMax,
  });

  /// Which of the 8 workbook outcome buckets this performance fell into.
  final ProgressOutcome outcome;

  /// Updated training max after applying the delta.
  /// newTrainingMax = currentTrainingMax + (currentTrainingMax x delta)
  final double newTrainingMax;

  @override
  String toString() =>
      'ProgressionResult(outcome: $outcome, newTrainingMax: $newTrainingMax)';
}

/// Pure domain service - no DB, no Riverpod.
///
/// Accepts a completed [ExerciseLog] and its linked [ExercisePrescription],
/// compares [ExerciseLog.completedSets] against [ExercisePrescription.setGoal]
/// and [ExerciseLog.repsOnLastSet] against [ExercisePrescription.repOutTarget],
/// maps the result to a [ProgressOutcome], looks up the matching
/// [ProgressAdjustment] delta, and returns a [ProgressionResult].
///
/// Outcome mapping (workbook):
///
/// 1. Set-failure branch (checked first):
///    completedSets < setGoal - 1  -> belowBy2  (2+ sets missed)
///    completedSets == setGoal - 1 -> belowBy1  (1 set missed)
///
/// 2. RIR branch (all sets completed):
///    diff = repsOnLastSet - repOutTarget
///    diff <= -2  -> belowBy2
///    diff = -1   -> belowBy1
///    diff =  0   -> hit
///    diff = +1   -> plus1
///    diff = +2   -> plus2
///    diff = +3   -> plus3
///    diff = +4   -> plus4
///    diff >= +5  -> plus5
///
/// Adjustment lookup order:
///   1. Exact match on liftId + outcome (appliesToTrainingMax = true).
///   2. Fallback key 'all_lifts' + outcome.
///   3. Throws [ArgumentError] if neither found.
class ProgressionService {
  const ProgressionService();

  /// Evaluates performance and returns the progression result.
  ProgressionResult evaluate({
    required ExerciseLog log,
    required ExercisePrescription prescription,
    required List<ProgressAdjustment> adjustments,
    required double currentTrainingMax,
  }) {
    final outcome = _mapOutcome(
      completedSets: log.completedSets,
      setGoal: prescription.setGoal,
      repsOnLastSet: log.repsOnLastSet ?? 0,
      repOutTarget: prescription.repOutTarget,
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

  /// Exposed separately so unit tests can verify outcome mapping in isolation.
  ProgressOutcome determineOutcome({
    required int completedSets,
    required int setGoal,
    required int repsOnLastSet,
    required int repOutTarget,
  }) =>
      _mapOutcome(
        completedSets: completedSets,
        setGoal: setGoal,
        repsOnLastSet: repsOnLastSet,
        repOutTarget: repOutTarget,
      );

  // ---------------------------------------------------------------------------

  ProgressOutcome _mapOutcome({
    required int completedSets,
    required int setGoal,
    required int repsOnLastSet,
    required int repOutTarget,
  }) {
    final setsMissed = setGoal - completedSets;
    if (setsMissed >= 2) return ProgressOutcome.belowBy2;
    if (setsMissed == 1) return ProgressOutcome.belowBy1;

    // RIR branch: all sets completed — outcome driven by last-set reps.
    final diff = repsOnLastSet - repOutTarget;
    if (diff <= -2) return ProgressOutcome.belowBy2;
    if (diff == -1) return ProgressOutcome.belowBy1;
    if (diff == 0) return ProgressOutcome.hit;
    if (diff == 1) return ProgressOutcome.plus1;
    if (diff == 2) return ProgressOutcome.plus2;
    if (diff == 3) return ProgressOutcome.plus3;
    if (diff == 4) return ProgressOutcome.plus4;
    return ProgressOutcome.plus5; // diff >= 5
  }

  double _lookupDelta({
    required String liftId,
    required ProgressOutcome outcome,
    required List<ProgressAdjustment> adjustments,
  }) {
    final specific = adjustments
        .where((a) =>
            a.liftId == liftId &&
            a.outcome == outcome &&
            a.appliesToTrainingMax)
        .firstOrNull;
    if (specific != null) return specific.delta;

    final fallback = adjustments
        .where((a) =>
            a.liftId == 'all_lifts' &&
            a.outcome == outcome &&
            a.appliesToTrainingMax)
        .firstOrNull;
    if (fallback != null) return fallback.delta;

    throw ArgumentError(
      'No ProgressAdjustment found for liftId: $liftId, outcome: $outcome. '
      'Add an entry for this lift or an "all_lifts" fallback.',
    );
  }
}
