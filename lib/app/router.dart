import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/repositories/program_repository.dart';
import '../features/history/history_detail_screen.dart';
import '../features/history/history_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/setup/setup_screen.dart';
import '../features/workout/today_screen.dart';
import 'nav_shell.dart';

final goRouterProvider = Provider<GoRouter>((ref) {
  final programRepo = ref.read(programRepositoryProvider);

  return GoRouter(
    initialLocation: '/today',
    redirect: (context, state) async {
      // On first launch, check if an active program exists.
      // If not, redirect to setup (unless already heading there).
      if (state.matchedLocation == '/setup') return null;
      final active = await programRepo.getActiveProgram();
      if (active == null) return '/setup';
      return null;
    },
    routes: [
      ShellRoute(
        builder: (context, state, child) => NavShell(child: child),
        routes: [
          GoRoute(
            path: '/today',
            name: 'today',
            builder: (context, state) => const TodayScreen(),
          ),
          GoRoute(
            path: '/history',
            name: 'history',
            builder: (context, state) => const HistoryScreen(),
            routes: [
              GoRoute(
                path: ':dayId',
                name: 'history-detail',
                builder: (context, state) {
                  final dayId =
                      int.parse(state.pathParameters['dayId'] ?? '0');
                  return HistoryDetailScreen(dayId: dayId);
                },
              ),
            ],
          ),
          GoRoute(
            path: '/setup',
            name: 'setup',
            builder: (context, state) => const SetupScreen(),
          ),
          GoRoute(
            path: '/settings',
            name: 'settings',
            builder: (context, state) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
});
