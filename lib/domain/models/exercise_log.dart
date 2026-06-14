/// Represents the performed result for one exercise.
/// Logged after completing a workout to record actual performance.
class ExerciseLog {
  final String id;
  final String prescriptionId;
  final int completedSets;
  final int repsOnLastSet;
  final String? notes;
  final String? videoUrl;
  final DateTime completedAt;

  const ExerciseLog({
    required this.id,
    required this.prescriptionId,
    required this.completedSets,
    required this.repsOnLastSet,
    this.notes,
    this.videoUrl,
    required this.completedAt,
  });

  ExerciseLog copyWith({
    String? id,
    String? prescriptionId,
    int? completedSets,
    int? repsOnLastSet,
    String? notes,
    String? videoUrl,
    DateTime? completedAt,
  }) {
    return ExerciseLog(
      id: id ?? this.id,
      prescriptionId: prescriptionId ?? this.prescriptionId,
      completedSets: completedSets ?? this.completedSets,
      repsOnLastSet: repsOnLastSet ?? this.repsOnLastSet,
      notes: notes ?? this.notes,
      videoUrl: videoUrl ?? this.videoUrl,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExerciseLog &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          prescriptionId == other.prescriptionId &&
          completedSets == other.completedSets &&
          repsOnLastSet == other.repsOnLastSet &&
          notes == other.notes &&
          videoUrl == other.videoUrl &&
          completedAt == other.completedAt;

  @override
  int get hashCode =>
      id.hashCode ^
      prescriptionId.hashCode ^
      completedSets.hashCode ^
      repsOnLastSet.hashCode ^
      notes.hashCode ^
      videoUrl.hashCode ^
      completedAt.hashCode;

  @override
  String toString() =>
      'ExerciseLog(id: $id, prescriptionId: $prescriptionId, completedSets: $completedSets, repsOnLastSet: $repsOnLastSet, notes: $notes, videoUrl: $videoUrl, completedAt: $completedAt)';
}
