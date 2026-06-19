import '../models/enums.dart';

/// Rounds a working weight to the nearest plate-friendly increment.
class RoundingService {
  const RoundingService();

  /// Round [weight] to the nearest multiple of [increment] using [mode].
  ///
  /// [increment] must be > 0 (e.g. 2.5 kg barbell, 1.0 kg dumbbells).
  /// Returns a value rounded to 2 decimal places.
  ///
  /// Examples (increment = 2.5):
  ///   round(88.1, nearest, 2.5) -> 87.5
  ///   round(88.1, floor,   2.5) -> 87.5
  ///   round(88.1, ceiling, 2.5) -> 90.0
  double round(double weight, RoundingMode mode, double increment) {
    assert(increment > 0, 'Rounding increment must be > 0, got $increment');
    final divisor = weight / increment;
    final rounded = switch (mode) {
      RoundingMode.nearest => divisor.round()  * increment,
      RoundingMode.floor   => divisor.floor()  * increment,
      RoundingMode.ceiling => divisor.ceil()   * increment,
    };
    return double.parse(rounded.toStringAsFixed(2));
  }
}
