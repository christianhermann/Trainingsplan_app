/// Represents one intensity lookup value for one lift and week.
/// The workbook uses a 21-week intensity structure.
class IntensityPoint {
  final String id;
  final String liftId;
  final int weekNumber; // 1-21
  final double intensity; // e.g., 0.70, 0.725, 0.75, etc.

  const IntensityPoint({
    required this.id,
    required this.liftId,
    required this.weekNumber,
    required this.intensity,
  });

  IntensityPoint copyWith({
    String? id,
    String? liftId,
    int? weekNumber,
    double? intensity,
  }) {
    return IntensityPoint(
      id: id ?? this.id,
      liftId: liftId ?? this.liftId,
      weekNumber: weekNumber ?? this.weekNumber,
      intensity: intensity ?? this.intensity,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IntensityPoint &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          liftId == other.liftId &&
          weekNumber == other.weekNumber &&
          intensity == other.intensity;

  @override
  int get hashCode =>
      id.hashCode ^ liftId.hashCode ^ weekNumber.hashCode ^ intensity.hashCode;

  @override
  String toString() =>
      'IntensityPoint(id: $id, liftId: $liftId, weekNumber: $weekNumber, intensity: $intensity)';
}
