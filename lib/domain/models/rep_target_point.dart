/// Represents rep target lookup data for one lift at one intensity level.
/// Contains the reps-per-set target and the RIR target for the last set.
///
/// Source of truth: workbook Quick Setup tab.
/// RIR target = 0 means "work to technical failure / technical limit".
class RepTargetPoint {
  final String id;
  final String liftId;
  final double intensity; // e.g. 0.875
  final int repsPerSet;   // target reps for all sets (incl. last set)
  final int lastSetRirTarget; // 0 = work to technical limit

  const RepTargetPoint({
    required this.id,
    required this.liftId,
    required this.intensity,
    required this.repsPerSet,
    required this.lastSetRirTarget,
  });

  RepTargetPoint copyWith({
    String? id,
    String? liftId,
    double? intensity,
    int? repsPerSet,
    int? lastSetRirTarget,
  }) {
    return RepTargetPoint(
      id: id ?? this.id,
      liftId: liftId ?? this.liftId,
      intensity: intensity ?? this.intensity,
      repsPerSet: repsPerSet ?? this.repsPerSet,
      lastSetRirTarget: lastSetRirTarget ?? this.lastSetRirTarget,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is RepTargetPoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          liftId == other.liftId &&
          intensity == other.intensity &&
          repsPerSet == other.repsPerSet &&
          lastSetRirTarget == other.lastSetRirTarget;

  @override
  int get hashCode =>
      id.hashCode ^
      liftId.hashCode ^
      intensity.hashCode ^
      repsPerSet.hashCode ^
      lastSetRirTarget.hashCode;

  @override
  String toString() =>
      'RepTargetPoint(id: $id, liftId: $liftId, intensity: $intensity, '
      'repsPerSet: $repsPerSet, lastSetRirTarget: $lastSetRirTarget)';
}
