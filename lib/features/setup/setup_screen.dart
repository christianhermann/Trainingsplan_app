import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalogue/lift_catalogue.dart';
import '../../domain/models/enums.dart';
import 'setup_provider.dart';

// ── Screen ────────────────────────────────────────────────────────────────────────────

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(setupProvider);
    final notifier = ref.read(setupProvider.notifier);

    return Scaffold(
      // No backgroundColor override — inherits from theme (high-contrast surface)
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

              // ── Frequency ────────────────────────────────────────────────────────────────
              Text('Training Frequency',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _FrequencySelector(
                selected: s.selectedFrequency,
                onSelected: notifier.selectFrequency,
              ),
              const SizedBox(height: 32),

              // ── Training maxes ────────────────────────────────────────────────────────
              Text('Training Maxes',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _TrainingMaxesInput(
                mainMaxes: s.trainingMaxes,
                auxMaxes: s.auxTrainingMaxes,
                singleEightPercentages: s.singleEightPercentages,
                liftNames: s.liftNames,
                onMainMaxUpdated: notifier.updateTrainingMax,
                onAuxMaxUpdated: notifier.updateAuxTrainingMax,
                onSingleEightUpdated: notifier.updateSingleEightPercentage,
              ),
              const SizedBox(height: 32),

              // ── Lift selection ────────────────────────────────────────────────────────
              Text('Lift Selection',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Tap any lift to choose from presets or enter a custom name.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              _LiftSelectionSection(
                liftNames: s.liftNames,
                onNameSet: notifier.setLiftName,
              ),
              const SizedBox(height: 24),

              // ── Error banner ───────────────────────────────────────────────────────────
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

              // ── Action buttons ────────────────────────────────────────────────────────
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
                              width: 20,
                              height: 20,
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

// ── Lift selection section ────────────────────────────────────────────────────────────────

class _LiftSelectionSection extends StatelessWidget {
  const _LiftSelectionSection({
    required this.liftNames,
    required this.onNameSet,
  });
  final Map<String, String> liftNames;
  final void Function(String, String) onNameSet;

  static const _groups = [
    (
      label: 'Squat',
      slotLabel: 'Squat pattern',
      slots: ['squat', 'front_squat', 'squat_aux2'],
    ),
    (
      label: 'Bankdrücken',
      slotLabel: 'Bench pattern',
      slots: ['bench_press', 'close_grip_bench', 'bench_aux2'],
    ),
    (
      label: 'Deadlift',
      slotLabel: 'Hinge pattern',
      slots: ['deadlift', 'deadlift_aux'],
    ),
    (
      label: 'Schulterdrücken',
      slotLabel: 'Press pattern',
      slots: ['overhead_press', 'ohp_aux'],
    ),
    (
      label: 'Back / Accessory',
      slotLabel: 'Pull pattern',
      slots: ['barbell_rows', 'dumbbell_rows', 'pulldowns'],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final g in _groups)
          _LiftGroupCard(
            groupLabel: g.label,
            slotKeys: g.slots,
            liftNames: liftNames,
            onNameSet: onNameSet,
          ),
      ],
    );
  }
}

// ── Group card ────────────────────────────────────────────────────────────────────────────────

class _LiftGroupCard extends StatelessWidget {
  const _LiftGroupCard({
    required this.groupLabel,
    required this.slotKeys,
    required this.liftNames,
    required this.onNameSet,
  });
  final String groupLabel;
  final List<String> slotKeys;
  final Map<String, String> liftNames;
  final void Function(String, String) onNameSet;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final mainSlot = slotKeys.first;
    final mainName = liftNames[mainSlot] ?? liftDefaults[mainSlot] ?? mainSlot;

    final isBackGroup = slotKeys.every((k) =>
        const ['barbell_rows', 'dumbbell_rows', 'pulldowns'].contains(k));

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      // No hardcoded color — uses cardTheme.color from theme.dart
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Row(
          children: [
            Text(
              groupLabel,
              style: tt.labelSmall?.copyWith(color: cs.onSurfaceVariant),
            ),
            if (!isBackGroup) ...[
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mainName,
                  style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ] else
              const Expanded(child: SizedBox()),
          ],
        ),
        trailing: Text(
          '${slotKeys.length} slot${slotKeys.length > 1 ? 's' : ''}',
          style: tt.labelSmall?.copyWith(color: cs.primary),
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 8),
          for (final slotKey in slotKeys)
            _LiftSlotTile(
              slotKey: slotKey,
              badgeLabel:
                  isBackGroup ? 'Acc' : (slotKey == mainSlot ? 'Main' : 'Aux'),
              isMain: !isBackGroup && slotKey == mainSlot,
              currentName:
                  liftNames[slotKey] ?? liftDefaults[slotKey] ?? slotKey,
              onTap: () => _openPicker(context, slotKey),
            ),
        ],
      ),
    );
  }

  void _openPicker(BuildContext context, String slotKey) {
    final currentName = liftNames[slotKey] ?? liftDefaults[slotKey] ?? slotKey;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _LiftPickerSheet(
        slotKey: slotKey,
        currentName: currentName,
        onSelected: (name) => onNameSet(slotKey, name),
      ),
    );
  }
}

