import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/domain/models/enums.dart';
import 'package:trainingsplan_app/domain/models/training_max.dart';
import 'package:trainingsplan_app/domain/services/workout_generation_service.dart';

void main() {
  group('WorkoutGenerationService', () {
    final service = WorkoutGenerationService();

    test('repsForIntensity correctly maps standard intensity steps', () {
      expect(repsForIntensity(0.875), 3);
      expect(repsForIntensity(0.825), 5);
      expect(repsForIntensity(0.750), 8);
      expect(repsForIntensity(0.700), 10);
      expect(repsForIntensity(0.500), 20);
      expect(repsForIntensity(0.975), 1);
    });

    test('intensityForLift returns canonical workbook intensities', () {
      expect(intensityForLift('squat'), 0.875);
      expect(intensityForLift('bench_press'), 0.875);
      expect(intensityForLift('deadlift'), 0.875);
      expect(intensityForLift('overhead_press'), 0.875);
      expect(intensityForLift('front_squat'), 0.825);
      expect(intensityForLift('close_grip_bench'), 0.825);
      expect(intensityForLift('barbell_rows'), 0.750);
    });

    test('generateSinglePrescription calculates workingWeight and reps correctly', () {
      final tm = TrainingMax(
        id: 'tm_squat',
        liftId: 'squat',
        value: 140.0,
        singleEightPercentage: 0.9,
        sourceType: MaxSourceType.manual,
        effectiveDate: DateTime(2026, 1, 1),
      );

      final presc = service.generateSinglePrescription(
        workoutDayId: 'day_1',
        liftId: 'squat',
        displayOrder: 1,
        isPrimaryBlock: true,
        weekNumber: 1,
        trainingMax: tm,
        intensity: 0.875,
        roundingIncrement: 2.5,
        roundingMode: RoundingMode.nearest,
      );

      // 140 * 0.875 = 122.5
      expect(presc.workingWeight, 122.5);
      expect(presc.repsPerNormalSet, 3);
      expect(presc.repOutTarget, 3);
      expect(presc.setGoal, 3);
      expect(presc.isPrimaryBlock, isTrue);
    });
  });
}
