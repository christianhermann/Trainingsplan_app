import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'data/persistence/database.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ProviderScope(
      overrides: [
        // Eagerly create the DB so the provider is ready before first frame
        databaseProvider.overrideWith((ref) {
          final db = AppDatabase();
          ref.onDispose(db.close);
          return db;
        }),
      ],
      child: const TrainingsplanApp(),
    ),
  );
}
