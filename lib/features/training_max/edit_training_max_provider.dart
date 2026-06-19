import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/catalogue/lift_catalogue.dart';
import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/workout_generator_service.dart';
import '../setup/setup_provider.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class EditTmState {
  const EditTmState({
    this.trainingMaxes = const {},
    this.isSaving      = false,
    this.isDone        = false,
    this.errorMessage,
  });

  /// slotKey (e.g. 'squat') → current TM value in kg.
  final Map<String, double> trainingMaxes;
  final bool    isSaving;
  final bool    isDone;
  final String? errorMessage;

  bool get isValid =>
      _mainLiftKeys.every((k) => (trainingMaxes[k] ?? 0) > 0);

  EditTmState copyWith({
    Map<String, double>? trainingMaxes,
    bool?    isSaving,
    bool?    isDone,
    String?  errorMessage,
    bool     clearError = false,
  }) =>
      EditTmState(
        trainingMaxes: trainingMaxes ?? this.trainingMaxes,
        isSaving:      isSaving      ?? this.isSaving,
        isDone:        isDone        ?? this.isDone,
        errorMessage: clearError
            ? null
            : (errorMessage ?? this.errorMessage),
      );
}

const _mainLiftKeys = [
  'squat',
  'bench_press',
  'deadlift',
  'overhead_press',
];

// ── Notifier ──────────────────────────────────────────────────────────────────

class EditTmNotifier extends AsyncNotifier<EditTmState> {
  @override
  Future<EditTmState> build() async {
    final liftRepo = ref.read(liftRepositoryProvider);
    final tmRepo   = ref.read(trainingMaxRepositoryProvider);

    final maxes = <String, double>{};
    for (final key in _mainLiftKeys) {
      final lift = await liftRepo.getLiftByName(key);
      if (lift == null) continue;
      final tm = await tmRepo.getMaxForLift(lift.id);
      if (tm != null) maxes[key] = tm.value;
    }
    return EditTmState(trainingMaxes: maxes);
  }

  void updateMax(String liftKey, double value) {
    if (!state.hasValue) return;
    final current = state.value!;
    final updated = Map<String, double>.from(current.trainingMaxes);
    if (value > 0) {
      updated[liftKey] = value;
    } else {
      updated.remove(liftKey);
    }
    state = AsyncData(current.copyWith(trainingMaxes: updated));
  }

  Future<void> save() async {
    if (!state.hasValue || !state.value!.isValid) return;
    final current = state.value!;
    state = AsyncData(current.copyWith(isSaving: true, clearError: true));

    try {
      final liftRepo    = ref.read(liftRepositoryProvider);
      final tmRepo      = ref.read(trainingMaxRepositoryProvider);
      final programRepo = ref.read(programRepositoryProvider);
      final genSvc      = ref.read(workoutGeneratorServiceProvider);
      final now         = DateTime.now();

      final program = await programRepo.getActiveProgram();
      if (program == null) throw Exception('No active program found.');

      final frequency = ProgramFrequency.fromString(program.frequency);
      final fromWeek  = program.currentWeek;

      // 1. Persist new TM rows for the 4 main lifts.
      final liftDbIds = <String, int>{};
      for (final key in _mainLiftKeys) {
        final lift = await liftRepo.getLiftByName(key);
        if (lift == null) continue;
        liftDbIds[key] = lift.id;
        await tmRepo.saveMax(TrainingMaxesCompanion.insert(
          liftId:        lift.id,
          value:         current.trainingMaxes[key]!,
          effectiveDate: now,
          notes: const Value('mid-cycle edit'),
        ));
      }

      // 2. Resolve remaining lift IDs (auxiliaries).
      for (final key in liftDefaults.keys) {
        if (liftDbIds.containsKey(key)) continue;
        final lift = await liftRepo.getLiftByName(key);
        if (lift != null) liftDbIds[key] = lift.id;
      }

      // 3. Build full TM map — aux lifts inherit from their parent main lift.
      final fullTmMap = <String, double>{
        for (final key in _mainLiftKeys)
          key: current.trainingMaxes[key]!,
      };
      for (final entry in auxOptions.entries) {
        final mainKey = entry.key;
        for (final aux in entry.value) {
          fullTmMap[aux.key] = current.trainingMaxes[mainKey]!;
        }
      }
      const backKeys = ['barbell_rows', 'dumbbell_rows', 'pulldowns'];
      for (final k in backKeys) {
        fullTmMap[k] = current.trainingMaxes['deadlift']!;
      }

      // 4. Regenerate future workouts.
      await genSvc.regenerateFromWeek(
        programId:     program.id,
        fromWeek:      fromWeek,
        frequency:     frequency,
        trainingMaxes: fullTmMap,
        liftDbIds:     liftDbIds,
      );

      state = AsyncData(current.copyWith(isSaving: false, isDone: true));
    } catch (e) {
      final s = state.hasValue ? state.value! : const EditTmState();
      state = AsyncData(
          s.copyWith(isSaving: false, errorMessage: 'Failed to update: $e'));
    }
  }
}

final editTmProvider =
    AsyncNotifierProvider<EditTmNotifier, EditTmState>(EditTmNotifier.new);
