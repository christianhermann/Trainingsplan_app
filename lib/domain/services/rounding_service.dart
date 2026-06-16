import '../models/app_settings.dart';

class RoundingService {
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
      'ceil'  => (divisor.ceil()  * roundingIncrement),
      'round' => (divisor.round() * roundingIncrement),
      _ => throw ArgumentError(
        'Invalid rounding mode: $roundingMode. Must be floor, ceil, or round.',
      ),
    };
    return double.parse(rounded.toStringAsFixed(2));
  }

  double roundWeightWithSettings(double weight, AppSettings settings) =>
      roundWeight(weight, settings.roundingIncrement, settings.roundingMode);
}
