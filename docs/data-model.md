# Data Model

The data model mirrors the workbook concepts used by the app.

## Main entities

- **Lift** — stable key, display name, category, and training-max behavior.
- **TrainingMax** — lift value, single-at-8 percentage, source, date, and
  history.
- **Program** — frequency, current week, total weeks, and active state.
- **WorkoutWeek** — generated week belonging to a program.
- **WorkoutDay** — day index, title, status, and completion time.
- **ExercisePrescription** — lift, training-max snapshot, intensity, working
  weight, rep target, set goal, order, and block type.
- **ExerciseLog** — completed sets, last-set reps, notes, video URL, and
  completion time.
- **AppSettings** — units, rounding, theme, timer, and optional fields.

## Stable naming

Database lift names are stable internal keys such as `squat`,
`bench_press`, `deadlift`, and `overhead_press`. Display names can be changed
without changing the training logic.

## Persistence

The local Drift/SQLite database stores:

- seeded lift definitions and progression rules
- training-max history
- active programs and generated weeks
- workout days and prescriptions
- completed logs
- app settings

JSON backup and restore operate on this local data.
