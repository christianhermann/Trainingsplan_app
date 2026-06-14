import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:trainingsplan_app/domain/models/enums.dart';

/// State for Setup screen.
class SetupState {
  final ProgramFrequency? selectedFrequency;
  final Map<String, double> trainingMaxes; // liftId -> max value
  final bool isValid;
  final String? errorMessage;

  const SetupState({
    this.selectedFrequency,
    this.trainingMaxes = const {},
    this.isValid = false,
    this.errorMessage,
  });

  SetupState copyWith({
    ProgramFrequency? selectedFrequency,
    Map<String, double>? trainingMaxes,
    bool? isValid,
    String? errorMessage,
  }) {
    return SetupState(
      selectedFrequency: selectedFrequency ?? this.selectedFrequency,
      trainingMaxes: trainingMaxes ?? this.trainingMaxes,
      isValid: isValid ?? this.isValid,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  @override
  String toString() =>
      'SetupState(frequency: $selectedFrequency, maxes: ${trainingMaxes.length}, valid: $isValid)';
}

/// Notifier for Setup screen state.
class SetupNotifier extends StateNotifier<SetupState> {
  SetupNotifier() : super(const SetupState());

  /// Select training frequency.
  void selectFrequency(ProgramFrequency frequency) {
    state = state.copyWith(
      selectedFrequency: frequency,
      errorMessage: null,
    );
    _validate();
  }

  /// Update training max for a lift.
  void updateTrainingMax(String liftId, double value) {
    final newMaxes = {...state.trainingMaxes};
    if (value > 0) {
      newMaxes[liftId] = value;
    } else {
      newMaxes.remove(liftId);
    }
    state = state.copyWith(trainingMaxes: newMaxes);
    _validate();
  }

  /// Clear all training maxes.
  void clearAllMaxes() {
    state = state.copyWith(trainingMaxes: {});
    _validate();
  }

  /// Validate setup is complete.
  void _validate() {
    final isValid = state.selectedFrequency != null &&
        state.trainingMaxes.isNotEmpty &&
        _hasAllMainLifts();

    state = state.copyWith(
      isValid: isValid,
      errorMessage: _getValidationError(),
    );
  }

  /// Check if all main lifts have maxes.
  bool _hasAllMainLifts() {
    const mainLifts = ['squat', 'bench_press', 'deadlift', 'overhead_press'];
    return mainLifts.every((lift) => state.trainingMaxes.containsKey(lift));
  }

  /// Get validation error message.
  String? _getValidationError() {
    if (state.selectedFrequency == null) {
      return 'Please select a training frequency';
    }

    const mainLifts = ['squat', 'bench_press', 'deadlift', 'overhead_press'];
    final missing = mainLifts
        .where((lift) => !state.trainingMaxes.containsKey(lift))
        .toList();

    if (missing.isNotEmpty) {
      return 'Missing maxes for: ${missing.join(", ")}';
    }

    if (state.trainingMaxes.values.any((v) => v <= 0)) {
      return 'All maxes must be greater than 0';
    }

    return null;
  }
}

/// Setup screen state provider using Riverpod.
final setupProvider = StateNotifierProvider<SetupNotifier, SetupState>((ref) {
  return SetupNotifier();
});
