# Workbook Logic

## Source structure

The workbook contains a Quick Setup area, a Setup sheet, an Untouched reference sheet, and separate weekly frequency templates for 2x, 3x, 4x, 5x, and 6x training. 
It also contains tables for intensity, normal set rep targets, last set rep targets, and progression adjustments based on performance. 

## Main lifts

The core main lifts are:
- Squat
- Bankdruecken
- Deadlift
- Schulterdruecken 

In Quick Setup, each main lift has a max value and a “single 8 percentage” value of 0.9 shown beside it. 

## Auxiliary lifts

The workbook defines these auxiliary lift slots and defaults:
- Squat auxiliary 1 = Leg Press
- Squat auxiliary 2 = Wider Stance Squat
- Bench auxiliary 1 = DB Bench
- Bench auxiliary 2 = Incline DB Press
- Deadlift auxiliary = Trap Bar Deadlift
- OHP auxiliary = DB Schulterdruecken 

These auxiliary lifts also have max values and a “single 8 percentage” value of 0.9 in Quick Setup. 

## Intensity logic

The workbook includes a 21-week intensity table for each lift. 
For main lifts, the visible weekly pattern is 0.70, 0.725, 0.75, 0.725, 0.75, 0.775, 0.60, then later waves repeat and eventually reach 0.825 before returning to 0.60 in week 21. 
For the listed auxiliary lifts, the visible weekly pattern starts at 0.65, 0.675, 0.70, 0.675, 0.70, 0.725, 0.55 and later climbs to 0.775 before returning to 0.55 in week 21. 

## Rep targets

The workbook has a “Normal set rep target” table indexed by intensity. 
For main lifts, visible examples include 10 reps at 0.70, 9 reps at 0.725, 8 reps at 0.75, 7 reps at 0.775, 6 reps at 0.80, and 5 reps at 0.825. 
For auxiliary lifts, visible examples include 12 reps at 0.65, 11 reps at 0.675, 10 reps at 0.70, 9 reps at 0.725, 8 reps at 0.75, and 7 reps at 0.775. 

The workbook also has a “Last set rep target” table. 
For main lifts, visible examples include 12 reps at 0.70, 11 reps at 0.725, 10 reps at 0.75, 9 reps at 0.775, 8 reps at 0.80, and 6 reps at 0.825. 
For auxiliary lifts, visible examples include 15 reps at 0.65, 13 reps at 0.675, 12 reps at 0.70, 11 reps at 0.725, 10 reps at 0.75, and 9 reps at 0.775. 

## Set goals

The visible setup tables show 4 sets for both main and listed auxiliary lifts. 
That set count appears repeatedly across the generated weekly prescription rows. 

## Progression adjustments

The workbook includes adjustment columns labeled:
- Below rep target by 2 reps
- Below rep target by 1 rep
- Hit rep target
- Beat by 1 rep
- Beat by 2 reps
- Beat by 3 reps
- Beat by 4 reps
- Beat by 5 reps 

The visible adjustment values are:
- below by 2 = -0.05
- below by 1 = -0.02
- hit = 0
- beat by 1 = 0.005
- beat by 2 = 0.01
- beat by 3 = 0.015
- beat by 4 = 0.02
- beat by 5 = 0.03 

These should be treated as core progression rules and implemented in a dedicated calculation service. 

## Workout row fields

The workbook’s repeated training rows use these fields:
- Weight
- Reps per normal set
- Rep out target
- Set goal
- Reps on last set
- Video
- Notes 

These fields should map directly into the app’s workout prescription and workout log models. 

## Observed examples

The Untouched sheet shows examples such as Squat with TM 85 producing week 1 work of 60 kg for 10 reps per normal set, a rep-out target of 12, and 4 sets. 
It also shows Bench with TM 85 producing 60 kg, Deadlift with TM 110 producing 78 kg, and Schulterdruecken with TM 45 producing 32 kg in comparable week-1 rows. 
For auxiliaries, examples include Leg Press TM 230 producing 150, DB Bench TM 75 producing 48, Incline DB Press TM 60 producing 40, and Trap Bar Deadlift TM 113 producing 74 in early rows. 

## Implementation guidance

The app should calculate prescriptions from normalized lookup data rather than trying to execute spreadsheet formulas at runtime.
The workbook should be treated as the source of truth for training behavior.
Any ambiguity should be documented explicitly instead of guessed silently.