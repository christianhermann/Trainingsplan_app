# Lookup Table TODOs

All TODOs documented in code with clear references. This file provides quick navigation.

## Critical TODOs (Block 21-week Cycle)

### TODO #1: Weeks 8-14 Intensity Pattern
**File:** `lib/data/seeders/intensity_seeder.dart` (lines 62-75)
**Issue:** Workbook says "later waves repeat" but doesn't specify exact weeks 8-14 values
**Current:** Copying weeks 1-7 pattern
**Options:**
- Option A: Exact repetition (weeks 8-14 identical to 1-7)
- Option B: Different pattern

**Action Required:** 
```
Examine workbook's intensity table for weeks 8-14.
Check both main lift and auxiliary lift columns.
Copy exact values per week.
```

**Workbook Location:** "Intensity" or "Weekly Intensity" sheet, weeks 8-14 columns

---

### TODO #2: Weeks 15-20 Intensity Pattern
**File:** `lib/data/seeders/intensity_seeder.dart` (lines 85-95)
**Issue:** Workbook says "reach 0.825 before returning to 0.60" but weeks 16-20 not specified
**Current:** Inferred structure based on "peaking" language
**Known Facts:**
- Main lifts: Week 15 = 0.825, Week 21 = 0.60
- Auxiliary lifts: Week 15 = 0.775, Week 21 = 0.55
- Weeks 16-20: Unknown

**Action Required:**
```
Examine workbook's intensity table for weeks 15-20.
Fill in exact values for all main and auxiliary lifts.
```

**Workbook Location:** "Intensity" sheet, weeks 15-20 columns

---

### TODO #3: Deload Week Rep Targets
**File:** `lib/data/seeders/rep_target_seeder.dart` (line 135)
**Issue:** Deload weeks (0.60 main, 0.55 auxiliary) have no rep targets in workbook
**Impact:** Cannot log reps on deload weeks without target

**Options:**
- Option A: Infer from pattern (e.g., 0.60 → 11 reps normal, 13 reps last set)
- Option B: Make rep-out optional/skipped on deload weeks
- Option C: Use closest intensity match as fallback

**Action Required:**
```
1. Check if workbook shows deload week rep targets
2. Check open-questions.md #4 for product decision
3. Implement chosen option
```

**Workbook Location:** "Normal Set Rep Target" and "Last Set Rep Target" sheets, intensity 0.60/0.55 rows

---

## High-Priority TODOs (Block Non-2x Frequencies)

### TODO #4: Frequency Templates 3x-6x
**File:** `lib/data/seeders/frequency_template_seeder.dart` (lines 98-154)
**Issue:** Only 2x frequency partially implemented; 3x-6x are placeholders
**Impact:** Users cannot select 3x, 4x, 5x, or 6x frequencies

**Action Required per Frequency:**
```
For each frequency (3x, 4x, 5x, 6x):
  1. Count total training days
  2. For each day (day 0, day 1, day 2, ...):
     - List all lifts in order (as liftId strings)
     - Mark each as 'main' or 'auxiliary' (for UI grouping)
     - Assign displayOrder (1, 2, 3, ...)
  3. Record in _generateThree() / _generateFour() / etc.
```

**Workbook Locations:**
- "2x" sheet → `_generateTwo()` (partially done)
- "3x" sheet → `_generateThree()` (TODO)
- "4x" sheet → `_generateFour()` (TODO)
- "5x" sheet → `_generateFive()` (TODO)
- "6x" sheet → `_generateSix()` (TODO)

**Expected Output per Day:**
```
FrequencyTemplate(
  id: 'freq_4_day_0_squat',
  frequency: ProgramFrequency.four,
  dayIndex: 0,
  liftId: 'squat',
  defaultOrder: 1,
  blockType: 'main',
)
```

---

## Medium-Priority TODOs (Optional for MVP)

### TODO #5: Accessory Catalog Scope
**File:** `lib/data/seeders/frequency_template_seeder.dart` (line 22)
**Issue:** Workbook mentions additional movements not in seed data
**Mentioned Accessories:** Latzug, Rudern, T-Bar Rudern, Bizeps Curls, Trizeps Extension

**Action Required:**
```
1. Check open-questions.md #6 for product decision
2. If including in MVP:
   - Add to lift seed data with category/displayName
   - Add to frequency templates where they appear
3. If deferring:
   - Add TODO note for future expansion
```

**Workbook Location:** Frequency sheets, accessory exercise rows

---

### TODO #6: Lift-Specific Adjustment Verification
**File:** `lib/data/seeders/progression_adjustment_seeder.dart` (line 18)
**Issue:** Assuming all lifts use same adjustment deltas; workbook only shows one set of values
**Current:** Creating 8 adjustment records per lift (all with same deltas)

**Action Required:**
```
Verify: Do ALL lifts (main and auxiliary) use identical adjustment rules?
OR: Do adjustments vary by category (main vs. auxiliary)?
```

**Workbook Location:** Progression adjustment table

---

## Low-Priority TODOs (Refinements)

### TODO #7: Floating-Point Tolerance
**File:** `lib/domain/services/rep_target_lookup_service.dart` (line 10)
**Issue:** Using 0.001 tolerance for intensity matching
**Question:** Is this tolerance appropriate?

**Action:** Run tests with actual rounded values to verify tolerance is sufficient.

---

## Template for TODO Resolution

When resolving a TODO:

```markdown
## TODO #{N}: [Brief Title]

**Date Resolved:** YYYY-MM-DD
**Resolved By:** [Name]

**Finding:**
[Describe what was discovered in the workbook]

**Changes Made:**
[List files and changes]

**Verification:**
[How was it tested/validated?]
```

---

## Quick Navigation

| TODO | File | Priority | Status |
|------|------|----------|--------|
| #1: Weeks 8-14 | intensity_seeder.dart | CRITICAL | ❌ |
| #2: Weeks 15-20 | intensity_seeder.dart | CRITICAL | ❌ |
| #3: Deload Targets | rep_target_seeder.dart | CRITICAL | ❌ |
| #4: 3x-6x Templates | frequency_template_seeder.dart | HIGH | ❌ |
| #5: Accessory Scope | frequency_template_seeder.dart | MEDIUM | ⏳ |
| #6: Lift Adjustments | progression_adjustment_seeder.dart | MEDIUM | ⏳ |
| #7: Tolerance | rep_target_lookup_service.dart | LOW | ⏳ |

---

## Related Documents

- `docs/lookup-tables-implementation.md` — Full technical details
- `docs/open-questions.md` — Product decisions
- `docs/workbook-logic.md` — Workbook structure
- Session artifacts: `COMPLETE_SUMMARY.md`, `LOOKUP_TABLES_SUMMARY.md`
