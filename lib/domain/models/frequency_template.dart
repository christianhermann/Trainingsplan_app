import 'enums.dart';

/// Represents the structural layout of a training frequency.
class FrequencyTemplate {
  final String id;
  final ProgramFrequency frequency;
  final int dayIndex;
  final String liftId;
  final int defaultOrder;
  final String blockType;

  const FrequencyTemplate({
    required this.id,
    required this.frequency,
    required this.dayIndex,
    required this.liftId,
    required this.defaultOrder,
    required this.blockType,
  });
}
