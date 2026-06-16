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

/// Orchestrates full 21-week program generation.
///
/// Responsibilities (I/O layer only):
///   • Read rounding settings (increment + mode) from AppSettingsTable via
///     [SettingsRepository]. Defaults: increment=2.5 kg, mode=nearest.
///   • Generate pure seeder data (no DB reads for lookup tables).
///   • Persist one [WorkoutDay] row per week × day.
///   • Delegate pure prescription building to [WorkoutGenerationService],
///     which calls [RoundingService.round] with the typed [RoundingMode] enum.
///   • Batch-persist [ExercisePrescription] rows.
class WorkoutGeneratorService {
  WorkoutGeneratorService(this._ref);
  final Ref _ref;

  final _generationSvc = WorkoutGenerationService();

  // Default rounding settings (barbell standard).
  static const _defaultIncrement = 2.5;
  static const _defaultMode      = RoundingMode.nearest;

  /// Generate and persist all 21 weeks × N days for [programId].
  ///
  ///   [programId]     — DB id of the already-saved Program row.
  ///   [frequency]     — [ProgramFrequency] enum (2x–6x).
  ///   [weeks]         — pre-saved WorkoutWeek rows ({id, weekNumber}).
  ///   [trainingMaxes] — liftId → TM value for all 13 canonical lift IDs.
  ///   [liftDbIds]     — liftId → DB integer id from the lifts table.
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

    // ── 1. Read rounding settings from AppSettingsTable ──────────────────────
    // getSettings() returns AppSettingsTableData (Drift-generated).
    // roundingMode is stored as a String; parse it to RoundingMode enum here
    // so the pure generation layer never sees raw strings.
    final settings = await settingsRepo.getSettings();
    final roundingIncrement = settings?.roundingIncrement ?? _defaultIncrement;
    final roundingMode =
        RoundingMode.fromString(settings?.roundingMode) ?? _defaultMode;

    // ── 2. Pure seeder data (no DB reads) ─────────────────────────────────
    final allTemplates  = FrequencyTemplateSeeder.generateFrequencyTemplates();
    final allIntensity  = IntensitySeeder.generateIntensityPoints();
    final allRepTargets = RepTargetSeeder.generateRepTargetPoints();

    final freqTemplates = allTemplates
        .where((t) => t.frequency == frequency)
        .toList();

    if (freqTemplates.isEmpty) {
      throw ArgumentError(
          'No FrequencyTemplate entries for frequency: ${frequency.name}');
    }

    final dayIndices = freqTemplates
        .map((t) => t.dayIndex)
        .toSet()
        .toList()
      ..sort();

    // ── 3. Build domain TrainingMax map ─────────────────────────────────────
    final now   = DateTime.now();
    final tmMap = <String, TrainingMax>{
      for (final e in trainingMaxes.entries)
        e.key: TrainingMax(
          id:                    '${e.key}_snap',
          liftId:                e.key,
          value:                 e.value,
          singleEightPercentage: 0.9,
          sourceType:            MaxSourceType.manual,
          effectiveDate:         now,
        ),
    };

    // ── 4. Generate week × day ─────────────────────────────────────────────
    for (final week in weeks) {
      for (final dayIndex in dayIndices) {

        // a. Persist WorkoutDay row.
        final dayDbId = await programRepo.saveDay(
          WorkoutDaysCompanion.insert(
            workoutWeekId: week.id,
            dayIndex:      dayIndex,
            title: Value('Week ${week.weekNumber} — Day ${dayIndex + 1}'),
          ),
        );

        // b. Build prescriptions (pure — no DB).
        //    roundingMode is now a typed RoundingMode enum; no string passed.
        final prescriptions = _generationSvc.generateDayPrescriptions(
          workoutDayId:       dayDbId.toString(),
          frequency:          frequency,
          dayIndex:           dayIndex,
          weekNumber:         week.weekNumber,
          frequencyTemplates: freqTemplates,
          trainingMaxes:      tmMap,
          intensityPoints:    allIntensity,
          repTargetPoints:    allRepTargets,
          roundingIncrement:  roundingIncrement,
          roundingMode:       roundingMode,        // ← typed enum
        );

        // c. Resolve liftId → DB integer id, build Companions.
        final companions = prescriptions.map((p) {
          final dbLiftId = liftDbIds[p.liftId];
          if (dbLiftId == null) {
            throw ArgumentError(
                'DB liftId not resolved for "${p.liftId}". '
                'Ensure liftDbIds contains all 13 canonical lift IDs.');
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
        }).toList();

        // d. Batch-persist prescriptions.
        await workoutRepo.savePrescriptions(companions);
      }
    }
  }
}

final workoutGeneratorServiceProvider = Provider<WorkoutGeneratorService>((ref) {
  return WorkoutGeneratorService(ref);
});
