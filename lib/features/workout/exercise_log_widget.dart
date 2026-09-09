import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../data/persistence/database.dart';

class ExerciseLogWidget extends StatefulWidget {
  const ExerciseLogWidget({
    super.key,
    required this.prescription,
    required this.log,
    required this.liftName,
    required this.onLogUpdated,
    this.showHeader =
        true, // fix: add parameter; default true preserves existing callers
  });

  final ExercisePrescription prescription;
  final ExerciseLog? log;
  final String liftName;
  final ValueChanged<ExerciseLogsCompanion> onLogUpdated;

  /// When false, the lift-name row and stat-chip row are omitted.
  /// Use when the parent widget already renders those elements.
  final bool showHeader;

  @override
  State<ExerciseLogWidget> createState() => _ExerciseLogWidgetState();
}

class _ExerciseLogWidgetState extends State<ExerciseLogWidget> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _notesController;
  late TextEditingController _videoController;
  bool _expanded = false;

  @override
  void initState() {
    super.initState();
    _setsController =
        TextEditingController(text: widget.log?.completedSets.toString() ?? '');
    _repsController = TextEditingController(
        text: widget.log?.repsOnLastSet?.toString() ?? '');
    _notesController = TextEditingController(text: widget.log?.notes ?? '');
    _videoController = TextEditingController(text: widget.log?.videoUrl ?? '');
  }

  @override
  void dispose() {
    _setsController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _save() {
    final sets = int.tryParse(_setsController.text);
    final reps = int.tryParse(_repsController.text);
    if (sets == null ||
        reps == null ||
        sets < 0 ||
        sets > widget.prescription.setGoal ||
        reps < 0) {
      return;
    }
    widget.onLogUpdated(ExerciseLogsCompanion(
      id: widget.log != null ? Value(widget.log!.id) : const Value.absent(),
      prescriptionId: Value(widget.prescription.id),
      completedSets: Value(sets),
      repsOnLastSet: Value(reps),
      notes:
          Value(_notesController.text.isEmpty ? null : _notesController.text),
      videoUrl:
          Value(_videoController.text.isEmpty ? null : _videoController.text),
      completedAt: Value(DateTime.now()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;
    final isLogged = widget.log?.repsOnLastSet != null;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header (lift name + expand toggle) ────────────────────────────
            if (widget.showHeader) ...[
              Row(
                children: [
                  Expanded(
                    child: Text(widget.liftName,
                        style: Theme.of(context).textTheme.headlineSmall),
                  ),
                  if (isLogged)
                    const Icon(Icons.check_circle,
                        color: Colors.greenAccent, size: 20),
                  IconButton(
                    icon:
                        Icon(_expanded ? Icons.expand_less : Icons.expand_more),
                    onPressed: () => setState(() => _expanded = !_expanded),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _StatChip(
                      label: 'Weight',
                      value: '${p.workingWeight.toStringAsFixed(1)} kg',
                      highlight: true),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Sets', value: '${p.setGoal}'),
                  const SizedBox(width: 8),
                  _StatChip(label: 'Reps', value: '${p.repsPerNormalSet}'),
                  const SizedBox(width: 8),
                  _StatChip(
                      label: 'Last set ≥',
                      value: '${p.repOutTarget}',
                      accent: true),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // ── Reps input (always shown) ───────────────────────────────────────
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _setsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: InputDecoration(
                      labelText: 'Sets completed',
                      hintText: '${widget.prescription.setGoal}',
                    ),
                    onChanged: (_) => _save(),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextField(
                    controller: _repsController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    decoration: const InputDecoration(
                      labelText: 'Reps on last set',
                      hintText: 'e.g. 8',
                    ),
                    onChanged: (_) => _save(),
                  ),
                ),
              ],
            ),

            // ── Expandable notes / video (always available) ────────────────────
            if (_expanded) ...[
              const SizedBox(height: 12),
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Notes',
                  hintText: 'Optional notes',
                ),
                maxLines: 2,
                onChanged: (_) => _save(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _videoController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => _save(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    this.highlight = false,
    this.accent = false,
  });
  final String label;
  final String value;
  final bool highlight;
  final bool accent;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = highlight
        ? cs.primaryContainer
        : accent
            ? cs.tertiaryContainer
            : cs.surfaceContainerHighest;
    final fg = highlight
        ? cs.onPrimaryContainer
        : accent
            ? cs.onTertiaryContainer
            : cs.onSurface;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label,
              style: TextStyle(fontSize: 10, color: fg.withValues(alpha: 0.7))),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14, fontWeight: FontWeight.bold, color: fg)),
        ],
      ),
    );
  }
}
