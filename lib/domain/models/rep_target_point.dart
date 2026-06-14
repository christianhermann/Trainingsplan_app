/// Represents rep target lookup data for one lift at one intensity level.
/// Contains both normal-set and last-set targets.
class RepTargetPoint {
  final String id;
  final String liftId;
  final double intensity; // e.g., 0.70, 0.725, 0.75, etc.
  final int normalSetTarget; // e.g., 10 reps
  final int lastSetTarget; // e.g., 12 reps (always >= normalSetTarget)

  const RepTargetPoint({
    required this.id,
    required this.liftId,
    required this.intensity,
    required this.normalSetTarget,
    required this.lastSetTarget,
  });

  RepTargetPoint copyWith({
    String? id,
    String? liftId,
    double? intensity,
    int? normalSetTarget,
    int? lastSetTarget,
  }) {
    return RepTargetPoint(
      id: id ?? this.id,
      liftId: liftId ?? this.liftId,
      intensity: intensity ?? this.intensity,
      normalSetTarget: normalSetTarget ?? this.normalSetTarget,
      lastSetTarget: lastSetTarget ?? this.lastSetTarget,
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
          normalSetTarget == other.normalSetTarget &&
          lastSetTarget == other.lastSetTarget;

  @override
  int get hashCode =>
      id.hashCode ^
      liftId.hashCode ^
      intensity.hashCode ^
      normalSetTarget.hashCode ^
      lastSetTarget.hashCode;

  @override
  String toString() =>
      'RepTargetPoint(id: $id, liftId: $liftId, intensity: $intensity, normalSetTarget: $normalSetTarget, lastSetTarget: $lastSetTarget)';
}
