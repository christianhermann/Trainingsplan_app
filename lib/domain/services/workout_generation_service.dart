// workout_generation_service.dart
//
// ROLE: Pure domain service - zero DB and zero Riverpod dependencies.
//
// Receives pre-loaded lookup tables (intensity points, rep-target points,
// frequency templates) and training maxes, then computes
// [ExercisePrescription] objects for a single workout day.
//
// This is the math layer. Called exclusively by [WorkoutGeneratorService]
// (workout_generator_service.dart), which owns DB persistence and Riverpod.
//
// Two-file architecture:
//   workout_generator_service.dart  -> DB orchestrator (Riverpod provider)
//   workout_generation_service.dart -> Pure math (this file, no side-effects)
//
// See docs/workbook--logic.md for the full prescription calculation spec.

import '../models/enums.dart';
import '../models/exercise_prescription.dart';
import '../models/frequency_template.dart';
import '../models/training_max.dart';

import 'rounding_service.dart';

// ---------------------------------------------------------------------------
// Rep-target lookup — replaces RepTargetPoint table + RepTargetLookupService.
// Workbook Quick Setup: 21 intensity steps from 50.0% to 100.0% in 2.5%
// increments. Same curve for every lift.
// ---------------------------------------------------------------------------

/// Returns the reps-per-set target for a given intensity (0.0–1.0).
///
/// Workbook Quick Setup tab, rows C24:W24:
///   0.50 → 20, 0.525 → 18, 0.55 → 16, 0.575 → 15,
///   0.60 → 14, 0.625 → 13, 0.65 → 12, 0.675 → 11,
///   0.70 → 10, 0.725 →  9, 0.75 →  8, 0.775 →  7,
///   0.80 →  6, 0.825 →  5, 0.85 →  4, 0.875 →  3,
///   0.90 →  2, 0.925 →  2, 0.95 →  1, 0.975 →  1, 1.00 →  1.
///
/// Values between steps round down to the nearest bucket (e.g. 0.71 → 10 reps).
int repsForIntensity(double intensity) {
  if (intensity >= 0.975) return 1;
  if (intensity >= 0.950) return 1;
  if (intensity >= 0.925) return 2;
  if (intensity >= 0.900) return 2;
  if (intensity >= 0.875) return 3;
  if (intensity >= 0.850) return 4;
  if (intensity >= 0.825) return 5;
  if (intensity >= 0.800) return 6;
  if (intensity >= 0.775) return 7;
  if (intensity >= 0.750) return 8;
  if (intensity >= 0.725) return 9;
  if (intensity >= 0.700) return 10;
  if (intensity >= 0.675) return 11;
  if (intensity >= 0.650) return 12;
  if (intensity >= 0.625) return 13;
  if (intensity >= 0.600) return 14;
  if (intensity >= 0.575) return 15;
  if (intensity >= 0.550) return 16;
  if (intensity >= 0.525) return 18;
  return 20;
}

/// Returns the intensity fraction for a given lift.
///
/// Workbook Quick Setup:
///   Main lifts (squat, bench_press, deadlift, overhead_press) → 0.875
///   Aux tier-1 (front_squat, close_grip_bench)               → 0.825
///   Aux tier-2 + back exercises                               → 0.750
double intensityForLift(String liftId) {
  switch (liftId) {
    case 'squat':
    case 'bench_press':
    case 'deadlift':
    case 'overhead_press':
      return 0.875;
    case 'front_squat':
    case 'close_grip_bench':
      return 0.825;
    default:
      return 0.750;
  }
}

/// Pure domain service - no DB, no Riverpod.
///
/// Given lookup tables (loaded by [WorkoutGeneratorService]) and training maxes,
/// builds [ExercisePrescription] objects for a single workout day.
///
/// Workbook constants:
///   setGoal  = 3  (all lifts, all weeks)
///   RIR target = 0 (last set always to technical limit)
///   workingWeight = round(trainingMax x intensity, mode, increment)
class WorkoutGenerationService {
  // Workbook constant: all lifts are prescribed 3 sets per session.
  static const int kSetGoal = 3;

