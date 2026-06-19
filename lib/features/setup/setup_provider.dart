import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalogue/lift_catalogue.dart';
import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/workout_generator_service.dart';

// ---------------------------------------------------------------------------
// Lift key constants
// ---------------------------------------------------------------------------

/// The 4 main lift slot keys, in display order.
const mainLiftKeys = [
  'squat',
  'bench_press',
  'deadlift',
  'overhead_press',
];

/// Default Single @8% ratio (matches workbook Quick Setup default).
const kDefaultSingleAt8 = 0.9;

/// Ratio applied to derive auxiliary and back-exercise TMs when the user
/// does not provide explicit values.
const kAuxTmRatio = 0.9;

/// Initial map so every main lift already has the workbook default.
const _defaultSingleEightPercentages = <String, double>{
  'squat':          kDefaultSingleAt8,
  'bench_press':    kDefaultSingleAt8,
  'deadlift':       kDefaultSingleAt8,
  'overhead_press': kDefaultSingleAt8,
};

/// Auxiliary lift slot keys grouped by their parent main lift.
const auxSlotsByMain = <String, List<String>>{
  'squat':          ['front_squat', 'squat_aux2'],
  'bench_press':    ['close_grip_bench', 'bench_aux2'],
  'deadlift':       ['deadlift_aux'],
  'overhead_press': ['ohp_aux'],
};

/// All auxiliary slot keys in display order.
const _allAuxKeys = [
  'front_squat', 'squat_aux2',
  'close_grip_bench', 'bench_aux2',
  'deadlift_aux',
  'ohp_aux',
];

/// Back exercise keys. TMs default to deadlift x [kAuxTmRatio].
const backKeys = ['barbell_rows', 'dumbbell_rows', 'pulldowns'];

/// All non-main lift keys that need a TM saved to DB.
const _allNonMainKeys = [..._allAuxKeys, ...backKeys];

const _defaultAux = <String, String>{
  'squat':          'front_squat',
  'bench_press':    'close_grip_bench',
  'deadlift':       'deadlift_aux',
  'overhead_press': 'ohp_aux',
};

/// Aux options per main lift (slot key -> list of named options).
const auxOptions = <String, List<({String key, String label})>>{
  'squat': [
    (key: 'front_squat',      label: 'Leg Press'),
    (key: 'squat_aux2',       label: 'Wider Stance Squat'),
  ],
  'bench_press': [
    (key: 'close_grip_bench', label: 'DB Bench'),
    (key: 'bench_aux2',       label: 'Incline DB Press'),
  ],
  'deadlift': [
    (key: 'deadlift_aux',     label: 'Trap Bar Deadlift'),
  ],
  'overhead_press': [
    (key: 'ohp_aux',          label: 'DB Schulterdr\u00FCcken'),
  ],
};

// ---------------------------------------------------------------------------
// State
// ---------------------------------------------------------------------------

class SetupState {
  const SetupState({
    this.selectedFrequency,
    this.trainingMaxes            = const {},
    this.auxTrainingMaxes         = const {},
    this.singleEightPercentages   = _defaultSingleEightPercentages,
    this.selectedAuxiliaries      = _defaultAux,
    this.liftNames                = liftDefaults,
    this.isValid                  = false,
    this.isSaving                 = false,
    this.errorMessage,
  });

  final ProgramFrequency? selectedFrequency;
  final Map<String, double> trainingMaxes;
  final Map<String, double> auxTrainingMaxes;
  final Map<String, double> singleEightPercentages;
  final Map<String, String> selectedAuxiliaries;
  final Map<String, String> liftNames;
  final bool    isValid;
  final bool    isSaving;
  final String? errorMessage;

  SetupState copyWith({
    ProgramFrequency?    selectedFrequency,
    Map<String, double>? trainingMaxes,
    Map<String, double>? auxTrainingMaxes,
    Map<String, double>? singleEightPercentages,
    Map<String, String>? selectedAuxiliaries,
    Map<String, String>? liftNames,
    bool?                isValid,
    bool?                isSaving,
    String?              errorMessage,
    bool                 clearError = false,
  }) =>
      SetupState(
        selectedFrequency:         selectedFrequency         ?? this.selectedFrequency,
        trainingMaxes:             trainingMaxes             ?? this.trainingMaxes,
        auxTrainingMaxes:          auxTrainingMaxes          ?? this.auxTrainingMaxes,
        singleEightPercentages:    singleEightPercentages    ?? this.singleEightPercentages,
        selectedAuxiliaries:       selectedAuxiliaries       ?? this.selectedAuxiliaries,
        liftNames:                 liftNames                 ?? this.liftNames,
        isValid:                   isValid                   ?? this.isValid,
        isSaving:                  isSaving                  ?? this.isSaving,
        errorMessage: clearError
            ? null
            : (errorMessage ?? this.errorMessage),
      );
}

