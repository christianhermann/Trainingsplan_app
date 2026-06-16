import '../models/app_settings.dart';
import '../models/enums.dart';

/// Rounds a working weight to the nearest plate-friendly increment.
///
/// Primary API: [round] — uses the typed [RoundingMode] enum.
///
/// Legacy shims kept for backward compatibility:
///   [roundWeight]             — accepts String mode.
///   [roundWeightWithSettings] — accepts [AppSettings] domain model.
class RoundingService {
  const RoundingService();

  // ---------------------------------------------------------------------------
  // Primary API
  // ---------------------------------------------------------------------------

  /// Round [weight] to the nearest multiple of [increment] using [mode].
  ///
  /// [increment] must be > 0 (e.g. 2.5 kg for a barbell, 1.0 for dumbbells).
  /// Returns a value rounded to 2 decimal places.
  ///
  /// Examples (increment = 2.5):
  ///   round(88.1, nearest, 2.5) → 87.5
  ///   round(88.1, floor,   2.5) → 87.5
  ///   round(88.1, ceiling, 2.5) → 90.0
  ///   round(87.5, nearest, 2.5) → 87.5  (exact — no change)
  double round(double weight, RoundingMode mode, double increment) {
    _validateIncrement(increment);
    final divisor = weight / increment;
    final rounded = switch (mode) {
      RoundingMode.nearest => divisor.round() * increment,
      RoundingMode.floor   => divisor.floor() * increment,
      RoundingMode.ceiling => divisor.ceil()  * increment,
    };
    return double.parse(rounded.toStringAsFixed(2));
  }

  // ---------------------------------------------------------------------------
  // Backward-compat shims
  // ---------------------------------------------------------------------------

  /// Legacy shim — accepts a String mode and delegates to [round].
  ///
  /// Accepts: 'round', 'nearest', 'floor', 'ceil', 'ceiling' (case-insensitive).
  double roundWeight(
    double weight,
    double roundingIncrement,
    String roundingMode,
  ) =>
      round(weight, RoundingMode.fromString(roundingMode), roundingIncrement);

  /// Convenience overload that reads mode and increment from [AppSettings].
  double roundWeightWithSettings(double weight, AppSettings settings) =>
      round(
        weight,
        RoundingMode.fromString(settings.roundingMode),
        settings.roundingIncrement,
      );

  // ---------------------------------------------------------------------------

  void _validateIncrement(double increment) {
    if (increment <= 0) {
      throw ArgumentError(
          'Rounding increment must be > 0, got $increment');
    }
  }
}
