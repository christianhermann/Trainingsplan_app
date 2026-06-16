import '../models/enums.dart';
import '../models/exercise_prescription.dart';
import '../models/frequency_template.dart';
import '../models/intensity_point.dart';
import '../models/rep_target_point.dart';
import '../models/training_max.dart';

import 'intensity_lookup_service.dart';
import 'rep_target_lookup_service.dart';
import 'rounding_service.dart';

/// Pure domain service — no DB, no Riverpod.
///
/// Given lookup tables (loaded by [WorkoutGeneratorService]) and training maxes,
/// builds [ExercisePrescription] objects for a single workout day.
///
/// setGoal is always 4 (workbook constant).
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

  /// Generate prescriptions for one day.
  ///
  /// [frequency] must be a [ProgramFrequency] enum value — compared directly
  /// against [FrequencyTemplate.frequency] (no string conversion).
  List<ExercisePrescription> generateDayPrescriptions({
    required String workoutDayId,
    required ProgramFrequency frequency,   // ← enum, not String
    required int dayIndex,
    required int weekNumber,
    required List<FrequencyTemplate> frequencyTemplates,
    required Map<String, TrainingMax> trainingMaxes,
    required List<IntensityPoint> intensityPoints,
    required List<RepTargetPoint> repTargetPoints,
    required double roundingIncrement,
    required String roundingMode,
  }) {
    // Filter templates for this frequency + day, sorted by display order.
    final dayTemplates = frequencyTemplates
        .where((t) => t.frequency == frequency && t.dayIndex == dayIndex)
        .toList()
      ..sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

    if (dayTemplates.isEmpty) {
      throw ArgumentError(
        'No FrequencyTemplate entries for frequency: ${frequency.name}, '
        'dayIndex: $dayIndex',
      );
    }

    return [
      for (final template in dayTemplates)
        _buildPrescription(
          template:          template,
          workoutDayId:      workoutDayId,
          weekNumber:        weekNumber,
          trainingMaxes:     trainingMaxes,
          intensityPoints:   intensityPoints,
          repTargetPoints:   repTargetPoints,
          roundingIncrement: roundingIncrement,
          roundingMode:      roundingMode,
        ),
    ];
  }

  ExercisePrescription _buildPrescription({
    required FrequencyTemplate template,
    required String workoutDayId,
    required int weekNumber,
    required Map<String, TrainingMax> trainingMaxes,
    required List<IntensityPoint> intensityPoints,
    required List<RepTargetPoint> repTargetPoints,
    required double roundingIncrement,
    required String roundingMode,
  }) {
    final trainingMax = trainingMaxes[template.liftId];
    if (trainingMax == null) {
      throw ArgumentError(
          'Training max not found for liftId: ${template.liftId}. '
          'Ensure all lifts in the frequency template have a TM entry.');
    }

    final intensity = _intensityLookup.getIntensity(
      template.liftId,
      weekNumber,
      intensityPoints,
    );

    final workingWeight = _rounding.roundWeight(
      trainingMax.value * intensity,
      roundingIncrement,
      roundingMode,
    );

    final repsPerNormalSet = _repTargetLookup.getRepTarget(
      template.liftId,
      intensity,
      repTargetPoints,
    );

    // repOutTarget == repsPerNormalSet: workbook has one rep count per intensity;
    // RIR=0 on the last set means "work to technical limit", not a different
    // rep number.
    final repOutTarget = repsPerNormalSet;

    return ExercisePrescription(
      id:                  '${workoutDayId}_${template.liftId}_w$weekNumber',
      workoutDayId:        workoutDayId,
      liftId:              template.liftId,
      trainingMaxSnapshot: trainingMax.value,
      intensity:           intensity,
      workingWeight:       workingWeight,
      repsPerNormalSet:    repsPerNormalSet,
      repOutTarget:        repOutTarget,
      setGoal:             4, // workbook constant
      displayOrder:        template.defaultOrder,
      isPrimaryBlock:      template.blockType.toLowerCase() == 'main',
    );
  }

  /// Convenience method used by tests — generates a single prescription
  /// without needing a FrequencyTemplate.
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
    final repsPerNormalSet =
        _repTargetLookup.getRepTarget(liftId, intensity, repTargetPoints);

    return ExercisePrescription(
      id:                  '${workoutDayId}_${liftId}_w$weekNumber',
      workoutDayId:        workoutDayId,
      liftId:              liftId,
      trainingMaxSnapshot: trainingMax.value,
      intensity:           intensity,
      workingWeight:       workingWeight,
      repsPerNormalSet:    repsPerNormalSet,
      repOutTarget:        repsPerNormalSet,
      setGoal:             4,
      displayOrder:        displayOrder,
      isPrimaryBlock:      isPrimaryBlock,
    );
  }
}