// ---------------------------------------------------------------------------
// Notifier
// ---------------------------------------------------------------------------

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

  void updateAuxTrainingMax(String liftId, double value) {
    final updated = Map<String, double>.from(state.auxTrainingMaxes);
    if (value > 0) {
      updated[liftId] = value;
    } else {
      updated.remove(liftId);
    }
    state = state.copyWith(auxTrainingMaxes: updated);
  }

  void updateSingleEightPercentage(String liftId, double value) {
    if (value <= 0 || value > 1) return;
    final updated = Map<String, double>.from(state.singleEightPercentages);
    updated[liftId] = value;
    state = state.copyWith(singleEightPercentages: updated);
  }

  void selectAuxiliary(String mainLiftKey, String auxLiftKey) {
    final updated = Map<String, String>.from(state.selectedAuxiliaries);
    updated[mainLiftKey] = auxLiftKey;
    state = state.copyWith(selectedAuxiliaries: updated, clearError: true);
  }

  void setLiftName(String slotKey, String displayName) {
    final name = displayName.trim().isEmpty
        ? (liftDefaults[slotKey] ?? slotKey)
        : displayName.trim();
    final updated = Map<String, String>.from(state.liftNames);
    updated[slotKey] = name;
    state = state.copyWith(liftNames: updated);
  }

  void clearAllMaxes() {
    state = state.copyWith(
      trainingMaxes:          {},
      auxTrainingMaxes:       {},
      singleEightPercentages: _defaultSingleEightPercentages,
      selectedAuxiliaries:    _defaultAux,
      liftNames:              liftDefaults,
    );
    _validate();
  }

  void _validate() {
    final allPresent =
        mainLiftKeys.every((l) => (state.trainingMaxes[l] ?? 0) > 0);
    final isValid = state.selectedFrequency != null && allPresent;
    String? error;
    if (state.selectedFrequency == null) {
      error = 'Please select a training frequency';
    } else if (!allPresent) {
      final missing =
          mainLiftKeys.where((l) => (state.trainingMaxes[l] ?? 0) <= 0);
      error = 'Missing maxes for: ${missing.join(', ')}';
    }
    state = state.copyWith(isValid: isValid, errorMessage: error);
  }

  Future<void> saveAndGenerate() async {
    if (!state.isValid) return;
    state = state.copyWith(isSaving: true, clearError: true);

    try {
      final db           = ref.read(databaseProvider);
      final liftRepo     = ref.read(liftRepositoryProvider);
      final tmRepo       = ref.read(trainingMaxRepositoryProvider);
      final programRepo  = ref.read(programRepositoryProvider);
      final generatorSvc = ref.read(workoutGeneratorServiceProvider);
      final now          = DateTime.now();
      final frequency    = state.selectedFrequency!;

      // Resolve DB lift IDs
      final allLiftKeys = [...mainLiftKeys, ..._allNonMainKeys];
      final liftDbIds   = <String, int>{};
      for (final liftId in allLiftKeys) {
        final lift = await liftRepo.getLiftByName(liftId);
        if (lift != null) liftDbIds[liftId] = lift.id;
      }
      for (final key in mainLiftKeys) {
        if (!liftDbIds.containsKey(key)) {
          throw Exception('Lift not found in DB: $key');
        }
      }

      // Build full TM map
      final deadliftTm = state.trainingMaxes['deadlift']!;
      final fullTmMap  = <String, double>{
        for (final key in mainLiftKeys) key: state.trainingMaxes[key]!,
      };

      for (final mainKey in mainLiftKeys) {
        final mainTm  = state.trainingMaxes[mainKey]!;
        final auxKeys = auxSlotsByMain[mainKey] ?? [];
        for (final auxKey in auxKeys) {
          final userValue = state.auxTrainingMaxes[auxKey];
          fullTmMap[auxKey] = (userValue != null && userValue > 0)
              ? userValue
              : mainTm * kAuxTmRatio;
        }
      }

      for (final k in backKeys) {
        fullTmMap[k] = deadliftTm * kAuxTmRatio;
      }

      // Everything inside a single DB transaction
      await db.transaction(() async {
        await programRepo.deactivateAll();

        // Use partial update (only displayName) to avoid InvalidDataException.
        for (final entry in state.liftNames.entries) {
          final dbId = liftDbIds[entry.key];
          if (dbId == null) continue;
          await liftRepo.updateDisplayName(dbId, entry.value);
        }

        for (final key in mainLiftKeys) {
          final s8p  = state.singleEightPercentages[key] ?? kDefaultSingleAt8;
          final dbId = liftDbIds[key]!;
          await tmRepo.saveMax(TrainingMaxesCompanion.insert(
            liftId:                dbId,
            value:                 state.trainingMaxes[key]!,
            singleEightPercentage: Value(s8p),
            effectiveDate:         now,
          ));
        }

        for (final key in _allNonMainKeys) {
          final dbId = liftDbIds[key];
          if (dbId == null) continue;
          await tmRepo.saveMax(TrainingMaxesCompanion.insert(
            liftId:        dbId,
            value:         fullTmMap[key]!,
            effectiveDate: now,
          ));
        }

        final programId = await programRepo.saveProgram(
          ProgramsCompanion.insert(
            name:      'My Program',
            frequency: frequency.name,
            createdAt: now,
            updatedAt: now,
            isActive:  const Value(true),
          ),
        );

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

        await generatorSvc.generateFullProgram(
          programId:     programId,
          frequency:     frequency,
          weeks:         weeks,
          trainingMaxes: fullTmMap,
          liftDbIds:     liftDbIds,
        );
      });

      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
        isSaving:     false,
        errorMessage: 'Failed to save: $e',
      );
    }
  }
}

final setupProvider =
    NotifierProvider<SetupNotifier, SetupState>(SetupNotifier.new);
