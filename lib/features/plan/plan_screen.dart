import '../../core/widgets/ronnie_loading_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'plan_provider.dart';

class PlanScreen extends ConsumerStatefulWidget {
  const PlanScreen({super.key});

  @override
  ConsumerState<PlanScreen> createState() => _PlanScreenState();
}

class _PlanScreenState extends ConsumerState<PlanScreen> {
  int _selectedWeek = 1;

  @override
  Widget build(BuildContext context) {
    final planAsync = ref.watch(planSummaryProvider(_selectedWeek));

    return Scaffold(
      appBar: AppBar(title: const Text('Plan')),
      body: planAsync.when(
        loading: () => const Center(child: RonnieLoadingIndicator(message: 'Loading periodization plan...')),
        error: (error, _) => Center(child: Text('Error: $error')),
        data: (plan) {
          if (plan == null) {
            return const Center(
                child: Text('No active plan. Generate one in Setup.'));
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '${_frequencyLabel(plan.frequency)} · Week ${plan.weekNumber}',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                  DropdownButton<int>(
                    value: plan.weekNumber,
                    items: [
                      for (var week = 1; week <= plan.totalWeeks; week++)
                        DropdownMenuItem(
                          value: week,
                          child: Text('Week $week'),
                        ),
                    ],
                    onChanged: (week) {
                      if (week != null) setState(() => _selectedWeek = week);
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              for (final day in plan.days) ...[
                Opacity(
                  opacity: day.isCompleted ? 0.45 : 1.0,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Day ${day.dayNumber}',
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              if (day.estimatedDurationMinutes > 0) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .surfaceContainerHighest
                                        .withValues(alpha: 0.8),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.schedule_rounded,
                                        size: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurfaceVariant,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        '~${_formatDuration(day.estimatedDurationMinutes)}',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                              const Spacer(),
                              if (day.isCompleted) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context)
                                        .colorScheme
                                        .secondaryContainer,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_circle_rounded,
                                        size: 14,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSecondaryContainer,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Completed',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSecondaryContainer,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 8),
                          for (final exercise in day.exercises)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Row(
                                children: [
                                  Expanded(child: Text(exercise.name)),
                                  Text(
                                    '${_formatWeight(exercise.weight)} kg · '
                                    '${exercise.sets} × ${exercise.reps}',
                                    style: Theme.of(context).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ],
          );
        },
      ),
    );
  }

  String _frequencyLabel(String value) {
    final number = switch (value) {
      'two' => 2,
      'three' => 3,
      'four' => 4,
      'five' => 5,
      'six' => 6,
      _ => value,
    };
    return '$number days/week';
  }

  String _formatWeight(double weight) {
    return weight == weight.roundToDouble()
        ? weight.toInt().toString()
        : weight.toStringAsFixed(1);
  }

  String _formatDuration(int minutes) {
    if (minutes < 60) return '$minutes min';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}min';
  }
}
