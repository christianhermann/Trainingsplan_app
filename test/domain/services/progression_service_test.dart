import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/domain/models/enums.dart';
import 'package:trainingsplan_app/domain/models/exercise_log.dart';
import 'package:trainingsplan_app/domain/models/exercise_prescription.dart';
import 'package:trainingsplan_app/domain/models/progress_adjustment.dart';
import 'package:trainingsplan_app/domain/services/progression_service.dart';

// ---------------------------------------------------------------------------
// Test helpers
// ---------------------------------------------------------------------------

ExerciseLog _log(int repsOnLastSet) => ExerciseLog(
      id: 'log_1',
      prescriptionId: 'presc_1',
      completedSets: 4,
      repsOnLastSet: repsOnLastSet,
      completedAt: DateTime(2026, 1, 1),
    );

ExercisePrescription _prescription({
  String liftId = 'squat',
  int repOutTarget = 3,
}) =>
    ExercisePrescription(
      id: 'presc_1',
      workoutDayId: 'day_1',
      liftId: liftId,
      trainingMaxSnapshot: 100.0,
      intensity: 0.875,
      workingWeight: 87.5,
      repsPerNormalSet: 3,
      repOutTarget: repOutTarget,
      setGoal: 4,
      displayOrder: 1,
      isPrimaryBlock: true,
    );

List<ProgressAdjustment> _adjustmentsFor(String liftId) {
  const rules = [
    (ProgressOutcome.belowBy2, -0.050),
    (ProgressOutcome.belowBy1, -0.020),
    (ProgressOutcome.hit,       0.000),
    (ProgressOutcome.plus1,     0.005),
    (ProgressOutcome.plus2,     0.010),
    (ProgressOutcome.plus3,     0.015),
    (ProgressOutcome.plus4,     0.020),
    (ProgressOutcome.plus5,     0.030),
  ];
  return rules
      .map((r) => ProgressAdjustment(
            id: '${liftId}_${r.$1.name}',
            liftId: liftId,
            outcome: r.$1,
            delta: r.$2,
            appliesToCycle: true,
            appliesToTrainingMax: true,
          ))
      .toList();
}

// ---------------------------------------------------------------------------
// Tests
// ---------------------------------------------------------------------------

void main() {
  const svc = ProgressionService();
  const currentTm = 100.0;

  final squat3Presc = _prescription(liftId: 'squat', repOutTarget: 3);
  final squatAdjs   = _adjustmentsFor('squat');

  ProgressionResult eval(int reps) => svc.evaluate(
        log: _log(reps),
        prescription: squat3Presc,
        adjustments: squatAdjs,
        currentTrainingMax: currentTm,
      );

  // ── 8 core outcome cases ───────────────────────────────────────────────────
  group('8 outcome cases (repOutTarget = 3, currentTm = 100)', () {
    test('belowBy2 — reps=1 (diff=-2): outcome belowBy2, TM = 95.0', () {
      final r = eval(1);
      expect(r.outcome, ProgressOutcome.belowBy2);
      expect(r.newTrainingMax, closeTo(95.0, 0.001));
    });

    test('belowBy1 — reps=2 (diff=-1): outcome belowBy1, TM = 98.0', () {
      final r = eval(2);
      expect(r.outcome, ProgressOutcome.belowBy1);
      expect(r.newTrainingMax, closeTo(98.0, 0.001));
    });

    test('hit — reps=3 (diff=0): outcome hit, TM unchanged = 100.0', () {
      final r = eval(3);
      expect(r.outcome, ProgressOutcome.hit);
      expect(r.newTrainingMax, closeTo(100.0, 0.001));
    });

    test('plus1 — reps=4 (diff=+1): outcome plus1, TM = 100.5', () {
      final r = eval(4);
      expect(r.outcome, ProgressOutcome.plus1);
      expect(r.newTrainingMax, closeTo(100.5, 0.001));
    });

    test('plus2 — reps=5 (diff=+2): outcome plus2, TM = 101.0', () {
      final r = eval(5);
      expect(r.outcome, ProgressOutcome.plus2);
      expect(r.newTrainingMax, closeTo(101.0, 0.001));
    });

    test('plus3 — reps=6 (diff=+3): outcome plus3, TM = 101.5', () {
      final r = eval(6);
      expect(r.outcome, ProgressOutcome.plus3);
      expect(r.newTrainingMax, closeTo(101.5, 0.001));
    });

    test('plus4 — reps=7 (diff=+4): outcome plus4, TM = 102.0', () {
      final r = eval(7);
      expect(r.outcome, ProgressOutcome.plus4);
      expect(r.newTrainingMax, closeTo(102.0, 0.001));
    });

    test('plus5 — reps=8 (diff=+5): outcome plus5, TM = 103.0', () {
      final r = eval(8);
      expect(r.outcome, ProgressOutcome.plus5);
      expect(r.newTrainingMax, closeTo(103.0, 0.001));
    });
  });

  // ── Boundary / clamp behaviour ─────────────────────────────────────────────
  group('Boundary clamps', () {
    test('diff=-5 still maps to belowBy2 (lower clamp)', () {
      expect(
        svc.determineOutcome(repsOnLastSet: 0, repOutTarget: 5),
        ProgressOutcome.belowBy2,
      );
    });

    test('diff=+10 still maps to plus5 (upper clamp)', () {
      expect(
        svc.determineOutcome(repsOnLastSet: 15, repOutTarget: 5),
        ProgressOutcome.plus5,
      );
    });
  });

  // ── Fallback key ───────────────────────────────────────────────────────────
  group('all_lifts fallback', () {
    test('uses all_lifts adjustment when no lift-specific entry exists', () {
      final fallbackAdjs  = _adjustmentsFor('all_lifts');
      final unknownPresc  = _prescription(liftId: 'unknown_lift', repOutTarget: 3);
      final r = svc.evaluate(
        log: _log(3),
        prescription: unknownPresc,
        adjustments: fallbackAdjs,
        currentTrainingMax: 100.0,
      );
      expect(r.outcome, ProgressOutcome.hit);
      expect(r.newTrainingMax, closeTo(100.0, 0.001));
    });
  });

  // ── Error handling ─────────────────────────────────────────────────────────
  group('Error handling', () {
    test('throws ArgumentError when no adjustment entry found at all', () {
      expect(
        () => svc.evaluate(
          log: _log(3),
          prescription: squat3Presc,
          adjustments: [],
          currentTrainingMax: 100.0,
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
