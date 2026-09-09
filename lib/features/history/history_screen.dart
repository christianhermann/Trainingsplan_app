import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/repositories/lift_repository.dart';
import 'history_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(historySessionsProvider);
    final liftsAsync   = ref.watch(allLiftsProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (sessions) {
          final days = sessions.map((s) => s.day).toList();
          return CustomScrollView(
            slivers: [
              // ── Lift Browse header ───────────────────────────────────────
              SliverToBoxAdapter(
                child: liftsAsync.when(
                  loading: () => const SizedBox.shrink(),
                  error:   (_, __) => const SizedBox.shrink(),
                  data:    (lifts) {
                    if (lifts.isEmpty) return const SizedBox.shrink();
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                          child: Text(
                            'Browse by Lift',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: cs.outline,
                                    letterSpacing: 0.5),
                          ),
                        ),
                        SizedBox(
                          height: 40,
                          child: ListView.separated(
                            padding:
                                const EdgeInsets.symmetric(horizontal: 16),
                            scrollDirection: Axis.horizontal,
                            itemCount: lifts.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final lift = lifts[i];
                              return ActionChip(
                                label: Text(lift.displayName),
                                onPressed: () => context.goNamed(
                                  'lift-history',
                                  pathParameters: {
                                    'liftId': lift.id.toString(),
                                  },
                                  queryParameters: {'name': lift.displayName},
                                ),
                              );
                            },
                          ),
                        ),
                        const Padding(
                          padding: EdgeInsets.fromLTRB(16, 16, 16, 4),
                          child: Divider(height: 1),
                        ),
                        Padding(
                          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                          child: Text(
                            'Session Log',
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(
                                    color: cs.outline,
                                    letterSpacing: 0.5),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),

              // ── Session list ─────────────────────────────────────────────
              days.isEmpty
                  ? const SliverFillRemaining(
                      child: Center(
                          child: Text('No completed workouts yet.')))
                  : SliverPadding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                      sliver: SliverList.separated(
                        itemCount: days.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 8),
                        itemBuilder: (context, i) {
                          final day = days[i];
                          final dateStr = day.completedAt != null
                              ? _formatDate(day.completedAt!)
                              : 'Unknown date';
                          return Card(
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor:
                                    cs.primary.withValues(alpha: 0.12),
                                child: Icon(Icons.fitness_center,
                                    color: cs.primary, size: 20),
                              ),
                              title: Text(day.title.isNotEmpty
                                  ? day.title
                                  : 'Day ${day.dayIndex + 1}'),
                              subtitle: Text(dateStr),
                              trailing:
                                  const Icon(Icons.chevron_right),
                              onTap: () => context.goNamed(
                                'history-detail',
                                pathParameters: {
                                  'dayId': day.id.toString(),
                                },
                              ),
                            ),
                          );
                        },
                      ),
                    ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}'
        '.${dt.month.toString().padLeft(2, '0')}'
        '.${dt.year}';
  }
}
