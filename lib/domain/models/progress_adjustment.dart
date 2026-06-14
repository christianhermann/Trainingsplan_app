import 'enums.dart';

/// Represents the lookup rule used after performance is logged.
/// Maps a ProgressOutcome to a training max delta adjustment.
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

  ProgressAdjustment copyWith({
    String? id,
    String? liftId,
    ProgressOutcome? outcome,
    double? delta,
    bool? appliesToCycle,
    bool? appliesToTrainingMax,
  }) {
    return ProgressAdjustment(
      id: id ?? this.id,
      liftId: liftId ?? this.liftId,
      outcome: outcome ?? this.outcome,
      delta: delta ?? this.delta,
      appliesToCycle: appliesToCycle ?? this.appliesToCycle,
      appliesToTrainingMax: appliesToTrainingMax ?? this.appliesToTrainingMax,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ProgressAdjustment &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          liftId == other.liftId &&
          outcome == other.outcome &&
          delta == other.delta &&
          appliesToCycle == other.appliesToCycle &&
          appliesToTrainingMax == other.appliesToTrainingMax;

  @override
  int get hashCode =>
      id.hashCode ^
      liftId.hashCode ^
      outcome.hashCode ^
      delta.hashCode ^
      appliesToCycle.hashCode ^
      appliesToTrainingMax.hashCode;

  @override
  String toString() =>
      'ProgressAdjustment(id: $id, liftId: $liftId, outcome: $outcome, delta: $delta, appliesToCycle: $appliesToCycle, appliesToTrainingMax: $appliesToTrainingMax)';
}
