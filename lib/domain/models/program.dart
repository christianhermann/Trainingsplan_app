import 'enums.dart';

/// Represents the current plan configuration.
/// A 21-week program with a selected training frequency.
class Program {
  final String id;
  final String name;
  final ProgramFrequency frequency;
  final int currentWeek;
  final int totalWeeks;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  const Program({
    required this.id,
    required this.name,
    required this.frequency,
    required this.currentWeek,
    required this.totalWeeks,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  Program copyWith({
    String? id,
    String? name,
    ProgramFrequency? frequency,
    int? currentWeek,
    int? totalWeeks,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Program(
      id: id ?? this.id,
      name: name ?? this.name,
      frequency: frequency ?? this.frequency,
      currentWeek: currentWeek ?? this.currentWeek,
      totalWeeks: totalWeeks ?? this.totalWeeks,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Program &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          frequency == other.frequency &&
          currentWeek == other.currentWeek &&
          totalWeeks == other.totalWeeks &&
          isActive == other.isActive &&
          createdAt == other.createdAt &&
          updatedAt == other.updatedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      frequency.hashCode ^
      currentWeek.hashCode ^
      totalWeeks.hashCode ^
      isActive.hashCode ^
      createdAt.hashCode ^
      updatedAt.hashCode;

  @override
  String toString() =>
      'Program(id: $id, name: $name, frequency: $frequency, currentWeek: $currentWeek, totalWeeks: $totalWeeks, isActive: $isActive, createdAt: $createdAt, updatedAt: $updatedAt)';
}
