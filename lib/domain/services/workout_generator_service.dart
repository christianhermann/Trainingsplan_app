import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/settings_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../data/seeders/frequency_template_seeder.dart';
import '../../data/seeders/intensity_seeder.dart';
import '../../data/seeders/rep_target_seeder.dart';
import '../models/enums.dart';
import '../models/training_max.dart';
import 'workout_generation_service.dart';

/// Orchestrates full program generation.
///
/// Pipeline per [generateFullProgram] call:
///   1. Load AppSettings (rounding increment + mode).
///   2. Load all FrequencyTemplates for the frequency (seeder — pure, no DB).
///   3. Load IntensityPoints (seeder).
///   4. Load RepTargetPoints (seeder).
///   5. For every week × every day index in the frequency template:
///      a. Persist WorkoutDay row.
///      b. Build ExercisePrescriptions via [WorkoutGenerationService].
///      c. Batch-persist prescriptions.
///
/// [WorkoutGenerationService] stays pure (no DB); all I/O lives here.
class WorkoutGeneratorService {
  WorkoutGeneratorService(this._ref);
  final Ref _ref;

  final _generationSvc = WorkoutGenerationService();

  /// Generate all 21 weeks × N days for [programId].
  ///
  /// [weeks] must be pre-saved WorkoutWeek DB rows (id + weekNumber needed).
  /// [trainingMaxes] maps liftId → TM value for every liftId that appears
  ///   in the frequency template (main + aux).
  /// [liftDbIds] maps liftId → DB integer id from the lifts table.
  Future<void> generateFullProgram({
    required int programId,
    required ProgramFrequency frequency,
    required List<({int id, int weekNumber})> weeks,
    required Map<String, double> trainingMaxes,
    required Map<String, int> liftDbIds,
  }) async {
    final settingsRepo = _ref.read(settingsRepositoryProvider);
    final programRepo  = _ref.read(programRepositoryProvider);
    final workoutRepo  = _ref.read(workoutRepositoryProvider);

    // 1. Rounding settings
    final settings         = await settingsRepo.getSettings();
    final roundingIncrement = settings?.roundingIncrement ?? 2.5;
    final roundingMode      = settings?.roundingMode      ?? 'round';

    // 2–4. Pure seeder data (no DB)
    final allTemplates  = FrequencyTemplateSeeder.generateFrequencyTemplates();
    final allIntensity  = IntensitySeeder.generateIntensityPoints();
    final allRepTargets = RepTargetSeeder.generateRepTargetPoints();

    final freqTemplates = allTemplates
        .where((t) => t.frequency == frequency)
        .toList();

    if (freqTemplates.isEmpty) {
      throw Exception(
          'No FrequencyTemplate entries for frequency: ${frequency.name}');
    }

    final dayIndices = freqTemplates
        .map((t) => t.dayIndex)
        .toSet()
        .toList()
      ..sort();

    // 5. Build domain TrainingMax map
    final tmMap = <String, TrainingMax>{
      for (final e in trainingMaxes.entries)
        e.key: TrainingMax(
          id: '${e.key}_snap',
          liftId: e.key,
          value: e.value,
          singleEightPercentage: 0.9,
          sourceType: MaxSourceType.manual,
          effectiveDate: DateTime.now(),
        ),
    };

    // 6. Generate week × day
    for (final week in weeks) {
      for (final dayIndex in dayIndices) {
        // a. Persist WorkoutDay
        final dayDbId = await programRepo.saveDay(
          WorkoutDaysCompanion.insert(
            workoutWeekId: week.id,
            dayIndex: dayIndex,
          ),
        );
        final workoutDayId = dayDbId.toString();

        // b. Build prescriptions (pure, no DB)
        final prescriptions = _generationSvc.generateDayPrescriptions(
          workoutDayId:       workoutDayId,
          frequency:          frequency.name,
          dayIndex:           dayIndex,
          weekNumber:         week.weekNumber,
          frequencyTemplates: freqTemplates,
          trainingMaxes:      tmMap,
          intensityPoints:    allIntensity,
          repTargetPoints:    allRepTargets,
          roundingIncrement:  roundingIncrement,
          roundingMode:       roundingMode,
        );

        // c. Batch-persist prescriptions
        await workoutRepo.savePrescriptions(
          prescriptions.map((p) {
            final dbLiftId = liftDbIds[p.liftId];
            if (dbLiftId == null) {
              throw Exception(
                  'DB liftId not resolved for liftId: ${p.liftId}');
            }
            return ExercisePrescriptionsCompanion.insert(
              workoutDayId:        dayDbId,
              liftId:              dbLiftId,
              trainingMaxSnapshot: p.trainingMaxSnapshot,
              intensity:           p.intensity,
              workingWeight:       p.workingWeight,
              repsPerNormalSet:    p.repsPerNormalSet,
              repOutTarget:        p.repOutTarget,
              setGoal:             p.setGoal,
              displayOrder:        Value(p.displayOrder),
              isPrimaryBlock:      Value(p.isPrimaryBlock),
            );
          }).toList(),
        );
      }
    }
  }
}

final workoutGeneratorServiceProvider = Provider<WorkoutGeneratorService>((ref) {
  return WorkoutGeneratorService(ref);
});
