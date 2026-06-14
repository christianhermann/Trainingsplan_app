import '../models/intensity_point.dart';

/// Looks up weekly intensity values for a given lift and week.
/// The workbook defines a 21-week intensity progression for each lift.
abstract class IntensityLookupService {
  /// Returns the intensity value for a lift at a specific week.
  /// 
  /// Parameters:
  ///   - liftId: The ID of the lift
  ///   - weekNumber: The week in the cycle (1-21)
  ///   - intensityPoints: The complete set of IntensityPoint records
  /// 
  /// Returns the intensity as a decimal (e.g., 0.70, 0.725, 0.75).
  /// Throws an exception if the lift/week combination is not found.
  double getIntensity(
    String liftId,
    int weekNumber,
    List<IntensityPoint> intensityPoints,
  );

  /// Finds the best matching intensity from available points.
  /// Used when exact intensity match is not critical and closest value is acceptable.
  double? getClosestIntensity(
    String liftId,
    int weekNumber,
    List<IntensityPoint> intensityPoints,
  );
}

/// Default implementation of IntensityLookupService.
class DefaultIntensityLookupService implements IntensityLookupService {
  @override
  double getIntensity(
    String liftId,
    int weekNumber,
    List<IntensityPoint> intensityPoints,
  ) {
    try {
      final point = intensityPoints.firstWhere(
        (p) => p.liftId == liftId && p.weekNumber == weekNumber,
      );
      return point.intensity;
    } catch (e) {
      throw Exception(
        'Intensity not found for lift: $liftId, week: $weekNumber',
      );
    }
  }

  @override
  double? getClosestIntensity(
    String liftId,
    int weekNumber,
    List<IntensityPoint> intensityPoints,
  ) {
    final relevantPoints =
        intensityPoints.where((p) => p.liftId == liftId).toList();

    if (relevantPoints.isEmpty) return null;

    relevantPoints.sort(
      (a, b) => (a.weekNumber - weekNumber).abs()
          .compareTo((b.weekNumber - weekNumber).abs()),
    );

    return relevantPoints.first.intensity;
  }
}


