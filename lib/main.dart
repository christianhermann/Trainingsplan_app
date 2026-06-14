import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/router.dart';
import 'app/theme.dart';

void main() async {
  // TODO: Initialize database
  // TODO: Load seed data into database
  // TODO: Initialize providers from persisted state
  runApp(
    const ProviderScope(
      child: TrainingsplanApp(),
    ),
  );
}

class TrainingsplanApp extends ConsumerWidget {
  const TrainingsplanApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);

    return MaterialApp.router(
      title: 'Trainingsplan',
      theme: appTheme,
      routerDelegate: router.routerDelegate,
      routeInformationParser: router.routeInformationParser,
      routeInformationProvider: router.routeInformationProvider,
    );
  }
}
