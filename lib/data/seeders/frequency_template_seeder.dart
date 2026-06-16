import '../../domain/models/enums.dart';
import '../../domain/models/frequency_template.dart';

/// Seed data for frequency templates.
///
/// Maps the static workout structure: which lifts are trained on which days
/// for each training frequency (2x–6x per week).
///
/// Source of truth: workbook 3x/4x/5x/6x training sheets, corrected
/// against the canonical day-by-day layout.
///
/// Slot → liftId mapping (workbook defaults):
///   Main Squat       → squat
///   Main Bench       → bench_press
///   Main Deadlift    → deadlift
///   Main OHP         → overhead_press
///   Aux 1 Squat      → front_squat
///   Aux 1 Bench      → close_grip_bench
///   Aux 1 Deadlift   → deadlift_aux
///   Aux 1 OHP        → ohp_aux
///   Aux 2 Squat      → squat_aux2
///   Aux 2 Bench      → bench_aux2
///   Back Exercise 1  → barbell_rows
///   Back Exercise 2  → dumbbell_rows
///   Back Exercise 3  → pulldowns

class FrequencyTemplateSeeder {
  static List<FrequencyTemplate> generateFrequencyTemplates() {
    return [
      ..._generateTwo(),
      ..._generateThree(),
      ..._generateFour(),
      ..._generateFive(),
      ..._generateSix(),
    ];
  }

  // ---------------------------------------------------------------------------
  // Helper — avoids repeating the constructor boilerplate
  // ---------------------------------------------------------------------------
  static FrequencyTemplate _t(
    ProgramFrequency freq,
    int day,
    String liftId,
    int order,
    String blockType,
  ) {
    return FrequencyTemplate(
      id: 'freq_${freq.value}_day_${day}_$liftId',
      frequency: freq,
      dayIndex: day,
      liftId: liftId,
      defaultOrder: order,
      blockType: blockType,
    );
  }

  // ---------------------------------------------------------------------------
  // 2x — 2 days/week
  // Day 0: Main Squat, Main OHP, Aux1 Deadlift, Aux2 Bench, Back3, Back1
  // Day 1: Main Bench, Aux1 Squat, Aux1 OHP, Main Deadlift, Aux2 Squat, Back2
  // (2x keeps all 13 lifts across 2 sessions — existing placeholder preserved)
  // ---------------------------------------------------------------------------
  static List<FrequencyTemplate> _generateTwo() {
    const f = ProgramFrequency.two;
    return [
      // Day 0
      _t(f, 0, 'squat',          1, 'main'),
      _t(f, 0, 'overhead_press', 2, 'main'),
      _t(f, 0, 'deadlift_aux',   3, 'auxiliary'),
      _t(f, 0, 'bench_aux2',     4, 'auxiliary'),
      _t(f, 0, 'pulldowns',      5, 'auxiliary'),
      _t(f, 0, 'barbell_rows',   6, 'auxiliary'),
      // Day 1
      _t(f, 1, 'bench_press',    1, 'main'),
      _t(f, 1, 'deadlift',       2, 'main'),
      _t(f, 1, 'front_squat',    3, 'auxiliary'),
      _t(f, 1, 'close_grip_bench', 4, 'auxiliary'),
      _t(f, 1, 'squat_aux2',     5, 'auxiliary'),
      _t(f, 1, 'ohp_aux',        6, 'auxiliary'),
      _t(f, 1, 'dumbbell_rows',  7, 'auxiliary'),
    ];
  }

  // ---------------------------------------------------------------------------
  // 3x — 3 days/week
  // Day 0: Main Squat, Main OHP, Aux1 Deadlift, Aux2 Bench, Back3
  // Day 1: Main Bench, Aux1 Squat, Aux1 OHP, Back1
  // Day 2: Main Deadlift, Aux1 Bench, Aux2 Squat, Back2
  // ---------------------------------------------------------------------------
  static List<FrequencyTemplate> _generateThree() {
    const f = ProgramFrequency.three;
    return [
      // Day 0
      _t(f, 0, 'squat',            1, 'main'),
      _t(f, 0, 'overhead_press',   2, 'main'),
      _t(f, 0, 'deadlift_aux',     3, 'auxiliary'),
      _t(f, 0, 'bench_aux2',       4, 'auxiliary'),
      _t(f, 0, 'pulldowns',        5, 'auxiliary'), // Back 3
      // Day 1
      _t(f, 1, 'bench_press',      1, 'main'),
      _t(f, 1, 'front_squat',      2, 'auxiliary'), // Aux 1 Squat
      _t(f, 1, 'ohp_aux',          3, 'auxiliary'), // Aux 1 OHP
      _t(f, 1, 'barbell_rows',     4, 'auxiliary'), // Back 1
      // Day 2
      _t(f, 2, 'deadlift',         1, 'main'),
      _t(f, 2, 'close_grip_bench', 2, 'auxiliary'), // Aux 1 Bench
      _t(f, 2, 'squat_aux2',       3, 'auxiliary'), // Aux 2 Squat
      _t(f, 2, 'dumbbell_rows',    4, 'auxiliary'), // Back 2
    ];
  }

