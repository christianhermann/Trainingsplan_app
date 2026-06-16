import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/workout_repository.dart';
import 'rest_timer_widget.dart';
import 'workout_provider.dart';
import 'exercise_log_widget.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(todayWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: workoutAsync.when(
          data: (s) => Text(
            s != null ? 'Week ${s.weekNumber} · Day ${s.dayIndex + 1}' : 'Today',
          ),
          loading: () => const Text('Today'),
          error: (_, __) => const Text('Today'),
        ),
        actions: [
          workoutAsync.when(
            data: (s) => s != null && !s.isCompleted
                ? TextButton(
                    onPressed: () => ref
                        .read(todayWorkoutProvider.notifier)
                        .completeWorkout(),
                    child: const Text('Complete'),
                  )
                : const SizedBox.shrink(),
            loading: () => const SizedBox.shrink(),
            error: (_, __) => const SizedBox.shrink(),
          ),
        ],
      ),
      body: Column(
        children: [
          const RestTimerWidget(),
          Expanded(
            child: workoutAsync.when(
              loading: () =>
                  const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
              data: (state) {
                if (state == null) {
                  return const Center(
                    child: Text('No active program. Go to Setup to start.'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.prescriptions.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, i) {
                    final prescription = state.prescriptions[i];
                    final log = state.logs[prescription.id];
                    final lift = state.lifts[prescription.liftId];
                    return ExerciseLogWidget(
                      prescription: prescription,
                      log: log,
                      liftName: lift?.displayName ?? 'Exercise',
                      onLogSaved: (companion) => ref
                          .read(todayWorkoutProvider.notifier)
                          .updateLog(
                            WorkoutRepositoryCompanionHelper
                                .exerciseLogsCompanionFrom(companion),
                          ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
