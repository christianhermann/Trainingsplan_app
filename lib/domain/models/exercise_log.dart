/// Logged execution details for an exercise.
class ExerciseLog {
  final String id;
  final String prescriptionId;
  final int completedSets;
  final int? repsOnLastSet;
  final String? notes;
  final String? videoUrl;
  final DateTime completedAt;

  const ExerciseLog({
    required this.id,
    required this.prescriptionId,
    required this.completedSets,
    this.repsOnLastSet,
    this.notes,
    this.videoUrl,
    required this.completedAt,
  });
}
