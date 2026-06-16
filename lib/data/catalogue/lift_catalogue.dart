/// Curated preset display-name options for each of the 13 canonical slot keys.
///
/// Rules:
///   • First entry is always the workbook default display name.
///   • Last entry is always the sentinel string [kCustomEntry] which triggers
///     a free-text input in the UI.
///   • Slot keys are the stable [name] column values from the lifts table —
///     they never change; only the [displayName] is user-overridable.
const kCustomEntry = 'Custom…';

/// slotKey → ordered list of preset display names.
/// The generation engine never sees these strings — it works on slot keys.
const liftCatalogue = <String, List<String>>{

  // ── Main lifts ────────────────────────────────────────────────────────────
  'squat': [
    'Squat',
    'Low Bar Squat',
    'High Bar Squat',
    'Box Squat',
    'Pause Squat',
    'Safety Bar Squat',
    kCustomEntry,
  ],
  'bench_press': [
    'Bankdrücken',
    'Flachbank Hantel',
    'Close Grip Bench',
    'Pause Bench',
    'Board Press',
    'Floor Press',
    kCustomEntry,
  ],
  'deadlift': [
    'Deadlift',
    'Sumo Deadlift',
    'Romanian Deadlift',
    'Deficit Deadlift',
    'Rack Pull',
    'Trap Bar Deadlift',
    kCustomEntry,
  ],
  'overhead_press': [
    'Schulterdrücken',
    'Sitzend Schulterdrücken',
    'Push Press',
    'Z-Press',
    'Landmine Press',
    kCustomEntry,
  ],

  // ── Squat auxiliaries ─────────────────────────────────────────────────────
  'front_squat': [
    'Leg Press',
    'Front Squat',
    'Hack Squat',
    'Bulgarian Split Squat',
    'Step Up',
    'Lunge',
    kCustomEntry,
  ],
  'squat_aux2': [
    'Wider Stance Squat',
    'Sumo Squat',
    'Pause Squat',
    'Box Squat',
    'Goblet Squat',
    'Zercher Squat',
    kCustomEntry,
  ],

  // ── Bench auxiliaries ─────────────────────────────────────────────────────
  'close_grip_bench': [
    'DB Bench',
    'Close Grip Bench',
    'Dips',
    'JM Press',
    'Tricep Pushdown',
    'Skull Crushers',
    kCustomEntry,
  ],
  'bench_aux2': [
    'Incline DB Press',
    'Incline Barbell Press',
    'Cable Fly',
    'Pec Dec',
    'Push-Ups',
    'Dumbbell Fly',
    kCustomEntry,
  ],

  // ── Deadlift auxiliary ────────────────────────────────────────────────────
  'deadlift_aux': [
    'Trap Bar Deadlift',
    'Romanian Deadlift',
    'Good Mornings',
    'Hyperextensions',
    'Deficit Deadlift',
    'Kettlebell Swing',
    kCustomEntry,
  ],

  // ── OHP auxiliary ─────────────────────────────────────────────────────────
  'ohp_aux': [
    'DB Schulterdrücken',
    'Seitliches Heben',
    'Face Pulls',
    'Arnold Press',
    'Upright Row',
    'Cable Lateral Raise',
    kCustomEntry,
  ],

  // ── Back exercises ────────────────────────────────────────────────────────
  'barbell_rows': [
    'Barbell Rows',
    'Pendlay Row',
    'Yates Row',
    'T-Bar Row',
    'Seal Row',
    kCustomEntry,
  ],
  'dumbbell_rows': [
    'Dumbbell Rows',
    'Cable Row',
    'Machine Row',
    'Chest Supported Row',
    kCustomEntry,
  ],
  'pulldowns': [
    'Pull-downs',
    'Pull-Ups',
    'Chin-Ups',
    'Neutral Grip Pull-Up',
    'Assisted Pull-Up',
    kCustomEntry,
  ],
};

/// Workbook default display name for each slot key.
/// Used to pre-populate [SetupState.liftNames].
const liftDefaults = <String, String>{
  'squat':            'Squat',
  'bench_press':      'Bankdrücken',
  'deadlift':         'Deadlift',
  'overhead_press':   'Schulterdrücken',
  'front_squat':      'Leg Press',
  'squat_aux2':       'Wider Stance Squat',
  'close_grip_bench': 'DB Bench',
  'bench_aux2':       'Incline DB Press',
  'deadlift_aux':     'Trap Bar Deadlift',
  'ohp_aux':          'DB Schulterdrücken',
  'barbell_rows':     'Barbell Rows',
  'dumbbell_rows':    'Dumbbell Rows',
  'pulldowns':        'Pull-downs',
};
