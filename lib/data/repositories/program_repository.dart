import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/enums.dart';
import '../persistence/database.dart';

class ProgramRepository {
  ProgramRepository(this._db);
  final AppDatabase _db;

  Future<Program?> getActiveProgram() =>
      (_db.select(_db.programs)..where((t) => t.isActive.equals(true)))
          .getSingleOrNull();

  Future<List<Program>> getAllPrograms() =>
      _db.select(_db.programs).get();

  Future<int> saveProgram(ProgramsCompanion companion) =>
      _db.into(_db.programs).insertOnConflictUpdate(companion);

  Future<bool> updateProgram(ProgramsCompanion companion) =>
      _db.update(_db.programs).replace(companion);

  /// Partially updates a program row — only the supplied fields are written.
  Future<void> patchProgram(int programId, ProgramsCompanion patch) =>
      (_db.update(_db.programs)..where((t) => t.id.equals(programId)))
          .write(patch);

  Future<void> deactivateAll() async {
    await (_db.update(_db.programs))
        .write(const ProgramsCompanion(isActive: Value(false)));
  }

  Future<void> setActive(int programId) async {
    await deactivateAll();
    await (_db.update(_db.programs)
          ..where((t) => t.id.equals(programId)))
        .write(const ProgramsCompanion(isActive: Value(true)));
  }

  // -- Workout weeks --

  Future<List<WorkoutWeek>> getWeeksForProgram(int programId) =>
      (_db.select(_db.workoutWeeks)
            ..where((t) => t.programId.equals(programId))
            ..orderBy([(t) => OrderingTerm.asc(t.weekNumber)]))
          .get();

  /// Returns a single week by its primary key, or null if not found.
  Future<WorkoutWeek?> getWeekById(int weekId) =>
      (_db.select(_db.workoutWeeks)..where((t) => t.id.equals(weekId)))
          .getSingleOrNull();

  Future<int> saveWeek(WorkoutWeeksCompanion companion) =>
      _db.into(_db.workoutWeeks).insertOnConflictUpdate(companion);

  // -- Workout days --

  Future<List<WorkoutDay>> getDaysForWeek(int weekId) =>
      (_db.select(_db.workoutDays)
            ..where((t) => t.workoutWeekId.equals(weekId))
            ..orderBy([(t) => OrderingTerm.asc(t.dayIndex)]))
          .get();

  /// Returns a single workout day by its primary key, or null if not found.
  Future<WorkoutDay?> getDayById(int dayId) =>
      (_db.select(_db.workoutDays)..where((t) => t.id.equals(dayId)))
          .getSingleOrNull();

  Future<int> saveDay(WorkoutDaysCompanion companion) =>
      _db.into(_db.workoutDays).insertOnConflictUpdate(companion);

  Future<bool> updateDay(WorkoutDaysCompanion companion) =>
      _db.update(_db.workoutDays).replace(companion);

  /// Partially updates a workout day — only the supplied fields are written.
  /// Use this instead of [updateDay] when you don't have the full row.
  Future<void> patchDay(int dayId, WorkoutDaysCompanion patch) =>
      (_db.update(_db.workoutDays)..where((t) => t.id.equals(dayId)))
          .write(patch);

  /// Deletes all non-completed workout days (and their prescriptions) for
  /// [programId] whose week number is >= [fromWeek].
  ///
  /// Completed days are never touched. Used by
  /// [WorkoutGeneratorService.regenerateFromWeek] before re-generating future
  /// prescriptions with updated TM values.
  Future<void> deleteFutureDaysForProgram(
    int programId,
    int fromWeek,
  ) async {
    final weeks = await getWeeksForProgram(programId);
    final futureWeekIds = weeks
        .where((w) => w.weekNumber >= fromWeek)
        .map((w) => w.id)
        .toList();
    if (futureWeekIds.isEmpty) return;

    final futureDayIds = <int>[];
    for (final weekId in futureWeekIds) {
      final days = await getDaysForWeek(weekId);
      futureDayIds.addAll(
        days
            .where((d) =>
                WorkoutStatus.fromString(d.status) != WorkoutStatus.completed)
            .map((d) => d.id),
      );
    }
    if (futureDayIds.isEmpty) return;

    // Delete prescriptions first (Drift has no FK cascade).
    await (_db.delete(_db.exercisePrescriptions)
          ..where((t) => t.workoutDayId.isIn(futureDayIds)))
        .go();

    await (_db.delete(_db.workoutDays)
          ..where((t) => t.id.isIn(futureDayIds)))
        .go();
  }
}

final programRepositoryProvider = Provider<ProgramRepository>((ref) {
  return ProgramRepository(ref.watch(databaseProvider));
});
