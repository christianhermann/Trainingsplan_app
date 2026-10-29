/// Represents the planned training instruction for one lift on one workout day.
class ExercisePrescription {
  final String id;
  final String workoutDayId;
  final String liftId;
  final double trainingMaxSnapshot;
  final double intensity;
  final double workingWeight;
  final int repsPerNormalSet;
  final int repOutTarget;
  final int setGoal;
  final int displayOrder;
  final bool isPrimaryBlock;

  const ExercisePrescription({
    required this.id,
    required this.workoutDayId,
    required this.liftId,
    required this.trainingMaxSnapshot,
    required this.intensity,
    required this.workingWeight,
    required this.repsPerNormalSet,
    required this.repOutTarget,
    required this.setGoal,
    required this.displayOrder,
    required this.isPrimaryBlock,
  });
}
