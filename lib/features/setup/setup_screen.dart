import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../domain/models/enums.dart';
import 'setup_provider.dart';

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    final notifier   = ref.read(setupProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(title: const Text('Setup')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header ───────────────────────────────────────────────────────────
              Text('Configure Your Program',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Select your training frequency and enter your training maxes.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // ── Frequency ──────────────────────────────────────────────────────────
              Text('Training Frequency',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _FrequencySelector(
                selected:   setupState.selectedFrequency,
                onSelected: notifier.selectFrequency,
              ),
              const SizedBox(height: 32),

              // ── Training maxes ────────────────────────────────────────────────────
              Text('Training Maxes',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _TrainingMaxesInput(
                maxes:        setupState.trainingMaxes,
                onMaxUpdated: notifier.updateTrainingMax,
              ),
              const SizedBox(height: 32),

              // ── Auxiliary lifts ───────────────────────────────────────────────────
              Text('Auxiliary Lifts',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 4),
              Text(
                'Choose one auxiliary lift per main movement. Defaults match the workbook.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.55)),
              ),
              const SizedBox(height: 16),
              _AuxiliaryLiftsSection(
                selectedAux: setupState.selectedAuxiliaries,
                onSelected:  notifier.selectAuxiliary,
              ),
              const SizedBox(height: 24),

              // ── Error banner ───────────────────────────────────────────────────────
              if (setupState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border:
                        Border.all(color: Colors.redAccent.withAlpha(100)),
                  ),
                  child: Text(setupState.errorMessage!,
                      style:
                          const TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(height: 16),
              ],

              // ── Action buttons ──────────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: notifier.clearAllMaxes,
                      child:     const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (setupState.isValid && !setupState.isSaving)
                          ? () async {
                              await notifier.saveAndGenerate();
                              if (context.mounted &&
                                  ref
                                          .read(setupProvider)
                                          .errorMessage ==
                                      null) {
                                context.go('/today');
                              }
                            }
                          : null,
                      child: setupState.isSaving
                          ? const SizedBox(
                              width:  20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white),
                            )
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

// ── Auxiliary lifts section ──────────────────────────────────────────────────────────────

class _AuxiliaryLiftsSection extends StatelessWidget {
  const _AuxiliaryLiftsSection({
    required this.selectedAux,
    required this.onSelected,
  });
  final Map<String, String>                 selectedAux;
  final void Function(String, String) onSelected; // (mainKey, auxKey)

  static const _mainLifts = [
    (key: 'squat',          label: 'Squat'),
    (key: 'bench_press',    label: 'Bankdr\u00FCcken'),
    (key: 'deadlift',       label: 'Deadlift'),
    (key: 'overhead_press', label: 'Schulterdr\u00FCcken'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (final main in _mainLifts) ...[
          _AuxRow(
            mainKey:     main.key,
            mainLabel:   main.label,
            options:     auxOptions[main.key]!,
            selectedKey: selectedAux[main.key] ??
                auxOptions[main.key]!.first.key,
            onSelected:  (auxKey) => onSelected(main.key, auxKey),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// One row: main lift label on the left, two-option toggle on the right.
class _AuxRow extends StatelessWidget {
  const _AuxRow({
    required this.mainKey,
    required this.mainLabel,
    required this.options,
    required this.selectedKey,
    required this.onSelected,
  });
  final String                                      mainKey;
  final String                                      mainLabel;
  final List<({String key, String label})>          options;
  final String                                      selectedKey;
  final void Function(String auxKey)                onSelected;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Deduplicate: if both options share the same key (Deadlift / OHP with a
    // single workbook option), only show one button.
    final distinct = options
        .fold(<String, ({String key, String label})>{}, (map, o) {
          map[o.key] = o;
          return map;
        })
        .values
        .toList();

    // isSelected list required by ToggleButtons (same length as children).
    final selected =
        distinct.map((o) => o.key == selectedKey).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(mainLabel,
            style: tt.bodyMedium?.copyWith(
                color: cs.onSurface.withValues(alpha: 0.7))),
        const SizedBox(height: 6),
        SizedBox(
          width: double.infinity,
          child: ToggleButtons(
            borderRadius:     BorderRadius.circular(10),
            selectedColor:    cs.onPrimary,
            fillColor:        cs.primary,
            color:            cs.onSurface.withValues(alpha: 0.65),
            borderColor:      cs.outlineVariant,
            selectedBorderColor: cs.primary,
            constraints: BoxConstraints(
              minHeight: 40,
              // Divide available width equally between however many options.
              minWidth: (MediaQuery.sizeOf(context).width - 32) /
                  distinct.length,
            ),
            isSelected: selected,
            onPressed: (i) => onSelected(distinct[i].key),
            children: [
              for (final opt in distinct)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    opt.label,
                    style: tt.bodySmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    textAlign: TextAlign.center,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Frequency selector (unchanged) ───────────────────────────────────────────────────────

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector(
      {required this.selected, required this.onSelected});
  final ProgramFrequency? selected;
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
      crossAxisCount:  3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap:      true,
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
          color: isSelected
              ? const Color(0xFF5A9FFF)
              : const Color(0xFF1E1E1E),
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
            Text(
              label,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: isSelected
                        ? Colors.white
                        : const Color(0xFF888888),
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: isSelected
                        ? const Color(0xFFDDDDDD)
                        : const Color(0xFF666666),
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ── Training maxes (unchanged) ─────────────────────────────────────────────────────────

class _TrainingMaxesInput extends StatelessWidget {
  const _TrainingMaxesInput(
      {required this.maxes, required this.onMaxUpdated});
  final Map<String, double>          maxes;
  final void Function(String, double) onMaxUpdated;

  @override
  Widget build(BuildContext context) {
    const lifts = [
      ('squat',          'Squat'),
      ('bench_press',    'Bankdr\u00FCcken'),
      ('deadlift',       'Deadlift'),
      ('overhead_press', 'Schulterdr\u00FCcken'),
    ];
    return Column(
      children: [
        for (final (id, name) in lifts) ...[
          _MaxInput(
            liftId:      id,
            displayName: name,
            currentMax:  maxes[id],
            onChanged:   (v) => onMaxUpdated(id, v),
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
  late TextEditingController _ctrl;

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
          controller: _ctrl,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
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
