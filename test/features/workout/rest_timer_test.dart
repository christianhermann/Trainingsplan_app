import 'package:flutter_test/flutter_test.dart';
import 'package:trainingsplan_app/features/workout/rest_timer_widget.dart';

void main() {
  group('RestTimerState Wall-Clock Logic', () {
    test('initial state calculates progress correctly', () {
      const state = RestTimerState(
        totalSeconds: 180,
        remaining: 180,
        isRunning: false,
      );

      expect(state.progress, 1.0);
      expect(state.isFinished, isFalse);
    });

    test('finished state identifies remaining == 0 and not running', () {
      const state = RestTimerState(
        totalSeconds: 180,
        remaining: 0,
        isRunning: false,
      );

      expect(state.progress, 0.0);
      expect(state.isFinished, isTrue);
    });

    test('copyWith updates targetEndTime and clearTarget works', () {
      final now = DateTime.now();
      final target = now.add(const Duration(seconds: 120));

      final state = const RestTimerState(
        totalSeconds: 180,
        remaining: 180,
        isRunning: false,
      ).copyWith(isRunning: true, targetEndTime: target);

      expect(state.isRunning, isTrue);
      expect(state.targetEndTime, target);

      final cleared = state.copyWith(isRunning: false, clearTarget: true);
      expect(cleared.isRunning, isFalse);
      expect(cleared.targetEndTime, isNull);
    });
  });
}
