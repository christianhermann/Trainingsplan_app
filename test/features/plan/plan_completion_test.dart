import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/data/persistence/database.dart';
import 'package:trainingsplan_app/data/repositories/lift_repository.dart';
import 'package:trainingsplan_app/data/repositories/program_repository.dart';
import 'package:trainingsplan_app/data/repositories/settings_repository.dart';
import 'package:trainingsplan_app/data/repositories/workout_repository.dart';
import 'package:trainingsplan_app/features/plan/plan_provider.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepo;
  late WorkoutRepository workoutRepo;
  late LiftRepository liftRepo;
  late SettingsRepository settingsRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    workoutRepo = WorkoutRepository(db);
    liftRepo = LiftRepository(db);
    settingsRepo = SettingsRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  test('planSummaryProvider sets isCompleted accurately for completed and planned days', () async {
    final now = DateTime.now();
    final programId = await programRepo.saveProgram(ProgramsCompanion.insert(
      name: 'Test Program',
      frequency: 'three',
      createdAt: now,
      updatedAt: now,
      isActive: const Value(true),
    ));

    final weekId = await programRepo.saveWeek(WorkoutWeeksCompanion.insert(
      programId: programId,
      weekNumber: 1,
    ));

    // Day 1: completed
    await programRepo.saveDay(WorkoutDaysCompanion.insert(
      workoutWeekId: weekId,
      dayIndex: 0,
      title: const Value('Week 1 - Day 1'),
      status: const Value('completed'),
      completedAt: Value(now),
    ));

    // Day 2: planned
    await programRepo.saveDay(WorkoutDaysCompanion.insert(
      workoutWeekId: weekId,
      dayIndex: 1,
      title: const Value('Week 1 - Day 2'),
      status: const Value('planned'),
    ));

    final container = ProviderContainer(
      overrides: [
        programRepositoryProvider.overrideWithValue(programRepo),
        workoutRepositoryProvider.overrideWithValue(workoutRepo),
        liftRepositoryProvider.overrideWithValue(liftRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
    );
    addTearDown(container.dispose);

    final summary = await container.read(planSummaryProvider(1).future);
    expect(summary, isNotNull);
    expect(summary!.days.length, 2);
    expect(summary.days[0].dayNumber, 1);
    expect(summary.days[0].isCompleted, isTrue);

    expect(summary.days[1].dayNumber, 2);
    expect(summary.days[1].isCompleted, isFalse);
  });
}
