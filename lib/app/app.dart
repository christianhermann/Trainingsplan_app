import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/settings/settings_provider.dart';
import 'router.dart';
import 'theme.dart';

class TrainingsplanApp extends ConsumerWidget {
  const TrainingsplanApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router       = ref.watch(goRouterProvider);
    final settingsAsync = ref.watch(settingsProvider);

    // Map the persisted string → Flutter ThemeMode.
    // Falls back to dark while settings are loading.
    final themeMode = settingsAsync.whenOrNull(
          data: (s) => _toThemeMode(s?.themeMode ?? 'dark'),
        ) ??
        ThemeMode.dark;

    return MaterialApp.router(
      title:       'Trainingsplan',
      theme:       appTheme,
      darkTheme:   appThemeDark,
      themeMode:   themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }

  static ThemeMode _toThemeMode(String value) => switch (value) {
    'light'  => ThemeMode.light,
    'system' => ThemeMode.system,
    _        => ThemeMode.dark,
  };
}
