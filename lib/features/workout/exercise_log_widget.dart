import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/persistence/database.dart';
import 'rest_timer_widget.dart';

class ExerciseLogWidget extends ConsumerStatefulWidget {
  const ExerciseLogWidget({
    super.key,
    required this.prescription,
    required this.log,
    required this.liftName,
    required this.onLogUpdated,
    this.showHeader = true,
  });

  final ExercisePrescription prescription;
  final ExerciseLog? log;
  final String liftName;
  final ValueChanged<ExerciseLogsCompanion> onLogUpdated;
  final bool showHeader;

  @override
  ConsumerState<ExerciseLogWidget> createState() => _ExerciseLogWidgetState();
}

class _ExerciseLogWidgetState extends ConsumerState<ExerciseLogWidget> {
  late TextEditingController _setsController;
  late TextEditingController _repsController;
  late TextEditingController _notesController;
  late TextEditingController _videoController;
  bool _expanded = false;
  Timer? _debounceTimer;

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
  void didUpdateWidget(covariant ExerciseLogWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.prescription.id != oldWidget.prescription.id ||
        widget.log != oldWidget.log) {
      final setsText = (widget.log != null && widget.log!.completedSets > 0)
          ? widget.log!.completedSets.toString()
          : '';
      _setsController.text = setsText;

      final repsText = widget.log?.repsOnLastSet != null
          ? widget.log!.repsOnLastSet.toString()
          : '';
      _repsController.text = repsText;

      _notesController.text = widget.log?.notes ?? '';
      _videoController.text = widget.log?.videoUrl ?? '';
      setState(() {});
    }
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _setsController.dispose();
    _repsController.dispose();
    _notesController.dispose();
    _videoController.dispose();
    super.dispose();
  }

  void _onFieldChanged() {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 300), _save);
  }

  void _onSetTapped(int setIndex) {
    HapticFeedback.mediumImpact();
    final currentSets = int.tryParse(_setsController.text) ?? 0;
    final newSets = (currentSets == setIndex) ? setIndex - 1 : setIndex;
    _setsController.text = newSets > 0 ? newSets.toString() : '';

    // Auto-trigger rest timer when completing a set
    if (newSets >= setIndex) {
      ref.read(restTimerProvider.notifier).reset();
      ref.read(restTimerProvider.notifier).start();
    }

    // If completing final rep-out set, prefill target if empty
    if (newSets == widget.prescription.setGoal && _repsController.text.isEmpty) {
      _repsController.text = widget.prescription.repOutTarget.toString();
    }

    _save();
    setState(() {});
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
      notes: Value(
          _notesController.text.trim().isEmpty ? null : _notesController.text.trim()),
      videoUrl: Value(
          _videoController.text.trim().isEmpty ? null : _videoController.text.trim()),
      completedAt: Value(DateTime.now()),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;
    final isLogged = widget.log?.repsOnLastSet != null;
    final currentSets = int.tryParse(_setsController.text) ?? (widget.log?.completedSets ?? 0);
    final cs = Theme.of(context).colorScheme;

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

            // ── Interactive Set-by-Set check-off pills ─────────────────────────
            Row(
              children: [
                Text(
                  'Sets:',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      for (int i = 1; i <= p.setGoal; i++)
                        _SetChip(
                          setIndex: i,
                          isLastSet: i == p.setGoal,
                          isCompleted: currentSets >= i,
                          onTap: () => _onSetTapped(i),
                        ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Reps input ───────────────────────────────────────
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
                    onChanged: (_) => _onFieldChanged(),
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
                    onChanged: (_) => _onFieldChanged(),
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
                onChanged: (_) => _onFieldChanged(),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _videoController,
                decoration: const InputDecoration(
                  labelText: 'Video URL',
                  hintText: 'https://...',
                ),
                keyboardType: TextInputType.url,
                onChanged: (_) => _onFieldChanged(),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SetChip extends StatelessWidget {
  const _SetChip({
    required this.setIndex,
    required this.isLastSet,
    required this.isCompleted,
    required this.onTap,
  });

  final int setIndex;
  final bool isLastSet;
  final bool isCompleted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    final bg = isCompleted
        ? cs.primary
        : cs.surfaceContainerHighest;
    final fg = isCompleted
        ? cs.onPrimary
        : cs.onSurface;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isCompleted ? cs.primary : cs.outlineVariant,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isCompleted ? Icons.check_circle_rounded : Icons.radio_button_unchecked,
              size: 14,
              color: fg,
            ),
            const SizedBox(width: 4),
            Text(
              isLastSet ? 'Set $setIndex (AMRAP)' : 'Set $setIndex',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: fg,
              ),
            ),
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
