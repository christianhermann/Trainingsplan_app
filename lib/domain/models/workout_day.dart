import 'enums.dart';

/// Represents a generated training day.
class WorkoutDay {
  final String id;
  final String workoutWeekId;
  final int dayIndex;
  final String title;
  final WorkoutStatus status;
  final DateTime? completedAt;

  const WorkoutDay({
    required this.id,
    required this.workoutWeekId,
    required this.dayIndex,
    required this.title,
    required this.status,
    this.completedAt,
  });

  WorkoutDay copyWith({
    String? id,
    String? workoutWeekId,
    int? dayIndex,
    String? title,
    WorkoutStatus? status,
    DateTime? completedAt,
  }) {
    return WorkoutDay(
      id: id ?? this.id,
      workoutWeekId: workoutWeekId ?? this.workoutWeekId,
      dayIndex: dayIndex ?? this.dayIndex,
      title: title ?? this.title,
      status: status ?? this.status,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is WorkoutDay &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workoutWeekId == other.workoutWeekId &&
          dayIndex == other.dayIndex &&
          title == other.title &&
          status == other.status &&
          completedAt == other.completedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      workoutWeekId.hashCode ^
      dayIndex.hashCode ^
      title.hashCode ^
      status.hashCode ^
      completedAt.hashCode;

  @override
  String toString() =>
      'WorkoutDay(id: $id, workoutWeekId: $workoutWeekId, dayIndex: $dayIndex, title: $title, status: $status, completedAt: $completedAt)';
}
