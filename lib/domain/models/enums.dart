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
