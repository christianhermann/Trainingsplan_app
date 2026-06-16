import '../models/exercise_prescription.dart';
import '../models/frequency_template.dart';
import '../models/intensity_point.dart';
import '../models/rep_target_point.dart';
import '../models/training_max.dart';

import 'intensity_lookup_service.dart';
import 'rep_target_lookup_service.dart';
import 'rounding_service.dart';

class WorkoutGenerationService {
  final IntensityLookupService _intensityLookup;
  final RepTargetLookupService _repTargetLookup;
  final RoundingService _rounding;

  WorkoutGenerationService({
    IntensityLookupService? intensityLookup,
    RepTargetLookupService? repTargetLookup,
    RoundingService? rounding,
  })  : _intensityLookup = intensityLookup ?? IntensityLookupService(),
        _repTargetLookup = repTargetLookup ?? RepTargetLookupService(),
        _rounding = rounding ?? RoundingService();

  List<ExercisePrescription> generateDayPrescriptions({
    required String workoutDayId,
    required String frequency,
    required int dayIndex,
    required int weekNumber,
    required List<FrequencyTemplate> frequencyTemplates,
    required Map<String, TrainingMax> trainingMaxes,
    required List<IntensityPoint> intensityPoints,
    required List<RepTargetPoint> repTargetPoints,
    required double roundingIncrement,
    required String roundingMode,
  }) {
    final dayTemplates = frequencyTemplates.where(
      (t) => t.frequency.toString() == 'ProgramFrequency.$frequency' &&
             t.dayIndex == dayIndex,
    ).toList();

    if (dayTemplates.isEmpty) {
      throw Exception(
        'No frequency template found for frequency: $frequency, day: $dayIndex',
      );
    }

    dayTemplates.sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

    final prescriptions = <ExercisePrescription>[];
    for (final template in dayTemplates) {
      final trainingMax = trainingMaxes[template.liftId];
      if (trainingMax == null) {
        throw Exception('Training max not found for lift: ${template.liftId}');
      }

      final intensity = _intensityLookup.getIntensity(
        template.liftId,
        weekNumber,
        intensityPoints,
      );

      prescriptions.add(generateSinglePrescription(
        workoutDayId: workoutDayId,
        liftId: template.liftId,
        displayOrder: template.defaultOrder,
        isPrimaryBlock: template.blockType.toLowerCase() == 'main',
        weekNumber: weekNumber,
        trainingMax: trainingMax,
        intensity: intensity,
        repTargetPoints: repTargetPoints,
        roundingIncrement: roundingIncrement,
        roundingMode: roundingMode,
      ));
    }

    return prescriptions;
  }

  ExercisePrescription generateSinglePrescription({
    required String workoutDayId,
    required String liftId,
    required int displayOrder,
    required bool isPrimaryBlock,
    required int weekNumber,
    required TrainingMax trainingMax,
    required double intensity,
    required List<RepTargetPoint> repTargetPoints,
    required double roundingIncrement,
    required String roundingMode,
  }) {
    final workingWeight = _rounding.roundWeight(
      trainingMax.value * intensity,
      roundingIncrement,
      roundingMode,
    );

    final repsPerNormalSet = _repTargetLookup.getNormalSetTarget(
      liftId, intensity, repTargetPoints,
    );
    final repOutTarget = _repTargetLookup.getLastSetTarget(
      liftId, intensity, repTargetPoints,
    );

    return ExercisePrescription(
      id: '${workoutDayId}_${liftId}_$weekNumber',
      workoutDayId: workoutDayId,
      liftId: liftId,
      trainingMaxSnapshot: trainingMax.value,
      intensity: intensity,
      workingWeight: workingWeight,
      repsPerNormalSet: repsPerNormalSet,
      repOutTarget: repOutTarget,
      setGoal: 4,
      displayOrder: displayOrder,
      isPrimaryBlock: isPrimaryBlock,
    );
  }
}
