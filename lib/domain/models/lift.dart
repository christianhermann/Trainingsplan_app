import 'enums.dart';

/// Represents one exercise definition.
/// Maps to workbook lifts (Squat, Bankdruecken, Deadlift, Schulterdruecken, etc.).
class Lift {
  final String id;
  final String name;
  final String displayName;
  final LiftCategory category;
  final bool isMainLift;
  final bool isAuxiliaryLift;
  final int defaultOrder;
  final bool usesTrainingMax;

  const Lift({
    required this.id,
    required this.name,
    required this.displayName,
    required this.category,
    required this.isMainLift,
    required this.isAuxiliaryLift,
    required this.defaultOrder,
    required this.usesTrainingMax,
  });

  Lift copyWith({
    String? id,
    String? name,
    String? displayName,
    LiftCategory? category,
    bool? isMainLift,
    bool? isAuxiliaryLift,
    int? defaultOrder,
    bool? usesTrainingMax,
  }) {
    return Lift(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      category: category ?? this.category,
      isMainLift: isMainLift ?? this.isMainLift,
      isAuxiliaryLift: isAuxiliaryLift ?? this.isAuxiliaryLift,
      defaultOrder: defaultOrder ?? this.defaultOrder,
      usesTrainingMax: usesTrainingMax ?? this.usesTrainingMax,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Lift &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          displayName == other.displayName &&
          category == other.category &&
          isMainLift == other.isMainLift &&
          isAuxiliaryLift == other.isAuxiliaryLift &&
          defaultOrder == other.defaultOrder &&
          usesTrainingMax == other.usesTrainingMax;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      displayName.hashCode ^
      category.hashCode ^
      isMainLift.hashCode ^
      isAuxiliaryLift.hashCode ^
      defaultOrder.hashCode ^
      usesTrainingMax.hashCode;

  @override
  String toString() =>
      'Lift(id: $id, name: $name, displayName: $displayName, category: $category, isMainLift: $isMainLift, isAuxiliaryLift: $isAuxiliaryLift, defaultOrder: $defaultOrder, usesTrainingMax: $usesTrainingMax)';
}
