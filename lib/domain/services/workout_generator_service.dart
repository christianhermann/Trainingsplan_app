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
class WorkoutGeneratorService {
  WorkoutGeneratorService(this._ref);
  final Ref _ref;

  final _generationSvc = WorkoutGenerationService();

  static const _defaultIncrement = 2.5;

  // ── Full-program generation ─────────────────────────────────────────────────

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
    await _generateWeeks(
      programRepo:   programRepo,
      workoutRepo:   workoutRepo,
      settingsRepo:  settingsRepo,
      frequency:     frequency,
      weeks:         weeks,
      trainingMaxes: trainingMaxes,
      liftDbIds:     liftDbIds,
    );
  }

  // ── Mid-cycle regeneration ─────────────────────────────────────────────────

  /// Deletes all non-completed days from [fromWeek] onward, then re-generates
  /// them with the supplied [trainingMaxes]. Completed days are never touched.
  Future<void> regenerateFromWeek({
    required int programId,
    required int fromWeek,
    required ProgramFrequency frequency,
    required Map<String, double> trainingMaxes,
    required Map<String, int> liftDbIds,
  }) async {
    final settingsRepo = _ref.read(settingsRepositoryProvider);
    final programRepo  = _ref.read(programRepositoryProvider);
    final workoutRepo  = _ref.read(workoutRepositoryProvider);

    await programRepo.deleteFutureDaysForProgram(programId, fromWeek);

    final allWeeks    = await programRepo.getWeeksForProgram(programId);
    final futureWeeks = allWeeks
        .where((w) => w.weekNumber >= fromWeek)
        .map((w) => (id: w.id, weekNumber: w.weekNumber))
        .toList();

    if (futureWeeks.isEmpty) return;

    await _generateWeeks(
      programRepo:   programRepo,
      workoutRepo:   workoutRepo,
      settingsRepo:  settingsRepo,
      frequency:     frequency,
      weeks:         futureWeeks,
      trainingMaxes: trainingMaxes,
      liftDbIds:     liftDbIds,
    );
  }

  // ── Shared generation kernel ─────────────────────────────────────────────────

  Future<void> _generateWeeks({
    required ProgramRepository programRepo,
    required WorkoutRepository workoutRepo,
    required SettingsRepository settingsRepo,
    required ProgramFrequency frequency,
    required List<({int id, int weekNumber})> weeks,
    required Map<String, double> trainingMaxes,
    required Map<String, int> liftDbIds,
  }) async {
    final settings          = await settingsRepo.getSettings();
    final roundingIncrement = settings?.roundingIncrement ?? _defaultIncrement;
    final roundingMode      = RoundingMode.fromString(settings?.roundingMode);

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

    for (final week in weeks) {
      for (final dayIndex in dayIndices) {
        final dayDbId = await programRepo.saveDay(
          WorkoutDaysCompanion.insert(
            workoutWeekId: week.id,
            dayIndex:      dayIndex,
            title: Value('Week ${week.weekNumber} — Day ${dayIndex + 1}'),
          ),
        );

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
          roundingMode:       roundingMode,
        );

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

        await workoutRepo.savePrescriptions(companions);
      }
    }
  }
}

final workoutGeneratorServiceProvider = Provider<WorkoutGeneratorService>((ref) {
  return WorkoutGeneratorService(ref);
});
