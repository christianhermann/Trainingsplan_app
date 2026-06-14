import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/persistence/database.dart';
import 'workout_provider.dart';
import 'rest_timer_widget.dart';
import 'exercise_log_widget.dart';

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(todayWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: workoutAsync.maybeWhen(
          data: (state) => state == null
              ? const Text('Today')
              : Text('Week • Day ${state.dayIndex + 1}'),
          orElse: () => const Text('Today'),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'Setup',
            onPressed: () => context.go('/setup'),
          ),
        ],
      ),
      body: workoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _ErrorState(message: e.toString()),
        data: (state) {
          if (state == null) return const _EmptyState();
          return _WorkoutBody(state: state);
        },
      ),
    );
  }
}

class _WorkoutBody extends ConsumerWidget {
  const _WorkoutBody({required this.state});
  final TodayWorkoutState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        const RestTimerWidget(),
        Expanded(
          child: ListView.separated(
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
                liftName: lift?.displayName ?? 'Unknown',
                onLogUpdated: (updated) {
                  ref.read(todayWorkoutProvider.notifier).updateLog(updated);
                },
              );
            },
          ),
        ),
        if (!state.isCompleted)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            child: SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () =>
                    ref.read(todayWorkoutProvider.notifier).completeWorkout(),
                child: const Text('Complete Workout'),
              ),
            ),
          ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center,
                size: 64, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 16),
            Text('No workout for today',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(
              'Complete setup to generate your first program.',
              style: Theme.of(context).textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => GoRouter.of(context).go('/setup'),
              child: const Text('Go to Setup'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 48, color: Colors.redAccent),
            const SizedBox(height: 12),
            Text('Something went wrong',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Text(message,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
