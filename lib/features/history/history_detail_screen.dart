import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/persistence/database.dart';
import '../../domain/models/enums.dart';
import 'history_provider.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.dayId});
  final int dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync = ref.watch(historySessionDetailProvider(dayId));

    return Scaffold(
      appBar: AppBar(
        title: sessionAsync.maybeWhen(
          data:   (s) => Text(s?.title ?? 'Session'),
          orElse: () => const Text('Session'),
        ),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error: $e')),
        data:    (session) {
          if (session == null) {
            return const Center(child: Text('Session not found.'));
          }
          return _SessionDetail(session: session);
        },
      ),
    );
  }
}

// ── Session detail ─────────────────────────────────────────────────────────────

class _SessionDetail extends StatelessWidget {
  const _SessionDetail({required this.session});
  final HistorySession session;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _InfoRow(
          label: 'Completed',
          value: session.completedAt != null
              ? _formatDateTime(session.completedAt!)
              : 'Unknown',
        ),
        _InfoRow(
          label: 'Exercises',
          value: '${session.loggedCount}/${session.totalCount} logged',
        ),
        const SizedBox(height: 20),
        ...session.prescriptions.map((p) {
          final log     = session.logs[p.id];
          final lift    = session.lifts[p.liftId];
          final outcome = session.outcomeFor(p.id);
          final delta   = session.deltaFor(p.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExerciseHistoryCard(
              prescription: p,
              log:          log,
              liftName:     lift?.displayName ?? 'Unknown',
              liftId:       p.liftId,
              outcome:      outcome,
              delta:        delta,
            ),
          );
        }),
      ],
    );
  }

  String _formatDateTime(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}.'
        '${dt.month.toString().padLeft(2, '0')}.'
        '${dt.year}  '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}

// ── Exercise history card ───────────────────────────────────────────────────────

class _ExerciseHistoryCard extends StatelessWidget {
  const _ExerciseHistoryCard({
    required this.prescription,
    required this.log,
    required this.liftName,
    required this.liftId,
    required this.outcome,
    required this.delta,
  });

  final ExercisePrescription prescription;
  final ExerciseLog?         log;
  final String               liftName;
  final int                  liftId;
  final ProgressOutcome?     outcome;
  final double?              delta;

  @override
  Widget build(BuildContext context) {
    final p        = prescription;
    final isLogged = log != null;
    final cs       = Theme.of(context).colorScheme;
    final tt       = Theme.of(context).textTheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => context.goNamed(
          'lift-history',
          pathParameters: {'liftId': liftId.toString()},
          queryParameters: {'name': liftName},
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Lift name + logged icon ──────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: Text(
                      liftName,
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(
                    isLogged
                        ? Icons.check_circle_rounded
                        : Icons.radio_button_unchecked,
                    color: isLogged ? cs.primary : cs.outline,
                    size: 20,
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right,
                      size: 16, color: cs.outline),
                ],
              ),

              const SizedBox(height: 10),

              // ── Prescription + result chips ─────────────────────────────
              Wrap(
                spacing: 8,
                runSpacing: 6,
                children: [
                  _Chip(
                    p.workingWeight % 1 == 0
                        ? '${p.workingWeight.toInt()} kg'
                        : '${p.workingWeight.toStringAsFixed(1)} kg',
                    highlight: true,
                  ),
                  _Chip('${p.setGoal} sets'),
                  _Chip('${p.repsPerNormalSet} reps'),
                  _Chip('Target \u2265 ${p.repOutTarget}', accent: true),
                  if (log?.repsOnLastSet != null)
                    _Chip('Logged: ${log!.repsOnLastSet} reps',
                        success: true),
                ],
              ),

              // ── Outcome + TM delta chip ────────────────────────────────
              if (outcome != null && delta != null) ...[
                const SizedBox(height: 8),
                _OutcomeChip(outcome: outcome!, delta: delta!),
              ],

              // ── Notes ──────────────────────────────────────────────────
              if (log?.notes != null && log!.notes!.isNotEmpty) ...[
                const SizedBox(height: 10),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.notes, size: 16, color: cs.outline),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(log!.notes!, style: tt.bodyMedium),
                    ),
                  ],
                ),
              ],

              // ── Video link ─────────────────────────────────────────────
              if (log?.videoUrl != null && log!.videoUrl!.isNotEmpty) ...[
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final uri = Uri.tryParse(log!.videoUrl!);
                    if (uri != null && await canLaunchUrl(uri)) {
                      await launchUrl(uri,
                          mode: LaunchMode.externalApplication);
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.videocam, size: 16, color: cs.primary),
                      const SizedBox(width: 6),
                      Text(
                        'Watch video',
                        style: TextStyle(
                          color: cs.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Outcome + delta chip ────────────────────────────────────────────────────────

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

    final outcomeLabel = _outcomeLabel(outcome);
    final deltaLabel   = _deltaLabel(delta);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            '$outcomeLabel  \u00b7  $deltaLabel',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }

  static String _outcomeLabel(ProgressOutcome o) => switch (o) {
    ProgressOutcome.belowBy2 => 'Missed by 2+',
    ProgressOutcome.belowBy1 => 'Missed by 1',
    ProgressOutcome.hit      => 'Hit target',
    ProgressOutcome.plus1    => 'Beat by 1',
    ProgressOutcome.plus2    => 'Beat by 2',
    ProgressOutcome.plus3    => 'Beat by 3',
    ProgressOutcome.plus4    => 'Beat by 4',
    ProgressOutcome.plus5    => 'Beat by 5+',
  };

  static String _deltaLabel(double delta) {
    if (delta == 0) return 'No change';
    final pct = (delta * 100).toStringAsFixed(1);
    return delta > 0 ? '+$pct%' : '$pct%';
  }
}

// ── Shared chip ─────────────────────────────────────────────────────────────────

class _Chip extends StatelessWidget {
  const _Chip(this.label,
      {this.highlight = false, this.accent = false, this.success = false});
  final String label;
  final bool   highlight;
  final bool   accent;
  final bool   success;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = success
        ? cs.primaryContainer.withValues(alpha: 0.5)
        : highlight
            ? cs.primaryContainer
            : accent
                ? cs.tertiaryContainer
                : cs.surfaceContainerHighest;
    final fg = success
        ? cs.primary
        : highlight
            ? cs.onPrimaryContainer
            : accent
                ? cs.onTertiaryContainer
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

// ── Info row ────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label, style: tt.bodyMedium),
          const Spacer(),
          Text(value,
              style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
