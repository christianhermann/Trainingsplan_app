import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../data/persistence/database.dart';
import 'history_provider.dart';

class HistoryDetailScreen extends ConsumerWidget {
  const HistoryDetailScreen({super.key, required this.dayId});
  final int dayId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final sessionAsync =
        ref.watch(historySessionDetailProvider(dayId));

    return Scaffold(
      appBar: AppBar(
        title: sessionAsync.maybeWhen(
          data: (s) => Text(s?.title ?? 'Session'),
          orElse: () => const Text('Session'),
        ),
      ),
      body: sessionAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (session) {
          if (session == null) {
            return const Center(child: Text('Session not found.'));
          }
          return _SessionDetail(session: session);
        },
      ),
    );
  }
}

class _SessionDetail extends StatelessWidget {
  const _SessionDetail({required this.session});
  final HistorySession session;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Header info
        _InfoRow(
          label: 'Completed',
          value: session.completedAt != null
              ? _formatDateTime(session.completedAt!)
              : 'Unknown',
        ),
        _InfoRow(
          label: 'Exercises',
          value:
              '${session.loggedCount}/${session.totalCount} logged',
        ),
        const SizedBox(height: 20),
        ...session.prescriptions.map((p) {
          final log = session.logs[p.id];
          final lift = session.lifts[p.liftId];
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExerciseHistoryCard(
              prescription: p,
              log: log,
              liftName: lift?.displayName ?? 'Unknown',
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

class _ExerciseHistoryCard extends StatelessWidget {
  const _ExerciseHistoryCard({
    required this.prescription,
    required this.log,
    required this.liftName,
  });

  final ExercisePrescription prescription;
  final ExerciseLog? log;
  final String liftName;

  @override
  Widget build(BuildContext context) {
    final p = prescription;
    final isLogged = log != null;
    final cs = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(liftName,
                      style: Theme.of(context).textTheme.headlineSmall),
                ),
                Icon(
                  isLogged ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: isLogged ? Colors.greenAccent : cs.outline,
                  size: 20,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _Chip('${p.workingWeight.toStringAsFixed(1)} kg',
                    highlight: true),
                _Chip('${p.setGoal} sets'),
                _Chip('${p.repsPerNormalSet} reps'),
                _Chip('Target ≥ ${p.repOutTarget}', accent: true),
                if (log?.repsOnLastSet != null)
                  _Chip('Logged: ${log!.repsOnLastSet} reps',
                      success: true),
              ],
            ),
            if (log?.notes != null && log!.notes!.isNotEmpty) ...[
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.notes, size: 16, color: cs.outline),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(log!.notes!,
                        style: Theme.of(context).textTheme.bodyMedium),
                  ),
                ],
              ),
            ],
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
                    Text('Watch video',
                        style: TextStyle(
                            color: cs.primary,
                            decoration: TextDecoration.underline)),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip(this.label,
      {this.highlight = false, this.accent = false, this.success = false});
  final String label;
  final bool highlight;
  final bool accent;
  final bool success;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = success
        ? Colors.greenAccent.withOpacity(0.15)
        : highlight
            ? cs.primaryContainer
            : accent
                ? cs.tertiaryContainer
                : cs.surfaceContainerHighest;
    final fg = success
        ? Colors.greenAccent
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

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Text(label,
              style: Theme.of(context).textTheme.bodyMedium),
          const Spacer(),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
