import 'package:drift/drift.dart' show Value;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/settings_repository.dart';
import '../../domain/models/app_settings.dart';
import '../../domain/models/enums.dart';

// ── Default settings (mirrors DB column defaults) ─────────────────────────────

const AppSettings kDefaultSettings = AppSettings(
  id: 'default',
  weightUnit: 'kg',
  roundingMode: 'nearest',
  roundingIncrement: 2.5,
  themeMode: 'dark',
  restTimerSeconds: 180,
  showVideoField: true,
  showNotesField: true,
);

// ── DB row → domain model adapter ──────────────────────────────────────────────

AppSettings _fromRow(AppSettingsTableData row) => AppSettings(
      id: row.id.toString(),
      weightUnit: row.weightUnit,
      roundingMode: row.roundingMode,
      roundingIncrement: row.roundingIncrement,
      themeMode: row.themeMode,
      restTimerSeconds: row.restTimerSeconds,
      showVideoField: row.showVideoField,
      showNotesField: row.showNotesField,
    );

// ── AsyncNotifier ────────────────────────────────────────────────────────────────

/// Manages [AppSettings] state, backed by the [AppSettingsTable] Drift table.
///
/// Pattern for every setter:
///   1. Derive the updated [AppSettings] via [copyWith].
///   2. Optimistically write it to state (instant UI response).
///   3. Persist to DB via [SettingsRepository.saveSettings].
///   No [invalidateSelf] needed — optimistic update keeps state fresh.
class SettingsNotifier extends AsyncNotifier<AppSettings?> {
  @override
  Future<AppSettings?> build() async {
    final row = await ref.watch(settingsRepositoryProvider).getSettings();
    return row != null ? _fromRow(row) : null;
  }

  // ── Public setters ──────────────────────────────────────────────────────

  Future<void> setWeightUnit(String unit) => _update(
      (s) => s.copyWith(weightUnit: unit),
      AppSettingsTableCompanion(weightUnit: Value(unit)));

  Future<void> setRoundingMode(RoundingMode mode) => _update(
        (s) => s.copyWith(roundingMode: mode.storedValue),
        AppSettingsTableCompanion(roundingMode: Value(mode.storedValue)),
      );

  Future<void> setRoundingIncrement(double increment) => _update(
        (s) => s.copyWith(roundingIncrement: increment),
        AppSettingsTableCompanion(roundingIncrement: Value(increment)),
      );

  Future<void> setThemeMode(String themeMode) => _update(
        (s) => s.copyWith(themeMode: themeMode),
        AppSettingsTableCompanion(themeMode: Value(themeMode)),
      );

  Future<void> setRestTimerSeconds(int seconds) => _update(
        (s) => s.copyWith(restTimerSeconds: seconds),
        AppSettingsTableCompanion(restTimerSeconds: Value(seconds)),
      );

  Future<void> toggleVideoField() {
    final current =
        state.value?.showVideoField ?? kDefaultSettings.showVideoField;
    final next = !current;
    return _update(
      (s) => s.copyWith(showVideoField: next),
      AppSettingsTableCompanion(showVideoField: Value(next)),
    );
  }

  Future<void> toggleNotesField() {
    final current =
        state.value?.showNotesField ?? kDefaultSettings.showNotesField;
    final next = !current;
    return _update(
      (s) => s.copyWith(showNotesField: next),
      AppSettingsTableCompanion(showNotesField: Value(next)),
    );
  }

  // ── Reset (danger zone) ─────────────────────────────────────────────────────

  Future<void> resetAllData() async {
    final db = ref.read(databaseProvider);
    await db.transaction(() async {
      await db.delete(db.exerciseLogs).go();
      await db.delete(db.exercisePrescriptions).go();
      await db.delete(db.workoutDays).go();
      await db.delete(db.workoutWeeks).go();
      await db.delete(db.programs).go();
      await db.delete(db.trainingMaxes).go();
    });
    // Settings rows are intentionally kept after a data reset.
  }

  // ── Private helper ────────────────────────────────────────────────────────

  /// Apply [transform] to current state optimistically, then persist
  /// [companion] to the DB.
  Future<void> _update(
    AppSettings Function(AppSettings) transform,
    AppSettingsTableCompanion companion,
  ) async {
    // Optimistic update — UI responds immediately.
    final current = state.value ?? kDefaultSettings;
    state = AsyncData(transform(current));

    // Persist to DB (fire-and-forget: state already updated).
    await ref.read(settingsRepositoryProvider).saveSettings(companion);
  }
}

// ── Provider ────────────────────────────────────────────────────────────────────────

final settingsProvider =
    AsyncNotifierProvider<SettingsNotifier, AppSettings?>(SettingsNotifier.new);
