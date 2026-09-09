# Lookup Tables

The app seeds the lookup data used to generate prescriptions and progression.

## Intensity

Intensity is constant by lift across the 21-week cycle:

| Lift group | Intensity |
| --- | ---: |
| Main lifts | 87.5% |
| Front squat and close-grip bench | 82.5% |
| Other auxiliaries and back work | 75.0% |

## Rep targets

The shared rep-target curve runs from 50% to 100% intensity in 2.5%
increments. Selected points:

| Intensity | Reps |
| ---: | ---: |
| 75.0% | 8 |
| 82.5% | 5 |
| 87.5% | 3 |
| 100.0% | 1 |

The last-set RIR target is always 0.

## Progression

Progression compares last-set reps with the prescribed rep target:

```text
deltaReps = lastSetReps - repGoal
```

The resulting outcome changes the training max by the workbook adjustment
table. The new value is rounded using the configured rounding rule.

## Frequency templates

Frequency templates are implemented for 2, 3, 4, 5, and 6 training days per
week in `lib/data/seeders/frequency_template_seeder.dart`.
