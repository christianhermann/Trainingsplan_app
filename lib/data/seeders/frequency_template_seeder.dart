import '../../domain/models/enums.dart';
import '../../domain/models/frequency_template.dart';

/// Seed data for frequency templates.
///
/// Maps the static workout structure: which lifts are trained on which days
/// for each frequency (2x, 3x, 4x, 5x, 6x).
///
/// Per workbook-logic.md:
/// "The workbook has dedicated day layouts inside the frequency sheets,
/// including Day 1 and Day 2 in 2x and additional day sections in higher-frequency sheets."
///
/// IMPORTANT TODOs:
/// 1. The exact day-by-day lift assignments are NOT documented in workbook-logic.md.
/// 2. The data below is a PLACEHOLDER and must be verified against the actual workbook.
/// 3. We need to examine the workbook's frequency sheets (2x, 3x, 4x, 5x, 6x tabs)
///    to determine the correct exercise order for each day.
/// 4. Clarify whether the 10 seeded lifts are the ONLY ones in the templates,
///    or if there are accessory movements included.
///    See docs/open-questions.md #6 (accessory catalog scope).

class FrequencyTemplateSeeder {
  /// Generate all frequency template lookup points.
  /// This is a PLACEHOLDER - must be verified against actual workbook.
  static List<FrequencyTemplate> generateFrequencyTemplates() {
    final templates = <FrequencyTemplate>[];

    // TODO: Replace with actual workbook layout
    templates.addAll(_generateTwo());
    templates.addAll(_generateThree());
    templates.addAll(_generateFour());
    templates.addAll(_generateFive());
    templates.addAll(_generateSix());

    return templates;
  }

  /// Two-day frequency template (2x per week).
  /// TODO: Verify against workbook "2x" frequency sheet.
  static List<FrequencyTemplate> _generateTwo() {
    return [
      // Day 1 - Monday/first day
      FrequencyTemplate(
        id: 'freq_2_day_0_squat',
        frequency: ProgramFrequency.two,
        dayIndex: 0,
        liftId: 'squat',
        defaultOrder: 1,
        blockType: 'main',
      ),
      FrequencyTemplate(
        id: 'freq_2_day_0_leg_press',
        frequency: ProgramFrequency.two,
        dayIndex: 0,
        liftId: 'leg_press',
        defaultOrder: 2,
        blockType: 'auxiliary',
      ),
      FrequencyTemplate(
        id: 'freq_2_day_0_wider_stance_squat',
        frequency: ProgramFrequency.two,
        dayIndex: 0,
        liftId: 'wider_stance_squat',
        defaultOrder: 3,
        blockType: 'auxiliary',
      ),

      // Day 2 - Friday/second day (offset)
      FrequencyTemplate(
        id: 'freq_2_day_1_bench_press',
        frequency: ProgramFrequency.two,
        dayIndex: 1,
        liftId: 'bench_press',
        defaultOrder: 1,
        blockType: 'main',
      ),
      FrequencyTemplate(
        id: 'freq_2_day_1_dumbbell_bench',
        frequency: ProgramFrequency.two,
        dayIndex: 1,
        liftId: 'dumbbell_bench',
        defaultOrder: 2,
        blockType: 'auxiliary',
      ),
      FrequencyTemplate(
        id: 'freq_2_day_1_incline_dumbbell_press',
        frequency: ProgramFrequency.two,
        dayIndex: 1,
        liftId: 'incline_dumbbell_press',
        defaultOrder: 3,
        blockType: 'auxiliary',
      ),
    ];
  }

  /// Three-day frequency template (3x per week).
  /// TODO: Verify against workbook "3x" frequency sheet.
  static List<FrequencyTemplate> _generateThree() {
    // Placeholder structure
    return [
      FrequencyTemplate(
        id: 'freq_3_day_0_squat',
        frequency: ProgramFrequency.three,
        dayIndex: 0,
        liftId: 'squat',
        defaultOrder: 1,
        blockType: 'main',
      ),
      // TODO: Complete 3x template
    ];
  }

  /// Four-day frequency template (4x per week).
  /// TODO: Verify against workbook "4x" frequency sheet.
  static List<FrequencyTemplate> _generateFour() {
    // Placeholder structure
    return [
      FrequencyTemplate(
        id: 'freq_4_day_0_squat',
        frequency: ProgramFrequency.four,
        dayIndex: 0,
        liftId: 'squat',
        defaultOrder: 1,
        blockType: 'main',
      ),
      // TODO: Complete 4x template
    ];
  }

  /// Five-day frequency template (5x per week).
  /// TODO: Verify against workbook "5x" frequency sheet.
  static List<FrequencyTemplate> _generateFive() {
    // Placeholder structure
    return [
      FrequencyTemplate(
        id: 'freq_5_day_0_squat',
        frequency: ProgramFrequency.five,
        dayIndex: 0,
        liftId: 'squat',
        defaultOrder: 1,
        blockType: 'main',
      ),
      // TODO: Complete 5x template
    ];
  }

  /// Six-day frequency template (6x per week).
  /// TODO: Verify against workbook "6x" frequency sheet.
  static List<FrequencyTemplate> _generateSix() {
    // Placeholder structure
    return [
      FrequencyTemplate(
        id: 'freq_6_day_0_squat',
        frequency: ProgramFrequency.six,
        dayIndex: 0,
        liftId: 'squat',
        defaultOrder: 1,
        blockType: 'main',
      ),
      // TODO: Complete 6x template
    ];
  }
}
