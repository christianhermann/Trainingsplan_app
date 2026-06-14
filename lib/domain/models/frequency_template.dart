import 'enums.dart';

/// Represents the structural layout of a training frequency.
/// Maps the static workout template (e.g., which lifts are on which days)
/// for frequencies: 2x, 3x, 4x, 5x, 6x.
class FrequencyTemplate {
  final String id;
  final ProgramFrequency frequency; // 2x, 3x, 4x, 5x, 6x
  final int dayIndex; // 0-indexed day within the frequency (0-5)
  final String liftId;
  final int defaultOrder; // Display order for lifts on that day
  final String blockType; // 'main' or 'auxiliary' (for UI organization)

  const FrequencyTemplate({
    required this.id,
    required this.frequency,
    required this.dayIndex,
    required this.liftId,
    required this.defaultOrder,
    required this.blockType,
  });

  FrequencyTemplate copyWith({
    String? id,
    ProgramFrequency? frequency,
    int? dayIndex,
    String? liftId,
    int? defaultOrder,
    String? blockType,
  }) {
    return FrequencyTemplate(
      id: id ?? this.id,
      frequency: frequency ?? this.frequency,
      dayIndex: dayIndex ?? this.dayIndex,
      liftId: liftId ?? this.liftId,
      defaultOrder: defaultOrder ?? this.defaultOrder,
      blockType: blockType ?? this.blockType,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FrequencyTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          frequency == other.frequency &&
          dayIndex == other.dayIndex &&
          liftId == other.liftId &&
          defaultOrder == other.defaultOrder &&
          blockType == other.blockType;

  @override
  int get hashCode =>
      id.hashCode ^
      frequency.hashCode ^
      dayIndex.hashCode ^
      liftId.hashCode ^
      defaultOrder.hashCode ^
      blockType.hashCode;

  @override
  String toString() =>
      'FrequencyTemplate(id: $id, frequency: $frequency, dayIndex: $dayIndex, liftId: $liftId, defaultOrder: $defaultOrder, blockType: $blockType)';
}

