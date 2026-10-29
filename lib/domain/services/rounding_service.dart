import '../models/enums.dart';

/// Round [weight] to the nearest multiple of [increment] using [mode].
double roundWeight(double weight, RoundingMode mode, double increment) {
  assert(increment > 0, 'Rounding increment must be > 0, got $increment');
  final divisor = weight / increment;
  final rounded = switch (mode) {
    RoundingMode.nearest => divisor.round() * increment,
    RoundingMode.floor   => divisor.floor() * increment,
    RoundingMode.ceiling => divisor.ceil() * increment,
  };
  return (rounded * 100).roundToDouble() / 100;
}

class RoundingService {
  const RoundingService();
  double round(double weight, RoundingMode mode, double increment) =>
      roundWeight(weight, mode, increment);
}
