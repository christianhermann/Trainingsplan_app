import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';

/// Estimates workout duration based on exercise types, rep counts, and rest periods.
/// Formula: General Warmup (10m) + Exercise Warmup + Exercise Execution (Sets * Reps * Sec/Rep) + Rest Times
class WorkoutDurationService {
  const WorkoutDurationService();

  static const int generalWarmupMinutes = 10;

  /// Estimates workout duration in minutes for a given list of prescriptions.
  int estimateDurationMinutes({
    required List<ExercisePrescription> prescriptions,
    Map<int, Lift> lifts = const {},
    int defaultRestSeconds = 180,
  }) {
    if (prescriptions.isEmpty) return 0;

    double totalSeconds = generalWarmupMinutes * 60.0;

    for (int i = 0; i < prescriptions.length; i++) {
      final p = prescriptions[i];
      final lift = lifts[p.liftId];
      final slotKey = lift?.name.toLowerCase() ?? '';

      // 1. Exercise-specific warmup duration (seconds)
      final warmupSecs = _exerciseWarmupSeconds(slotKey, p.isPrimaryBlock);

      // 2. Exercise execution duration (seconds) = sets * reps * seconds_per_rep
      final secPerRep = _secondsPerRep(slotKey);
      final totalReps = p.setGoal * p.repsPerNormalSet;
      final executionSecs = totalReps * secPerRep;

      // 3. Rest time between sets
      final restPerSet = _restTimeSeconds(slotKey, p.isPrimaryBlock, defaultRestSeconds);
      final restSecs = (p.setGoal > 1 ? (p.setGoal - 1) : 0) * restPerSet;

      // 4. Equipment transition between distinct exercises
      final transitionSecs = (i < prescriptions.length - 1) ? 120.0 : 0.0;

      totalSeconds += warmupSecs + executionSecs + restSecs + transitionSecs;
    }

    return (totalSeconds / 60.0).round();
  }

  /// Estimated warmup time for an exercise based on compound status.
  double _exerciseWarmupSeconds(String slotKey, bool isPrimary) {
    if ((slotKey.contains('squat') && !slotKey.contains('aux')) ||
        (slotKey.contains('deadlift') && !slotKey.contains('aux'))) {
      return 300.0; // 5 min for heavy lower body compounds
    }
    if (slotKey.contains('bench') ||
        slotKey.contains('overhead') ||
        slotKey.contains('ohp')) {
      return 240.0; // 4 min for upper body compounds
    }
    if (isPrimary || slotKey.contains('aux') || slotKey.contains('row')) {
      return 150.0; // 2.5 min for secondary compounds / auxiliaries
    }
    return 60.0; // 1 min for isolation / accessories
  }

  /// Estimated time per rep based on range of motion and pacing of the movement.
  double _secondsPerRep(String slotKey) {
    if (slotKey.contains('squat') || slotKey.contains('deadlift')) {
      return 4.5; // Big compound movements: brace, slow eccentric, drive
    }
    if (slotKey.contains('bench') ||
        slotKey.contains('overhead') ||
        slotKey.contains('ohp') ||
        slotKey.contains('row') ||
        slotKey.contains('press')) {
      return 3.5;
    }
    return 2.5; // Quick isolation or machine reps
  }

  /// Rest time per set based on intensity and movement complexity.
  double _restTimeSeconds(String slotKey, bool isPrimary, int defaultRestSeconds) {
    if (isPrimary ||
        slotKey == 'squat' ||
        slotKey == 'deadlift' ||
        slotKey == 'bench_press' ||
        slotKey == 'overhead_press') {
      return defaultRestSeconds.toDouble();
    }
    if (slotKey.contains('aux') || slotKey.contains('row')) {
      return (defaultRestSeconds * 0.75).clamp(90.0, 150.0);
    }
    return 90.0; // 1.5 min for accessories
  }
}

final workoutDurationServiceProvider = Provider<WorkoutDurationService>((ref) {
  return const WorkoutDurationService();
});