// ── Slot tile ────────────────────────────────────────────────────────────────────────────────

class _LiftSlotTile extends StatelessWidget {
  const _LiftSlotTile({
    required this.slotKey,
    required this.badgeLabel,
    required this.isMain,
    required this.currentName,
    required this.onTap,
  });
  final String slotKey;
  final String badgeLabel;
  final bool isMain;
  final String currentName;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        child: Row(
          children: [
            Container(
              width: 46,
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isMain
                    ? cs.primary.withValues(alpha: 0.15)
                    : cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                badgeLabel,
                textAlign: TextAlign.center,
                style: tt.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isMain ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(currentName, style: tt.bodyMedium),
            ),
            Icon(Icons.chevron_right, size: 18, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ── Lift picker bottom sheet ─────────────────────────────────────────────────────────────

class _LiftPickerSheet extends StatefulWidget {
  const _LiftPickerSheet({
    required this.slotKey,
    required this.currentName,
    required this.onSelected,
  });
  final String slotKey;
  final String currentName;
  final void Function(String) onSelected;

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
    final isCustom =
        !presets.where((p) => p != kCustomEntry).contains(widget.currentName);
    _showCustomField = isCustom;
    _ctrl = TextEditingController(text: isCustom ? widget.currentName : '');
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
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.55,
      minChildSize: 0.35,
      maxChildSize: 0.85,
      expand: false,
      builder: (_, scrollCtrl) => Container(
        decoration: BoxDecoration(
          // Use theme surface container — visible against scaffold on both modes
          color: cs.surfaceContainer,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Title
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Text(
                liftDefaults[widget.slotKey] ?? widget.slotKey,
                style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
            ),
            Divider(height: 1, color: cs.outlineVariant),

            // Preset list
            Expanded(
              child: ListView.builder(
                controller: scrollCtrl,
                itemCount: presets.length,
                itemBuilder: (_, i) {
                  final preset = presets[i];
                  final isCustomSentinel = preset == kCustomEntry;
                  final isCurrent =
                      !isCustomSentinel && preset == widget.currentName;

                  if (isCustomSentinel) {
                    return _CustomEntryTile(
                      ctrl: _ctrl,
                      showField: _showCustomField,
                      onToggle: () =>
                          setState(() => _showCustomField = !_showCustomField),
                      onConfirm: () {
                        final val = _ctrl.text.trim();
                        if (val.isNotEmpty) _select(val);
                      },
                    );
                  }

                  return ListTile(
                    title: Text(preset),
                    trailing:
                        isCurrent ? Icon(Icons.check, color: cs.primary) : null,
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

// ── Custom entry tile ────────────────────────────────────────────────────────────────────

class _CustomEntryTile extends StatelessWidget {
  const _CustomEntryTile({
    required this.ctrl,
    required this.showField,
    required this.onToggle,
    required this.onConfirm,
  });
  final TextEditingController ctrl;
  final bool showField;
  final VoidCallback onToggle;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          leading: Icon(Icons.edit_outlined, color: cs.primary),
          title: const Text('Custom…'),
          trailing:
              Icon(showField ? Icons.expand_less : Icons.expand_more, size: 18),
          onTap: onToggle,
        ),
        if (showField)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: ctrl,
                    autofocus: true,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Enter exercise name',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => ctrl.clear(),
                      ),
                    ),
                    onSubmitted: (_) => onConfirm(),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: onConfirm,
                  child: const Text('OK'),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

// ── Frequency selector ───────────────────────────────────────────────────────────────────

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector({required this.selected, required this.onSelected});
  final ProgramFrequency? selected;
  final void Function(ProgramFrequency) onSelected;

  @override
  Widget build(BuildContext context) {
    const options = [
      (ProgramFrequency.two, '2x', '2 days/week'),
      (ProgramFrequency.three, '3x', '3 days/week'),
      (ProgramFrequency.four, '4x', '4 days/week'),
      (ProgramFrequency.five, '5x', '5 days/week'),
      (ProgramFrequency.six, '6x', '6 days/week'),
    ];
    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        for (final (freq, label, sub) in options)
          _FrequencyButton(
            label: label,
            subtitle: sub,
            isSelected: selected == freq,
            onTap: () => onSelected(freq),
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
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? cs.primary : cs.surfaceContainer,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? cs.primary : cs.outline,
            width: 2,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: tt.headlineMedium?.copyWith(
                color: isSelected ? cs.onPrimary : cs.onSurface,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: tt.labelSmall?.copyWith(
                color: isSelected
                    ? cs.onPrimary.withValues(alpha: 0.85)
                    : cs.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Training maxes (main + collapsible auxiliary) ───────────────────────────────────

class _TrainingMaxesInput extends StatelessWidget {
  const _TrainingMaxesInput({
    required this.mainMaxes,
    required this.auxMaxes,
    required this.singleEightPercentages,
    required this.liftNames,
    required this.onMainMaxUpdated,
    required this.onAuxMaxUpdated,
    required this.onSingleEightUpdated,
  });
  final Map<String, double> mainMaxes;
  final Map<String, double> auxMaxes;
  final Map<String, double> singleEightPercentages;
  final Map<String, String> liftNames;
  final void Function(String, double) onMainMaxUpdated;
  final void Function(String, double) onAuxMaxUpdated;
  final void Function(String, double) onSingleEightUpdated;

  static const _mainSlots = [
    'squat',
    'bench_press',
    'deadlift',
    'overhead_press',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final slotKey in _mainSlots) ...[
          _MaxInput(
            liftId: slotKey,
            displayName: liftNames[slotKey] ?? liftDefaults[slotKey] ?? slotKey,
            currentMax: mainMaxes[slotKey],
            singleEightPct:
                singleEightPercentages[slotKey] ?? kDefaultSingleAt8,
            hintText: 'Enter max in kg',
            onChanged: (v) => onMainMaxUpdated(slotKey, v),
            onSingleEightChanged: (v) => onSingleEightUpdated(slotKey, v),
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        _AuxiliaryMaxesSection(
          mainMaxes: mainMaxes,
          auxMaxes: auxMaxes,
          liftNames: liftNames,
          onAuxMaxUpdated: onAuxMaxUpdated,
        ),
      ],
    );
  }
}

// ── Auxiliary maxes collapsible section ──────────────────────────────────────────────────

class _AuxiliaryMaxesSection extends StatelessWidget {
  const _AuxiliaryMaxesSection({
    required this.mainMaxes,
    required this.auxMaxes,
    required this.liftNames,
    required this.onAuxMaxUpdated,
  });
  final Map<String, double> mainMaxes;
  final Map<String, double> auxMaxes;
  final Map<String, String> liftNames;
  final void Function(String, double) onAuxMaxUpdated;

  static const _auxRows = [
    (slot: 'front_squat', parent: 'squat'),
    (slot: 'squat_aux2', parent: 'squat'),
    (slot: 'close_grip_bench', parent: 'bench_press'),
    (slot: 'bench_aux2', parent: 'bench_press'),
    (slot: 'deadlift_aux', parent: 'deadlift'),
    (slot: 'ohp_aux', parent: 'overhead_press'),
  ];

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      // No hardcoded color — uses cardTheme.color
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      margin: EdgeInsets.zero,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        childrenPadding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          'Auxiliary Maxes',
          style: tt.bodyLarge?.copyWith(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          'Optional — defaults to main max × 0.9',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        trailing: Icon(
          Icons.tune,
          size: 18,
          color: cs.onSurfaceVariant,
        ),
        children: [
          const Divider(height: 1),
          const SizedBox(height: 12),
          for (final row in _auxRows) ...[
            _AuxMaxRow(
              slotKey: row.slot,
              parentKey: row.parent,
              displayName:
                  liftNames[row.slot] ?? liftDefaults[row.slot] ?? row.slot,
              parentMainMax: mainMaxes[row.parent],
              currentAuxMax: auxMaxes[row.slot],
              onChanged: (v) => onAuxMaxUpdated(row.slot, v),
            ),
            const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}

/// One row inside the auxiliary maxes section.
class _AuxMaxRow extends StatefulWidget {
  const _AuxMaxRow({
    required this.slotKey,
    required this.parentKey,
    required this.displayName,
    required this.parentMainMax,
    required this.currentAuxMax,
    required this.onChanged,
  });
  final String slotKey;
  final String parentKey;
  final String displayName;
  final double? parentMainMax;
  final double? currentAuxMax;
  final void Function(double) onChanged;

  @override
  State<_AuxMaxRow> createState() => _AuxMaxRowState();
}

class _AuxMaxRowState extends State<_AuxMaxRow> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
      text: widget.currentAuxMax != null ? widget.currentAuxMax.toString() : '',
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String get _autoHint {
    final parent = widget.parentMainMax;
    if (parent == null || parent <= 0) return 'auto (main × 0.9)';
    final computed = (parent * 0.9 * 10).round() / 10;
    return '$computed kg (auto)';
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          flex: 5,
          child: Text(
            widget.displayName,
            style: tt.bodyMedium,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          flex: 4,
          child: TextField(
            controller: _ctrl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            style: tt.bodyMedium,
            decoration: InputDecoration(
              isDense: true,
              hintText: _autoHint,
              hintStyle: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
              suffixText: 'kg',
              suffixStyle: tt.bodySmall,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            ),
            onChanged: (v) {
              final parsed = double.tryParse(v.replaceAll(',', '.'));
              widget.onChanged(parsed ?? 0.0);
            },
          ),
        ),
      ],
    );
  }
}

// ── Max input (main lifts) ──────────────────────────────────────────────────────────────────

/// Renders the training-max text field and the Single @8% field for one main lift.
class _MaxInput extends StatefulWidget {
  const _MaxInput({
    required this.liftId,
    required this.displayName,
    required this.currentMax,
    required this.singleEightPct,
    required this.onChanged,
    required this.onSingleEightChanged,
    this.hintText = 'Enter max in kg',
  });
  final String liftId;
  final String displayName;
  final double? currentMax;
  final double singleEightPct;
  final String hintText;
  final void Function(double) onChanged;
  final void Function(double) onSingleEightChanged;

  @override
  State<_MaxInput> createState() => _MaxInputState();
}

class _MaxInputState extends State<_MaxInput> {
  late final TextEditingController _tmCtrl;
  late final TextEditingController _s8Ctrl;
  late final FocusNode _tmFocus;
  late final FocusNode _s8Focus;

  @override
  void initState() {
    super.initState();
    _tmCtrl = TextEditingController(
        text: widget.currentMax != null ? widget.currentMax.toString() : '');
    _s8Ctrl = TextEditingController(text: widget.singleEightPct.toString());
    _tmFocus = FocusNode();
    _s8Focus = FocusNode();
  }

  @override
  void dispose() {
    _tmCtrl.dispose();
    _s8Ctrl.dispose();
    _tmFocus.dispose();
    _s8Focus.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _MaxInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    final maxText = widget.currentMax?.toString() ?? '';
    if (!_tmFocus.hasFocus && maxText != _tmCtrl.text) {
      _tmCtrl.text = maxText;
    }
    final singleText = widget.singleEightPct.toString();
    if (!_s8Focus.hasFocus && singleText != _s8Ctrl.text) {
      _s8Ctrl.text = singleText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.displayName, style: tt.bodyLarge),
        const SizedBox(height: 8),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Training Max field ─────────────────────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Training max',
                      style:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _tmCtrl,
                    focusNode: _tmFocus,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      hintText: widget.hintText,
                      suffixText: 'kg',
                      suffixStyle: tt.bodyMedium,
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      widget.onChanged(parsed ?? 0.0);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            // ── Single @8% field ──────────────────────────────────────────
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Single @8%',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  const SizedBox(height: 4),
                  TextField(
                    controller: _s8Ctrl,
                    focusNode: _s8Focus,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      isDense: true,
                      hintText: '0.9',
                      hintStyle:
                          tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 12),
                    ),
                    onChanged: (v) {
                      final parsed = double.tryParse(v.replaceAll(',', '.'));
                      if (parsed != null && parsed > 0 && parsed <= 1) {
                        widget.onSingleEightChanged(parsed);
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
