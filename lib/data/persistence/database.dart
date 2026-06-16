import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../seeders/progression_adjustment_seeder.dart';

part 'database.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────────────────────

class Lifts extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get displayName => text().withLength(min: 1, max: 100)();
  TextColumn get category => text()();
  BoolColumn get isMainLift => boolean().withDefault(const Constant(false))();
  BoolColumn get isAuxiliaryLift =>
      boolean().withDefault(const Constant(false))();
  IntColumn get defaultOrder => integer().withDefault(const Constant(0))();
  BoolColumn get usesTrainingMax =>
      boolean().withDefault(const Constant(true))();
}

class TrainingMaxes extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get liftId => integer().references(Lifts, #id)();
  RealColumn get value => real()();
  RealColumn get singleEightPercentage =>
      real().withDefault(const Constant(0.9))();
  TextColumn get sourceType =>
      text().withDefault(const Constant('manual'))();
  DateTimeColumn get effectiveDate => dateTime()();
  TextColumn get notes => text().nullable()();
}

class Programs extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  TextColumn get frequency => text()();
  IntColumn get currentWeek => integer().withDefault(const Constant(1))();
  IntColumn get totalWeeks => integer().withDefault(const Constant(21))();
  BoolColumn get isActive => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
}

class WorkoutWeeks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get programId => integer().references(Programs, #id)();
  IntColumn get weekNumber => integer()();
  TextColumn get displayLabel =>
      text().withDefault(const Constant(''))();
  DateTimeColumn get startDate => dateTime().nullable()();
  DateTimeColumn get endDate => dateTime().nullable()();
}

class WorkoutDays extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutWeekId =>
      integer().references(WorkoutWeeks, #id)();
  IntColumn get dayIndex => integer()();
  TextColumn get title => text().withDefault(const Constant(''))();
  TextColumn get status =>
      text().withDefault(const Constant('planned'))();
  DateTimeColumn get completedAt => dateTime().nullable()();
}

