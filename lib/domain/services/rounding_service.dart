import '../models/app_settings.dart';

/// Rounds calculated weights according to user preferences.
/// Supports multiple rounding modes: floor, round, ceil.
/// Uses a configurable increment (e.g., 2.5 kg, 5 lbs).
abstract class RoundingService {
  /// Rounds a weight value according to the specified mode and increment.
  /// 
  /// Parameters:
  ///   - weight: The weight to round
  ///   - roundingIncrement: The increment to round to (e.g., 2.5 for 2.5 kg)
  ///   - roundingMode: 'floor', 'round', or 'ceil'
  /// 
  /// Returns the rounded weight.
  double roundWeight(
    double weight,
    double roundingIncrement,
    String roundingMode,
  );
}

/// Default implementation of RoundingService.
class DefaultRoundingService implements RoundingService {
  @override
  double roundWeight(
    double weight,
    double roundingIncrement,
    String roundingMode,
  ) {
    if (roundingIncrement <= 0) {
      throw ArgumentError('Rounding increment must be greater than 0');
    }

    final divisor = weight / roundingIncrement;

    final rounded = switch (roundingMode.toLowerCase()) {
      'floor' => (divisor.floor() * roundingIncrement),
      'ceil' => (divisor.ceil() * roundingIncrement),
      'round' => (divisor.round() * roundingIncrement),
      _ => throw ArgumentError(
        'Invalid rounding mode: $roundingMode. Must be floor, ceil, or round.',
      ),
    };

    // Clean up floating point precision errors
    return double.parse(rounded.toStringAsFixed(2));
  }

  /// Convenience method that extracts rounding settings from AppSettings.
  double roundWeightWithSettings(
    double weight,
    AppSettings settings,
  ) {
    return roundWeight(weight, settings.roundingIncrement, settings.roundingMode);
  }
}


