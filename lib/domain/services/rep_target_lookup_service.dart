import '../models/rep_target_point.dart';

/// Looks up rep targets from seeder data.
///
/// The workbook defines ONE rep count per intensity step that applies to
/// every set including the last set.  RIR target = 0 means the lifter
/// works to their technical limit on the last set.
///
/// [getRepTarget]  → reps for normal sets AND the last set (repsPerSet).
/// [getRirTarget]  → RIR target for the last set (always 0 from seeder,
///                   but callers should not hard-code this).
///
/// Fallback (no matching RepTargetPoint in the list) uses the same
/// intensity-bracket table the workbook implies.
///
/// ## Tolerance choice
///
/// The seeder stores intensity as `pct / 100.0` (plain double division).
/// IEEE-754 double-precision can represent 0.55 exactly, but values like
/// 0.675, 0.725, 0.775, 0.825 have a small ULP drift (~2.2 × 10⁻¹⁶).
/// A tolerance of 0.0001 is:
///   • Wide enough to absorb any /100 rounding drift.
///   • Narrow enough to never span two adjacent 2.5 %-step buckets
///     (delta between neighbours = 0.025 ≫ 0.0001).
class RepTargetLookupService {
  /// Tolerance used for intensity matching.
  /// Must be << 0.025 (the step between adjacent intensity buckets).
  static const double _kTolerance = 0.0001;

  // Fallback table: intensity → reps per set
  static int _fallbackReps(double intensity) {
    if (intensity >= 1.00)  return 1;
    if (intensity >= 0.975) return 1;
    if (intensity >= 0.95)  return 1;
    if (intensity >= 0.925) return 2;
    if (intensity >= 0.90)  return 2;
    if (intensity >= 0.875) return 3;
    if (intensity >= 0.85)  return 4;
    if (intensity >= 0.825) return 5;
    if (intensity >= 0.80)  return 6;
    if (intensity >= 0.775) return 7;
    if (intensity >= 0.75)  return 8;
    if (intensity >= 0.725) return 9;
    if (intensity >= 0.70)  return 10;
    if (intensity >= 0.675) return 11;
    if (intensity >= 0.65)  return 12;
    if (intensity >= 0.625) return 13;
    if (intensity >= 0.60)  return 14;
    if (intensity >= 0.575) return 15;
    if (intensity >= 0.55)  return 16;
    if (intensity >= 0.525) return 18;
    return 20;
  }

  RepTargetPoint? _find(
    String liftId,
    double intensity,
    List<RepTargetPoint> points,
  ) {
    final matches = points.where(
      (p) =>
          p.liftId == liftId &&
          (p.intensity - intensity).abs() < _kTolerance,
    );
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Reps per set (applies to all sets including the last).
  int getRepTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final match = _find(liftId, intensity, repTargetPoints);
    return match?.repsPerSet ?? _fallbackReps(intensity);
  }

  /// RIR target for the last set (0 = work to technical limit).
  int getRirTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final match = _find(liftId, intensity, repTargetPoints);
    return match?.lastSetRirTarget ?? 0;
  }

  // ── Legacy compatibility shims ──────────────────────────────────────────────────────
  // Delegate to the new API so workout_generation_service.dart keeps compiling.

  int getNormalSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) =>
      getRepTarget(liftId, intensity, repTargetPoints);

  int getLastSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) =>
      getRepTarget(liftId, intensity, repTargetPoints);
}
