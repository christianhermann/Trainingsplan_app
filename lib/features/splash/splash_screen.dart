import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/widgets/ronnie_loading_indicator.dart';
import '../../data/repositories/program_repository.dart';

/// Full opening splash screen featuring animated comic Ronnie Coleman.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  bool _navigated = false;

  @override
  void initState() {
    super.initState();
    _startApp();
  }

  Future<void> _startApp() async {
    final stopwatch = Stopwatch()..start();
    final programRepo = ref.read(programRepositoryProvider);

    // Warm up database and resolve active program
    final active = await programRepo.getActiveProgram();
    if (active != null) {
      await programRepo.deduplicateDaysForProgram(active.id);
    }

    // Keep splash animation visible for 1500ms so the user can enjoy Ronnie lifting
    final elapsed = stopwatch.elapsedMilliseconds;
    final remaining = 1500 - elapsed;
    if (remaining > 0) {
      await Future.delayed(Duration(milliseconds: remaining));
    }

    _navigateNext(active != null);
  }

  void _navigateNext(bool hasActiveProgram) {
    if (_navigated || !mounted) return;
    _navigated = true;
    context.go(hasActiveProgram ? '/today' : '/setup');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: cs.surface,
      body: InkWell(
        // Allow immediate skip by tapping anywhere
        onTap: () async {
          final active =
              await ref.read(programRepositoryProvider).getActiveProgram();
          _navigateNext(active != null);
        },
        child: SafeArea(
          child: SizedBox.expand(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Spacer(flex: 3),
                const RonnieLoadingIndicator(
                  size: 160,
                  message: 'WARMING UP YOUR WORKOUT...',
                ),
                const Spacer(flex: 2),
                Text(
                  'TRAININGSPLAN',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: 2.0,
                    color: cs.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Stronger by Science Linear Progression',
                  style: tt.bodySmall?.copyWith(
                    color: cs.onSurfaceVariant.withValues(alpha: 0.7),
                    letterSpacing: 0.5,
                  ),
                ),
                const Spacer(flex: 2),
                Padding(
                  padding: const EdgeInsets.only(bottom: 24),
                  child: Text(
                    'Tap anywhere to skip',
                    style: tt.labelSmall?.copyWith(
                      color: cs.outline.withValues(alpha: 0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
