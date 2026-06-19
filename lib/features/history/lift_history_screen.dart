import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/program_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/progression_service.dart';
import '../../data/seeders/progression_adjustment_seeder.dart';
import 'history_provider.dart';

// ── Provider ───────────────────────────────────────────────────────────────────

class LiftHistoryEntry {
  const LiftHistoryEntry({
    required this.log,
    required this.prescription,
    required this.completedAt,
    required this.outcome,
    required this.delta,
  });

  final ExerciseLog           log;
  final ExercisePrescription  prescription;
  final DateTime?             completedAt;
  final ProgressOutcome?      outcome;
  final double?               delta;
}

final _adjustments =
    ProgressionAdjustmentSeeder.generateProgressionAdjustments();

final liftHistoryProvider =
    FutureProvider.family<List<LiftHistoryEntry>, int>((ref, liftId) async {
  final workoutRepo = ref.watch(workoutRepositoryProvider);
  final programRepo = ref.watch(programRepositoryProvider);

  final logs = await workoutRepo.getAllLogsForLift(liftId);
  if (logs.isEmpty) return [];

  // Build prescriptionId → WorkoutDay map so we can resolve completedAt.
  final allPrograms = await programRepo.getAllPrograms();
  final dayMap = <int, WorkoutDay>{}; // workoutDayId → day

  for (final program in allPrograms) {
    final weeks = await programRepo.getWeeksForProgram(program.id);
    for (final week in weeks) {
      final days = await programRepo.getDaysForWeek(week.id);
      for (final day in days) {
        dayMap[day.id] = day;
      }
    }
  }

  // Fetch all prescriptions for this lift to resolve prescriptionId → day.
  final allPrescriptions = await workoutRepo.getPrescriptionsForLift(liftId);
  final prescMap = {for (final p in allPrescriptions) p.id: p};

  final entries = <LiftHistoryEntry>[];

  for (final log in logs) {
    final presc = prescMap[log.prescriptionId];
    if (presc == null) continue;

    final day        = dayMap[presc.workoutDayId];
    final completedAt = log.completedAt ?? day?.completedAt;

    // Derive outcome.
    ProgressOutcome? outcome;
    double?          delta;

    if (log.repsOnLastSet != null) {
      outcome = const ProgressionService().determineOutcome(
        repsOnLastSet: log.repsOnLastSet!,
        repOutTarget:  presc.repOutTarget,
      );

      // Delta lookup — same logic as HistorySession.deltaFor.
      if (outcome != null) {
        final specific = _adjustments.where((a) =>
            a.liftId == 'all_lifts' &&
            a.outcome == outcome &&
            a.appliesToTrainingMax);
        delta = specific.isNotEmpty ? specific.first.delta : null;
      }
    }

    entries.add(LiftHistoryEntry(
      log:          log,
      prescription: presc,
      completedAt:  completedAt,
      outcome:      outcome,
      delta:        delta,
    ));
  }

  // Sort newest first.
  entries.sort((a, b) {
    final aDate = a.completedAt;
    final bDate = b.completedAt;
    if (aDate == null && bDate == null) return 0;
    if (aDate == null) return 1;
    if (bDate == null) return -1;
    return bDate.compareTo(aDate);
  });

  return entries;
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class LiftHistoryScreen extends ConsumerWidget {
  const LiftHistoryScreen({
    super.key,
    required this.liftId,
    this.liftName,
  });

  final int    liftId;
  final String? liftName;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final entriesAsync = ref.watch(liftHistoryProvider(liftId));

    // If liftName wasn't passed, try to resolve it from the lift repo.
    final nameAsync = liftName != null
        ? null
        : ref.watch(liftByIdProvider(liftId));

    final resolvedName = liftName ??
        nameAsync?.maybeWhen(
          data: (l) => l?.displayName,
          orElse: () => null,
        ) ??
        'Lift History';

    return Scaffold(
      appBar: AppBar(title: Text(resolvedName)),
      body: entriesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (entries) {
          if (entries.isEmpty) {
            return const Center(
              child: Text('No logged sessions for this lift yet.'),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _LiftHistoryTile(entry: entries[i]),
          );
        },
      ),
    );
  }
}

// ── Tile ────────────────────────────────────────────────────────────────────────

class _LiftHistoryTile extends StatelessWidget {
  const _LiftHistoryTile({required this.entry});
  final LiftHistoryEntry entry;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final p  = entry.prescription;
    final l  = entry.log;

    final weightStr = p.workingWeight % 1 == 0
        ? '${p.workingWeight.toInt()} kg'
        : '${p.workingWeight.toStringAsFixed(1)} kg';

    final repsStr = l.repsOnLastSet != null
        ? '${l.repsOnLastSet} reps (last set)'
        : '— reps';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Date column ───────────────────────────────────────────
            SizedBox(
              width: 52,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    entry.completedAt != null
                        ? entry.completedAt!.day
                            .toString()
                            .padLeft(2, '0')
                        : '--',
                    style: tt.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: cs.primary,
                    ),
                  ),
                  Text(
                    entry.completedAt != null
                        ? _monthAbbr(entry.completedAt!.month)
                        : '',
                    style: tt.bodySmall?.copyWith(color: cs.outline),
                  ),
                  Text(
                    entry.completedAt != null
                        ? '${entry.completedAt!.year}'
                        : '',
                    style: tt.bodySmall?.copyWith(
                      fontSize: 10,
                      color: cs.outline,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 14),

            // ── Main column ────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // Weight + reps row
                  Row(
                    children: [
                      _Chip(weightStr, highlight: true),
                      const SizedBox(width: 8),
                      _Chip(repsStr,
                          success: l.repsOnLastSet != null),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Prescription meta
                  Text(
                    '${p.setGoal} sets · ${p.repsPerNormalSet} reps prescribed · target ≥ ${p.repOutTarget}',
                    style: tt.bodySmall
                        ?.copyWith(color: cs.onSurface.withValues(alpha: 0.6)),
                  ),

                  // Outcome chip
                  if (entry.outcome != null && entry.delta != null) ...[
                    const SizedBox(height: 8),
                    _OutcomeChip(
                        outcome: entry.outcome!, delta: entry.delta!),
                  ],

                  // Notes
                  if (l.notes != null && l.notes!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(Icons.notes, size: 14, color: cs.outline),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(l.notes!,
                              style: tt.bodySmall),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  static String _monthAbbr(int m) =>
      const ['Jan','Feb','Mar','Apr','May','Jun',
             'Jul','Aug','Sep','Oct','Nov','Dec'][m - 1];
}

// ── Reused widgets (mirrors history_detail_screen.dart) ────────────────────────

class _OutcomeChip extends StatelessWidget {
  const _OutcomeChip({required this.outcome, required this.delta});
  final ProgressOutcome outcome;
  final double          delta;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final Color bg;
    final Color fg;
    final IconData icon;

    if (delta > 0) {
      bg   = cs.primaryContainer;
      fg   = cs.onPrimaryContainer;
      icon = Icons.trending_up_rounded;
    } else if (delta < 0) {
      bg   = cs.errorContainer;
      fg   = cs.onErrorContainer;
      icon = Icons.trending_down_rounded;
    } else {
      bg   = cs.surfaceContainerHighest;
      fg   = cs.onSurface.withValues(alpha: 0.7);
      icon = Icons.trending_flat_rounded;
    }

    final outcomeLabel = _label(outcome);
    final deltaLabel   = delta == 0
        ? 'No change'
        : '${delta > 0 ? '+' : ''}${(delta * 100).toStringAsFixed(1)}%';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text('$outcomeLabel  ·  $deltaLabel',
              style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
        ],
      ),
    );
  }

  static String _label(ProgressOutcome o) => switch (o) {
    ProgressOutcome.belowBy2 => 'Missed by 2+',
    ProgressOutcome.belowBy1 => 'Missed by 1',
    ProgressOutcome.hit      => 'Hit target',
    ProgressOutcome.plus1    => 'Beat by 1',
    ProgressOutcome.plus2    => 'Beat by 2',
    ProgressOutcome.plus3    => 'Beat by 3',
    ProgressOutcome.plus4    => 'Beat by 4',
    ProgressOutcome.plus5    => 'Beat by 5+',
  };
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.highlight = false, this.success = false});
  final String label;
  final bool   highlight;
  final bool   success;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = success
        ? cs.primaryContainer.withValues(alpha: 0.5)
        : highlight
            ? cs.primaryContainer
            : cs.surfaceContainerHighest;
    final fg = success
        ? cs.primary
        : highlight
            ? cs.onPrimaryContainer
            : cs.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Text(label,
          style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