  // ---------------------------------------------------------------------------
  // 4x — 4 days/week
  // Day 0: Main Squat, Aux2 Bench, Aux1 Deadlift, Back2
  // Day 1: Main Bench, Aux1 Squat, Aux1 OHP
  // Day 2: Main Deadlift, Aux1 Bench, Back3
  // Day 3: Main OHP, Aux2 Squat, Back1
  // ---------------------------------------------------------------------------
  static List<FrequencyTemplate> _generateFour() {
    const f = ProgramFrequency.four;
    return [
      // Day 0
      _t(f, 0, 'squat',            1, 'main'),
      _t(f, 0, 'bench_aux2',       2, 'auxiliary'), // Aux 2 Bench
      _t(f, 0, 'deadlift_aux',     3, 'auxiliary'), // Aux 1 Deadlift
      _t(f, 0, 'dumbbell_rows',    4, 'auxiliary'), // Back 2
      // Day 1
      _t(f, 1, 'bench_press',      1, 'main'),
      _t(f, 1, 'front_squat',      2, 'auxiliary'), // Aux 1 Squat
      _t(f, 1, 'ohp_aux',          3, 'auxiliary'), // Aux 1 OHP
      // Day 2
      _t(f, 2, 'deadlift',         1, 'main'),
      _t(f, 2, 'close_grip_bench', 2, 'auxiliary'), // Aux 1 Bench
      _t(f, 2, 'pulldowns',        3, 'auxiliary'), // Back 3
      // Day 3
      _t(f, 3, 'overhead_press',   1, 'main'),
      _t(f, 3, 'squat_aux2',       2, 'auxiliary'), // Aux 2 Squat
      _t(f, 3, 'barbell_rows',     3, 'auxiliary'), // Back 1
    ];
  }

  // ---------------------------------------------------------------------------
  // 5x — 5 days/week
  // Day 0: Main Squat, Aux1 OHP, Back1
  // Day 1: Main Bench, Aux1 Squat
  // Day 2: Main Deadlift, Aux1 Bench, Back3
  // Day 3: Main OHP, Aux2 Squat
  // Day 4: Aux2 Bench, Aux1 Deadlift, Back2
  // ---------------------------------------------------------------------------
  static List<FrequencyTemplate> _generateFive() {
    const f = ProgramFrequency.five;
    return [
      // Day 0
      _t(f, 0, 'squat',            1, 'main'),
      _t(f, 0, 'ohp_aux',          2, 'auxiliary'), // Aux 1 OHP
      _t(f, 0, 'barbell_rows',     3, 'auxiliary'), // Back 1
      // Day 1
      _t(f, 1, 'bench_press',      1, 'main'),
      _t(f, 1, 'front_squat',      2, 'auxiliary'), // Aux 1 Squat
      // Day 2
      _t(f, 2, 'deadlift',         1, 'main'),
      _t(f, 2, 'close_grip_bench', 2, 'auxiliary'), // Aux 1 Bench
      _t(f, 2, 'pulldowns',        3, 'auxiliary'), // Back 3
      // Day 3
      _t(f, 3, 'overhead_press',   1, 'main'),
      _t(f, 3, 'squat_aux2',       2, 'auxiliary'), // Aux 2 Squat
      // Day 4
      _t(f, 4, 'bench_aux2',       1, 'auxiliary'), // Aux 2 Bench
      _t(f, 4, 'deadlift_aux',     2, 'auxiliary'), // Aux 1 Deadlift
      _t(f, 4, 'dumbbell_rows',    3, 'auxiliary'), // Back 2
    ];
  }

  // ---------------------------------------------------------------------------
  // 6x — 6 days/week
  // Day 0: Main Squat, Aux2 Bench
  // Day 1: Aux1 Deadlift, Back3
  // Day 2: Main Bench, Aux1 Squat
  // Day 3: Main Deadlift, Aux1 OHP, Back2
  // Day 4: Aux2 Squat, Aux1 Bench
  // Day 5: Main OHP, Back1
  // ---------------------------------------------------------------------------
  static List<FrequencyTemplate> _generateSix() {
    const f = ProgramFrequency.six;
    return [
      // Day 0
      _t(f, 0, 'squat',            1, 'main'),
      _t(f, 0, 'bench_aux2',       2, 'auxiliary'), // Aux 2 Bench
      // Day 1
      _t(f, 1, 'deadlift_aux',     1, 'auxiliary'), // Aux 1 Deadlift
      _t(f, 1, 'pulldowns',        2, 'auxiliary'), // Back 3
      // Day 2
      _t(f, 2, 'bench_press',      1, 'main'),
      _t(f, 2, 'front_squat',      2, 'auxiliary'), // Aux 1 Squat
      // Day 3
      _t(f, 3, 'deadlift',         1, 'main'),
      _t(f, 3, 'ohp_aux',          2, 'auxiliary'), // Aux 1 OHP
      _t(f, 3, 'dumbbell_rows',    3, 'auxiliary'), // Back 2
      // Day 4
      _t(f, 4, 'squat_aux2',       1, 'auxiliary'), // Aux 2 Squat
      _t(f, 4, 'close_grip_bench', 2, 'auxiliary'), // Aux 1 Bench
      // Day 5
      _t(f, 5, 'overhead_press',   1, 'main'),
      _t(f, 5, 'barbell_rows',     2, 'auxiliary'), // Back 1
    ];
  }
}
