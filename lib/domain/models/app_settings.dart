/// Represents user preferences and app configuration.
class AppSettings {
  final String id;
  final String weightUnit;
  final String roundingMode;
  final double roundingIncrement;
  final String themeMode;
  final int restTimerSeconds;
  final bool showVideoField;
  final bool showNotesField;

  const AppSettings({
    required this.id,
    required this.weightUnit,
    required this.roundingMode,
    required this.roundingIncrement,
    required this.themeMode,
    required this.restTimerSeconds,
    required this.showVideoField,
    required this.showNotesField,
  });

  AppSettings copyWith({
    String? id,
    String? weightUnit,
    String? roundingMode,
    double? roundingIncrement,
    String? themeMode,
    int? restTimerSeconds,
    bool? showVideoField,
    bool? showNotesField,
  }) {
    return AppSettings(
      id: id ?? this.id,
      weightUnit: weightUnit ?? this.weightUnit,
      roundingMode: roundingMode ?? this.roundingMode,
      roundingIncrement: roundingIncrement ?? this.roundingIncrement,
      themeMode: themeMode ?? this.themeMode,
      restTimerSeconds: restTimerSeconds ?? this.restTimerSeconds,
      showVideoField: showVideoField ?? this.showVideoField,
      showNotesField: showNotesField ?? this.showNotesField,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is AppSettings &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          weightUnit == other.weightUnit &&
          roundingMode == other.roundingMode &&
          roundingIncrement == other.roundingIncrement &&
          themeMode == other.themeMode &&
          restTimerSeconds == other.restTimerSeconds &&
          showVideoField == other.showVideoField &&
          showNotesField == other.showNotesField;

  @override
  int get hashCode =>
      id.hashCode ^
      weightUnit.hashCode ^
      roundingMode.hashCode ^
      roundingIncrement.hashCode ^
      themeMode.hashCode ^
      restTimerSeconds.hashCode ^
      showVideoField.hashCode ^
      showNotesField.hashCode;

  @override
  String toString() =>
      'AppSettings(id: $id, weightUnit: $weightUnit, roundingMode: $roundingMode, roundingIncrement: $roundingIncrement, themeMode: $themeMode, restTimerSeconds: $restTimerSeconds, showVideoField: $showVideoField, showNotesField: $showNotesField)';
}
