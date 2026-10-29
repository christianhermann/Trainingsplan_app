import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/features/workout/plate_calculator_widget.dart';

void main() {
  group('PlateBreakdown.calculate', () {
    test('targetWeight equal or below barWeight returns 0 plates', () {
      final breakdown = PlateBreakdown.calculate(targetWeight: 20.0, barWeight: 20.0);
      expect(breakdown.weightPerSide, 0.0);
      expect(breakdown.platesPerSide.isEmpty, isTrue);
      expect(breakdown.actualLoadedWeight, 20.0);
      expect(breakdown.remainder, 0.0);
    });

    test('targetWeight 100kg with 20kg bar allocates 40kg per side accurately', () {
      final breakdown = PlateBreakdown.calculate(targetWeight: 100.0, barWeight: 20.0);
      expect(breakdown.weightPerSide, 40.0);
      expect(breakdown.actualLoadedWeight, 100.0);
      expect(breakdown.remainder, 0.0);

      // Verify sum of plates per side equals 40kg
      double sumPerSide = 0;
      breakdown.platesPerSide.forEach((plate, count) {
        sumPerSide += plate.weight * count;
      });
      expect(sumPerSide, 40.0);
    });

    test('targetWeight 62.5kg with 20kg bar allocates 21.25kg per side accurately', () {
      final breakdown = PlateBreakdown.calculate(targetWeight: 62.5, barWeight: 20.0);
      expect(breakdown.weightPerSide, 21.25);
      expect(breakdown.actualLoadedWeight, 62.5);
      expect(breakdown.remainder, 0.0);

      double sumPerSide = 0;
      breakdown.platesPerSide.forEach((plate, count) {
        sumPerSide += plate.weight * count;
      });
      expect(sumPerSide, 21.25);
    });

    test('handles 15kg bar option correctly', () {
      final breakdown = PlateBreakdown.calculate(targetWeight: 55.0, barWeight: 15.0);
      expect(breakdown.weightPerSide, 20.0);
      expect(breakdown.actualLoadedWeight, 55.0);
      expect(breakdown.remainder, 0.0);
    });
  });

  group('Warmup Ramp calculations', () {
    test('calculateRamp produces standard ramp percentages rounded to 2.5kg', () {
      final ramp = calculateRamp(targetWeight: 100.0, barWeight: 20.0);
      expect(ramp.length, 4);

      // Set 1: Empty Bar
      expect(ramp[0].weight, 20.0);
      expect(ramp[0].reps, 10);

      // Set 2: 50%
      expect(ramp[1].weight, 50.0);
      expect(ramp[1].reps, 5);

      // Set 3: 70%
      expect(ramp[2].weight, 70.0);
      expect(ramp[2].reps, 3);

      // Set 4: 85%
      expect(ramp[3].weight, 85.0);
      expect(ramp[3].reps, 1);
    });

    test('calculateRamp with low target clamps minimum to barWeight', () {
      final ramp = calculateRamp(targetWeight: 30.0, barWeight: 20.0);
      for (final step in ramp) {
        expect(step.weight, greaterThanOrEqualTo(20.0));
      }
    });
  });
}
