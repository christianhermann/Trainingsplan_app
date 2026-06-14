import 'enums.dart';

/// Represents the active max used for calculations.
/// Paired with a lift to store the user's current training maximum.
class TrainingMax {
  final String id;
  final String liftId;
  final double value;
  final double singleEightPercentage;
  final MaxSourceType sourceType;
  final DateTime effectiveDate;
  final String? notes;

  const TrainingMax({
    required this.id,
    required this.liftId,
    required this.value,
    required this.singleEightPercentage,
    required this.sourceType,
    required this.effectiveDate,
    this.notes,
  });

  TrainingMax copyWith({
    String? id,
    String? liftId,
    double? value,
    double? singleEightPercentage,
    MaxSourceType? sourceType,
    DateTime? effectiveDate,
    String? notes,
  }) {
    return TrainingMax(
      id: id ?? this.id,
      liftId: liftId ?? this.liftId,
      value: value ?? this.value,
      singleEightPercentage: singleEightPercentage ?? this.singleEightPercentage,
      sourceType: sourceType ?? this.sourceType,
      effectiveDate: effectiveDate ?? this.effectiveDate,
      notes: notes ?? this.notes,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TrainingMax &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          liftId == other.liftId &&
          value == other.value &&
          singleEightPercentage == other.singleEightPercentage &&
          sourceType == other.sourceType &&
          effectiveDate == other.effectiveDate &&
          notes == other.notes;

  @override
  int get hashCode =>
      id.hashCode ^
      liftId.hashCode ^
      value.hashCode ^
      singleEightPercentage.hashCode ^
      sourceType.hashCode ^
      effectiveDate.hashCode ^
      notes.hashCode;

  @override
  String toString() =>
      'TrainingMax(id: $id, liftId: $liftId, value: $value, singleEightPercentage: $singleEightPercentage, sourceType: $sourceType, effectiveDate: $effectiveDate, notes: $notes)';
}
