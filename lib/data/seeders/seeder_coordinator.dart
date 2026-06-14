import '../../domain/models/intensity_point.dart';
import '../../domain/models/rep_target_point.dart';
import '../../domain/models/progress_adjustment.dart';
import '../../domain/models/frequency_template.dart';

import 'intensity_seeder.dart';
import 'rep_target_seeder.dart';
import 'progression_adjustment_seeder.dart';
import 'frequency_template_seeder.dart';

/// Coordinates all lookup table seeders.
/// Call this once during app initialization to populate lookup tables.
///
/// These seeders generate data from the workbook structure:
/// - 21-week intensity progression per lift
/// - Rep targets indexed by intensity
/// - Progression adjustment rules (ProgressOutcome → delta)
/// - Frequency templates (which lifts on which days)
class SeederCoordinator {
  /// Seed all lookup tables in order.
  /// Call during database initialization.
  static Future<void> seedAllLookupTables({
    required void Function(List<IntensityPoint>) onIntensityPoints,
    required void Function(List<RepTargetPoint>) onRepTargetPoints,
    required void Function(List<ProgressAdjustment>) onProgressionAdjustments,
    required void Function(List<FrequencyTemplate>) onFrequencyTemplates,
  }) async {
    // Order matters: these are independent tables with no foreign key dependencies.
    // Each can be seeded in any order.

    final intensities = IntensitySeeder.generateIntensityPoints();
    onIntensityPoints(intensities);

    final repTargets = RepTargetSeeder.generateRepTargetPoints();
    onRepTargetPoints(repTargets);

    final progressionAdjustments =
        ProgressionAdjustmentSeeder.generateProgressionAdjustments();
    onProgressionAdjustments(progressionAdjustments);

    final frequencyTemplates =
        FrequencyTemplateSeeder.generateFrequencyTemplates();
    onFrequencyTemplates(frequencyTemplates);
  }

  /// Summary of seeded data for debugging.
  static String summary() {
    final intensities = IntensitySeeder.generateIntensityPoints();
    final repTargets = RepTargetSeeder.generateRepTargetPoints();
    final adjustments = ProgressionAdjustmentSeeder.generateProgressionAdjustments();
    final templates = FrequencyTemplateSeeder.generateFrequencyTemplates();

    return '''
Lookup Table Seed Summary:
- IntensityPoints: ${intensities.length} records
  (21 weeks × ${intensities.length ~/ 21} lifts)
- RepTargetPoints: ${repTargets.length} records
  (${repTargets.length} intensity levels × lifts)
- ProgressionAdjustments: ${adjustments.length} records
  (8 outcomes × ${adjustments.length ~/ 8} lifts)
- FrequencyTemplates: ${templates.length} records
  (${templates.length} lift-day assignments)

NOTE: FrequencyTemplates are INCOMPLETE.
See frequency_template_seeder.dart for TODOs.
''';
  }
}
