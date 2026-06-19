import '../models/intensity_point.dart';

/// Looks up the intensity (0-1 fraction) for a given lift and week.
///
/// Primary source: [IntensityPoint] list from [IntensitySeeder].
/// Fallback: flat workbook values by lift tier.
///
/// Intensity is FLAT for all 21 weeks - load grows through TM autoregulation.
class IntensityLookupService {
  static const _mainLiftIds = {
    'squat', 'bench_press', 'deadlift', 'overhead_press',
  };
  static const _auxTier1Ids = {'front_squat', 'close_grip_bench'};

  static const _mainIntensity = 0.875;
  static const _auxTier1     = 0.825;
  static const _auxTier2     = 0.750; // tier-2 + back exercises

  double getIntensity(
    String liftId,
    int weekNumber,
    List<IntensityPoint> intensityPoints,
  ) {
    final match = intensityPoints
        .where((p) => p.liftId == liftId && p.weekNumber == weekNumber)
        .firstOrNull;
    return match?.intensity ?? _fallback(liftId);
  }

  double _fallback(String liftId) {
    if (_mainLiftIds.contains(liftId)) return _mainIntensity;
    if (_auxTier1Ids.contains(liftId)) return _auxTier1;
    return _auxTier2;
  }
}
