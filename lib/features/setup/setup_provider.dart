import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/workout_generator_service.dart';

/// Maps domain liftId keys → [name] column values in the lifts table.
/// Must exactly match what _seedLifts() inserts in database.dart.
const _liftNameMap = <String, String>{
  // Main lifts
  'squat':            'squat',
  'bench_press':      'bench_press',
  'deadlift':         'deadlift',
  'overhead_press':   'overhead_press',
  // Auxiliary tier 1
  'front_squat':      'front_squat',
  'close_grip_bench': 'close_grip_bench',
  // Auxiliary tier 2
  'squat_aux2':       'squat_aux2',
  'bench_aux2':       'bench_aux2',
  'deadlift_aux':     'deadlift_aux',
  'ohp_aux':          'ohp_aux',
  // Back exercises
  'barbell_rows':     'barbell_rows',
  'dumbbell_rows':    'dumbbell_rows',
  'pulldowns':        'pulldowns',
};

/// Lift IDs for which the user must supply a training max on the setup screen.
const _mainLiftKeys = [
  'squat',
  'bench_press',
  'deadlift',
  'overhead_press',
];

/// Aux lifts inherit TM from their parent main lift (same movement pattern).
const _auxToMainTmKey = <String, String>{
  'front_squat':      'squat',
  'squat_aux2':       'squat',
  'close_grip_bench': 'bench_press',
  'bench_aux2':       'bench_press',
  'deadlift_aux':     'deadlift',
  'ohp_aux':          'overhead_press',
  // Back exercises share the deadlift TM as the closest pattern
  'barbell_rows':     'deadlift',
  'dumbbell_rows':    'deadlift',
  'pulldowns':        'deadlift',
};

class SetupState {
  const SetupState({
    this.selectedFrequency,
    this.trainingMaxes = const {},
    this.isValid   = false,
    this.isSaving  = false,
    this.errorMessage,
  });

  final ProgramFrequency?   selectedFrequency;
  final Map<String, double> trainingMaxes;
  final bool                isValid;
  final bool                isSaving;
  final String?             errorMessage;

  SetupState copyWith({
    ProgramFrequency?    selectedFrequency,
    Map<String, double>? trainingMaxes,
    bool?                isValid,
    bool?                isSaving,
    String?              errorMessage,
    bool                 clearError = false,
  }) =>
      SetupState(
        selectedFrequency: selectedFrequency ?? this.selectedFrequency,
        trainingMaxes:     trainingMaxes     ?? this.trainingMaxes,
        isValid:           isValid           ?? this.isValid,
        isSaving:          isSaving          ?? this.isSaving,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

class SetupNotifier extends Notifier<SetupState> {
  @override
  SetupState build() => const SetupState();

  void selectFrequency(ProgramFrequency frequency) {
    state = state.copyWith(selectedFrequency: frequency, clearError: true);
    _validate();
  }

  void updateTrainingMax(String liftId, double value) {
    final updated = Map<String, double>.from(state.trainingMaxes);
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
    final allPresent =
        _mainLiftKeys.every((l) => (state.trainingMaxes[l] ?? 0) > 0);
    final isValid = state.selectedFrequency != null && allPresent;
    String? error;
    if (state.selectedFrequency == null) {
      error = 'Please select a training frequency';
    } else if (!allPresent) {
      final missing =
          _mainLiftKeys.where((l) => (state.trainingMaxes[l] ?? 0) <= 0);
      error = 'Missing maxes for: ${missing.join(', ')}';
    }
    state = state.copyWith(isValid: isValid, errorMessage: error);
  }

  Future<void> saveAndGenerate() async {
    if (!state.isValid) return;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final liftRepo     = ref.read(liftRepositoryProvider);
      final tmRepo       = ref.read(trainingMaxRepositoryProvider);
      final programRepo  = ref.read(programRepositoryProvider);
      final generatorSvc = ref.read(workoutGeneratorServiceProvider);
      final now          = DateTime.now();
      final frequency    = state.selectedFrequency!;

      // ── 1. Deactivate existing programs ─────────────────────────────────
      await programRepo.deactivateAll();

      // ── 2. Resolve all 13 lift DB ids ───────────────────────────────────
      // liftNameMap key == DB name column, so lookup by name = key itself.
      final liftDbIds = <String, int>{};
      for (final liftId in _liftNameMap.keys) {
        final lift = await liftRepo.getLiftByName(liftId);
        if (lift != null) liftDbIds[liftId] = lift.id;
      }

      // Verify all 4 main lifts resolved (aux lifts may not exist on old DBs).
      for (final key in _mainLiftKeys) {
        if (!liftDbIds.containsKey(key)) {
          throw Exception('Lift not found in DB: $key');
        }
      }

      // ── 3. Save training maxes for the 4 main lifts ─────────────────────
      for (final key in _mainLiftKeys) {
        final tm    = state.trainingMaxes[key]!;
        final dbId  = liftDbIds[key]!;
        await tmRepo.saveMax(TrainingMaxesCompanion.insert(
          liftId:        dbId,
          value:         tm,
          effectiveDate: now,
        ));
      }

      // ── 4. Insert Program row (active = true) ────────────────────────────
      final programId = await programRepo.saveProgram(
        ProgramsCompanion.insert(
          name:      'My Program',
          frequency: frequency.name,
          createdAt: now,
          updatedAt: now,
          isActive:  const Value(true),
        ),
      );

      // ── 5. Insert 21 WorkoutWeek rows ────────────────────────────────────
      final weeks = <({int id, int weekNumber})>[];
      for (int w = 1; w <= 21; w++) {
        final weekId = await programRepo.saveWeek(
          WorkoutWeeksCompanion.insert(
            programId:  programId,
            weekNumber: w,
          ),
        );
        weeks.add((id: weekId, weekNumber: w));
      }

      // ── 6. Derive full TM map: aux lifts inherit their main lift TM ──────
      final fullTmMap = <String, double>{
        // Main lifts
        for (final key in _mainLiftKeys) key: state.trainingMaxes[key]!,
        // Aux lifts
        for (final e in _auxToMainTmKey.entries)
          e.key: state.trainingMaxes[e.value]!,
      };

      // ── 7. Delegate all WorkoutDay + ExercisePrescription generation ─────
      await generatorSvc.generateFullProgram(
        programId:     programId,
        frequency:     frequency,
        weeks:         weeks,
        trainingMaxes: fullTmMap,
        liftDbIds:     liftDbIds,
      );

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
    NotifierProvider<SetupNotifier, SetupState>(SetupNotifier.new);
