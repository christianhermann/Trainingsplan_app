# Open Questions

## Purpose

This file tracks product and logic questions that are not fully resolved from the workbook alone.
When a question is answered, move the decision into the relevant source doc and remove it from here.

## Training logic questions

### 4. Rep-out handling on lower-stress weeks

Always populate `repOutTarget`. Every prescription row has a rep-out target
derived from the intensity lookup table. No suppression on any week.

**Decision (2026-06-16):** Always show and enforce rep-out target on every set,
every week. The lookup table covers all seeded intensities via the fallback
bracket when no exact match exists.

---

## Content questions

### 7. Language strategy

Keep mixed names as they appear in the workbook. German names are used where
they are the natural/common name in the target audience (e.g. "Schulterdrücken",
"Latzug"); English names are used where they are more common (e.g. "Leg Press",
"Incline DB Press"). No translation layer or localisation needed for MVP.

**Decision (2026-06-16):** Preserve original mixed-language names verbatim.

---

## Product questions

### 9. Import timing

v1 stays manual-entry only. The "Import workbook" button in Settings is
present but disabled (`onPressed: null`). Import support is deferred until the
calculation engine is validated in production.

**Decision (2026-06-16):** Manual entry only for v1. Revisit after first release.

### 11. Program regeneration

If a user changes a training max mid-cycle, the app must regenerate all
future (not yet completed) workout days for the current program.

**Decision (2026-06-16):** Mid-cycle TM change triggers regeneration of all
planned/future days from the current week onward. Completed days are preserved.
This requires a `RegenerateFromWeekUseCase` (or equivalent method in
`WorkoutGeneratorService`) that deletes future `WorkoutDay` + `ExercisePrescription`
rows and re-runs generation from `currentWeek`.

**Implementation required:**
- UI: add "Edit Training Max" flow (e.g. from Setup screen or a dedicated edit screen)
- On save: call `tmRepo.saveMax(...)`, then trigger regeneration from `program.currentWeek`
- `WorkoutGeneratorService.regenerateFromWeek(programId, fromWeek, ...)` — delete
  future days, re-run the week×day loop for weeks `fromWeek..21`

---

## Technical questions

### 14. Auditability

Not in MVP scope. Could be added as a hidden debug screen behind a long-press
or developer toggle in Settings if needed during validation.

---

## Resolved (kept for reference)

| # | Question | Decision |
|---|---|---|
| 1 | TM semantics | Treat entered value as a **true max**. `singleEightPercentage = 0.9` field reserved for future RPE estimation helper but not used in v1 calculations. |
| 2 | Rounding behaviour | Default 2.5 kg / `nearest`. User-configurable (1.0 / 1.25 / 2.5 / 5.0 kg, three modes). No per-equipment differentiation in v1. |
| 3 | Progression target | Deltas modify the stored training max directly. `newMax = currentMax + (currentMax × delta)`. Persisted as a new TM row immediately after workout completion. |
| 5 | Deload interpretation | Moot — SBS uses flat intensity for all 21 weeks. No deload weeks exist in this program. |
| 6 | Accessory catalog scope | Fixed catalog for MVP (13 canonical lifts). No custom exercise creation in v1. |
| 8 | Onboarding max-estimation helper | No helper. Users enter their max directly; setup copy advises estimating low. |
| 10 | History detail | Row-level only: `repsOnLastSet`, `completedSets`, `notes`, `videoUrl`, `completedAt`. No per-set breakdown in v1. |
| 12 | Multiple programs | One active program at a time. `deactivateAll()` is called before each new program is saved. |
| 13 | Source of truth strategy | Hard-seeded in Dart code (`lib/data/seeders/`). No JSON assets or runtime DB seeding. |

## Decision rule

Do not let Copilot guess answers to unresolved questions.
Use explicit TODOs and link back to this file until each decision is confirmed.
