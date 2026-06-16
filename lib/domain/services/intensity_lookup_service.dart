import '../models/intensity_point.dart';

/// Looks up the intensity (0–1 fraction) for a given lift and week.
///
/// Primary source: [IntensityPoint] list from [IntensitySeeder].
/// Fallback (lift not in seeder): workbook flat values by lift tier.
///
/// Workbook values (SBS Linear Progression, Quick Setup):
///   Main lifts (squat, bench_press, deadlift, overhead_press) : 87.5 % = 0.875
///   Auxiliary tier-1 (front_squat, close_grip_bench)          : 82.5 % = 0.825
///   Auxiliary tier-2 + back exercises                         : 75.0 % = 0.750
///
/// Intensity is FLAT for all 21 weeks — training load grows through
/// training-max autoregulation (RIR feedback), not by changing intensity %.
class IntensityLookupService {
  // Canonical main lift IDs — used for fallback tier detection.
  static const _mainLiftIds = {
    'squat', 'bench_press', 'deadlift', 'overhead_press',
  };
  static const _auxTier1LiftIds = {
    'front_squat', 'close_grip_bench',
  };

  // Workbook-correct flat intensities per tier.
  static const _mainIntensity   = 0.875;
  static const _auxTier1Intensity = 0.825;
  static const _auxTier2Intensity = 0.750; // tier-2 + all back exercises

  /// Primary lookup: finds the [IntensityPoint] matching [liftId] + [weekNumber].
  /// Falls back to [_fallbackIntensity] if no seeder entry exists.
  double getIntensity(
    String liftId,
    int weekNumber,
    List<IntensityPoint> intensityPoints,
  ) {
    final match = intensityPoints.where(
      (p) => p.liftId == liftId && p.weekNumber == weekNumber,
    );
    return match.isNotEmpty ? match.first.intensity : _fallbackIntensity(liftId);
  }

  /// Flat workbook intensity for a lift not present in the seeder data.
  double _fallbackIntensity(String liftId) {
    if (_mainLiftIds.contains(liftId))    return _mainIntensity;
    if (_auxTier1LiftIds.contains(liftId)) return _auxTier1Intensity;
    return _auxTier2Intensity; // tier-2 + back exercises + any unknown lift
  }
}
