import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../persistence/database.dart';

class SettingsRepository {
  SettingsRepository(this._db);
  final AppDatabase _db;

  Future<AppSettingsTableData?> getSettings() =>
      (_db.select(_db.appSettingsTable)..limit(1)).getSingleOrNull();

  Future<void> saveSettings(AppSettingsTableCompanion companion) =>
      _db.update(_db.appSettingsTable).write(companion);
}

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  return SettingsRepository(ref.watch(databaseProvider));
});
