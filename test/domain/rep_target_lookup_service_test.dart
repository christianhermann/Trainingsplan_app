import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/data/seeders/rep_target_seeder.dart';
import 'package:trainingsplan_app/domain/services/rep_target_lookup_service.dart';

void main() {
  // Build the seeded data once for the whole suite.
  final seededPoints = RepTargetSeeder.generateRepTargetPoints();
  final service      = RepTargetLookupService();

  // Expected values directly from workbook / rep_target_seeder.dart comments.
  // intensity → (repsPerSet, lastSetRirTarget)
  // Must be `final`, not `const` — double is not a valid const map key in Dart.
  final workbookTable = <double, (int reps, int rir)>{
    0.55:  (16, 0),
    0.60:  (14, 0),
    0.65:  (12, 0),
    0.675: (11, 0),
    0.70:  (10, 0),
    0.725: ( 9, 0),
    0.75:  ( 8, 0),
    0.775: ( 7, 0),
    0.80:  ( 6, 0),
    0.825: ( 5, 0),
  };

  // Representative lift IDs: one main, one auxiliary.
  const testLiftIds = ['squat', 'front_squat'];

  // ── 1. Exact seeder values resolve correctly ──────────────────────────────
  //
  // The seeder produces intensity = pct / 100.0.  We feed those exact
  // same doubles back in; every lookup must find a match (no fallback).
  group('getRepTarget — exact seeder intensity', () {
    for (final liftId in testLiftIds) {
      for (final entry in workbookTable.entries) {
        final intensity    = entry.key;
        final expectedReps = entry.value.$1;

        test('$liftId @ ${(intensity * 100).toStringAsFixed(1)}% → $expectedReps reps', () {
          final result = service.getRepTarget(liftId, intensity, seededPoints);
          expect(result, expectedReps,
              reason: '$liftId: expected $expectedReps reps at '
                  '${(intensity * 100).toStringAsFixed(1)}% '
                  'but got $result');
        });
      }
    }
  });

  // ── 2. getRirTarget is 0 for every workbook intensity ───────────────────
  group('getRirTarget — always 0 for seeded intensities', () {
    for (final liftId in testLiftIds) {
      for (final intensity in workbookTable.keys) {
        test('$liftId @ ${(intensity * 100).toStringAsFixed(1)}% RIR = 0', () {
          final result = service.getRirTarget(liftId, intensity, seededPoints);
          expect(result, 0,
              reason: '$liftId: RIR at '
                  '${(intensity * 100).toStringAsFixed(1)}% should be 0');
        });
      }
    }
  });

  // ── 3. Arithmetic drift does not cause false misses ───────────────────────
  //
  // All drifted values are within 0.0001 of a seeded bucket, so they
  // must NOT fall back to _fallbackReps.
  group('getRepTarget — tolerance absorbs arithmetic drift', () {
    // `final` list of records — records with double fields can't be const either.
    final driftCases = <(String liftId, double drifted, int expectedReps)>[
      ('squat',       0.70 + 1e-5,  10),
      ('squat',       0.725 - 1e-5,  9),
      ('squat',       0.775 + 1e-5,  7),
      ('squat',       0.825 - 1e-5,  5),
      ('front_squat', 0.675 + 1e-5, 11),
    ];

    for (final c in driftCases) {
      final (liftId, drifted, expectedReps) = c;
      test(
        '$liftId: drifted ${drifted.toStringAsFixed(8)} → $expectedReps reps',
        () {
          final result = service.getRepTarget(liftId, drifted, seededPoints);
          expect(result, expectedReps,
              reason: 'Drift case failed for $liftId: expected '
                  '$expectedReps reps but got $result');
        },
      );
    }
  });

  // ── 4. Unknown intensity falls back (not a seeded bucket) ─────────────────
  //
  // 0.71 is not a seeded 2.5% step; fallback bracket 0.71 >= 0.70 → 10 reps.
  test('getRepTarget — unrecognised intensity uses fallback', () {
    final result = service.getRepTarget('squat', 0.71, seededPoints);
    expect(result, 10,
        reason: 'Expected fallback value 10 for unrecognised intensity 0.71');
  });

  // ── 5. Completeness: all 13 lifts × 10 task intensities (130 combos) ──────
  test('getRepTarget — no false miss across all 13 lifts × 10 intensities', () {
    const allLiftIds = [
      'squat', 'bench_press', 'deadlift', 'overhead_press',
      'front_squat', 'close_grip_bench', 'squat_aux2', 'bench_aux2',
      'deadlift_aux', 'ohp_aux', 'barbell_rows', 'dumbbell_rows', 'pulldowns',
    ];

    for (final liftId in allLiftIds) {
      for (final entry in workbookTable.entries) {
        final intensity = entry.key;
        final expected  = entry.value.$1;

        final result = service.getRepTarget(liftId, intensity, seededPoints);
        expect(
          result, expected,
          reason: 'False miss for $liftId @ '
              '${(intensity * 100).toStringAsFixed(1)}%: '
              'expected $expected got $result',
        );
      }
    }
  });
}
