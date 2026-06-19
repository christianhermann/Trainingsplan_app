import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/persistence/database.dart';
import 'exercise_log_widget.dart';
import 'rest_timer_widget.dart';
import 'workout_provider.dart';

// ── Screen ──────────────────────────────────────────────────────────────────────

class TodayScreen extends ConsumerWidget {
  const TodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final workoutAsync = ref.watch(todayWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        centerTitle: false,
        title: workoutAsync.when(
          data: (s) => s != null
              ? _WorkoutHeaderTitle(
                  weekNumber:  s.weekNumber,
                  dayIndex:    s.dayIndex,
                  isCompleted: s.isCompleted,
                )
              : const Text('Today'),
          loading: () => const Text('Today'),
          error:   (_, __) => const Text('Today'),
        ),
        actions: [
          IconButton(
            icon:    const Icon(Icons.edit_rounded),
            tooltip: 'Edit Training Maxes',
            onPressed: () => context.push('/edit-training-maxes'),
          ),
        ],
      ),
      body: workoutAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => _ErrorView(message: e.toString()),
        data: (state) {
          if (state == null) return const _NoActiveProgram();
          return _WorkoutBody(state: state);
        },
      ),
      floatingActionButton: workoutAsync.maybeWhen(
        data: (s) {
          if (s == null || s.isCompleted) return null;
          return _CompleteWorkoutFab(
            onPressed: () => _onCompletePressed(context, ref),
          );
        },
        orElse: () => null,
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _onCompletePressed(BuildContext context, WidgetRef ref) async {
    // Confirm before completing.
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title:   const Text('Complete workout?'),
        content: const Text(
            'This will log progression and advance to the next training day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Complete'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    if (!context.mounted) return;

    HapticFeedback.mediumImpact();

    try {
      await ref.read(todayWorkoutProvider.notifier).completeWorkout();
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not complete workout: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}

// ── AppBar title ────────────────────────────────────────────────────────────────────

class _WorkoutHeaderTitle extends StatelessWidget {
  const _WorkoutHeaderTitle({
    required this.weekNumber,
    required this.dayIndex,
    required this.isCompleted,
  });
  final int  weekNumber;
  final int  dayIndex;
  final bool isCompleted;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final cs = Theme.of(context).colorScheme;
    return Row(
      children: [
        Text(
          'Week $weekNumber  ·  Day ${dayIndex + 1}',
          style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        if (isCompleted) ...[
          const SizedBox(width: 8),
          Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
        ],
      ],
    );
  }
}

// ── Body ────────────────────────────────────────────────────────────────────────

class _WorkoutBody extends StatelessWidget {
  const _WorkoutBody({required this.state});
  final TodayWorkoutState state;

  @override
  Widget build(BuildContext context) {
    final main = state.prescriptions
        .where((p) => p.isPrimaryBlock)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final auxiliary = state.prescriptions
        .where((p) => !p.isPrimaryBlock)
        .toList()
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));

    final items = <_ListItem>[
      if (main.isNotEmpty)       const _SectionHeaderItem('Main'),
      for (final p in main)      _CardItem(p),
      if (auxiliary.isNotEmpty)  const _SectionHeaderItem('Auxiliary'),
      for (final p in auxiliary) _CardItem(p),
    ];

    return Column(
      children: [
        if (state.isCompleted) const _CompletedBanner(),
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final item = items[i];
              return switch (item) {
                _SectionHeaderItem() => _SectionHeader(label: item.label),
                _CardItem()         => _ExerciseCard(
                    prescription: item.prescription,
                    log:          state.logs[item.prescription.id],
                    liftName:     state.lifts[item.prescription.liftId]
                                      ?.displayName ?? 'Exercise',
                    isCompleted:  state.isCompleted,
                  ),
              };
            },
          ),
        ),
        const RestTimerWidget(),
        const SizedBox(height: 80),
      ],
    );
  }
}

// ── Sealed list item types ─────────────────────────────────────────────────────────

sealed class _ListItem {
  const _ListItem();
}

final class _SectionHeaderItem extends _ListItem {
  const _SectionHeaderItem(this.label);
  final String label;
}

final class _CardItem extends _ListItem {
  const _CardItem(this.prescription);
  final ExercisePrescription prescription;
}

// ── Section header ─────────────────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize:      11,
          fontWeight:    FontWeight.w700,
          letterSpacing: 1.4,
          color: cs.onSurface.withValues(alpha: 0.45),
        ),
      ),
    );
  }
}

// ── Exercise card ────────────────────────────────────────────────────────────────────────

