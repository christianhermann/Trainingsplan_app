import '../../core/widgets/ronnie_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/persistence/database.dart';
import 'exercise_log_widget.dart';
import 'rest_timer_widget.dart';
import 'plate_calculator_widget.dart';
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
          PopupMenuButton<String>(
            tooltip: 'Session options',
            icon: const Icon(Icons.more_vert_rounded),
            onSelected: (value) async {
              switch (value) {
                case 'repeat_week':
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Repeat this week?'),
                      content: const Text(
                        'This will reset all days in the current week to planned and clear their exercise logs.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Repeat Week'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(todayWorkoutProvider.notifier).repeatWeek();
                  }
                  break;
                case 'skip_day':
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text("Skip today's workout?"),
                      content: const Text(
                        'This will mark today as skipped and advance to the next scheduled day.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Skip Workout'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref.read(todayWorkoutProvider.notifier).skipDay();
                  }
                  break;
                case 'deload_week':
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (dCtx) => AlertDialog(
                      title: const Text('Apply Deload Mode?'),
                      content: const Text(
                        'This will reduce working weights to ~70% and volume to 2-3 sets with no AMRAP for all remaining days this week.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(dCtx, false),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          onPressed: () => Navigator.pop(dCtx, true),
                          child: const Text('Apply Deload'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true && context.mounted) {
                    await ref
                        .read(todayWorkoutProvider.notifier)
                        .applyDeloadToCurrentWeek();
                  }
                  break;
              }
            },
            itemBuilder: (ctx) => const [
              PopupMenuItem(
                value: 'repeat_week',
                child: Row(
                  children: [
                    Icon(Icons.replay_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Repeat Current Week'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'skip_day',
                child: Row(
                  children: [
                    Icon(Icons.skip_next_rounded, size: 20),
                    SizedBox(width: 12),
                    Text("Skip Today's Workout"),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'deload_week',
                child: Row(
                  children: [
                    Icon(Icons.battery_charging_full_rounded, size: 20),
                    SizedBox(width: 12),
                    Text('Apply Deload to Week'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: workoutAsync.when(
        loading: () => const Center(child: RonnieLoadingIndicator(message: 'Loading today\'s workout...')),
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
      builder: (dialogContext) => AlertDialog(
        title:   const Text('Complete workout?'),
        content: const Text(
            'This will log progression and advance to the next training day.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
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

    double totalTonnage = 0.0;
    int totalSetsDone = 0;
    final logTimes = <DateTime>[];

    for (final p in state.prescriptions) {
      final l = state.logs[p.id];
      if (l != null && l.completedSets > 0) {
        final normalSets = (l.completedSets - 1).clamp(0, 999);
        final normalReps = normalSets * p.repsPerNormalSet;
        final lastReps = l.repsOnLastSet ?? p.repsPerNormalSet;
        totalTonnage += (normalReps + lastReps) * p.workingWeight;
        totalSetsDone += l.completedSets;
        logTimes.add(l.completedAt);
      }
    }

    int durationMin = 0;
    if (logTimes.isNotEmpty) {
      logTimes.sort();
      final diff = DateTime.now().difference(logTimes.first).inMinutes;
      durationMin = (diff >= 5 && diff <= 180)
          ? diff
          : (totalSetsDone * 3.5).round().clamp(10, 120);
    }

    return Column(
      children: [
        if (state.isCompleted)
          _CompletedBanner(
            totalTonnage: totalTonnage,
            durationMinutes: durationMin,
          )
        else if (totalSetsDone > 0)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.5),
            child: Row(
              children: [
                Icon(Icons.bolt_rounded,
                    size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 6),
                Text(
                  'Sets done: $totalSetsDone · Volume: ${totalTonnage.toStringAsFixed(0)} kg',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
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
                    key:          ValueKey('card_${item.prescription.id}'),
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

// ── List item discriminator ──────────────────────────────────────────────────────

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
    super.key,
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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

              // Working weight (tap to open Plate Calculator & Warmup Ramp)
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () => PlateCalculatorSheet.show(
                      context,
                      targetWeight: p.workingWeight,
                      liftName: _formatLiftName(liftName),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
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
                          const SizedBox(width: 6),
                          Icon(
                            Icons.calculate_outlined,
                            size: 22,
                            color: cs.primary.withValues(alpha: 0.8),
                          ),
                        ],
                      ),
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
                key:          ValueKey('log_${p.id}'),
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

// ── Rep-out target chip ────────────────────────────────────────────────────────────────────

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
  const _CompletedBanner({this.totalTonnage, this.durationMinutes});
  final double? totalTonnage;
  final int? durationMinutes;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final density = (durationMinutes != null &&
            durationMinutes! > 0 &&
            totalTonnage != null)
        ? (totalTonnage! / durationMinutes!).round()
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      color: cs.primaryContainer.withValues(alpha: 0.6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle_rounded, color: cs.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Workout completed — great work!',
                style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: cs.onPrimaryContainer),
              ),
            ],
          ),
          if (totalTonnage != null && totalTonnage! > 0) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 14,
              runSpacing: 4,
              children: [
                _BannerMetric(
                  icon: Icons.fitness_center_rounded,
                  label: '${totalTonnage!.toStringAsFixed(0)} kg volume',
                ),
                if (durationMinutes != null && durationMinutes! > 0)
                  _BannerMetric(
                    icon: Icons.timer_outlined,
                    label: '$durationMinutes min duration',
                  ),
                if (density != null && density > 0)
                  _BannerMetric(
                    icon: Icons.speed_rounded,
                    label: '$density kg/min density',
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _BannerMetric extends StatelessWidget {
  const _BannerMetric({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon,
            size: 14,
            color: cs.onPrimaryContainer.withValues(alpha: 0.8)),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: cs.onPrimaryContainer,
          ),
        ),
      ],
    );
  }
}

// ── Empty / error states ──────────────────────────────────────────────────────────────────────

class _NoActiveProgram extends StatelessWidget {
  const _NoActiveProgram();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(32),
        child: Text(
          'No active program. Go to Setup to get started.',
          textAlign: TextAlign.center,
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
        padding: const EdgeInsets.all(32),
        child: Text('Error: $message'),
      ),
    );
  }
}
