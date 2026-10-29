import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/data/persistence/database.dart';
import 'package:trainingsplan_app/data/repositories/program_repository.dart';
import 'package:trainingsplan_app/data/repositories/workout_repository.dart';
import 'package:trainingsplan_app/domain/models/enums.dart';

void main() {
  late AppDatabase db;
  late ProgramRepository programRepo;
  late WorkoutRepository workoutRepo;

  setUp(() {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    programRepo = ProgramRepository(db);
    workoutRepo = WorkoutRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('Workout Completion & Progression Regression Tests', () {
    test('deduplicateDaysForProgram deletes uncompleted duplicate day and keeps completed day', () async {
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

      // 1. Completed Day 1
      final completedDayId = await programRepo.saveDay(WorkoutDaysCompanion.insert(
        workoutWeekId: weekId,
        dayIndex: 0,
        title: const Value('Week 1 - Day 1'),
        status: const Value('completed'),
        completedAt: Value(now),
      ));

      // 2. Duplicate planned Day 1 (caused by old bug)
      final duplicatePlannedDayId = await programRepo.saveDay(WorkoutDaysCompanion.insert(
        workoutWeekId: weekId,
        dayIndex: 0,
        title: const Value('Week 1 - Day 1'),
        status: const Value('planned'),
      ));

      // 3. Planned Day 2
      final plannedDay2Id = await programRepo.saveDay(WorkoutDaysCompanion.insert(
        workoutWeekId: weekId,
        dayIndex: 1,
        title: const Value('Week 1 - Day 2'),
        status: const Value('planned'),
      ));

      // Before deduplication: 3 days in week
      var days = await programRepo.getDaysForWeek(weekId);
      expect(days.length, 3);

      // Run deduplication
      await programRepo.deduplicateDaysForProgram(programId);

      // After deduplication: 2 days (duplicate Day 1 deleted, completed Day 1 preserved)
      days = await programRepo.getDaysForWeek(weekId);
      expect(days.length, 2);
      expect(days.map((d) => d.id), contains(completedDayId));
      expect(days.map((d) => d.id), contains(plannedDay2Id));
      expect(days.map((d) => d.id), isNot(contains(duplicatePlannedDayId)));
    });

    test('updateFuturePrescriptionsForLift updates working weight on planned days without altering completed days', () async {
      final now = DateTime.now();
      final programId = await programRepo.saveProgram(ProgramsCompanion.insert(
        name: 'Test Program',
        frequency: 'three',
        createdAt: now,
        updatedAt: now,
      ));

      final weekId = await programRepo.saveWeek(WorkoutWeeksCompanion.insert(
        programId: programId,
        weekNumber: 1,
      ));

      final day1Id = await programRepo.saveDay(WorkoutDaysCompanion.insert(
        workoutWeekId: weekId,
        dayIndex: 0,
        status: const Value('completed'),
        completedAt: Value(now),
      ));

      final day2Id = await programRepo.saveDay(WorkoutDaysCompanion.insert(
        workoutWeekId: weekId,
        dayIndex: 1,
        status: const Value('planned'),
      ));

      final liftId = await db.into(db.lifts).insert(LiftsCompanion.insert(
        name: 'squat',
        displayName: 'Squat',
        category: 'main',
      ));

      // Completed day prescription (100 kg TM, 0.70 intensity -> 70 kg)
      await workoutRepo.savePrescription(ExercisePrescriptionsCompanion.insert(
        workoutDayId: day1Id,
        liftId: liftId,
        trainingMaxSnapshot: 100.0,
        intensity: 0.70,
        workingWeight: 70.0,
        repsPerNormalSet: 5,
        repOutTarget: 5,
        setGoal: 3,
      ));

      // Future planned day prescription (100 kg TM, 0.75 intensity -> 75 kg)
      await workoutRepo.savePrescription(ExercisePrescriptionsCompanion.insert(
        workoutDayId: day2Id,
        liftId: liftId,
        trainingMaxSnapshot: 100.0,
        intensity: 0.75,
        workingWeight: 75.0,
        repsPerNormalSet: 5,
        repOutTarget: 5,
        setGoal: 3,
      ));

      // Update future prescriptions with new TM = 110 kg
      await workoutRepo.updateFuturePrescriptionsForLift(
        liftId: liftId,
        newTrainingMax: 110.0,
        roundingIncrement: 2.5,
        roundingMode: RoundingMode.nearest,
      );

      final futurePrescs = await workoutRepo.getPrescriptionsForDay(day2Id);
      expect(futurePrescs.first.trainingMaxSnapshot, 110.0);
      // 110 * 0.75 = 82.5 kg
      expect(futurePrescs.first.workingWeight, 82.5);

      // Completed day should remain completely untouched
      final completedPrescs = await workoutRepo.getPrescriptionsForDay(day1Id);
      expect(completedPrescs.first.trainingMaxSnapshot, 100.0);
      expect(completedPrescs.first.workingWeight, 70.0);
    });
  });
}
