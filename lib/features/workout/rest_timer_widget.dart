import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/notification_service.dart';
import '../settings/settings_provider.dart';

// ── Timer state ───────────────────────────────────────────────────────────────────

class RestTimerState {
  const RestTimerState({
    required this.totalSeconds,
    required this.remaining,
    required this.isRunning,
    this.targetEndTime,
  });
  final int totalSeconds;
  final int remaining;
  final bool isRunning;
  final DateTime? targetEndTime;

  bool get isFinished => !isRunning && remaining == 0;
  double get progress =>
      totalSeconds == 0 ? 0 : remaining / totalSeconds;

  RestTimerState copyWith({
    int? totalSeconds,
    int? remaining,
    bool? isRunning,
    DateTime? targetEndTime,
    bool clearTarget = false,
  }) =>
      RestTimerState(
        totalSeconds: totalSeconds ?? this.totalSeconds,
        remaining: remaining ?? this.remaining,
        isRunning: isRunning ?? this.isRunning,
        targetEndTime: clearTarget ? null : (targetEndTime ?? this.targetEndTime),
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────────

class RestTimerNotifier extends Notifier<RestTimerState>
    with WidgetsBindingObserver {
  static const _defaultSeconds = 180;
  Timer? _timer;

  @override
  RestTimerState build() {
    WidgetsBinding.instance.addObserver(this);
    // React to settings changes: reset duration whenever restTimerSeconds changes.
    ref.listen(settingsProvider, (_, next) {
      next.whenData((s) {
        if (s != null) setDuration(s.restTimerSeconds);
      });
    });
    ref.onDispose(() {
      WidgetsBinding.instance.removeObserver(this);
      _timer?.cancel();
    });
    return const RestTimerState(
      totalSeconds: _defaultSeconds,
      remaining: _defaultSeconds,
      isRunning: false,
    );
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && this.state.isRunning) {
      _onTick();
    }
  }

  void start() {
    if (state.isRunning) return;
    final target = DateTime.now().add(Duration(seconds: state.remaining));
    state = state.copyWith(isRunning: true, targetEndTime: target);

    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => _onTick());
  }

  void _onTick() {
    if (!state.isRunning || state.targetEndTime == null) return;
    final diff = state.targetEndTime!.difference(DateTime.now()).inSeconds;
    if (diff <= 0) {
      _timer?.cancel();
      HapticFeedback.vibrate();
      NotificationService.showRestFinishedNotification();
      state = state.copyWith(
        remaining: 0,
        isRunning: false,
        clearTarget: true,
      );
    } else {
      state = state.copyWith(remaining: diff);
    }
  }

  void stop() {
    _timer?.cancel();
    NotificationService.cancelRestNotification();
    state = state.copyWith(isRunning: false, clearTarget: true);
  }

  void reset() {
    _timer?.cancel();
    NotificationService.cancelRestNotification();
    state = state.copyWith(
      remaining: state.totalSeconds,
      isRunning: false,
      clearTarget: true,
    );
  }

  void setDuration(int seconds) {
    _timer?.cancel();
    state = RestTimerState(
      totalSeconds: seconds,
      remaining: seconds,
      isRunning: false,
      targetEndTime: null,
    );
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
