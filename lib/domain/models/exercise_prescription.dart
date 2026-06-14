/// Represents the planned training instruction for one lift on one workout day.
/// Contains all calculated values for the exercise on that day.
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

  ExercisePrescription copyWith({
    String? id,
    String? workoutDayId,
    String? liftId,
    double? trainingMaxSnapshot,
    double? intensity,
    double? workingWeight,
    int? repsPerNormalSet,
    int? repOutTarget,
    int? setGoal,
    int? displayOrder,
    bool? isPrimaryBlock,
  }) {
    return ExercisePrescription(
      id: id ?? this.id,
      workoutDayId: workoutDayId ?? this.workoutDayId,
      liftId: liftId ?? this.liftId,
      trainingMaxSnapshot: trainingMaxSnapshot ?? this.trainingMaxSnapshot,
      intensity: intensity ?? this.intensity,
      workingWeight: workingWeight ?? this.workingWeight,
      repsPerNormalSet: repsPerNormalSet ?? this.repsPerNormalSet,
      repOutTarget: repOutTarget ?? this.repOutTarget,
      setGoal: setGoal ?? this.setGoal,
      displayOrder: displayOrder ?? this.displayOrder,
      isPrimaryBlock: isPrimaryBlock ?? this.isPrimaryBlock,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ExercisePrescription &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          workoutDayId == other.workoutDayId &&
          liftId == other.liftId &&
          trainingMaxSnapshot == other.trainingMaxSnapshot &&
          intensity == other.intensity &&
          workingWeight == other.workingWeight &&
          repsPerNormalSet == other.repsPerNormalSet &&
          repOutTarget == other.repOutTarget &&
          setGoal == other.setGoal &&
          displayOrder == other.displayOrder &&
          isPrimaryBlock == other.isPrimaryBlock;

  @override
  int get hashCode =>
      id.hashCode ^
      workoutDayId.hashCode ^
      liftId.hashCode ^
      trainingMaxSnapshot.hashCode ^
      intensity.hashCode ^
      workingWeight.hashCode ^
      repsPerNormalSet.hashCode ^
      repOutTarget.hashCode ^
      setGoal.hashCode ^
      displayOrder.hashCode ^
      isPrimaryBlock.hashCode;

  @override
  String toString() =>
      'ExercisePrescription(id: $id, workoutDayId: $workoutDayId, liftId: $liftId, trainingMaxSnapshot: $trainingMaxSnapshot, intensity: $intensity, workingWeight: $workingWeight, repsPerNormalSet: $repsPerNormalSet, repOutTarget: $repOutTarget, setGoal: $setGoal, displayOrder: $displayOrder, isPrimaryBlock: $isPrimaryBlock)';
}
