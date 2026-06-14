# Data Model

## Goal

The data model should mirror the workbook closely enough that every visible training concept has a typed home in the app. 
That includes lifts, training maxes, weekly templates, calculated prescriptions, last-set logging, notes, video links, and progression outcomes. 

## Core enums

Recommended enums:
- `LiftCategory` = main, auxiliary, accessory
- `ProgramFrequency` = two, three, four, five, six
- `MaxSourceType` = manual, estimated, imported
- `WorkoutStatus` = planned, inProgress, completed, skipped
- `ProgressOutcome` = belowBy2, belowBy1, hit, plus1, plus2, plus3, plus4, plus5

## Core models

### Lift

Represents one exercise definition.

Suggested fields:
- `id`
- `name`
- `displayName`
- `category`
- `isMainLift`
- `isAuxiliaryLift`
- `defaultOrder`
- `usesTrainingMax`

The initial seeded lift list should include Squat, Bankdruecken, Deadlift, Schulterdruecken, Leg Press, Wider Stance Squat, DB Bench, Incline DB Press, Trap Bar Deadlift, and DB Schulterdruecken. 

### TrainingMax

Represents the active max used for calculations.

Suggested fields:
- `id`
- `liftId`
- `value`
- `singleEightPercentage`
- `sourceType`
- `effectiveDate`
- `notes`

Quick Setup shows max values paired with a “single 8 percentage” value of 0.9 for both main and listed auxiliary lifts. 

### Program

Represents the current plan configuration.

Suggested fields:
- `id`
- `name`
- `frequency`
- `currentWeek`
- `totalWeeks`
- `isActive`
- `createdAt`
- `updatedAt`

The workbook structure clearly uses a 21-week program length. 

### WorkoutWeek

Represents one generated week in a program.

Suggested fields:
- `id`
- `programId`
- `weekNumber`
- `displayLabel`
- `startDate`
- `endDate`

### WorkoutDay

Represents a generated training day.

Suggested fields:
- `id`
- `workoutWeekId`
- `dayIndex`
- `title`
- `status`
- `completedAt`

The workbook has dedicated day layouts inside the frequency sheets, including Day 1 and Day 2 in 2x and additional day sections in higher-frequency sheets. 

### ExercisePrescription

Represents the planned training instruction for one lift on one workout day.

Suggested fields:
- `id`
- `workoutDayId`
- `liftId`
- `trainingMaxSnapshot`
- `intensity`
- `workingWeight`
- `repsPerNormalSet`
- `repOutTarget`
- `setGoal`
- `displayOrder`
- `isPrimaryBlock`

These fields come directly from the repeated workbook row structure. 

### ExerciseLog

Represents the performed result for one exercise.

Suggested fields:
- `id`
- `prescriptionId`
- `completedSets`
- `repsOnLastSet`
- `notes`
- `videoUrl`
- `completedAt`

The workbook explicitly includes “Reps on last set,” “Video,” and “Notes” as logging fields. 

### ProgressAdjustment

Represents the lookup rule used after performance is logged.

Suggested fields:
- `id`
- `liftId`
- `outcome`
- `delta`
- `appliesToCycle`
- `appliesToTrainingMax`

The workbook shows fixed delta values from -0.05 through +0.03 based on how far below or above the target the user finishes. 

### IntensityPoint

Represents one lookup value for one lift and week.

Suggested fields:
- `id`
- `liftId`
- `weekNumber`
- `intensity`

The workbook uses week-indexed intensity values across all 21 weeks. 

### RepTargetPoint

Represents lookup data for normal-set and last-set targets.

Suggested fields:
- `id`
- `liftId`
- `intensity`
- `normalSetTarget`
- `lastSetTarget`

The workbook contains both a normal set rep target table and a last set rep target table. 

### FrequencyTemplate

Represents the structural layout of a training frequency.

Suggested fields:
- `id`
- `frequency`
- `dayIndex`
- `liftId`
- `defaultOrder`
- `blockType`

Separate workbook sheets exist for 2x, 3x, 4x, 5x, and 6x structures. 

### AppSettings

Suggested fields:
- `id`
- `weightUnit`
- `roundingMode`
- `roundingIncrement`
- `themeMode`
- `restTimerSeconds`
- `showVideoField`
- `showNotesField`

## Persistence notes

Persist:
- lifts
- training maxes
- programs
- generated workout weeks
- generated workout days
- prescriptions
- exercise logs
- progression results
- settings

Prefer storing generated prescriptions once a cycle is created, while keeping lookup tables separate and versionable.

## Naming notes

Normalize German workbook names into stable internal IDs but keep user-facing display strings flexible.
For example, `bankdruecken` can map to display text “Bench Press” or “Bankdruecken,” depending on app language.
Do not rely on spreadsheet column names as runtime identifiers.