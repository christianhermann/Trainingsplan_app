import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/repositories/lift_repository.dart';
import '../../data/repositories/progression_adjustment_repository.dart';
import '../../data/repositories/training_max_repository.dart';
import '../../data/repositories/workout_repository.dart';
import '../../domain/models/enums.dart';
import '../../domain/services/progression_service.dart';
import '../workout/workout_provider.dart';

// ── Debug data model ─────────────────────────────────────────────────────

class DebugLiftRow {
  const DebugLiftRow({
    required this.liftName,
    required this.trainingMax,
    required this.intensity,
    required this.rawWeight,
    required this.workingWeight,
    required this.repsPerNormalSet,
    required this.repOutTarget,
    required this.setGoal,
    required this.isPrimaryBlock,
    required this.deltas,
  });

  final String              liftName;
  final double              trainingMax;       // TM from DB
  final double              intensity;         // e.g. 0.75
  final double              rawWeight;         // TM * intensity (pre-rounding)
  final double              workingWeight;     // stored rounded value
  final int                 repsPerNormalSet;
  final int                 repOutTarget;
  final int                 setGoal;
  final bool                isPrimaryBlock;
  /// Maps each [ProgressOutcome] to its TM delta for this lift.
  final Map<ProgressOutcome, double> deltas;
}

// ── Provider ────────────────────────────────────────────────────────────

final debugWorkoutProvider =
    FutureProvider<List<DebugLiftRow>>((ref) async {
  final today = await ref.watch(todayWorkoutProvider.future);
  if (today == null) return [];

  final tmRepo         = ref.watch(trainingMaxRepositoryProvider);
  final adjustmentRepo = ref.watch(progressionAdjustmentRepositoryProvider);
  final liftRepo       = ref.watch(liftRepositoryProvider);

  final adjustments = await adjustmentRepo.getAdjustments();
  final allLifts    = await liftRepo.getAllLifts();
  final liftByName  = {for (final l in allLifts) l.name: l};

  final rows = <DebugLiftRow>[];

  for (final presc in today.prescriptions) {
    final liftRow = today.lifts[presc.liftId];
    if (liftRow == null) continue;

    final tm = await tmRepo.getMaxForLift(liftRow.id);
    final tmValue = tm?.value ?? presc.trainingMaxSnapshot;

    // Raw (pre-rounding) weight
    final rawWeight = tmValue * presc.intensity;

    // Per-outcome deltas for this lift
    final deltas = <ProgressOutcome, double>{};
    for (final outcome in ProgressOutcome.values) {
      // Lift-specific rule first, then 'all_lifts' fallback.
      final specific = adjustments.where((a) =>
          a.liftId == liftRow.name &&
          a.outcome == outcome &&
          a.appliesToTrainingMax);
      if (specific.isNotEmpty) {
        deltas[outcome] = specific.first.delta;
        continue;
      }
      final fallback = adjustments.where((a) =>
          a.liftId == 'all_lifts' &&
          a.outcome == outcome &&
          a.appliesToTrainingMax);
      if (fallback.isNotEmpty) {
        deltas[outcome] = fallback.first.delta;
      }
    }

    rows.add(DebugLiftRow(
      liftName:          liftRow.displayName,
      trainingMax:       tmValue,
      intensity:         presc.intensity,
      rawWeight:         rawWeight,
      workingWeight:     presc.workingWeight,
      repsPerNormalSet:  presc.repsPerNormalSet,
      repOutTarget:      presc.repOutTarget,
      setGoal:           presc.setGoal,
      isPrimaryBlock:    presc.isPrimaryBlock,
      deltas:            deltas,
    ));
  }

  return rows;
});

// ── Screen ─────────────────────────────────────────────────────────────────────

class DebugScreen extends ConsumerWidget {
  const DebugScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dataAsync = ref.watch(debugWorkoutProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug — Today\'s Workout'),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy),
            tooltip: 'Copy all as text',
            onPressed: () => dataAsync.whenData(
              (rows) => _copyAll(context, rows),
            ),
          ),
        ],
      ),
      body: dataAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, st) => SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Text('$e\n$st',
              style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
        ),
        data: (rows) {
          if (rows.isEmpty) {
            return const Center(child: Text('No active workout day.'));
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: rows.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _DebugCard(row: rows[i]),
          );
        },
      ),
    );
  }

  void _copyAll(BuildContext context, List<DebugLiftRow> rows) {
    final buf = StringBuffer();
    for (final r in rows) {
      buf.writeln('=== ${r.liftName} ===');
      buf.writeln('TM: ${r.trainingMax} kg');
      buf.writeln('Intensity: ${(r.intensity * 100).toStringAsFixed(1)}%');
      buf.writeln('Raw weight: ${r.rawWeight.toStringAsFixed(2)} kg');
      buf.writeln('Working weight: ${r.workingWeight} kg');
      buf.writeln('Sets: ${r.setGoal}  Reps: ${r.repsPerNormalSet}  Target: ${r.repOutTarget}');
      buf.writeln('Primary block: ${r.isPrimaryBlock}');
      buf.writeln('Deltas:');
      for (final e in r.deltas.entries) {
        final pct = (e.value * 100).toStringAsFixed(2);
        buf.writeln('  ${e.key.name.padRight(10)} ${e.value >= 0 ? '+' : ''}$pct%');
      }
      buf.writeln();
    }
    Clipboard.setData(ClipboardData(text: buf.toString()));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}

