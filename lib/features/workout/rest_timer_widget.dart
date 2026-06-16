import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../settings/settings_provider.dart';

// ── Timer state ───────────────────────────────────────────────────────────────────

class RestTimerState {
  const RestTimerState({
    required this.totalSeconds,
    required this.remaining,
    required this.isRunning,
  });
  final int  totalSeconds;
  final int  remaining;
  final bool isRunning;

  bool   get isFinished => !isRunning && remaining == 0;
  double get progress   =>
      totalSeconds == 0 ? 0 : remaining / totalSeconds;

  RestTimerState copyWith({
    int?  totalSeconds,
    int?  remaining,
    bool? isRunning,
  }) =>
      RestTimerState(
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remaining:    remaining    ?? this.remaining,
        isRunning:    isRunning    ?? this.isRunning,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────────

class RestTimerNotifier extends Notifier<RestTimerState> {
  static const _defaultSeconds = 180;
  Timer? _timer;

  @override
  RestTimerState build() {
    // React to settings changes: reset duration whenever restTimerSeconds changes.
    ref.listen(settingsProvider, (_, next) {
      next.whenData((s) {
        if (s != null) setDuration(s.restTimerSeconds);
      });
    });
    ref.onDispose(() => _timer?.cancel());
    return const RestTimerState(
      totalSeconds: _defaultSeconds,
      remaining:    _defaultSeconds,
      isRunning:    false,
    );
  }

  void start() {
    if (state.isRunning) return;
    state = state.copyWith(isRunning: true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (state.remaining <= 0) {
        _timer?.cancel();
        state = state.copyWith(isRunning: false);
      } else {
        state = state.copyWith(remaining: state.remaining - 1);
      }
    });
  }

  void stop() {
    _timer?.cancel();
    state = state.copyWith(isRunning: false);
  }

  void reset() {
    _timer?.cancel();
    state = state.copyWith(remaining: state.totalSeconds, isRunning: false);
  }

  void setDuration(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
        totalSeconds: seconds, remaining: seconds, isRunning: false);
  }
}

final restTimerProvider =
    NotifierProvider<RestTimerNotifier, RestTimerState>(RestTimerNotifier.new);

// ── Widget ────────────────────────────────────────────────────────────────────────

class RestTimerWidget extends ConsumerWidget {
  const RestTimerWidget({super.key});

  String _fmt(int s) =>
      '${(s ~/ 60).toString().padLeft(2, '0')}:'
      '${(s % 60).toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timer = ref.watch(restTimerProvider);
    final cs    = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.4),
        border: Border(
            bottom: BorderSide(color: cs.outlineVariant, width: 0.5)),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: Stack(
              fit: StackFit.expand,
              children: [
                CircularProgressIndicator(
                  value:           timer.progress,
                  strokeWidth:     3,
                  backgroundColor: cs.outlineVariant,
                  valueColor:      AlwaysStoppedAnimation<Color>(
                      timer.isFinished ? cs.error : cs.primary),
                ),
                Center(
                  child: Text(
                    _fmt(timer.remaining),
                    style: TextStyle(
                        fontSize:   9,
                        fontWeight: FontWeight.bold,
                        color: timer.isFinished ? cs.error : cs.onSurface),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text('Rest timer', style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          IconButton(
            icon: Icon(timer.isRunning ? Icons.pause : Icons.play_arrow),
            onPressed: () => timer.isRunning
                ? ref.read(restTimerProvider.notifier).stop()
                : ref.read(restTimerProvider.notifier).start(),
          ),
          IconButton(
            icon:      const Icon(Icons.refresh),
            onPressed: () => ref.read(restTimerProvider.notifier).reset(),
          ),
        ],
      ),
    );
  }
}