class ExercisePrescriptions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get workoutDayId =>
      integer().references(WorkoutDays, #id)();
  IntColumn get liftId => integer().references(Lifts, #id)();
  RealColumn get trainingMaxSnapshot => real()();
  RealColumn get intensity => real()();
  RealColumn get workingWeight => real()();
  IntColumn get repsPerNormalSet => integer()();
  IntColumn get repOutTarget => integer()();
  IntColumn get setGoal => integer()();
  IntColumn get displayOrder =>
      integer().withDefault(const Constant(0))();
  BoolColumn get isPrimaryBlock =>
      boolean().withDefault(const Constant(true))();
}

class ExerciseLogs extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get prescriptionId =>
      integer().references(ExercisePrescriptions, #id)();
  IntColumn get completedSets =>
      integer().withDefault(const Constant(0))();
  IntColumn get repsOnLastSet => integer().nullable()();
  TextColumn get notes => text().nullable()();
  TextColumn get videoUrl => text().nullable()();
  DateTimeColumn get completedAt => dateTime()();
}

class AppSettingsTable extends Table {
  @override
  String get tableName => 'app_settings';

  IntColumn get id => integer().autoIncrement()();
  TextColumn get weightUnit =>
      text().withDefault(const Constant('kg'))();
  TextColumn get roundingMode =>
      text().withDefault(const Constant('nearest'))();
  RealColumn get roundingIncrement =>
      real().withDefault(const Constant(2.5))();
  TextColumn get themeMode =>
      text().withDefault(const Constant('dark'))();
  IntColumn get restTimerSeconds =>
      integer().withDefault(const Constant(180))();
  BoolColumn get showVideoField =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get showNotesField =>
      boolean().withDefault(const Constant(true))();
}

/// Stores the progression adjustment rules that map a [ProgressOutcome]
/// to a training-max delta percentage.
///
/// Seeded on first install and on schema upgrade from v1 → v2.
/// Rows can be overridden at runtime without code changes.
class ProgressAdjustments extends Table {
  /// Stable key: e.g. 'squat_plus1', 'all_lifts_belowBy2'.
  TextColumn get id => text()();

  /// Lift name key (matches [Lifts.name]) or 'all_lifts' for the global fallback.
  TextColumn get liftId => text()();

  /// Serialised [ProgressOutcome] enum name, e.g. 'plus1', 'belowBy2'.
  TextColumn get outcome => text()();

  /// Fractional adjustment applied to the training max.
  /// E.g. 0.010 means newTM = currentTM × 1.010.
  RealColumn get delta => real()();

  BoolColumn get appliesToCycle =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get appliesToTrainingMax =>
      boolean().withDefault(const Constant(true))();

  @override
  Set<Column> get primaryKey => {id};
}

// ── Database ──────────────────────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Lifts,
  TrainingMaxes,
  Programs,
  WorkoutWeeks,
  WorkoutDays,
  ExercisePrescriptions,
  ExerciseLogs,
  AppSettingsTable,
  ProgressAdjustments,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedLifts();
          await _seedDefaultSettings();
          await _seedProgressionAdjustments();
        },
        onUpgrade: (m, from, to) async {
          if (from < 2) {
            // v1 → v2: add the progression_adjustments table and populate it.
            await m.createTable(progressAdjustments);
            await _seedProgressionAdjustments();
          }
        },
      );

  /// Seeds the canonical 13 workbook lifts.
  ///
  /// The [name] column is the stable liftId key used throughout the app.
  /// The [displayName] column uses the workbook's official labels.
  Future<void> _seedLifts() async {
    const seeds = [
      // ── Main lifts ───────────────────────────────────────────────────
      ('squat',             'Squat',                  'main',      true,  false, 1),
      ('bench_press',       'Bankdr\u00FCcken',        'main',      true,  false, 2),
      ('deadlift',          'Deadlift',               'main',      true,  false, 3),
      ('overhead_press',    'Schulterdr\u00FCcken',    'main',      true,  false, 4),
      // ── Squat auxiliaries ───────────────────────────────────────────
      ('front_squat',       'Leg Press',              'auxiliary', false, true,  5),
      ('squat_aux2',        'Wider Stance Squat',     'auxiliary', false, true,  6),
      // ── Bench auxiliaries ───────────────────────────────────────────
      ('close_grip_bench',  'DB Bench',               'auxiliary', false, true,  7),
      ('bench_aux2',        'Incline DB Press',       'auxiliary', false, true,  8),
      // ── Deadlift auxiliaries ────────────────────────────────────────
      ('deadlift_aux',      'Trap Bar Deadlift',      'auxiliary', false, true,  9),
      // ── OHP auxiliaries ───────────────────────────────────────────
      ('ohp_aux',           'DB Schulterdruecken',    'auxiliary', false, true,  10),
      // ── Back exercises ───────────────────────────────────────────
      ('barbell_rows',      'Barbell Rows',           'auxiliary', false, true,  11),
      ('dumbbell_rows',     'Dumbbell Rows',          'auxiliary', false, true,  12),
      ('pulldowns',         'Pull-downs',             'auxiliary', false, true,  13),
    ];
    for (final s in seeds) {
      await into(lifts).insert(LiftsCompanion.insert(
        name:            s.$1,
        displayName:     s.$2,
        category:        s.$3,
        isMainLift:      Value(s.$4),
        isAuxiliaryLift: Value(s.$5),
        defaultOrder:    Value(s.$6),
      ));
    }
  }

  Future<void> _seedDefaultSettings() async {
    await into(appSettingsTable).insert(const AppSettingsTableCompanion());
  }

  /// Seeds all progression adjustment rows from the canonical seeder.
  ///
  /// Uses [insertOnConflictUpdate] so re-running on an existing database
  /// (e.g. after a future delta correction) is idempotent.
  Future<void> _seedProgressionAdjustments() async {
    final rows = ProgressionAdjustmentSeeder.generateProgressionAdjustments();
    for (final r in rows) {
      await into(progressAdjustments).insertOnConflictUpdate(
        ProgressAdjustmentsCompanion.insert(
          id:                  r.id,
          liftId:              r.liftId,
          outcome:             r.outcome.name,
          delta:               r.delta,
          appliesToCycle:      Value(r.appliesToCycle),
          appliesToTrainingMax: Value(r.appliesToTrainingMax),
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'trainingsplan.db'));
    return NativeDatabase(file);
  });
}

// ── Provider ──────────────────────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
