# Lookup Tables Implementation

## Overview

The app uses four primary lookup tables that seed from the workbook structure:
1. **Intensity Points** - 21-week intensity progression per lift
2. **Rep Target Points** - Rep targets indexed by intensity
3. **Progression Adjustments** - ProgressOutcome → training max delta mappings
4. **Frequency Templates** - Which lifts are trained on which days

## 1. Intensity Points (21-Week Progression)

### Location
`lib/data/seeders/intensity_seeder.dart`

### Explicit Values from Workbook

#### Main Lifts (Squat, Bench Press, Deadlift, Overhead Press)

**Weeks 1-7 (Wave 1 - CONFIRMED):**
```
Week 1:  0.70
Week 2:  0.725
Week 3:  0.75
Week 4:  0.725
Week 5:  0.75
Week 6:  0.775
Week 7:  0.60  (deload)
```

**Weeks 8-14 (Wave 2 - ASSUMED):**
Currently copying Wave 1 structure. See TODO below.

**Weeks 15-21 (Wave 3 - PARTIAL):**
```
Week 15: 0.825  (peaking, per workbook)
Week 21: 0.60   (deload, per workbook)
Weeks 16-20: INFERRED
```

#### Auxiliary Lifts (Leg Press, Wider Stance Squat, DB Bench, Incline DB Press, Trap Bar Deadlift, DB Overhead Press)

**Weeks 1-7 (Wave 1 - CONFIRMED):**
```
Week 1:  0.65
Week 2:  0.675
Week 3:  0.70
Week 4:  0.675
Week 5:  0.70
Week 6:  0.725
Week 7:  0.55  (deload)
```

**Weeks 8-14 (Wave 2 - ASSUMED):**
Currently copying Wave 1 structure. See TODO below.

**Weeks 15-21 (Wave 3 - PARTIAL):**
```
Week 15: 0.775  (climbing per workbook)
Week 21: 0.55   (deload, per workbook)
Weeks 16-20: INFERRED
```

### Ambiguities & TODOs

**TODO #1: Wave 2 (Weeks 8-14) Exact Pattern**

The workbook says:
> "then later waves repeat"

This could mean:
- Option A: Exact repetition (weeks 8-14 identical to weeks 1-7)
- Option B: Similar structure with different intensity values

**Action Required:** Examine the actual workbook's week-by-week intensity cells for weeks 8-14.

**TODO #2: Wave 3 (Weeks 15-20) Exact Pattern**

The workbook says:
> "eventually reach 0.825 before returning to 0.60 in week 21"

For main lifts, we know:
- Week 15: 0.825 (high)
- Week 21: 0.60 (deload)
- Weeks 16-20: INFERRED

For auxiliary lifts, we know:
- Week 15: 0.775 (climbing)
- Week 21: 0.55 (deload)
- Weeks 16-20: INFERRED

**Action Required:** Examine the actual workbook's week-by-week intensity cells for weeks 16-20.

**TODO #3: Deload Week Definition**

Currently assuming deload weeks are:
- Main lifts: 0.60 intensity in weeks 7, 14, 21
- Auxiliary lifts: 0.55 intensity in weeks 7, 14, 21

**Action Required:** Confirm deload timing matches the workbook's actual layout.

## 2. Rep Target Points (Intensity-Based Lookup)

### Location
`lib/data/seeders/rep_target_seeder.dart`

### Explicit Values from Workbook

#### Main Lift Normal Set Targets

```
0.70  → 10 reps
0.725 → 9 reps
0.75  → 8 reps
0.775 → 7 reps
0.80  → 6 reps
0.825 → 5 reps
```

#### Main Lift Last Set Targets

```
0.70  → 12 reps
0.725 → 11 reps
0.75  → 10 reps
0.775 → 9 reps
0.80  → 8 reps
0.825 → 6 reps
```

#### Auxiliary Lift Normal Set Targets

```
0.65  → 12 reps
0.675 → 11 reps
0.70  → 10 reps
0.725 → 9 reps
0.75  → 8 reps
0.775 → 7 reps
```

#### Auxiliary Lift Last Set Targets

```
0.65  → 15 reps
0.675 → 13 reps
0.70  → 12 reps
0.725 → 11 reps
0.75  → 10 reps
0.775 → 9 reps
```

### Ambiguities & TODOs

**TODO #4: Deload Week Rep Targets (0.60 main / 0.55 auxiliary)**

The workbook does NOT specify rep targets for deload weeks (0.60 and 0.55).

Options:
- A: Infer from pattern (e.g., 0.60 → 11 reps normal, 13 last set)
- B: Make rep-out optional on deload weeks (logging may be skipped)
- C: Use closest intensity match as fallback

**Action Required:** Check if deload weeks should have explicit rep targets or if logging is optional.

**Cross-reference:** docs/open-questions.md #4 (Rep-out handling on lower-stress weeks)

**TODO #5: Floating Point Rounding**

The lookup service uses 0.001 tolerance to handle floating-point precision:
```dart
static const double _intensityTolerance = 0.001;
```

If rounding produces intensities like 0.7049999 or 0.7050001, this tolerance bridges the gap.

**Action Required:** Verify this tolerance is appropriate for the rounding logic.

## 3. Progression Adjustments (Performance → Training Max Delta)

### Location
`lib/data/seeders/progression_adjustment_seeder.dart`

### Explicit Values from Workbook

All lifts use the same adjustment deltas:

