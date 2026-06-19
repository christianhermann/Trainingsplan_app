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
  six;

  /// Parse a stored string to a [ProgramFrequency].
  ///
  /// Accepted values: 'two', 'three', 'four', 'five', 'six'.
  /// Unknown values fall back to [three].
  static ProgramFrequency fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'two':
        return ProgramFrequency.two;
      case 'three':
        return ProgramFrequency.three;
      case 'four':
        return ProgramFrequency.four;
      case 'five':
        return ProgramFrequency.five;
      case 'six':
        return ProgramFrequency.six;
      default:
        return ProgramFrequency.three;
    }
  }
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
  skipped;

  /// Parse a stored string to a [WorkoutStatus].
  ///
  /// Accepted values (case-insensitive): 'planned', 'inprogress', 'completed', 'skipped'.
  /// Unknown values fall back to [planned].
  static WorkoutStatus fromString(String? value) {
    switch (value?.toLowerCase().trim()) {
      case 'planned':
        return WorkoutStatus.planned;
      case 'inprogress':
        return WorkoutStatus.inProgress;
      case 'completed':
        return WorkoutStatus.completed;
      case 'skipped':
        return WorkoutStatus.skipped;
      default:
        return WorkoutStatus.planned;
    }
  }
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
