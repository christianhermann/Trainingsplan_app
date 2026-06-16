# Lookup Tables Implementation

## Overview

The app uses four primary lookup tables that seed from the workbook:
1. **Intensity Points** — flat per-lift intensity, identical across all 21 weeks
2. **Rep Target Points** — reps per set indexed by intensity
3. **Progression Adjustments** — last-set outcome → training max delta
4. **Frequency Templates** — which lifts appear on which days per frequency

---

## 1. Intensity Points (Per-Lift, All 21 Weeks)

### Location
`lib/data/seeders/intensity_seeder.dart`

### Verified flat values from workbook

Intensity is constant for every week. Seed one record per lift with the same value repeated for weeks 1–21.

| Lift | Intensity |
|------|-----------|
| Squat (main) | 0.875 |
| Bench Press (main) | 0.875 |
| Deadlift (main) | 0.875 |
| Push Press (main) | 0.875 |
| Front Squat | 0.825 |
| Close Grip Bench | 0.825 |
| Squat (aux) | 0.750 |
| Bench Press (aux) | 0.750 |
| Deadlift (aux) | 0.750 |
| OHP | 0.750 |
| Barbell rows | 0.750 |
| DB rows | 0.750 |
| Pull-downs | 0.750 |

All wave-based and deload intensity assumptions from previous documentation are **removed**. There are no week-specific intensity overrides in the visible workbook data.

---

## 2. Rep Target Points (Intensity → Reps per Set)

### Location
`lib/data/seeders/rep_target_seeder.dart`

### Verified values from workbook

All lifts share the same rep target curve. The full workbook table runs from 50.0% to 100.0% in 2.5% steps.

| Intensity | Reps per set |
|-----------|-------------|
| 0.500 | 20 |
| 0.525 | 18 |
| 0.550 | 16 |
| 0.575 | 15 |
| 0.600 | 14 |
| 0.625 | 13 |
| 0.650 | 12 |
| 0.675 | 11 |
| 0.700 | 10 |
| 0.725 | 9 |
| 0.750 | 8 |
| 0.775 | 7 |
| 0.800 | 6 |
| 0.825 | 5 |
| 0.850 | 4 |
| 0.875 | 3 |
| 0.900 | 2 |
| 0.925 | 2 |
| 0.950 | 1 |
| 0.975 | 1 |
| 1.000 | 1 |

### Last set RIR target

The last set RIR target is **always 0** for all lifts at all intensities. This is a program constant — no lookup table is needed.

```dart
static const int lastSetRirTarget = 0;
```

---

## 3. Progression Adjustments (Last-Set Outcome → TM Delta)

### Location
`lib/data/seeders/progression_adjustment_seeder.dart`

### Logic

Progression is determined by comparing the **reps logged on the last set** against the **rep goal for that set** (from the rep target lookup). Because the RIR target is always 0, the user is always expected to go to near-failure.

```
deltaReps = lastSetReps − repGoal
```

| Outcome enum | Condition | TM Delta |
|--------------|-----------|----------|
| `failedSets2Plus` | 2 or more sets not completed | −5.00% |
| `failedSets1OrBelowRIR` | 1 set not completed, **or** last set stopped before failure (deltaReps < 0) | −2.00% |
| `hitTarget` | All sets done; deltaReps = 0 | 0.00% |
| `plus1` | deltaReps = +1 | +1.00% |
| `plus2` | deltaReps = +2 | +3.00% |
| `plus3` | deltaReps = +3 | +5.00% |
| `plus4` | deltaReps = +4 | +5.00% |
| `plus5` | deltaReps ≥ +5 | +5.00% |

Applied as: `newTM = currentTM × (1 + delta)`, then rounded to nearest 2.5 kg.

**Example:** TM = 100 kg, repGoal = 3, lastSetReps = 5 → deltaReps = +2 → `plus2` → +3% → new TM = 103 kg.

### Implementation note

The app must capture two fields per logged session:
1. `setsCompleted` — to resolve the `failedSets2Plus` and `failedSets1OrBelowRIR` set-failure branches.
2. `lastSetReps` — to derive `deltaReps` and select the RIR-based outcome branch.

The `failedSets1OrBelowRIR` branch fires when either `setsCompleted < setGoal - 1` OR `deltaReps < 0` (stopped before hitting the prescribed rep count on the last set).

---

## 4. Frequency Templates (Workout Structure)

### Location
`lib/data/seeders/frequency_template_seeder.dart`

### Status

The workbook contains 2x, 3x, 4x, 5x, and 6x frequency sheets. Day layouts still require separate extraction from those sheets before the seeder can be fully populated.

---

## Implementation Status

| Component | Status | Confidence |
|-----------|--------|------------|
| Intensity — flat values (all lifts, all weeks) | ✅ Verified | High |
| Rep target curve (50%–100%, 21 steps) | ✅ Verified | High |
| Last set RIR target = 0 (program constant) | ✅ Verified | High |
| Progression: last-set reps vs. rep goal | ✅ Verified | High |
| Progression delta table (8 outcomes) | ✅ Verified | High |
| Frequency templates (2x–6x day layouts) | ⚠️ Needs extraction | Low |

---

## Testing Recommendations

1. **Intensity seed test** — assert identical intensity value for all 21 weeks for every seeded lift.
2. **Rep target lookup** — test exact matches: 0.875 → 3 reps, 0.825 → 5 reps, 0.750 → 8 reps.
3. **RIR constant** — assert `lastSetRirTarget == 0` everywhere it is referenced.
4. **Progression outcome derivation** — test all 8 branches with concrete (repGoal, lastSetReps) inputs:
   - `(3, 3)` → `hitTarget` → 0%
   - `(3, 4)` → `plus1` → +1%
   - `(3, 5)` → `plus2` → +3%
   - `(3, 6)` → `plus3` → +5%
   - `(3, 2)` → `failedSets1OrBelowRIR` → −2% (stopped before failure)
   - Sets missed → `failedSets2Plus` or `failedSets1OrBelowRIR` as appropriate
5. **TM delta math** — verify `newTM = currentTM × (1 + delta)` with 2.5 kg rounding.

---

## Data Flow

```
IntensityPoint (liftId) → intensity (constant per lift)
        ↓
RepTargetPoint (intensity) → repsPerSet
        ↓
User logs: setsCompleted, lastSetReps
        ↓
deltaReps = lastSetReps − repsPerSet
ProgressOutcome derived from (setsCompleted, deltaReps)
        ↓
ProgressAdjustment (outcome) → delta
        ↓
newTM = currentTM × (1 + delta), rounded to 2.5 kg
```

## Links

- Seeder code: `lib/data/seeders/`
- Domain models: `lib/domain/models/`
- Calculation services: `lib/domain/services/`
- Open questions: `docs/open-questions.md`
- Workbook logic: `docs/workbook--logic.md`
