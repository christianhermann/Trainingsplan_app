import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/models/training_max.dart' as domain;
import '../../domain/services/intensity_lookup_service.dart';
import '../../domain/services/rep_target_lookup_service.dart';
import '../../domain/services/rounding_service.dart';
import '../../domain/services/workout_generation_service.dart';

// ── Lift name map ────────────────────────────────────────────────────────────
// Maps UI lift keys (used in setup screen) to DB seeded lift names.
const _liftNameMap = {
  'squat': 'squat',
  'bench_press': 'bankdruecken',
  'deadlift': 'deadlift',
  'overhead_press': 'schulterdruecken',
};

// ── Frequency lookup data (minimal inline tables) ─────────────────────────────
// Maps ProgramFrequency enum to number of training days per week.
const _frequencyDays = {
  ProgramFrequency.two: 2,
  ProgramFrequency.three: 3,
  ProgramFrequency.four: 4,
  ProgramFrequency.five: 5,
  ProgramFrequency.six: 6,
};

// ── Setup state ─────────────────────────────────────────────────────────────

class SetupState {
  const SetupState({
    this.selectedFrequency,
    this.trainingMaxes = const {},
    this.isValid = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final ProgramFrequency? selectedFrequency;
  final Map<String, double> trainingMaxes;
  final bool isValid;
  final bool isSaving;
  final String? errorMessage;

  SetupState copyWith({
    ProgramFrequency? selectedFrequency,
    Map<String, double>? trainingMaxes,
    bool? isValid,
    bool? isSaving,
    String? errorMessage,
    bool clearError = false,
  }) {
    return SetupState(
      selectedFrequency: selectedFrequency ?? this.selectedFrequency,
      trainingMaxes: trainingMaxes ?? this.trainingMaxes,
      isValid: isValid ?? this.isValid,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier(this._ref) : super(const SetupState());

  final Ref _ref;

  void selectFrequency(ProgramFrequency frequency) {
    state = state.copyWith(
        selectedFrequency: frequency, clearError: true);
    _validate();
  }

  void updateTrainingMax(String liftId, double value) {
    final updated = {...state.trainingMaxes};
    if (value > 0) {
      updated[liftId] = value;
    } else {
      updated.remove(liftId);
    }
    state = state.copyWith(trainingMaxes: updated);
    _validate();
  }

  void clearAllMaxes() {
    state = state.copyWith(trainingMaxes: {});
    _validate();
  }

  void _validate() {
    const mainLifts = ['squat', 'bench_press', 'deadlift', 'overhead_press'];
    final allMaxesPresent =
        mainLifts.every((l) => (state.trainingMaxes[l] ?? 0) > 0);
    final isValid = state.selectedFrequency != null && allMaxesPresent;
    String? error;
    if (state.selectedFrequency == null) {
      error = 'Please select a training frequency';
    } else if (!allMaxesPresent) {
      final missing = mainLifts
          .where((l) => (state.trainingMaxes[l] ?? 0) <= 0)
          .toList();
      error = 'Missing maxes for: ${missing.join(', ')}';
    }
    state = state.copyWith(isValid: isValid, errorMessage: error);
  }

  /// Save setup: persist training maxes + generate full 21-week program.
  Future<void> saveAndGenerate() async {
    if (!state.isValid) return;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final liftRepo = _ref.read(liftRepositoryProvider);
      final tmRepo = _ref.read(trainingMaxRepositoryProvider);
      final programRepo = _ref.read(programRepositoryProvider);
      final workoutRepo = _ref.read(workoutRepositoryProvider);

      // 1. Deactivate any existing active program
      await programRepo.deactivateAll();

      // 2. Resolve UI lift keys to DB lift rows
      final liftIdMap = <String, int>{}; // uiKey -> db id
      for (final entry in _liftNameMap.entries) {
        final lift = await liftRepo.getLiftByName(entry.value);
        if (lift == null) {
          throw Exception('Lift not found in DB: ${entry.value}');
        }
        liftIdMap[entry.key] = lift.id;
      }

      // 3. Save training maxes
      final now = DateTime.now();
      final domainMaxes = <String, domain.TrainingMax>{};
      for (final entry in state.trainingMaxes.entries) {
        final dbLiftId = liftIdMap[entry.key];
        if (dbLiftId == null) continue;
        await tmRepo.saveMax(TrainingMaxesCompanion.insert(
          liftId: dbLiftId,
          value: entry.value,
          effectiveDate: now,
        ));
        // Build domain model for generation service
        domainMaxes[entry.key] = domain.TrainingMax(
          id: entry.key,
          liftId: entry.key,
          value: entry.value,
          singleEightPercentage: 0.9,
          sourceType: domain.MaxSourceType.manual,
          effectiveDate: now,
        );
      }

      // 4. Create program record
      final frequency = state.selectedFrequency!;
      final programId = await programRepo.saveProgram(
        ProgramsCompanion.insert(
          name: const Value('My Program'),
          frequency: frequency.name,
          currentWeek: const Value(1),
          totalWeeks: const Value(21),
          isActive: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );

      // 5. Generate all 21 weeks
      final daysPerWeek = _frequencyDays[frequency] ?? 3;
      final generationService = DefaultWorkoutGenerationService();
      final intensityService = DefaultIntensityLookupService();
      final repTargetService = DefaultRepTargetLookupService();

      for (int week = 1; week <= 21; week++) {
        final weekId = await programRepo.saveWeek(
          WorkoutWeeksCompanion.insert(
            programId: programId,
            weekNumber: week,
            displayLabel: Value('Week $week'),
          ),
        );

        for (int day = 0; day < daysPerWeek; day++) {
          final dayId = await programRepo.saveDay(
            WorkoutDaysCompanion.insert(
              workoutWeekId: weekId,
              dayIndex: day,
              title: Value('Day ${day + 1}'),
              status: const Value('planned'),
            ),
          );

          // Generate prescriptions for main lifts on this day
          // Round-robin the main lifts across days
          final mainLiftKeys = ['squat', 'bench_press', 'deadlift', 'overhead_press'];
          final liftForDay = mainLiftKeys[day % mainLiftKeys.length];
          final dbLiftId = liftIdMap[liftForDay]!;
          final tm = domainMaxes[liftForDay]!;

          final intensity = intensityService.getIntensityForWeek(week);
          final repsNormal = repTargetService.getNormalSetReps(week);
          final repsLast = repTargetService.getLastSetReps(week);
          final workingWeight = (tm.value * intensity / 2.5).round() * 2.5;

          await workoutRepo.savePrescription(
            ExercisePrescriptionsCompanion.insert(
              workoutDayId: dayId,
              liftId: dbLiftId,
              trainingMaxSnapshot: tm.value,
              intensity: intensity,
              workingWeight: workingWeight.toDouble(),
              repsPerNormalSet: repsNormal,
              repOutTarget: repsLast,
              setGoal: const Value(4),
              displayOrder: const Value(0),
            ),
          );
        }
      }

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save: $e',
      );
    }
  }
}

final setupProvider =
    StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  return SetupNotifier(ref);
});
