# App Overview

## Purpose

Lightweight, Baby! converts the project's structured strength-training
workbook into a native, offline-first Android app. It is a workout execution
and logging tool, not a spreadsheet viewer or a generic fitness tracker.

The plan is derived from the [Stronger by Science Linear Strength
plan](https://www.strongerbyscience.com/) and follows the workbook as its
source of truth.

## Screens

- **Setup** — choose frequency, enter training maxes, choose auxiliary lifts,
  and generate a program.
- **Today** — execute the current workout, use the rest timer, and log results.
- **Plan** — inspect the selected week, training days, exercises, weights, sets,
  and rep targets.
- **History** — review completed sessions and lift history.
- **Settings** — configure the app, back up data, restore data, and reset
  generated training data.

## Training model

The app generates 21 weeks of workouts for 2–6 training days per week. It
stores generated prescriptions locally, including working weight, intensity,
rep target, set goal, and lift ordering.

After a workout is logged, progression rules update the relevant training max
and regenerate only future incomplete prescriptions.

## Technical direction

- Flutter and Dart
- Riverpod for state management
- Drift with SQLite for persistence
- GoRouter for navigation
- Material 3 with a custom dark theme

The project uses a feature-first structure. Domain models, repositories,
persistence, calculation services, and widgets are kept separate so training
logic remains testable.
