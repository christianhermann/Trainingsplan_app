import 'enums.dart';

/// Represents the active max used for calculations.
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
}
