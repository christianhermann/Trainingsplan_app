import '../models/exercise_prescription.dart';
import '../models/frequency_template.dart';
import '../models/intensity_point.dart';
import '../models/rep_target_point.dart';
import '../models/training_max.dart';

import 'intensity_lookup_service.dart';
import 'rep_target_lookup_service.dart';
import 'rounding_service.dart';

/// Generates workout prescriptions from frequency templates, training maxes, and lookup tables.
/// Orchestrates the calculation layer to produce complete ExercisePrescription objects.
abstract class WorkoutGenerationService {
  /// Generates prescriptions for all lifts scheduled on a specific workout day.
  /// 
  /// Parameters:
  ///   - workoutDayId: The ID of the workout day being generated
  ///   - frequency: The training frequency (2x, 3x, etc.)
  ///   - dayIndex: The day index within the frequency (0-based)
  ///   - weekNumber: The week in the cycle (1-21)
  ///   - frequencyTemplates: All available frequency templates
  ///   - trainingMaxes: Current training max values keyed by liftId
  ///   - intensityPoints: Intensity lookup table
  ///   - repTargetPoints: Rep target lookup table
  ///   - roundingIncrement: Weight rounding increment (e.g., 2.5)
  ///   - roundingMode: 'floor', 'ceil', or 'round'
  /// 
  /// Returns a list of ExercisePrescription objects, one per lift on that day.
  /// Throws an exception if any required lookup data is missing.
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
  });

  /// Generates a single prescription for one lift on one day.
  /// This is useful for recalculation or manual adjustments.
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
  });
}

/// Default implementation of WorkoutGenerationService.
class DefaultWorkoutGenerationService implements WorkoutGenerationService {
  final IntensityLookupService _intensityLookup;
  final RepTargetLookupService _repTargetLookup;
  final RoundingService _rounding;

  DefaultWorkoutGenerationService({
    IntensityLookupService? intensityLookup,
    RepTargetLookupService? repTargetLookup,
    RoundingService? rounding,
  })  : _intensityLookup = intensityLookup ?? DefaultIntensityLookupService(),
        _repTargetLookup = repTargetLookup ?? DefaultRepTargetLookupService(),
        _rounding = rounding ?? DefaultRoundingService();

  @override
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
    // Find all lifts scheduled for this day and frequency
    final dayTemplates = frequencyTemplates.where(
      (t) => t.frequency.toString() == 'ProgramFrequency.$frequency' && 
             t.dayIndex == dayIndex,
    ).toList();

    if (dayTemplates.isEmpty) {
      throw Exception(
        'No frequency template found for frequency: $frequency, day: $dayIndex',
      );
    }

    // Sort by default order for consistent prescription order
    dayTemplates.sort((a, b) => a.defaultOrder.compareTo(b.defaultOrder));

    // Generate prescription for each lift
    final prescriptions = <ExercisePrescription>[];
    for (final template in dayTemplates) {
      final trainingMax = trainingMaxes[template.liftId];
      if (trainingMax == null) {
        throw Exception(
          'Training max not found for lift: ${template.liftId}',
        );
      }

      final intensity = _intensityLookup.getIntensity(
        template.liftId,
        weekNumber,
        intensityPoints,
      );

      final prescription = generateSinglePrescription(
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
      );

      prescriptions.add(prescription);
    }

    return prescriptions;
  }

  @override
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
    // Calculate working weight: TM * intensity, then round
    final calculatedWeight = trainingMax.value * intensity;
    final workingWeight = _rounding.roundWeight(
      calculatedWeight,
      roundingIncrement,
      roundingMode,
    );

    // Look up rep targets for this intensity
    final repsPerNormalSet = _repTargetLookup.getNormalSetTarget(
      liftId,
      intensity,
      repTargetPoints,
    );

    final repOutTarget = _repTargetLookup.getLastSetTarget(
      liftId,
      intensity,
      repTargetPoints,
    );

    // Default set goal is 4 for all prescribed lifts (from workbook)
    const setGoal = 4;

    return ExercisePrescription(
      id: '${workoutDayId}_${liftId}_$weekNumber',
      workoutDayId: workoutDayId,
      liftId: liftId,
      trainingMaxSnapshot: trainingMax.value,
      intensity: intensity,
      workingWeight: workingWeight,
      repsPerNormalSet: repsPerNormalSet,
      repOutTarget: repOutTarget,
      setGoal: setGoal,
      displayOrder: displayOrder,
      isPrimaryBlock: isPrimaryBlock,
    );
  }
}

