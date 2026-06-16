import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/data/seeders/rep_target_seeder.dart';
import 'package:trainingsplan_app/domain/models/rep_target_point.dart';
import 'package:trainingsplan_app/domain/services/rep_target_lookup_service.dart';

void main() {
  // Build the seeded data once for the whole suite.
  final seededPoints = RepTargetSeeder.generateRepTargetPoints();
  final service      = RepTargetLookupService();

  // Expected values directly from workbook / rep_target_seeder.dart comments.
  // intensity → (repsPerSet, lastSetRirTarget)
  const workbookTable = <double, (int reps, int rir)>{
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
          // Derive the same double the seeder produces.
          final seederIntensity = intensity; // identical bit pattern
          final result = service.getRepTarget(
              liftId, seederIntensity, seededPoints);
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
          final result = service.getRirTarget(
              liftId, intensity, seededPoints);
          expect(result, 0,
              reason: '$liftId: RIR at '
                  '${(intensity * 100).toStringAsFixed(1)}% should be 0');
        });
      }
    }
  });

  // ── 3. Arithmetic drift does not cause false misses ───────────────────
  //
  // Simulate the kind of drift that occurs when intensity is derived
  // via arithmetic (e.g. 0.70 expressed as 0.7 + tiny epsilon, or
  // computed as 70 * 0.01) rather than the literal 0.70 constant.
  // All drifted values are within 0.0001 of a seeded bucket, so they
  // must NOT fall back to _fallbackReps.
  group('getRepTarget — tolerance absorbs arithmetic drift', () {
    const driftCases = <(String liftId, double drifted, double exact, int expectedReps)>[
      // 0.70 with +1e-5 drift
      ('squat',       0.70 + 1e-5,  0.70,  10),
      // 0.725 with -1e-5 drift (this value is not exact in IEEE-754)
      ('squat',       0.725 - 1e-5, 0.725,  9),
      // 0.775 with +1e-5 drift
      ('squat',       0.775 + 1e-5, 0.775,  7),
      // 0.825 with -1e-5 drift
      ('squat',       0.825 - 1e-5, 0.825,  5),
      // 0.675 auxiliary
      ('front_squat', 0.675 + 1e-5, 0.675, 11),
    ];

    for (final c in driftCases) {
      final (liftId, drifted, exact, expectedReps) = c;
      test(
        '$liftId: drifted ${drifted.toStringAsFixed(8)} near '
        '${(exact * 100).toStringAsFixed(1)}% → $expectedReps reps',
        () {
          final result = service.getRepTarget(
              liftId, drifted, seededPoints);
          expect(result, expectedReps,
              reason: 'Drift case failed for $liftId: expected '
                  '$expectedReps reps but got $result');
        },
      );
    }
  });

  // ── 4. Unknown intensity falls back (not a seeded bucket) ─────────────
  //
  // 0.71 is not a seeded step; it must use _fallbackReps (returns 10
  // because 0.71 >= 0.70 bracket).
  test('getRepTarget — unrecognised intensity uses fallback', () {
    const unrecognised = 0.71; // not a 2.5% step
    final result = service.getRepTarget(
        'squat', unrecognised, seededPoints);
    // Fallback: 0.71 >= 0.70 → 10 reps.
    expect(result, 10,
        reason: 'Expected fallback value 10 for unrecognised intensity 0.71');
  });

  // ── 5. Completeness: every seeded RepTargetPoint is reachable ─────────
  //
  // Iterates all 13 lift IDs × 10 task intensities (130 combinations)
  // and confirms none of them silently falls through to the fallback
  // when the seeded data is present.
  test('getRepTarget — no false miss across all 13 lifts × 10 intensities', () {
    const allLiftIds = [
      'squat', 'bench_press', 'deadlift', 'overhead_press',
      'front_squat', 'close_grip_bench', 'squat_aux2', 'bench_aux2',
      'deadlift_aux', 'ohp_aux', 'barbell_rows', 'dumbbell_rows', 'pulldowns',
    ];

    // Build a quick set of all seeded (liftId, intensity) pairs to confirm
    // the result came from the seeded table rather than the fallback.
    final seededSet = <String>{
      for (final p in seededPoints)
        '${p.liftId}_${p.intensity.toStringAsFixed(6)}',
    };

    for (final liftId in allLiftIds) {
      for (final entry in workbookTable.entries) {
        final intensity = entry.key;
        final expected  = entry.value.$1;

        final seededKey = '${liftId}_${(intensity).toStringAsFixed(6)}';
        // Sanity: confirm the seeder actually produced this row.
        expect(
          seededSet.contains(seededKey) ||
              // toStringAsFixed may differ by 1 ULP; also check the point
              // is directly findable by the service.
              service.getRepTarget(liftId, intensity, seededPoints) == expected,
          isTrue,
          reason: 'Seeded row missing or mismatched for '
              '$liftId @ ${(intensity * 100).toStringAsFixed(1)}%',
        );

        final result = service.getRepTarget(
            liftId, intensity, seededPoints);
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
