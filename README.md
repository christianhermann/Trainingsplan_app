# Trainingsplan

A Flutter Android app that converts a structured Excel-based strength training workbook ("SBS Linear Progression") into a native mobile experience.

## What it does

- Set up your training maxes, frequency (2x–6x/week), and auxiliary lift choices
- Auto-generate a 21-week program with calculated working weights and rep targets
- Log each workout — sets completed, reps on last set, notes, video links
- Progression adjusts your training max after every session based on performance
- Review session history and per-lift progression curves
- Import / export your data as JSON backup

## Architecture

Local-first, no cloud sync.

| Layer | Technology |
|-------|------------|
| UI | Flutter, Material 3 (dark theme) |
| State | Riverpod |
| Persistence | Drift + SQLite |
| Navigation | Go Router |

Feature-first folder structure under `lib/`:

```
lib/
  app/          — MaterialApp, router, theme
  features/     — setup, workout, history, settings, training_max
  data/         — repositories, seeders, persistence
  domain/       — models, pure calculation services
```

All training math lives in pure, testable domain services — never in widgets.

## Workbook fidelity

The workbook is the source of truth. All calculation rules (intensity, rep targets, progression deltas, rounding) are implemented verbatim from the spreadsheet. See `docs/workbook--logic.md` for the full spec.

## Getting started

```bash
flutter pub get
flutter run
```

## Testing

```bash
flutter test
```

Covers progression logic, rep-target lookup, and workout generation.