  final RoundingService        _rounding;

  WorkoutGenerationService({
    RoundingService?        rounding,
  })  : _rounding        = rounding        ?? const RoundingService();

  /// Generate prescriptions for one day.
  ///
  /// [frequency]    - [ProgramFrequency] enum; compared directly against
  ///                  [FrequencyTemplate.frequency].
  /// [roundingMode] - [RoundingMode] enum (parsed from AppSettings by caller).
  List<ExercisePrescription> generateDayPrescriptions({
    required String              workoutDayId,
    required ProgramFrequency    frequency,
    required int                 dayIndex,
    required int                 weekNumber,
    required List<FrequencyTemplate> frequencyTemplates,
    required Map<String, TrainingMax> trainingMaxes,
    required double                  roundingIncrement,
    required RoundingMode            roundingMode,
  }) {
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
          roundingIncrement: roundingIncrement,
          roundingMode:      roundingMode,
        ),
    ];
  }

  ExercisePrescription _buildPrescription({
    required FrequencyTemplate        template,
    required String                   workoutDayId,
    required int                      weekNumber,
    required Map<String, TrainingMax> trainingMaxes,
    required double                   roundingIncrement,
    required RoundingMode             roundingMode,
  }) {
    final trainingMax = trainingMaxes[template.liftId];
    if (trainingMax == null) {
      throw ArgumentError(
          'Training max not found for liftId: ${template.liftId}. '
          'Ensure all lifts in the frequency template have a TM entry.');
    }

    final intensity = intensityForLift(template.liftId);

    final workingWeight = _rounding.round(
      trainingMax.value * intensity,
      roundingMode,
      roundingIncrement,
    );

    final repsPerNormalSet = repsForIntensity(intensity);

    // repOutTarget == repsPerNormalSet: workbook has one rep count per
    // intensity step; RIR=0 on the last set means work to technical limit.
    return ExercisePrescription(
      id:                  '${workoutDayId}_${template.liftId}_w$weekNumber',
      workoutDayId:        workoutDayId,
      liftId:              template.liftId,
      trainingMaxSnapshot: trainingMax.value,
      intensity:           intensity,
      workingWeight:       workingWeight,
      repsPerNormalSet:    repsPerNormalSet,
      repOutTarget:        repsPerNormalSet,
      setGoal:             kSetGoal,
      displayOrder:        template.defaultOrder,
      isPrimaryBlock:      template.blockType.toLowerCase() == 'main',
    );
  }

  /// Convenience method used by tests - generates a single prescription
  /// without requiring a FrequencyTemplate.
  ExercisePrescription generateSinglePrescription({
    required String       workoutDayId,
    required String       liftId,
    required int          displayOrder,
    required bool         isPrimaryBlock,
    required int          weekNumber,
    required TrainingMax  trainingMax,
    required double       intensity,
    required double       roundingIncrement,
    required RoundingMode roundingMode,
  }) {
    final workingWeight = _rounding.round(
      trainingMax.value * intensity,
      roundingMode,
      roundingIncrement,
    );
    final repsPerNormalSet =
        repsForIntensity(intensity);

    return ExercisePrescription(
      id:                  '${workoutDayId}_${liftId}_w$weekNumber',
      workoutDayId:        workoutDayId,
      liftId:              liftId,
      trainingMaxSnapshot: trainingMax.value,
      intensity:           intensity,
      workingWeight:       workingWeight,
      repsPerNormalSet:    repsPerNormalSet,
      repOutTarget:        repsPerNormalSet,
      setGoal:             kSetGoal,
      displayOrder:        displayOrder,
      isPrimaryBlock:      isPrimaryBlock,
    );
  }
}
