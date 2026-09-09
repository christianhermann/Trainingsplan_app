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
        loading: () => const Center(child: CircularProgressIndicator()),
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
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Day ${day.dayNumber}',
                            style: Theme.of(context).textTheme.titleLarge),
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
}
