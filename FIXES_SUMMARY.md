# Fixes Summary - Trainingsplan App

Branch: `fix/progression-and-data-integrity`

Erster Commit bereits umgesetzt:
- ✅ **Fix #2,#3**: `progression_service.dart` - Set-Failure-Logik implementiert

---

## Fix #4: exercise_log_widget.dart - completedSets als editierbares Feld

**Datei:** `lib/features/workout/exercise_log_widget.dart`

**Problem:** completedSets wird nicht vom User eingegeben, sondern hardcodiert auf setGoal gesetzt.

**Loesung:** TextField fuer completedSets hinzufuegen, aehnlich wie repsOnLastSet.

**Code-Aenderung:**
```dart
// Im Widget State: completedSets als Variable hinzufuegen
int _completedSets = exerciseLog.completedSets ?? prescription.setGoal;

// TextField hinzufuegen (nach repsOnLastSet TextField):
TextField(
  initialValue: _completedSets.toString(),
  keyboardType: TextInputType.number,
  onChanged: (value) {
    setState(() => _completedSets = int.tryParse(value) ?? prescription.setGoal);
  },
  decoration: const InputDecoration(
    labelText: 'Completed Sets',
    border: OutlineInputBorder(),
  ),
),

// Beim Speichern:
final updatedLog = exerciseLog.copyWith(
  repsOnLastSet: _repsOnLastSet,
  completedSets: _completedSets, // NEU
);
```

**Commit Message:** `Fix #4: exercise_log_widget - completedSets als editierbares Feld`

---

## Fix #5: workout_provider.dart - completeWorkout mit regenerateFromWeek

**Datei:** `lib/features/workout/workout_provider.dart`

**Problem:** completeWorkout aktualisiert nicht die prescription bei TM-Aenderungen.

**Loesung:** regenerateFromWeek() nach saveTrainingMax aufrufen.

**Code-Aenderung:**
```dart
Future<void> completeWorkout() async {
  // ... existing code ...
  
  // AFTER saving training max:
  await regenerateFromWeek(); // NEU - aktualisiert prescriptions
  
  state = state.copyWith(isWorkoutComplete: true);
}
```

**Commit Message:** `Fix #5: workout_provider - regenerateFromWeek nach completeWorkout`

---

## Fix #6: backup_service.dart - Vollstaendiges Backup/Restore

**Datei:** `lib/data/services/backup_service.dart`

**Problem:** Backup exportiert nur workouts, nicht training_max oder settings.

**Loesung:** Alle Tabellen exportieren/importieren.

**Code-Aenderung:**
```dart
// Export-Methode erweitern:
Future<String> exportBackup() async {
  final db = await _database;
  
  final backup = {
    'version': 1,
    'timestamp': DateTime.now().toIso8601String(),
    'workouts': await db.exportWorkouts(),
    'training_max': await db.exportTrainingMax(), // NEU
    'settings': await db.exportSettings(), // NEU
    'exercise_logs': await db.exportExerciseLogs(), // NEU
  };
  
  return jsonEncode(backup);
}

// Import-Methode erweitern:
Future<void> importBackup(String jsonStr) async {
  final backup = jsonDecode(jsonStr) as Map<String, dynamic>;
  
  await db.importWorkouts(backup['workouts']);
  await db.importTrainingMax(backup['training_max']); // NEU
  await db.importSettings(backup['settings']); // NEU
  await db.importExerciseLogs(backup['exercise_logs']); // NEU
}
```

**Commit Message:** `Fix #6: backup_service - alle Tabellen exportieren/importieren`

---

## Fix #7: frequency_template_seeder.dart - 2x Template pruefen

**Datei:** `lib/data/seeding/frequency_template_seeder.dart`

**Problem:** 2x/Woche Template wird nicht korrekt erstellt.

**Loesung:** Explizite Pruefung und Erstellung fuer 2x Frequenz.

**Code-Aenderung:**
```dart
// In createTemplatesForFrequency():
if (frequency == 2) {
  // Explizites 2x Template erstellen
  templates.add(FrequencyTemplate(
    frequency: 2,
    day1Exercises: [...], // Squat, Bench
    day2Exercises: [...], // Deadlift, OHP
  ));
}
```

**Commit Message:** `Fix #7: frequency_template_seeder - 2x Template explizit erstellen`

---

## Fix #8: edit_training_max_provider.dart - Aux-TMs beibehalten

**Datei:** `lib/features/settings/edit_training_max_provider.dart` (oder aehnliche Datei)

**Problem:** Beim Bearbeiten von main lifts werden aux lifts zurueckgesetzt.

**Loesung:** Nur das bearbeitete TM updaten, nicht alle loeschen.

**Code-Aenderung:**
```dart
// Statt alle TMs zu loeschen und neu zu erstellen:
await trainingMaxRepository.deleteByLiftId(liftId); // Nur dieses Lift loeschen
await trainingMaxRepository.insert(updatedTM); // Neues TM eintragen

// Alternative: update-Methode verwenden:
await trainingMaxRepository.update(updatedTM); // NEU
```

**Commit Message:** `Fix #8: edit_training_max - Aux-TMs beim Update beibehalten`

---

## Fix #9: nav_shell.dart - Tab-Highlighting fix

**Datei:** `lib/features/nav/nav_shell.dart`

**Problem:** Navigation highlight ist nicht synchron mit aktuellem Tab.

**Loesung:** currentIndex korrekt setzen.

**Code-Aenderung:**
```dart
NavigationShell(
  currentIndex: _controller.currentIndex, // Sicherstellen dass synchron
  // ...
)
```

**Commit Message:** `Fix #9: nav_shell - Tab-Highlighting synchronisieren`

---

