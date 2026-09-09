# Copilot Instructions

## Project context

This repository is a Flutter Android app that converts a structured Excel-based strength training workbook into a native mobile application.

This is not a generic workout tracker.
It is a workbook-to-app conversion project.
Preserve workbook logic and app consistency over speed or creativity.

## Required reference docs

Before generating code for this project, always consult these files:

- `docs/app-overview.md`
- `docs/workbook-logic.md`
- `docs/data-model.md`
- `docs/ui-guidelines.md`
- `docs/lookup-tables-implementation.md`

Use them as follows:
- For training calculations and progression rules, use `docs/workbook-logic.md` as the primary reference.
- For entities, persistence, and naming, use `docs/data-model.md`.
- For screen structure and visual decisions, use `docs/ui-guidelines.md`.
- For lookup table implementation status, use `docs/lookup-tables-implementation.md`.
- For overall product scope and architecture intent, use `docs/app-overview.md`.

If anything is unclear, do not guess silently.
Leave a clear TODO and mention which open question or missing rule caused the uncertainty.

## Core product rules

Build a mobile-first Android app in Flutter.

Use these defaults unless explicitly changed:
- Flutter
- Dart
- Riverpod for state management
- Drift with SQLite for local persistence
- Material 3 with a custom dark theme

Do not build this as:
- a spreadsheet viewer
- a WebView wrapper
- a generic fitness app
- a web-first dashboard

## Screens

The app should be organized around these main screens:
- Setup
- Today Workout / Timer
- History
- Settings

Favor fast workout execution and logging over decorative UI.

## Architecture

Use a feature-first clean structure.

Preferred folders:
- `lib/app/`
- `lib/features/setup/`
- `lib/features/workout/`
- `lib/features/history/`
- `lib/features/settings/`
- `lib/features/training_max/`
- `lib/data/`
- `lib/domain/`

Keep business logic out of widgets.

Separate:
- domain models
- repositories
- calculation services
- persistence layer
- presentation layer

## Coding rules

- Write small, readable, strongly typed Dart code.
- Prefer explicit names over short or clever names.
- Use immutable models where practical.
- Use `copyWith` for state updates where appropriate.
- Keep nullability intentional.
- Avoid `Map<String, dynamic>` when a typed model is better.
- Keep methods focused and short.
- Avoid hidden logic in UI widgets.

## Training logic rules

The workbook is the source of truth for training behavior.

Do not invent or simplify workbook logic when the rules are already documented.
Use dedicated services for calculations.

Preferred services:
- `IntensityLookupService`
- `RepTargetLookupService`
- `ProgressionService`
- `WorkoutGenerationService`
- `RoundingService`

The calculation layer should handle:
- weekly intensity lookup
- normal set rep target lookup
- last set rep target lookup
- working weight calculation
- rounding
- set-goal generation
- progression adjustments from logged performance

## Data modeling rules

Use strongly typed models for at least:
- `Lift`
- `TrainingMax`
- `Program`
- `ProgramFrequency`
- `WorkoutWeek`
- `WorkoutDay`
- `ExercisePrescription`
- `ExerciseLog`
- `AppSettings`

Match workbook concepts closely.
Do not rename concepts casually once established.

## Persistence rules

Persist:
- user settings
- training maxes
- selected frequency
- generated workouts
- completed workout logs
- notes
- video links
- progression results
- current cycle state

Use local-first storage for MVP.

Do not add cloud sync unless explicitly requested.

## UI rules

The UI should be:
- dark
- clean
- card-based
- mobile-first
- practical

Prioritize:
- readable working weights
- easy last-set logging
- fast navigation
- large tap targets
- clear distinction between main lifts and accessories

Avoid:
- spreadsheet-like cramped layouts
- dashboard clutter
- tiny controls
- unnecessary animations

## Testing rules

Write tests for business logic before polishing edge-case UI behavior.

At minimum, cover:
- intensity lookup
- rep target lookup
- rounding
- workout generation by frequency
- progression adjustments
- model serialization

## How to respond when generating code

When generating code:
1. State the filename.
2. Briefly explain the file’s role.
3. Output complete compilable code.
4. Keep imports clean.
5. Do not leave placeholder logic unless explicitly requested.

When uncertain:
- do not guess silently
- reference the relevant docs
- leave a TODO with the unresolved point

## MVP priority order

Build in this order:
1. project foundation
2. theme and routing
3. domain models
4. persistence models
5. calculation engine
6. setup flow
7. today workout screen
8. logging flow
9. history screen
10. settings
11. workbook import

## Final instruction

Favor correctness of training logic over speed of generation.
Use the repository docs actively before proposing architecture, UI, models, or calculation code.