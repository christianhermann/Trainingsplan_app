import '../models/rep_target_point.dart';

abstract class RepTargetLookupService {
  int getNormalSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  );

  int getLastSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  );

  /// Direct week-based lookups using built-in table.
  int getNormalSetReps(int weekNumber);
  int getLastSetReps(int weekNumber);
}

class DefaultRepTargetLookupService implements RepTargetLookupService {
  // Normal set rep targets per week (1–21)
  static const _normalReps = [
    10, 10, 8, 8, 6, 6, 6,
    5, 5, 5, 4, 4, 4,
    3, 3, 3, 3, 3, 3,
    2, 1,
  ];

  // Last set rep targets per week (1–21)
  static const _lastSetReps = [
    12, 12, 10, 10, 8, 8, 8,
    7, 7, 7, 6, 6, 6,
    5, 5, 5, 4, 4, 4,
    3, 2,
  ];

  @override
  int getNormalSetReps(int weekNumber) {
    final idx = (weekNumber - 1).clamp(0, _normalReps.length - 1);
    return _normalReps[idx];
  }

  @override
  int getLastSetReps(int weekNumber) {
    final idx = (weekNumber - 1).clamp(0, _lastSetReps.length - 1);
    return _lastSetReps[idx];
  }

  @override
  int getNormalSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final match = repTargetPoints.where(
      (p) => p.liftId == liftId && (p.intensity - intensity).abs() < 0.01,
    );
    if (match.isNotEmpty) return match.first.normalSetReps;
    // Fallback: estimate from intensity
    if (intensity >= 0.95) return 2;
    if (intensity >= 0.90) return 3;
    if (intensity >= 0.85) return 4;
    if (intensity >= 0.80) return 5;
    if (intensity >= 0.75) return 6;
    if (intensity >= 0.70) return 8;
    return 10;
  }

  @override
  int getLastSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final match = repTargetPoints.where(
      (p) => p.liftId == liftId && (p.intensity - intensity).abs() < 0.01,
    );
    if (match.isNotEmpty) return match.first.lastSetReps;
    if (intensity >= 0.95) return 3;
    if (intensity >= 0.90) return 4;
    if (intensity >= 0.85) return 5;
    if (intensity >= 0.80) return 6;
    if (intensity >= 0.75) return 8;
    if (intensity >= 0.70) return 10;
    return 12;
  }
}
