# Open Questions

## Purpose

This file tracks product and logic questions that are not fully resolved from the workbook alone.
When a question is answered, move the decision into the relevant source doc and remove it from here.

## Training logic questions

### 1. Training max semantics
Quick Setup shows a max for each lift and a “single 8 percentage” value of 0.9. 
Do we treat the entered max as an actual max, a training max, or an estimated single-at-RPE-8 style value that still needs conversion?

### 2. Rounding behavior
Quick Setup references rounding. 
What exact rounding increment should the app use by default, and should that differ for barbells, dumbbells, and machines?

### 3. Progression target
The workbook shows outcome deltas from -0.05 to +0.03. 
Do those deltas modify the stored training max directly, a hidden planning value, or only the next generated cycle?

### 4. Rep-out handling on lower-stress weeks
The general reference tables include last-set rep targets, but some frequency-sheet rows in lower weeks visibly show blank rep-out cells while still showing set goals. 
Should the app suppress rep-out logging on those planned rows, or should it infer a default from the lookup table?

### 5. Deload interpretation
Main-lift intensity visibly drops to 0.60 in weeks 7, 14, and 21, while listed auxiliary lifts drop to 0.55 in those same wave positions. 
Should the UI label these automatically as deload weeks?

## Content questions

### 6. Accessory catalog scope
The workbook clearly names some additional accessory movements such as Latzug, Rudern, T-Bar Rudern, Bizeps Curls, and Trizeps Extension. 
Should the MVP ship with a fixed accessory catalog, or should users be able to create custom accessory exercises from day one?

### 7. Language strategy
The workbook mixes German-style names such as Bankdruecken and Schulterdruecken with English-style names such as Leg Press and Incline DB Press. 
Should the app preserve the original names, translate them, or support both through localization?

## Product questions

### 8. Setup flexibility
Quick Setup includes a note that if the user does not know a max, they can estimate it and should estimate low when in doubt. 
Should the app include an onboarding helper for estimating starting maxes conservatively?

### 9. Import timing
The workbook is detailed enough to justify future import support. 
Do we want import in v1, or should v1 stay manual-entry only so the calculation engine can be validated first?

### 10. History detail
The workbook logs notes and video at the exercise-row level. 
Should history also store per-set data, or is row-level completion enough for MVP?

### 11. Program regeneration
If a user changes a training max mid-cycle, should the app regenerate only future workouts, regenerate the whole cycle, or require the user to start a new cycle?

### 12. Multiple programs
The workbook appears to represent one active program structure at a time. 
Should the app support multiple saved programs in MVP, or only one active plan?

## Technical questions

### 13. Source of truth strategy
Should workbook-derived lookup tables be hard-seeded in code, stored as local JSON assets, or inserted into SQLite on first run?

### 14. Auditability
Do we want a debug screen that shows:
- active intensity
- normal rep target
- last-set target
- applied progression rule
- rounded working weight

This would make workbook validation much easier during development.

## Decision rule

Do not let Copilot guess answers to unresolved questions.
Use explicit TODOs and link back to this file until each decision is confirmed.