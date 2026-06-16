import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'database.g.dart';

// ── Tables ────────────────────────────────────────────────────────────────────────

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

// ── Database ────────────────────────────────────────────────────────────────────────

@DriftDatabase(tables: [
  Lifts,
  TrainingMaxes,
  Programs,
  WorkoutWeeks,
  WorkoutDays,
  ExercisePrescriptions,
  ExerciseLogs,
  AppSettingsTable,
])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (m) async {
          await m.createAll();
          await _seedLifts();
          await _seedDefaultSettings();
        },
      );

  /// Seeds the canonical 13 workbook lifts.
  ///
  /// The [name] column is the stable liftId key used throughout the app.
  /// The [displayName] column uses the workbook's official labels.
  ///
  /// Schema:
  ///   (name, displayName, category, isMainLift, isAuxiliaryLift, defaultOrder)
  Future<void> _seedLifts() async {
    const seeds = [
      // ── Main lifts ─────────────────────────────────────────────────────
      ('squat',             'Squat',                  'main',      true,  false, 1),
      ('bench_press',       'Bankdr\u00FCcken',        'main',      true,  false, 2),
      ('deadlift',          'Deadlift',               'main',      true,  false, 3),
      ('overhead_press',    'Schulterdr\u00FCcken',    'main',      true,  false, 4),
      // ── Squat auxiliaries ─────────────────────────────────────────────
      ('front_squat',       'Leg Press',              'auxiliary', false, true,  5),
      ('squat_aux2',        'Wider Stance Squat',     'auxiliary', false, true,  6),
      // ── Bench auxiliaries ─────────────────────────────────────────────
      ('close_grip_bench',  'DB Bench',               'auxiliary', false, true,  7),
      ('bench_aux2',        'Incline DB Press',       'auxiliary', false, true,  8),
      // ── Deadlift auxiliaries ─────────────────────────────────────────
      ('deadlift_aux',      'Trap Bar Deadlift',      'auxiliary', false, true,  9),
      // ── OHP auxiliaries ───────────────────────────────────────────────
      ('ohp_aux',           'DB Schulterdruecken',    'auxiliary', false, true,  10),
      // ── Back exercises ──────────────────────────────────────────────────
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
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dir  = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'trainingsplan.db'));
    return NativeDatabase(file);
  });
}

// ── Provider ────────────────────────────────────────────────────────────────────────

final databaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});