class _ExerciseCard extends ConsumerWidget {
  const _ExerciseCard({
    required this.prescription,
    required this.log,
    required this.liftName,
    required this.isCompleted,
  });

  final ExercisePrescription prescription;
  final ExerciseLog?          log;
  final String                liftName;
  final bool                  isCompleted;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs      = Theme.of(context).colorScheme;
    final tt      = Theme.of(context).textTheme;
    final p       = prescription;
    final isLogged = log?.repsOnLastSet != null;

    return Opacity(
      opacity: isCompleted ? 0.6 : 1.0,
      child: Card(
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Lift name row
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _formatLiftName(liftName),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
                  if (isLogged)
                    Icon(Icons.check_circle_rounded,
                        color: cs.primary, size: 20),
                ],
              ),

              const SizedBox(height: 12),

              // Working weight
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    p.workingWeight % 1 == 0
                        ? '${p.workingWeight.toInt()} kg'
                        : '${p.workingWeight.toStringAsFixed(1)} kg',
                    style: tt.displaySmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: cs.primary,
                      height: 1,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Text(
                      '${p.setGoal} sets × ${p.repsPerNormalSet} reps',
                      style: tt.bodyMedium?.copyWith(
                        color: cs.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 6),

              // Rep-out target chip
              _RepOutChip(
                target:   p.repOutTarget,
                isLogged: isLogged,
                actual:   log?.repsOnLastSet,
              ),

              const Divider(height: 24, thickness: 0.5),

              // Logging form
              ExerciseLogWidget(
                prescription: p,
                log:          log,
                liftName:     liftName,
                onLogUpdated: (companion) => ref
                    .read(todayWorkoutProvider.notifier)
                    .updateLog(companion),
                showHeader: false,
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLiftName(String raw) {
    return raw
        .replaceAll('_', ' ')
        .split(' ')
        .map((w) => w.isEmpty ? w : w[0].toUpperCase() + w.substring(1))
        .join(' ');
  }
}

// ── Rep-out target chip ─────────────────────────────────────────────────────────────────────

class _RepOutChip extends StatelessWidget {
  const _RepOutChip({
    required this.target,
    required this.isLogged,
    this.actual,
  });
  final int  target;
  final bool isLogged;
  final int? actual;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color  bg;
    Color  fg;
    String label;

    if (!isLogged) {
      bg    = cs.secondaryContainer;
      fg    = cs.onSecondaryContainer;
      label = 'Last set target  ≥ $target';
    } else {
      final beat = (actual ?? 0) >= target;
      bg    = beat ? cs.primaryContainer   : cs.errorContainer;
      fg    = beat ? cs.onPrimaryContainer : cs.onErrorContainer;
      label = beat
          ? 'Last set  $actual  (target $target ✓)'
          : 'Last set  $actual  (target $target ✗)';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(
        label,
        style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: fg),
      ),
    );
  }
}

// ── Complete Workout FAB ────────────────────────────────────────────────────────────────────

class _CompleteWorkoutFab extends StatelessWidget {
  const _CompleteWorkoutFab({required this.onPressed});
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return FloatingActionButton.extended(
      onPressed:       onPressed,
      backgroundColor: cs.primary,
      foregroundColor: cs.onPrimary,
      elevation:       4,
      icon:  const Icon(Icons.check_rounded),
      label: const Text(
        'Complete Workout',
        style: TextStyle(fontWeight: FontWeight.w700),
      ),
    );
  }
}

// ── Completed banner ─────────────────────────────────────────────────────────────────────────

class _CompletedBanner extends StatelessWidget {
  const _CompletedBanner();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      width:   double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 16),
      color:   cs.primaryContainer.withValues(alpha: 0.6),
      child: Row(
        children: [
          Icon(Icons.check_circle_rounded, color: cs.primary, size: 18),
          const SizedBox(width: 8),
          Text(
            'Workout completed — great work!',
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: cs.onPrimaryContainer),
          ),
        ],
      ),
    );
  }
}

// ── Empty / error states ───────────────────────────────────────────────────────────────────────

class _NoActiveProgram extends StatelessWidget {
  const _NoActiveProgram();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.fitness_center_rounded,
                size: 56, color: cs.onSurface.withValues(alpha: 0.25)),
            const SizedBox(height: 16),
            Text(
              'No active program',
              style: tt.titleLarge?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              'Head to Setup to configure your training maxes and generate a program.',
              textAlign: TextAlign.center,
              style: tt.bodyMedium?.copyWith(
                  color: cs.onSurface.withValues(alpha: 0.55)),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text('Error: $message',
            style: TextStyle(
                color: Theme.of(context).colorScheme.error)),
      ),
    );
  }
}
