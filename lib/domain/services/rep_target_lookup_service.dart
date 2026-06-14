import '../models/rep_target_point.dart';

/// Looks up rep targets for normal sets and last sets based on lift and intensity.
/// The workbook defines separate tables for normal-set and last-set targets,
/// indexed by intensity level (e.g., 0.70, 0.725, 0.75, etc.).
abstract class RepTargetLookupService {
  /// Returns the normal-set rep target for a lift at a given intensity.
  /// 
  /// Parameters:
  ///   - liftId: The ID of the lift
  ///   - intensity: The intensity as a decimal (e.g., 0.75)
  ///   - repTargetPoints: The complete set of RepTargetPoint records
  /// 
  /// Returns the target rep count for normal sets.
  /// Throws an exception if the lift/intensity combination is not found.
  int getNormalSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  );

  /// Returns the last-set rep target for a lift at a given intensity.
  /// Last-set targets are typically higher than normal-set targets.
  /// 
  /// Parameters:
  ///   - liftId: The ID of the lift
  ///   - intensity: The intensity as a decimal (e.g., 0.75)
  ///   - repTargetPoints: The complete set of RepTargetPoint records
  /// 
  /// Returns the target rep count for the last set (typically higher).
  /// Throws an exception if the lift/intensity combination is not found.
  int getLastSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  );

  /// Finds the closest intensity match if an exact intensity is not available.
  /// Useful for handling rounding or slightly different intensity values.
  RepTargetPoint? getClosestRepTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  );
}

/// Default implementation of RepTargetLookupService.
class DefaultRepTargetLookupService implements RepTargetLookupService {
  static const double _intensityTolerance = 0.001; // Allow tiny rounding differences

  @override
  int getNormalSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final point = _findRepTargetPoint(liftId, intensity, repTargetPoints);
    return point.normalSetTarget;
  }

  @override
  int getLastSetTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final point = _findRepTargetPoint(liftId, intensity, repTargetPoints);
    return point.lastSetTarget;
  }

  @override
  RepTargetPoint? getClosestRepTarget(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    final relevantPoints =
        repTargetPoints.where((p) => p.liftId == liftId).toList();

    if (relevantPoints.isEmpty) return null;

    // Sort by distance to the target intensity
    relevantPoints.sort(
      (a, b) => (a.intensity - intensity).abs()
          .compareTo((b.intensity - intensity).abs()),
    );

    return relevantPoints.first;
  }

  RepTargetPoint _findRepTargetPoint(
    String liftId,
    double intensity,
    List<RepTargetPoint> repTargetPoints,
  ) {
    try {
      // First try exact match (with small tolerance for floating point)
      return repTargetPoints.firstWhere(
        (p) =>
            p.liftId == liftId &&
            (p.intensity - intensity).abs() < _intensityTolerance,
      );
    } catch (e) {
      // Fall back to closest match
      final closest = getClosestRepTarget(liftId, intensity, repTargetPoints);
      if (closest != null) {
        return closest;
      }
      throw Exception(
        'Rep target not found for lift: $liftId, intensity: $intensity',
      );
    }
  }
}

