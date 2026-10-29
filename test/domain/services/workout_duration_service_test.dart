import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/data/persistence/database.dart';
import 'package:trainingsplan_app/domain/services/workout_duration_service.dart';

void main() {
  const service = WorkoutDurationService();

  group('WorkoutDurationService Tests', () {
    test('returns 0 for empty prescriptions', () {
      final duration = service.estimateDurationMinutes(prescriptions: []);
      expect(duration, 0);
    });

    test('calculates duration correctly using formula: General Warmup (10m) + Exercise Warmup + Sets*Reps + Rest', () {
      const squatLift = Lift(
        id: 1,
        name: 'squat',
        displayName: 'Squat',
        category: 'squat',
        isMainLift: true,
        isAuxiliaryLift: false,
        defaultOrder: 1,
        usesTrainingMax: true,
      );

      // Squat: 4 sets of 5 reps
      // General Warmup = 10 min = 600s
      // Squat Warmup = 5 min = 300s
      // Reps time = 4 sets * 5 reps * 4.5s = 90s
      // Rest time = 3 rests * 180s = 540s
      // Total = 600 + 300 + 90 + 540 = 1530s = 25.5 min -> 26 min
      const prescription = ExercisePrescription(
        id: 1,
        workoutDayId: 1,
        liftId: 1,
        trainingMaxSnapshot: 100,
        intensity: 0.8,
        workingWeight: 80,
        repsPerNormalSet: 5,
        repOutTarget: 5,
        setGoal: 4,
        displayOrder: 0,
        isPrimaryBlock: true,
      );

      final duration = service.estimateDurationMinutes(
        prescriptions: [prescription],
        lifts: {1: squatLift},
        defaultRestSeconds: 180,
      );

      expect(duration, 26);
    });

    test('adds transition time and accounts for accessory exercises', () {
      const squatLift = Lift(
        id: 1,
        name: 'squat',
        displayName: 'Squat',
        category: 'squat',
        isMainLift: true,
        isAuxiliaryLift: false,
        defaultOrder: 1,
        usesTrainingMax: true,
      );

      const rowsLift = Lift(
        id: 2,
        name: 'barbell_rows',
        displayName: 'Barbell Rows',
        category: 'back',
        isMainLift: false,
        isAuxiliaryLift: false,
        defaultOrder: 2,
        usesTrainingMax: false,
      );

      const p1 = ExercisePrescription(
        id: 1,
        workoutDayId: 1,
        liftId: 1,
        trainingMaxSnapshot: 100,
        intensity: 0.8,
        workingWeight: 80,
        repsPerNormalSet: 5,
        repOutTarget: 5,
        setGoal: 4,
        displayOrder: 0,
        isPrimaryBlock: true,
      );

      // Rows: 3 sets of 8 reps
      // Rows Warmup = 2.5 min = 150s
      // Reps time = 3 * 8 * 3.5s = 84s
      // Rest time = 2 rests * 135s = 270s
      // Transition between Squat and Rows = 120s
      // Total = 1530s (Squat) + 120s (Transition) + 150s + 84s + 270s = 2154s = 35.9 min -> 36 min
      const p2 = ExercisePrescription(
        id: 2,
        workoutDayId: 1,
        liftId: 2,
        trainingMaxSnapshot: 60,
        intensity: 0.7,
        workingWeight: 42.5,
        repsPerNormalSet: 8,
        repOutTarget: 8,
        setGoal: 3,
        displayOrder: 1,
        isPrimaryBlock: false,
      );

      final duration = service.estimateDurationMinutes(
        prescriptions: [p1, p2],
        lifts: {1: squatLift, 2: rowsLift},
        defaultRestSeconds: 180,
      );

      expect(duration, 36);
    });
  });
}
