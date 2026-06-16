import '../models/intensity_point.dart';

class IntensityLookupService {
  // Workbook intensity table: week 1–21
  static const _table = [
    0.65, 0.70, 0.75, 0.75, 0.80, 0.80, 0.80,
    0.82, 0.85, 0.85, 0.87, 0.87, 0.87,
    0.90, 0.90, 0.90, 0.92, 0.92, 0.92,
    0.95, 0.97,
  ];

  double getIntensityForWeek(int weekNumber) {
    final idx = (weekNumber - 1).clamp(0, _table.length - 1);
    return _table[idx];
  }

  double getIntensity(
    String liftId,
    int weekNumber,
    List<IntensityPoint> intensityPoints,
  ) {
    final match = intensityPoints.where(
      (p) => p.liftId == liftId && p.weekNumber == weekNumber,
    );
    if (match.isNotEmpty) return match.first.intensity;
    return getIntensityForWeek(weekNumber);
  }
}
