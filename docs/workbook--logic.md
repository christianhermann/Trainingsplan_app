# Workbook Logic

## Source structure

The workbook contains a Quick Setup area, a Setup sheet, an Untouched reference sheet, and separate weekly frequency templates for 2x, 3x, 4x, 5x, and 6x training.
It also contains tables for intensity, rep targets, last set RIR targets, and progression adjustments based on performance.

## Main lifts

The core main lifts are:
- Squat
- Bench Press
- Deadlift
- Push Press (OHP)

In Quick Setup, each main lift has a max value and a "single @8 percentage" value of 0.9.

## Auxiliary lifts

The workbook defines these auxiliary lift slots:
- Squat auxiliary 1 = Front Squat
- Squat auxiliary 2 = Squat
- Bench auxiliary 1 = Close Grip Bench
- Bench auxiliary 2 = Bench Press
- Deadlift auxiliary = Deadlift
- OHP auxiliary = OHP

Back exercises include Barbell rows, DB rows, and Pull-downs. All auxiliary and back lifts share the same max and "single @8 percentage" (0.9) structure as the main lifts.

## Intensity logic

The workbook includes a 21-week intensity table for each lift. Intensity is **flat across all 21 weeks** — the same percentage is prescribed every week, determined by the lift, not the week number.

Verified flat intensity values per lift:

| Lift | Intensity |
|------|-----------|
| Squat (main) | 87.5% |
| Bench Press (main) | 87.5% |
| Deadlift (main) | 87.5% |
| Push Press (main) | 87.5% |
| Front Squat | 82.5% |
| Close Grip Bench | 82.5% |
| Squat (aux) | 75.0% |
| Bench Press (aux) | 75.0% |
| Deadlift (aux) | 75.0% |
| OHP | 75.0% |
| Barbell rows | 75.0% |
| DB rows | 75.0% |
| Pull-downs | 75.0% |

## Rep targets

The workbook has a "Rep target" table indexed by intensity from 50.0% to 100.0%. All visible lifts share the same rep target curve. Selected values:

| Intensity | Reps per set |
|-----------|-------------|
| 75.0% | 8 |
| 77.5% | 7 |
| 80.0% | 6 |
| 82.5% | 5 |
| 85.0% | 4 |
| 87.5% | 3 |

The full lookup table runs from 20 reps at 50.0% down to 1 rep at 100.0%.

## Last set RIR target

The workbook has a "Last set RIR target" table, also indexed by intensity. **The RIR target is 0 for every lift at every intensity level.** This means the last set of every exercise is always performed to near-failure (0 reps in reserve). There is no varying last-set RIR by week or by intensity — it is a program constant.

## Set count

All lifts are prescribed **3 sets** per session, visible consistently across the generated weekly rows. This is implemented as the constant `WorkoutGenerationService.kSetGoal = 3`.

## Progression logic

Progression is determined by comparing the **reps achieved on the last set against the rep goal per set**. The workbook column headers explicitly state:

> "1 fewer set completed **or last set below RIR target**"

Since the RIR target is always 0, "last set below RIR target" means the user stopped before reaching failure on the last set. The progression outcomes and their training max deltas are:

| Outcome | Dart enum | Condition | TM Delta |
|---------|-----------|-----------|----------|
| Failed 2+ sets | `belowBy2` | 2+ fewer sets completed | −5.00% |
| Failed 1 set or below RIR | `belowBy1` | 1 fewer set completed, or last set stopped before failure | −2.00% |
| Hit target | `hit` | All sets completed; last set reached failure (delta reps = 0) | 0.00% |
| Plus 1 | `plus1` | 1 rep above rep goal on last set | +1.00% |
| Plus 2 | `plus2` | 2 reps above rep goal on last set | +3.00% |
| Plus 3 | `plus3` | 3 reps above rep goal on last set | +5.00% |
| Plus 4 | `plus4` | 4 reps above rep goal on last set | +5.00% |
| Plus 5+ | `plus5` | 5+ reps above rep goal on last set | +5.00% |

Because RIR target = 0, "reps above RIR target on last set" equals **extra reps performed beyond the prescribed rep goal** on the last set. For example, if the rep goal is 8 and the user does 10, that is `plus2` (+3.00%).

## Workout row fields

The workbook's weekly training rows expose these fields per exercise:
- Intensity (% of training max)
- Reps per set (from rep target lookup)
- Last set RIR target (always 0 — program constant)
- Sets (always 3)
- Logged reps on last set (user input)
- Progression outcome (derived from logged vs. target)

## Observed examples

The extracted workbook shows Bench Press TM 100 → 87.5 kg for 3 reps × 3 sets, Front Squat TM 125 → 102.5 kg for 5 reps × 3 sets, and Squat TM 150 → 112.5 kg for 8 reps × 3 sets. These are consistent with flat intensity and the shared rep target curve above.

## Implementation guidance

- Intensity is a **constant per lift** — do not vary it by week number.
- The last set RIR target is always **0** — store as a program constant, not a lookup table.
- Set count is always **3** — use `WorkoutGenerationService.kSetGoal`.
- Progression is driven solely by **reps logged on the last set vs. the rep goal**: delta reps = `lastSetReps − repGoal`, capped at +5 for the maximum adjustment.
- The app should calculate prescriptions from the intensity and rep-target lookup tables and apply the TM delta after each session is logged.
- The workbook is the source of truth; any ambiguity should be documented explicitly rather than guessed silently.