## Fix #10: rest_timer_widget.dart - auf Notifier migrieren

**Datei:** `lib/features/workout/rest_timer_widget.dart`

**Problem:** Verwendet veraltetes State-Management.

**Loesung:** Auf Notifier/StateNotifier migrieren.

**Code-Aenderung:**
```dart
// Neues Notifier-Pattern:
class RestTimerNotifier extends StateNotifier<RestTimerState> {
  RestTimerNotifier() : super(RestTimerState.initial());
  
  void startTimer(int seconds) {
    state = state.copyWith(isRunning: true, remainingSeconds: seconds);
    // Timer logic...
  }
}

// Widget:
final timer = ref.watch(restTimerProvider);
// ...
```

**Commit Message:** `Fix #10: rest_timer_widget - auf Notifier migrieren`

---

## Fix #11: training_max_repository.dart - deterministische Sortierung

**Datei:** `lib/data/repositories/training_max_repository.dart`

**Problem:** TMs werden nicht konsistent sortiert zurueckgegeben.

**Loesung:** ORDER BY in SQL-Query hinzufuegen.

**Code-Aenderung:**
```dart
// In getAll():
final results = await db.query(
  'training_max',
  orderBy: 'lift_id ASC, week_number ASC', // NEU
);
```

**Commit Message:** `Fix #11: training_max_repository - deterministische Sortierung`

---

## Fix #12: exercise_log.dart - completedSets nullable

**Datei:** `lib/domain/models/exercise_log.dart`

**Problem:** completedSets ist required, sollte nullable sein fuer legacy Logs.

**Loesung:** completedSets als nullable definieren.

**Code-Aenderung:**
```dart
class ExerciseLog {
  // ...
  final int? completedSets; // Von required int zu int? aendern
  
  // In fromJson:
  completedSets: json['completed_sets'] as int?, // Nullable
  
  // In toJson:
  'completed_sets': completedSets, // Kann null sein
}
```

**Commit Message:** `Fix #12: exercise_log - completedSets nullable fuer Legacy-Support`

---

## Fix #13: exercise_prescription.dart - setGoal korrekt mappen

**Datei:** `lib/domain/models/exercise_prescription.dart`

**Problem:** setGoal wird nicht korrekt aus DB geladen.

**Loesung:** Spaltenname pruefen und korrekt mappen.

**Code-Aenderung:**
```dart
// In fromJson:
setGoal: json['set_goal'] as int? ?? 3, // Default 3 wenn null

// In toJson:
'set_goal': setGoal,
```

**Commit Message:** `Fix #13: exercise_prescription - setGoal korrekt mappen`

---

## Fix #14: workout_screen.dart - UI-Updates nach Regeneration

**Datei:** `lib/features/workout/workout_screen.dart`

**Problem:** UI zeigt alte prescriptions nach TM-Update.

**Loesung:** Provider-Update erzwingen nach regenerateFromWeek.

**Code-Aenderung:**
```dart
// Nach regenerateFromWeek:
ref.invalidate(workoutProvider); // Provider neu laden
```

**Commit Message:** `Fix #14: workout_screen - UI-Update nach Regeneration`

---

## Fix #15: frequency_template_seeder.dart - 3x Template orientieren

**Datei:** `lib/data/seeding/frequency_template_seeder.dart`

**Problem:** 3x Template sollte als Basis fuer andere Frequenzen dienen.

**Loesung:** 3x Template als Referenz verwenden.

**Code-Aenderung:**
```dart
// 3x Template zuerst definieren:
final template3x = FrequencyTemplate(
  frequency: 3,
  exercises: [squat, bench, deadlift, ohp],
);

// Andere Frequenzen davon ableiten:
final template2x = template3x.copyWith(
  frequency: 2,
  // Anpassungen...
);
```

**Commit Message:** `Fix #15: frequency_template_seeder - 3x Template als Basis`

---

## Fix #1: Flache Intensitaet (bereits bestaetigt)

**Status:** Keine Aenderung noetig - aktuelle Implementierung ist korrekt laut User.

---

## Zusammenfassung der Commits

1. ✅ `Fix #2,#3: Set-Failure-Logik in ProgressionService - completedSets hat Prioritaet`
2. ⏳ `Fix #4: exercise_log_widget - completedSets als editierbares Feld`
3. ⏳ `Fix #5: workout_provider - regenerateFromWeek nach completeWorkout`
4. ⏳ `Fix #6: backup_service - alle Tabellen exportieren/importieren`
5. ⏳ `Fix #7: frequency_template_seeder - 2x Template explizit erstellen`
6. ⏳ `Fix #8: edit_training_max - Aux-TMs beim Update beibehalten`
7. ⏳ `Fix #9: nav_shell - Tab-Highlighting synchronisieren`
8. ⏳ `Fix #10: rest_timer_widget - auf Notifier migrieren`
9. ⏳ `Fix #11: training_max_repository - deterministische Sortierung`
10. ⏳ `Fix #12: exercise_log - completedSets nullable fuer Legacy-Support`
11. ⏳ `Fix #13: exercise_prescription - setGoal korrekt mappen`
12. ⏳ `Fix #14: workout_screen - UI-Update nach Regeneration`
13. ⏳ `Fix #15: frequency_template_seeder - 3x Template als Basis`

---

## Naechste Schritte

1. Datei-fuer-Datei die obigen Aenderungen im Branch `fix/progression-and-data-integrity` umsetzen
2. Jede Aenderung mit `flutter analyze` pruefen
3. Nach allen Aenderungen: PR erstellen und Review anfordern
4. Nach Approval: in main mergen

**Branch URL:** https://github.com/christianhermann/Trainingsplan_app/tree/fix/progression-and-data-integrity
