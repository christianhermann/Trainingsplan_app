import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalogue/lift_catalogue.dart';
import '../../domain/models/enums.dart';
import 'setup_provider.dart';

// ── Screen ────────────────────────────────────────────────────────────────────

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s        = ref.watch(setupProvider);
    final notifier = ref.read(setupProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Setup')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // Header
              Text('Configure Your Program',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Select training frequency, enter your maxes, and choose your lifts.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // ── Frequency ──────────────────────────────────────────────────
              Text('Training Frequency',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _FrequencySelector(
                selected:   s.selectedFrequency,
                onSelected: notifier.selectFrequency,
              ),
              const SizedBox(height: 32),

              // ── Training maxes ─────────────────────────────────────────────
              Text('Training Maxes',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _TrainingMaxesInput(
                maxes:        s.trainingMaxes,
                liftNames:    s.liftNames,
                onMaxUpdated: notifier.updateTrainingMax,
              ),
              const SizedBox(height: 32),

              // ── Lift selection ─────────────────────────────────────────────
              Text('Lift Selection',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Tap any lift to choose from presets or enter a custom name.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 12),
              _LiftSelectionSection(
                liftNames:  s.liftNames,
                onNameSet:  notifier.setLiftName,
              ),
              const SizedBox(height: 24),

              // ── Error banner ───────────────────────────────────────────────
              if (s.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.redAccent.withAlpha(100)),
                  ),
                  child: Text(s.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(height: 16),
              ],

              // ── Action buttons ─────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: notifier.clearAllMaxes,
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (s.isValid && !s.isSaving)
                          ? () async {
                              await notifier.saveAndGenerate();
                              if (context.mounted &&
                                  ref.read(setupProvider).errorMessage ==
                                      null) {
                                context.go('/today');
                              }
                            }
                          : null,
                      child: s.isSaving
                          ? const SizedBox(
                              width: 20, height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white))
                          : const Text('Generate Program'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Lift selection section ────────────────────────────────────────────────────

/// The 4 movement-pattern groups, each as an ExpansionTile.
/// Tapping a slot opens the picker sheet.
class _LiftSelectionSection extends StatelessWidget {
  const _LiftSelectionSection({
    required this.liftNames,
    required this.onNameSet,
  });
  final Map<String, String>          liftNames;
  final void Function(String, String) onNameSet; // (slotKey, displayName)

  // Group definitions: (groupLabel, mainSlot, [auxSlot, ...])
  static const _groups = [
    (
      label: 'Squat',
      slots: ['squat', 'front_squat', 'squat_aux2'],
    ),
    (
      label: 'Bankdrücken',
      slots: ['bench_press', 'close_grip_bench', 'bench_aux2'],
    ),
    (
      label: 'Deadlift',
      slots: ['deadlift', 'deadlift_aux'],
    ),
    (
      label: 'Schulterdrücken',
      slots: ['overhead_press', 'ohp_aux'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final group in _groups)
          _LiftGroupCard(
            groupLabel: group.label,
            slotKeys:   group.slots,
            liftNames:  liftNames,
            onNameSet:  onNameSet,
          ),
      ],
    );
  }
}

class _LiftGroupCard extends StatelessWidget {
  const _LiftGroupCard({
    required this.groupLabel,
    required this.slotKeys,
    required this.liftNames,
    required this.onNameSet,
  });
  final String                       groupLabel;
  final List<String>                 slotKeys;
  final Map<String, String>          liftNames;
  final void Function(String, String) onNameSet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final mainSlot = slotKeys.first;
    final mainName = liftNames[mainSlot] ?? liftDefaults[mainSlot] ?? mainSlot;

    return Card(
      margin:     const EdgeInsets.only(bottom: 10),
      color:      const Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding:     const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        shape:           const Border(),        // removes divider lines
        collapsedShape:  const Border(),
        title: Row(
          children: [
            Text(groupLabel,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: cs.onSurface.withValues(alpha: 0.5),
                    fontSize: 11)),
            const SizedBox(width: 8),
            Expanded(
              child: Text(mainName,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
        // Expand indicator badge showing how many slots total
        trailing: Text(
          '${slotKeys.length} slot${slotKeys.length > 1 ? 's' : ''}',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: cs.primary),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (final slotKey in slotKeys)
            _LiftSlotTile(
              slotKey:     slotKey,
              isMain:      slotKey == mainSlot,
              currentName: liftNames[slotKey] ??
                           liftDefaults[slotKey] ??
                           slotKey,
              onTap: () => _openPicker(context, slotKey),
            ),
        ],
      ),
    );
  }

  void _openPicker(BuildContext context, String slotKey) {
    final currentName =
        liftNames[slotKey] ?? liftDefaults[slotKey] ?? slotKey;
    showModalBottomSheet<void>(
      context:     context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LiftPickerSheet(
        slotKey:     slotKey,
        currentName: currentName,
        onSelected:  (name) => onNameSet(slotKey, name),
      ),
    );
  }
}

/// A single slot row inside an expansion card.
class _LiftSlotTile extends StatelessWidget {
  const _LiftSlotTile({
    required this.slotKey,
    required this.isMain,
    required this.currentName,
    required this.onTap,
  });
  final String       slotKey;
  final bool         isMain;
  final String       currentName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return InkWell(
      onTap:        onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color:        isMain
                    ? cs.primary.withValues(alpha: 0.15)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                isMain ? 'Main' : 'Aux',
                style: TextStyle(
                  fontSize:   10,
                  fontWeight: FontWeight.w600,
                  color: isMain ? cs.primary : cs.onSurface.withValues(alpha: 0.5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(currentName,
                  style: Theme.of(context).textTheme.bodyMedium),
            ),
            Icon(Icons.chevron_right,
                size: 18, color: cs.onSurface.withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }
}

// ── Lift picker bottom sheet ───────────────────────────────────────────────────

class _LiftPickerSheet extends StatefulWidget {
  const _LiftPickerSheet({
    required this.slotKey,
    required this.currentName,
    required this.onSelected,
  });
  final String                  slotKey;
  final String                  currentName;
  final void Function(String)   onSelected;

  @override
  State<_LiftPickerSheet> createState() => _LiftPickerSheetState();
}

class _LiftPickerSheetState extends State<_LiftPickerSheet> {
  late final TextEditingController _ctrl;
  bool _showCustomField = false;

  @override
  void initState() {
    super.initState();
    final presets = liftCatalogue[widget.slotKey] ?? [];
    final isCustom = !presets
        .where((p) => p != kCustomEntry)
        .contains(widget.currentName);
    _showCustomField = isCustom;
    _ctrl = TextEditingController(
        text: isCustom ? widget.currentName : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  void _select(String name) {
    widget.onSelected(name);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final presets = liftCatalogue[widget.slotKey] ?? [];
    final cs      = Theme.of(context).colorScheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize:     0.35,
      maxChildSize:     0.85,
      expand:           false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          color:        const Color(0xFF1E1E1E),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Handle ────────────────────────────────────────────────────
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width:  40, height: 4,
                decoration: BoxDecoration(
                  color:        cs.outlineVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // ── Title ─────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                liftDefaults[widget.slotKey] ?? widget.slotKey,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),

            // ── Preset list ───────────────────────────────────────────────
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount:  presets.length,
                itemBuilder: (_, i) {
                  final preset   = presets[i];
                  final isCustomSentinel = preset == kCustomEntry;
                  final isCurrent = !isCustomSentinel &&
                      preset == widget.currentName;

                  if (isCustomSentinel) {
                    return _CustomEntryTile(
                      ctrl:          _ctrl,
                      showField:     _showCustomField,
                      currentName:   widget.currentName,
                      onToggle: () =>
                          setState(() =>
                              _showCustomField = !_showCustomField),
                      onConfirm: () {
                        final val = _ctrl.text.trim();
                        if (val.isNotEmpty) _select(val);
                      },
                    );
                  }

                  return ListTile(
                    title: Text(preset),
                    trailing: isCurrent
                        ? Icon(Icons.check, color: cs.primary)
                        : null,
                    onTap: () => _select(preset),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The final row in the picker: toggles a text field for free-form input.
class _CustomEntryTile extends StatelessWidget {
  const _CustomEntryTile({
    required this.ctrl,
    required this.showField,
    required this.currentName,
    required this.onToggle,
    required this.onConfirm,
  });
  final TextEditingController ctrl;
  final bool                  showField;
  final String                currentName;
  final VoidCallback          onToggle;
  final VoidCallback          onConfirm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading:  Icon(Icons.edit_outlined, color: cs.primary),
          title:    const Text('Custom…'),
          trailing: Icon(
              showField ? Icons.expand_less : Icons.expand_more,
              size: 18),
          onTap: onToggle,
        ),
        if (showField)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller:    ctrl,
                    autofocus:     true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText:        'Enter exercise name',
                      suffixIcon: IconButton(
                        icon:      const Icon(Icons.clear, size: 18),
                        onPressed: () => ctrl.clear(),
                      ),
                    ),
                    onSubmitted: (_) => onConfirm(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onConfirm,
                  child:     const Text('OK'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Frequency selector (unchanged) ───────────────────────────────────────────

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector(
      {required this.selected, required this.onSelected});
  final ProgramFrequency?              selected;
  final void Function(ProgramFrequency) onSelected;

  @override
  Widget build(BuildContext context) {
    const options = [
      (ProgramFrequency.two,   '2x', '2 days/week'),
      (ProgramFrequency.three, '3x', '3 days/week'),
      (ProgramFrequency.four,  '4x', '4 days/week'),
      (ProgramFrequency.five,  '5x', '5 days/week'),
      (ProgramFrequency.six,   '6x', '6 days/week'),
    ];
    return GridView.count(
      crossAxisCount:   3,
      mainAxisSpacing:  8,
      crossAxisSpacing: 8,
      shrinkWrap:       true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        for (final (freq, label, sub) in options)
          _FrequencyButton(
            label:      label,
            subtitle:   sub,
            isSelected: selected == freq,
            onTap:      () => onSelected(freq),
          ),
      ],
    );
  }
}

class _FrequencyButton extends StatelessWidget {
  const _FrequencyButton({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });
  final String       label;
  final String       subtitle;
  final bool         isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF5A9FFF) : const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF5A9FFF)
                : const Color(0xFF333333),
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF888888))),
            const SizedBox(height: 4),
            Text(subtitle,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? const Color(0xFFDDDDDD)
                        : const Color(0xFF666666)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}

// ── Training maxes (label uses liftNames) ─────────────────────────────────────

class _TrainingMaxesInput extends StatelessWidget {
  const _TrainingMaxesInput({
    required this.maxes,
    required this.liftNames,
    required this.onMaxUpdated,
  });
  final Map<String, double>          maxes;
  final Map<String, String>          liftNames;
  final void Function(String, double) onMaxUpdated;

  static const _mainSlots = [
    'squat', 'bench_press', 'deadlift', 'overhead_press',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final slotKey in _mainSlots) ...[
          _MaxInput(
            liftId:      slotKey,
            displayName: liftNames[slotKey] ??
                         liftDefaults[slotKey] ??
                         slotKey,
            currentMax:  maxes[slotKey],
            onChanged:   (v) => onMaxUpdated(slotKey, v),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _MaxInput extends StatefulWidget {
  const _MaxInput({
    required this.liftId,
    required this.displayName,
    required this.currentMax,
    required this.onChanged,
  });
  final String  liftId;
  final String  displayName;
  final double? currentMax;
  final void Function(double) onChanged;

  @override
  State<_MaxInput> createState() => _MaxInputState();
}

class _MaxInputState extends State<_MaxInput> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.currentMax != null
            ? widget.currentMax.toString()
            : '');
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.displayName,
            style: Theme.of(context).textTheme.bodyLarge),
        const SizedBox(height: 8),
        TextField(
          controller:   _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText:    'Enter max in kg',
            suffixText:  'kg',
            suffixStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          onChanged: (v) {
            final parsed = double.tryParse(v);
            if (parsed != null) widget.onChanged(parsed);
          },
        ),
      ],
    );
  }
}
