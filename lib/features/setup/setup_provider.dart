import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalogue/lift_catalogue.dart';
import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/workout_generator_service.dart';

// ── Lift key maps ───────────────────────────────────────────────────

const _liftNameMap = <String, String>{
  'squat':            'squat',
  'bench_press':      'bench_press',
  'deadlift':         'deadlift',
  'overhead_press':   'overhead_press',
  'front_squat':      'front_squat',
  'close_grip_bench': 'close_grip_bench',
  'squat_aux2':       'squat_aux2',
  'bench_aux2':       'bench_aux2',
  'deadlift_aux':     'deadlift_aux',
  'ohp_aux':          'ohp_aux',
  'barbell_rows':     'barbell_rows',
  'dumbbell_rows':    'dumbbell_rows',
  'pulldowns':        'pulldowns',
};

const _mainLiftKeys = [
  'squat',
  'bench_press',
  'deadlift',
  'overhead_press',
];

/// Auxiliary lift slot keys grouped by their parent main lift.
/// Used in the UI for the collapsible "Auxiliary Maxes" section and in
/// saveAndGenerate() to resolve TMs (user-entered or mainMax * 0.9 default).
const auxSlotsByMain = <String, List<String>>{
  'squat':          ['front_squat', 'squat_aux2'],
  'bench_press':    ['close_grip_bench', 'bench_aux2'],
  'deadlift':       ['deadlift_aux'],
  'overhead_press': ['ohp_aux'],
};

/// All 9 auxiliary slot keys in display order.
const _allAuxKeys = [
  'front_squat', 'squat_aux2',
  'close_grip_bench', 'bench_aux2',
  'deadlift_aux',
  'ohp_aux',
];

/// Aux options per main lift (slot key → list of named options).
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
    (key: 'ohp_aux',          label: 'DB Schulterdrücken'),
  ],
};

const _defaultAux = <String, String>{
  'squat':          'front_squat',
  'bench_press':    'close_grip_bench',
  'deadlift':       'deadlift_aux',
  'overhead_press': 'ohp_aux',
};

// ── State ────────────────────────────────────────────────────────────────

class SetupState {
  const SetupState({
    this.selectedFrequency,
    this.trainingMaxes       = const {},
    this.auxTrainingMaxes    = const {},
    this.selectedAuxiliaries = _defaultAux,
    this.liftNames           = liftDefaults,
    this.isValid             = false,
    this.isSaving            = false,
    this.errorMessage,
  });

  final ProgramFrequency?   selectedFrequency;
  /// Main lift TMs (required). Keys: squat, bench_press, deadlift, overhead_press.
  final Map<String, double> trainingMaxes;
  /// Auxiliary lift TMs (optional). Keys from [_allAuxKeys].
  /// Missing keys fall back to mainMax * 0.9 in saveAndGenerate().
  final Map<String, double> auxTrainingMaxes;
  final Map<String, String> selectedAuxiliaries;
  final Map<String, String> liftNames;
  final bool    isValid;
  final bool    isSaving;
  final String? errorMessage;

  SetupState copyWith({
    ProgramFrequency?    selectedFrequency,
    Map<String, double>? trainingMaxes,
    Map<String, double>? auxTrainingMaxes,
    Map<String, String>? selectedAuxiliaries,
    Map<String, String>? liftNames,
    bool?                isValid,
    bool?                isSaving,
    String?              errorMessage,
    bool                 clearError = false,
  }) =>
      SetupState(
        selectedFrequency:   selectedFrequency   ?? this.selectedFrequency,
        trainingMaxes:       trainingMaxes       ?? this.trainingMaxes,
        auxTrainingMaxes:    auxTrainingMaxes    ?? this.auxTrainingMaxes,
        selectedAuxiliaries: selectedAuxiliaries ?? this.selectedAuxiliaries,
        liftNames:           liftNames           ?? this.liftNames,
        isValid:             isValid             ?? this.isValid,
        isSaving:            isSaving            ?? this.isSaving,
        errorMessage: clearError
            ? null
            : (errorMessage ?? this.errorMessage),
      );
}

