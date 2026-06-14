/// Represents one generated week in a program.
class WorkoutWeek {
  final String id;
  final String programId;
  final int weekNumber;
  final String displayLabel;
  final DateTime startDate;
  final DateTime endDate;

  const WorkoutWeek({
    required this.id,
    required this.programId,
    required this.weekNumber,
    required this.displayLabel,
    required this.startDate,
    required this.endDate,
  });

  WorkoutWeek copyWith({
    String? id,
    String? programId,
    int? weekNumber,
    String? displayLabel,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    return WorkoutWeek(
      id: id ?? this.id,
      programId: programId ?? this.programId,
      weekNumber: weekNumber ?? this.weekNumber,
      displayLabel: displayLabel ?? this.displayLabel,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutWeek &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          programId == other.programId &&
          weekNumber == other.weekNumber &&
          displayLabel == other.displayLabel &&
          startDate == other.startDate &&
          endDate == other.endDate;

  @override
  int get hashCode =>
      id.hashCode ^
      programId.hashCode ^
      weekNumber.hashCode ^
      displayLabel.hashCode ^
      startDate.hashCode ^
      endDate.hashCode;

  @override
  String toString() =>
      'WorkoutWeek(id: $id, programId: $programId, weekNumber: $weekNumber, displayLabel: $displayLabel, startDate: $startDate, endDate: $endDate)';
}
