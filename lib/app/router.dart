import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/setup/setup_screen.dart';
import '../features/workout/today_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';

/// Router provider for navigation.
final goRouterProvider = Provider((ref) {
  return GoRouter(
    // TODO: Determine initial route based on setup completion state
    initialLocation: '/setup',
    routes: [
      GoRoute(
        path: '/setup',
        name: 'setup',
        builder: (context, state) => const SetupScreen(),
      ),
      GoRoute(
        path: '/today',
        name: 'today',
        builder: (context, state) => const TodayScreen(),
      ),
      GoRoute(
        path: '/history',
        name: 'history',
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: '/settings',
        name: 'settings',
        builder: (context, state) => const SettingsScreen(),
      ),
    ],
  );
});
