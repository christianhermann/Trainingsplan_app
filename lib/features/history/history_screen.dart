import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/program_repository.dart';

final _historyProvider =
    FutureProvider<List<WorkoutDay>>((ref) async {
  final programRepo = ref.read(programRepositoryProvider);
  final programs = await programRepo.getAllPrograms();
  final days = <WorkoutDay>[];
  for (final p in programs) {
    final weeks = await programRepo.getWeeksForProgram(p.id);
    for (final w in weeks) {
      final d = await programRepo.getDaysForWeek(w.id);
      days.addAll(d.where((day) => day.status == 'completed'));
    }
  }
  days.sort((a, b) {
    final aDate = a.completedAt ?? DateTime(0);
    final bDate = b.completedAt ?? DateTime(0);
    return bDate.compareTo(aDate);
  });
  return days;
});

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(_historyProvider);
    final cs = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: historyAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (days) => days.isEmpty
            ? const Center(child: Text('No completed workouts yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: days.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
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
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {},
                    ),
                  );
                },
              ),
      ),
    );
  }

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}';
  }
}
