# Lightweight, Baby!

Lightweight, Baby! is a local-first Flutter Android app for running a
structured strength-training plan on a phone.

The app turns the concepts from the project's Excel workbook into a practical
mobile workflow:

- configure training frequency and training maxes
- generate a 21-week plan for 2–6 training days per week
- view the current workout and rest timer
- log completed sets, last-set reps, notes, and video links
- apply progression adjustments from logged performance
- review workout history and lift history
- browse the generated plan by week and training day
- export and restore local data as JSON
- configure units, rounding, theme, and timer defaults

## Training method

The workout plan is derived from the **Linear Strength** plan published by
[Stronger by Science](https://www.strongerbyscience.com/). The workbook used
by this project is the runtime reference for lift structure, intensity,
rep targets, rounding, set goals, and progression adjustments.

This project is an independent implementation and is not affiliated with
Stronger by Science.

## Technology

| Area | Technology |
| --- | --- |
| Platform | Flutter / Android |
| Language | Dart |
| UI | Material 3 with a custom dark theme |
| State | Riverpod |
| Persistence | Drift with SQLite |
| Navigation | GoRouter |

The app is local-first and does not require an account or cloud service.

## Project structure

```text
lib/
  app/                 app shell, theme, and routing
  data/                database, seeders, repositories, and backup services
  domain/              models and training calculations
  features/
    history/           workout and lift history
    plan/              generated-plan summary
    settings/          app settings and data management
    setup/             program setup and generation
    training_max/      training-max editing
    workout/           today's workout, timer, and logging
```

Training calculations live in domain services and generated prescriptions are
stored locally so workouts remain available offline.

The detailed workbook rules are documented in
[`docs/workbook--logic.md`](docs/workbook--logic.md).

## Getting started

Requirements:

- Flutter SDK
- Android SDK or an Android device/emulator

```bash
flutter pub get
flutter run
```

## Tests and checks

```bash
flutter analyze
flutter test
```

## Data and privacy

Workout data is stored in the app's local SQLite database. The app does not
send workout data to a remote server. Use the built-in JSON backup tools before
moving or resetting the app.

## Good to know

This app was heavily heavily vibecoded using different Models through Perplexity and Copilot Free.

## License

No open-source license has been selected for this repository yet.
