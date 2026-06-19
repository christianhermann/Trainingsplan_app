import '../models/rep_target_point.dart';

/// Looks up rep targets from seeder data.
///
/// The workbook defines ONE rep count per intensity step that applies to
/// every set including the last set. RIR target = 0 means the lifter
/// works to their technical limit on the last set.
///
/// ## Tolerance
/// 0.0001 absorbs IEEE-754 drift from pct/100 division without ever
/// spanning two adjacent 2.5 %-step buckets (delta = 0.025 >> 0.0001).
class RepTargetLookupService {
  static const double _kTolerance = 0.0001;

  static int _fallbackReps(double intensity) {
    if (intensity >= 0.975) return 1;
    if (intensity >= 0.950) return 1;
    if (intensity >= 0.925) return 2;
    if (intensity >= 0.900) return 2;
    if (intensity >= 0.875) return 3;
    if (intensity >= 0.850) return 4;
    if (intensity >= 0.825) return 5;
    if (intensity >= 0.800) return 6;
    if (intensity >= 0.775) return 7;
    if (intensity >= 0.750) return 8;
    if (intensity >= 0.725) return 9;
    if (intensity >= 0.700) return 10;
    if (intensity >= 0.675) return 11;
    if (intensity >= 0.650) return 12;
    if (intensity >= 0.625) return 13;
    if (intensity >= 0.600) return 14;
    if (intensity >= 0.575) return 15;
    if (intensity >= 0.550) return 16;
    if (intensity >= 0.525) return 18;
    return 20;
  }

  bool _matches(RepTargetPoint p, String liftId, double intensity) =>
      p.liftId == liftId && (p.intensity - intensity).abs() < _kTolerance;

  /// Reps per set (applies to all sets including the last).
  int getRepTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final match = repTargetPoints
        .where((p) => _matches(p, liftId, intensity))
        .firstOrNull;
    return match?.repsPerSet ?? _fallbackReps(intensity);
  }

  /// RIR target for the last set (0 = work to technical limit).
  int getRirTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final match = repTargetPoints
        .where((p) => _matches(p, liftId, intensity))
        .firstOrNull;
    return match?.lastSetRirTarget ?? 0;
  }
}