```
ProgressOutcome.belowBy2  → -0.05   (5% decrease)
ProgressOutcome.belowBy1  → -0.02   (2% decrease)
ProgressOutcome.hit       →  0.00   (no change)
ProgressOutcome.plus1     →  0.005  (0.5% increase)
ProgressOutcome.plus2     →  0.01   (1% increase)
ProgressOutcome.plus3     →  0.015  (1.5% increase)
ProgressOutcome.plus4     →  0.02   (2% increase)
ProgressOutcome.plus5     →  0.03   (3% increase)
```

### Application

Applied as: `newMax = currentMax + (currentMax * delta)`

Example:
- Current max: 100 kg
- Outcome: plus2 (beat by 2 reps)
- Delta: 0.01
- New max: 100 + (100 × 0.01) = 101 kg

### Ambiguities & TODOs

**TODO #6: Lift-Specific Adjustments?**

The model has `liftId` field, but the workbook shows ONE set of deltas.

Options:
- A: Global rules applied to all lifts (current implementation)
- B: Variation by lift category (main vs. auxiliary)
- C: Per-lift customization

**Action Required:** Confirm whether all lifts share the same adjustment rules.

**TODO #7: Cycle vs. Training Max Application**

The model has fields:
- `appliesToCycle` (currently true)
- `appliesToTrainingMax` (currently true)

Ambiguity: Do these adjustments only affect the *next cycle's* planning, or the stored *training max*?

**Cross-reference:** docs/open-questions.md #3 (Progression target semantics)

## 4. Frequency Templates (Workout Structure)

### Location
`lib/data/seeders/frequency_template_seeder.dart`

### Status: INCOMPLETE - PLACEHOLDERS ONLY

Currently only 2x frequency is partially implemented. All others need workbook verification.

### Explicit Information from Workbook

The workbook has separate sheets for:
- 2x (2 training days per week)
- 3x (3 training days per week)
- 4x (4 training days per week)
- 5x (5 training days per week)
- 6x (6 training days per week)

Each frequency sheet shows:
- Day layout (e.g., Day 1, Day 2, Day 3...)
- Which lifts appear on each day
- Exercise order within each day (main block, then auxiliary)

### 2x Frequency (PARTIAL GUESS)

Current placeholder assumes:
```
Day 1: Squat, Leg Press, Wider Stance Squat
Day 2: Bench Press, DB Bench, Incline DB Press
```

**Action Required:** Verify against workbook's actual 2x sheet.

### 3x, 4x, 5x, 6x Frequencies (NOT IMPLEMENTED)

Placeholder structure exists but needs completion from workbook.

**Action Required:** For each frequency:
1. Count the number of days
2. For each day, list all lifts in order
3. Mark each lift as main/auxiliary (for UI grouping)

### Accessory Catalog Question

The workbook mentions additional movements:
- Latzug (lat pulldown)
- Rudern (rowing)
- T-Bar Rudern (T-bar row)
- Bizeps Curls (bicep curls)
- Trizeps Extension (tricep extension)

**Action Required:** Clarify whether MVP should include these, or stick with the 10 seeded lifts.

**Cross-reference:** docs/open-questions.md #6 (Accessory catalog scope)

## Implementation Status

| Component | Status | Confidence |
|-----------|--------|------------|
| Main lift intensities (weeks 1-7) | ✅ Implemented | 100% |
| Auxiliary intensities (weeks 1-7) | ✅ Implemented | 100% |
| Intensities (weeks 8-21) | ⚠️ Inferred | 40% |
| Deload rep targets | ❌ Missing | 0% |
| Main lift rep targets | ✅ Implemented | 100% |
| Auxiliary rep targets | ✅ Implemented | 100% |
| Progression adjustments | ✅ Implemented | 90% |
| 2x frequency template | ⚠️ Partial | 50% |
| 3x-6x frequency templates | ❌ Placeholder | 0% |

## Testing Recommendations

### Unit Tests

1. **Intensity Lookup**
   - Test all 21 weeks for one lift
   - Test both main and auxiliary lifts
   - Verify no gaps or duplicates

2. **Rep Target Lookup**
   - Test exact intensity matches
   - Test fuzzy matching (0.001 tolerance)
   - Verify normal < last set targets

3. **Progression Adjustments**
   - Test all 8 outcomes
   - Verify delta application math

4. **Frequency Templates**
   - Test all 5 frequencies
   - Verify lift-day assignments match workbook
   - Check display order

### Validation Against Workbook Examples

From workbook-logic.md:
```
Squat TM 85:
- Week 1 intensity 0.70 → 60 kg weight, 10 reps normal, 12 reps last set

Bench TM 85 → 60 kg (week 1)
Deadlift TM 110 → 78 kg (week 1)
Overhead Press TM 45 → 32 kg (week 1)
```

**Action:** Create test data using these examples to validate the entire calculation chain.

## Data Flow

```
Intensity Lookup
    ↓
IntensityPoint (liftId, weekNumber) → intensity

Rep Target Lookup
    ↓
RepTargetPoint (liftId, intensity) → (normal, lastSet)

Progression Adjustment Lookup
    ↓
ProgressAdjustment (liftId, outcome) → delta

Frequency Template Lookup
    ↓
FrequencyTemplate (frequency, dayIndex) → [liftId, ...]

Workout Generation
    ↓
All four combined to produce ExercisePrescription
```

## Next Steps

1. **Resolve all 7 TODOs** by examining the actual workbook
2. **Implement missing frequency templates** (3x-6x)
3. **Create comprehensive test suite** using workbook examples
4. **Add validation endpoint** to catch data inconsistencies early
5. **Consider caching layer** if lookup performance becomes an issue

## Links

- Seeder code: `lib/data/seeders/`
- Domain models: `lib/domain/models/`
- Calculation services: `lib/domain/services/`
- Open questions: `docs/open-questions.md`
- Workbook logic: `docs/workbook-logic.md`