// ── Debug card ──────────────────────────────────────────────────────────────────

class _DebugCard extends StatelessWidget {
  const _DebugCard({required this.row});
  final DebugLiftRow row;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final r  = row;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Header row ───────────────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: Text(
                    r.liftName,
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: r.isPrimaryBlock
                        ? cs.primaryContainer
                        : cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    r.isPrimaryBlock ? 'Primary' : 'Auxiliary',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: r.isPrimaryBlock
                          ? cs.onPrimaryContainer
                          : cs.onSurface,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 20),

            // ── Calculation breakdown ────────────────────────────────
            _MonoRow('Training max',
                '${r.trainingMax.toStringAsFixed(1)} kg'),
            _MonoRow('Intensity',
                '${(r.intensity * 100).toStringAsFixed(1)}%'),
            _MonoRow('Raw weight (TM × intensity)',
                '${r.rawWeight.toStringAsFixed(3)} kg'),
            _MonoRow('Working weight (rounded)',
                '${r.workingWeight % 1 == 0 ? r.workingWeight.toInt() : r.workingWeight.toStringAsFixed(1)} kg',
                highlight: true),

            const SizedBox(height: 12),

            // ── Rep targets ───────────────────────────────────────────────
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip('${r.setGoal} sets'),
                _Chip('${r.repsPerNormalSet} reps/set'),
                _Chip('Last-set target ≥ ${r.repOutTarget}',
                    accent: true),
              ],
            ),

            const SizedBox(height: 14),

            // ── Delta table ───────────────────────────────────────────────
            Text(
              'Progression rule deltas',
              style: tt.labelMedium?.copyWith(color: cs.outline),
            ),
            const SizedBox(height: 6),
            ...r.deltas.entries.map(
              (e) => _DeltaRow(outcome: e.key, delta: e.value),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Sub-widgets ────────────────────────────────────────────────────────────────

class _MonoRow extends StatelessWidget {
  const _MonoRow(this.label, this.value, {this.highlight = false});
  final String label;
  final String value;
  final bool   highlight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
                color: cs.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              fontWeight:
                  highlight ? FontWeight.w700 : FontWeight.normal,
              color: highlight ? cs.primary : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

class _DeltaRow extends StatelessWidget {
  const _DeltaRow({required this.outcome, required this.delta});
  final ProgressOutcome outcome;
  final double          delta;

  @override
  Widget build(BuildContext context) {
    final cs  = Theme.of(context).colorScheme;
    final pct = (delta * 100).toStringAsFixed(2);
    final sign = delta > 0 ? '+' : (delta < 0 ? '' : '±');
    final color = delta > 0
        ? cs.primary
        : delta < 0
            ? cs.error
            : cs.onSurface.withValues(alpha: 0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Expanded(
            child: Text(
              _label(outcome),
              style: TextStyle(
                fontFamily: 'monospace',
                fontSize: 11,
                color: cs.onSurface.withValues(alpha: 0.65),
              ),
            ),
          ),
          Text(
            '$sign$pct%',
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  static String _label(ProgressOutcome o) => switch (o) {
    ProgressOutcome.belowBy2 => 'Missed by 2+',
    ProgressOutcome.belowBy1 => 'Missed by 1 ',
    ProgressOutcome.hit      => 'Hit target  ',
    ProgressOutcome.plus1    => 'Beat by 1   ',
    ProgressOutcome.plus2    => 'Beat by 2   ',
    ProgressOutcome.plus3    => 'Beat by 3   ',
    ProgressOutcome.plus4    => 'Beat by 4   ',
    ProgressOutcome.plus5    => 'Beat by 5+  ',
  };
}

class _Chip extends StatelessWidget {
  const _Chip(this.label, {this.accent = false});
  final String label;
  final bool   accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = accent ? cs.tertiaryContainer : cs.surfaceContainerHighest;
    final fg = accent ? cs.onTertiaryContainer : cs.onSurface;
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
