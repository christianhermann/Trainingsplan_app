# Lookup Table TODOs

All TODOs documented in code with clear references. This file provides quick navigation.

---

## Open TODOs

### TODO #5: Accessory Catalog Scope

**File:** `lib/data/seeders/frequency_template_seeder.dart`  
**Priority:** MEDIUM  
**Issue:** Workbook mentions additional movements not yet in seed data.

**Mentioned accessories:** Latzug, Rudern, T-Bar Rudern, Bizeps Curls, Trizeps Extension

**Decision:** Fixed catalog for MVP — no custom exercise creation. These accessories
are referenced in some frequency sheets but are not part of the 13 canonical lift IDs.

**Action required:**
```
1. Confirm which frequency sheets list these accessories and on which days.
2. Decide whether to add them as additional canonical IDs or defer to post-MVP.
3. If adding: extend lift seed data + frequency templates + liftDbIds resolution
   in SetupNotifier.saveAndGenerate().
```

**Workbook location:** Frequency sheets, accessory exercise rows

---

### TODO #6: Lift-Specific Adjustment Verification

**File:** `lib/data/seeders/progression_adjustment_seeder.dart`  
**Priority:** MEDIUM  
**Issue:** Assuming all lifts use the same 8 outcome deltas. Workbook only
shows one adjustment table without per-lift differentiation.

**Current:** 8 identical delta records generated for each of the 13 lift IDs
+ `all_lifts` fallback key.

**Action required:**
```
Verify in workbook: do ALL lifts (main and auxiliary) use identical
adjustment rules, or do they vary by category (main vs. auxiliary)?
```

**Workbook location:** Progression adjustment table

---

### TODO #11: Mid-Cycle Training Max Regeneration

**File:** `lib/domain/services/workout_generator_service.dart`  
**Priority:** HIGH  
**Decision (2026-06-16):** When a user changes a TM mid-cycle, regenerate all
future planned days from `program.currentWeek` onward. Completed days are untouched.

**Action required:**
```
1. Add WorkoutGeneratorService.regenerateFromWeek(
     programId, fromWeek, frequency, trainingMaxes, liftDbIds
   ):
   - Delete all WorkoutDay rows with weekNumber >= fromWeek and status != 'completed'
   - Delete their ExercisePrescription rows (cascade or manual)
   - Re-run the week×day generation loop for weeks fromWeek..21

2. Add an "Edit Training Max" UI entry point (Setup screen or dedicated screen).

3. On TM save: call tmRepo.saveMax(...) then regenerateFromWeek(...).

4. Invalidate todayWorkoutProvider after regeneration.
```

---

## Quick Navigation

| TODO | File | Priority | Status |
|------|------|----------|--------|
| #5: Accessory Scope | frequency_template_seeder.dart | MEDIUM | ⏳ |
| #6: Lift Adjustments | progression_adjustment_seeder.dart | MEDIUM | ⏳ |
| #11: Mid-Cycle TM Regen | workout_generator_service.dart | HIGH | ⏳ |

---

## Resolved TODOs

| # | Title | Resolution |
|---|---|---|
| #1 | Weeks 8-14 intensity pattern | **Resolved.** SBS uses flat intensity for all 21 weeks. No wave structure exists. |
| #2 | Weeks 15-20 intensity pattern | **Resolved.** Same — flat intensity. 87.5% main / 82.5% tier-1 aux / 75.0% tier-2 aux all 21 weeks. |
| #3 | Deload week rep targets | **Resolved.** No deload weeks in SBS. Every week uses the same intensity; rep target table covers all weeks. |
| #4 | 3x–6x frequency templates | **Resolved.** All five generators fully implemented in `frequency_template_seeder.dart`. |
| #7 | Floating-point tolerance | **Resolved.** Tolerance 0.0001 documented and validated by passing tests. |

---

## Related Documents

- `docs/lookup-tables-implementation.md` — Full technical details
- `docs/open-questions.md` — Product decisions
- `docs/workbook--logic.md` — Workbook structure