// ── Notifier ───────────────────────────────────────────────────────────────────

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

  /// Update a single auxiliary lift TM. Pass 0 to clear (falls back to
  /// mainMax * 0.9 at save time).
  void updateAuxTrainingMax(String liftId, double value) {
    final updated = Map<String, double>.from(state.auxTrainingMaxes);
    if (value > 0) {
      updated[liftId] = value;
    } else {
      updated.remove(liftId);
    }
    state = state.copyWith(auxTrainingMaxes: updated);
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
      trainingMaxes:       {},
      auxTrainingMaxes:    {},
      selectedAuxiliaries: _defaultAux,
      liftNames:           liftDefaults,
    );
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
      final chosenAux    = state.selectedAuxiliaries;

      await programRepo.deactivateAll();

      final liftDbIds = <String, int>{};
      for (final liftId in _liftNameMap.keys) {
        final lift = await liftRepo.getLiftByName(liftId);
        if (lift != null) liftDbIds[liftId] = lift.id;
      }
      for (final key in _mainLiftKeys) {
        if (!liftDbIds.containsKey(key)) {
          throw Exception('Lift not found in DB: $key');
        }
      }

      for (final entry in state.liftNames.entries) {
        final slotKey = entry.key;
        final label   = entry.value;
        final dbId    = liftDbIds[slotKey];
        if (dbId == null) continue;
        await liftRepo.updateLift(LiftsCompanion(
          id:          Value(dbId),
          displayName: Value(label),
        ));
      }

      // ── Save main lift TMs ────────────────────────────────────────────
      for (final key in _mainLiftKeys) {
        final tm   = state.trainingMaxes[key]!;
        final dbId = liftDbIds[key]!;
        await tmRepo.saveMax(TrainingMaxesCompanion.insert(
          liftId:        dbId,
          value:         tm,
          effectiveDate: now,
        ));
      }

      // ── Build full TM map for program generation ───────────────────────
      // Auxiliary TMs: use user-entered value if present, else mainMax * 0.9
      // (Quick Setup default from the workbook).
      final fullTmMap = <String, double>{
        for (final key in _mainLiftKeys)
          key: state.trainingMaxes[key]!,
      };

      for (final mainKey in _mainLiftKeys) {
        final mainTm = state.trainingMaxes[mainKey]!;
        final auxKeys = auxSlotsByMain[mainKey] ?? [];
        for (final auxKey in auxKeys) {
          final userValue = state.auxTrainingMaxes[auxKey];
          fullTmMap[auxKey] = (userValue != null && userValue > 0)
              ? userValue
              : mainTm * 0.9;
        }
      }

      // Back/accessory slots: default to deadlift * 0.9 if not overridden.
      const backKeys = ['barbell_rows', 'dumbbell_rows', 'pulldowns'];
      final deadliftTm = state.trainingMaxes['deadlift']!;
      for (final k in backKeys) {
        fullTmMap[k] = deadliftTm * 0.9;
      }

      // ── Save auxiliary TMs to DB (actual user-entered or computed defaults) ──
      for (final auxKey in _allAuxKeys) {
        final dbId = liftDbIds[auxKey];
        if (dbId == null) continue;
        await tmRepo.saveMax(TrainingMaxesCompanion.insert(
          liftId:        dbId,
          value:         fullTmMap[auxKey]!,
          effectiveDate: now,
        ));
      }
      for (final k in backKeys) {
        final dbId = liftDbIds[k];
        if (dbId == null) continue;
        await tmRepo.saveMax(TrainingMaxesCompanion.insert(
          liftId:        dbId,
          value:         fullTmMap[k]!,
          effectiveDate: now,
        ));
      }

      // ── Create program + 21 weeks ─────────────────────────────────────
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
