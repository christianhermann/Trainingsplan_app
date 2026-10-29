import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Volume & Density Calculations', () {
    test('computes total session tonnage accurately with normal sets + rep-out set', () {
      // Exercise 1: 100 kg, 3 sets goal, 8 reps normal. Completed 3 sets, 12 reps on last set.
      // (3 - 1) * 8 = 16 reps on sets 1 & 2. Set 3 = 12 reps. Total reps = 28.
      // 28 * 100 kg = 2800 kg.
      const workingWeight1 = 100.0;
      const completedSets1 = 3;
      const repsNormal1 = 8;
      const repsLast1 = 12;

      final totalReps1 = ((completedSets1 - 1) * repsNormal1) + repsLast1;
      final volume1 = totalReps1 * workingWeight1;
      expect(volume1, 2800.0);

      // Exercise 2: 70 kg, 3 sets goal, 10 reps normal. Completed 2 sets, 8 reps on last set.
      // (2 - 1) * 10 = 10 reps. Set 2 = 8 reps. Total reps = 18.
      // 18 * 70 kg = 1260 kg.
      const workingWeight2 = 70.0;
      const completedSets2 = 2;
      const repsNormal2 = 10;
      const repsLast2 = 8;

      final totalReps2 = ((completedSets2 - 1) * repsNormal2) + repsLast2;
      final volume2 = totalReps2 * workingWeight2;
      expect(volume2, 1260.0);

      final totalSessionTonnage = volume1 + volume2;
      expect(totalSessionTonnage, 4060.0);

      // Density tracking: 4060 kg over 40 minutes = 101.5 kg/min
      const durationMin = 40;
      final density = totalSessionTonnage / durationMin;
      expect(density, 101.5);
    });

    test('Epley Estimated 1RM calculates accurately', () {
      // E1RM = weight * (1 + reps / 30)
      // 100 kg for 10 reps -> 100 * (1 + 10/30) = 133.33 kg
      const weight = 100.0;
      const reps = 10;
      final e1rm = weight * (1.0 + reps / 30.0);
      expect(double.parse(e1rm.toStringAsFixed(1)), 133.3);

      // 140 kg for 5 reps -> 140 * (1 + 5/30) = 163.33 kg
      const weight2 = 140.0;
      const reps2 = 5;
      final e1rm2 = weight2 * (1.0 + reps2 / 30.0);
      expect(double.parse(e1rm2.toStringAsFixed(1)), 163.3);
    });

    test('Plan vs. Actual AMRAP Delta computes correctly', () {
      // Target was 12, user did 15 -> +3
      const target1 = 12;
      const done1 = 15;
      expect(done1 - target1, 3);

      // Target was 10, user did 8 -> -2
      const target2 = 10;
      const done2 = 8;
      expect(done2 - target2, -2);
    });
  });
}
