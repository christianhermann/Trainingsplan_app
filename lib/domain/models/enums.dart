/// Lift category classification.
enum LiftCategory {
  main,
  auxiliary,
  accessory,
}

/// Training frequency (workouts per week).
enum ProgramFrequency {
  two,
  three,
  four,
  five,
  six,
}

/// Source of training max value.
enum MaxSourceType {
  manual,
  estimated,
  imported,
}

/// Workout day status.
enum WorkoutStatus {
  planned,
  inProgress,
  completed,
  skipped,
}

/// Result outcome after logging performance against rep target.
enum ProgressOutcome {
  belowBy2,
  belowBy1,
  hit,
  plus1,
  plus2,
  plus3,
  plus4,
  plus5,
}

/// How a working weight is rounded to the nearest plate-friendly value.
///
/// Stored in [AppSettingsTable] as a lowercase string.
/// Use [RoundingMode.fromString] to parse the DB value.
enum RoundingMode {
  /// Round to the nearest multiple of the increment (0.5 goes up).
  nearest,

  /// Always round down to the nearest multiple of the increment.
  floor,

  /// Always round up to the nearest multiple of the increment.
  ceiling;

  /// Parse a stored string to a [RoundingMode].
  ///
  /// Accepted values (case-insensitive):
  ///   'nearest', 'round'           → [nearest]
  ///   'floor'                      → [floor]
  ///   'ceiling', 'ceil'            → [ceiling]
  ///
  /// Unknown values fall back to [nearest].
  static RoundingMode fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'nearest':
      case 'round':
        return RoundingMode.nearest;
      case 'floor':
        return RoundingMode.floor;
      case 'ceiling':
      case 'ceil':
        return RoundingMode.ceiling;
      default:
        return RoundingMode.nearest;
    }
  }

  /// The canonical string persisted to the DB.
  String get storedValue => name; // 'nearest', 'floor', 'ceiling'
}
