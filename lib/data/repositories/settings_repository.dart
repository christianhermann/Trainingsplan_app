import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/database.dart';

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<AppSettingsTableData?> getSettings() =>
      (_db.select(_db.appSettingsTable)..limit(1)).getSingleOrNull();

  Future<void> saveSettings(AppSettingsTableCompanion companion) async {
    final existing = await getSettings();
    if (existing == null) {
      await _db.into(_db.appSettingsTable).insert(companion);
    } else {
      await (_db.update(_db.appSettingsTable)
            ..where((t) => t.id.equals(existing.id)))
          .write(companion);
    }
  }

  Stream<AppSettingsTableData?> watchSettings() =>
      (_db.select(_db.appSettingsTable)..limit(1)).watchSingleOrNull();
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});
