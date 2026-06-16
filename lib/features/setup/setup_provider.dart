import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/intensity_lookup_service.dart';
import '../../domain/services/rep_target_lookup_service.dart';

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
      final liftRepo = ref.read(liftRepositoryProvider);
      final tmRepo = ref.read(trainingMaxRepositoryProvider);
      final programRepo = ref.read(programRepositoryProvider);
      final workoutRepo = ref.read(workoutRepositoryProvider);
      final intensitySvc = IntensityLookupService();
      final repSvc = RepTargetLookupService();
      final now = DateTime.now();

      await programRepo.deactivateAll();

      final liftIdMap = <String, int>{};
      for (final entry in _liftNameMap.entries) {
        final lift = await liftRepo.getLiftByName(entry.value);
        if (lift == null) throw Exception('Lift not found: ${entry.value}');
        liftIdMap[entry.key] = lift.id;
      }

      for (final entry in state.trainingMaxes.entries) {
        final dbId = liftIdMap[entry.key];
        if (dbId == null) continue;
        await tmRepo.saveMax(TrainingMaxesCompanion.insert(
          liftId: dbId,
          value: entry.value,
          effectiveDate: now,
        ));
      }

      final frequency = state.selectedFrequency!;
      final programId = await programRepo.saveProgram(
        ProgramsCompanion.insert(
          name: 'My Program',
          frequency: frequency.name,
          createdAt: now,
          updatedAt: now,
        ),
      );

      final daysPerWeek = _frequencyDays[frequency] ?? 3;

      for (int week = 1; week <= 21; week++) {
        final weekId = await programRepo.saveWeek(
          WorkoutWeeksCompanion.insert(
            programId: programId,
            weekNumber: week,
          ),
        );
        final intensity = intensitySvc.getIntensityForWeek(week);
        final repsNormal = repSvc.getNormalSetReps(week);
        final repsLast = repSvc.getLastSetReps(week);

        for (int day = 0; day < daysPerWeek; day++) {
          final dayId = await programRepo.saveDay(
            WorkoutDaysCompanion.insert(
              workoutWeekId: weekId,
              dayIndex: day,
            ),
          );
          final liftKey = _mainLiftKeys[day % _mainLiftKeys.length];
          final dbLiftId = liftIdMap[liftKey]!;
          final tm = state.trainingMaxes[liftKey]!;
          final workingWeight = ((tm * intensity / 2.5).round() * 2.5);

          await workoutRepo.savePrescription(
            ExercisePrescriptionsCompanion.insert(
              workoutDayId: dayId,
              liftId: dbLiftId,
              trainingMaxSnapshot: tm,
              intensity: intensity,
              workingWeight: workingWeight,
              repsPerNormalSet: repsNormal,
              repOutTarget: repsLast,
              setGoal: 4,
            ),
          );
        }
      }
      state = state.copyWith(isSaving: false);
    } catch (e) {
      state = state.copyWith(
          isSaving: false, errorMessage: 'Failed to save: $e');
    }
  }
}

final setupProvider =
    NotifierProvider<SetupNotifier, SetupState>(SetupNotifier.new);
