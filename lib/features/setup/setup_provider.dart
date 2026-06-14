import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/intensity_lookup_service.dart';
import '../../domain/services/rep_target_lookup_service.dart';

// Maps UI lift keys -> DB seeded lift names
const _liftNameMap = {
  'squat': 'squat',
  'bench_press': 'bankdruecken',
  'deadlift': 'deadlift',
  'overhead_press': 'schulterdruecken',
};

const _mainLiftKeys = ['squat', 'bench_press', 'deadlift', 'overhead_press'];

const _frequencyDays = {
  ProgramFrequency.two: 2,
  ProgramFrequency.three: 3,
  ProgramFrequency.four: 4,
  ProgramFrequency.five: 5,
  ProgramFrequency.six: 6,
};

// ── State ─────────────────────────────────────────────────────────────────

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
  }) =>
      SetupState(
        selectedFrequency: selectedFrequency ?? this.selectedFrequency,
        trainingMaxes: trainingMaxes ?? this.trainingMaxes,
        isValid: isValid ?? this.isValid,
        isSaving: isSaving ?? this.isSaving,
        errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      );
}

// ── Notifier ────────────────────────────────────────────────────────────────

class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier(this._ref) : super(const SetupState());
  final Ref _ref;

  void selectFrequency(ProgramFrequency frequency) {
    state = state.copyWith(selectedFrequency: frequency, clearError: true);
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
      final liftRepo = _ref.read(liftRepositoryProvider);
      final tmRepo = _ref.read(trainingMaxRepositoryProvider);
      final programRepo = _ref.read(programRepositoryProvider);
      final workoutRepo = _ref.read(workoutRepositoryProvider);
      final intensitySvc = DefaultIntensityLookupService();
      final repSvc = DefaultRepTargetLookupService();
      final now = DateTime.now();

      // 1. Deactivate old programs
      await programRepo.deactivateAll();

      // 2. Resolve lift keys to DB IDs
      final liftIdMap = <String, int>{};
      for (final entry in _liftNameMap.entries) {
        final lift = await liftRepo.getLiftByName(entry.value);
        if (lift == null) throw Exception('Lift not found: ${entry.value}');
        liftIdMap[entry.key] = lift.id;
      }

      // 3. Persist training maxes
      for (final entry in state.trainingMaxes.entries) {
        final dbId = liftIdMap[entry.key];
        if (dbId == null) continue;
        await tmRepo.saveMax(TrainingMaxesCompanion(
          liftId: Value(dbId),
          value: Value(entry.value),
          effectiveDate: Value(now),
        ));
      }

      // 4. Create program
      final frequency = state.selectedFrequency!;
      final programId = await programRepo.saveProgram(ProgramsCompanion(
        name: const Value('My Program'),
        frequency: Value(frequency.name),
        currentWeek: const Value(1),
        totalWeeks: const Value(21),
        isActive: const Value(true),
        createdAt: Value(now),
        updatedAt: Value(now),
      ));

      // 5. Generate 21 weeks
      final daysPerWeek = _frequencyDays[frequency] ?? 3;

      for (int week = 1; week <= 21; week++) {
        final weekId = await programRepo.saveWeek(WorkoutWeeksCompanion(
          programId: Value(programId),
          weekNumber: Value(week),
          displayLabel: Value('Week $week'),
        ));

        final intensity = intensitySvc.getIntensityForWeek(week);
        final repsNormal = repSvc.getNormalSetReps(week);
        final repsLast = repSvc.getLastSetReps(week);

        for (int day = 0; day < daysPerWeek; day++) {
          final dayId = await programRepo.saveDay(WorkoutDaysCompanion(
            workoutWeekId: Value(weekId),
            dayIndex: Value(day),
            title: Value('Day ${day + 1}'),
            status: const Value('planned'),
          ));

          // Assign main lift round-robin across days
          final liftKey = _mainLiftKeys[day % _mainLiftKeys.length];
          final dbLiftId = liftIdMap[liftKey]!;
          final tm = state.trainingMaxes[liftKey]!;
          // Round to nearest 2.5 kg
          final workingWeight =
              ((tm * intensity / 2.5).round() * 2.5);

          await workoutRepo.savePrescription(ExercisePrescriptionsCompanion(
            workoutDayId: Value(dayId),
            liftId: Value(dbLiftId),
            trainingMaxSnapshot: Value(tm),
            intensity: Value(intensity),
            workingWeight: Value(workingWeight),
            repsPerNormalSet: Value(repsNormal),
            repOutTarget: Value(repsLast),
            setGoal: const Value(4),
            displayOrder: const Value(0),
            isPrimaryBlock: const Value(true),
          ));
        }
      }

      state = state.copyWith(isSaving: false);
    } catch (e, st) {
      state = state.copyWith(
        isSaving: false,
        errorMessage: 'Failed to save: $e',
      );
    }
  }
}

final setupProvider =
    StateNotifierProvider<SetupNotifier, SetupState>(
        (ref) => SetupNotifier(ref));
