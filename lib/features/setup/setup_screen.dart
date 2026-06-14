import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'setup_provider.dart';
import '../../domain/models/enums.dart';

class SetupScreen extends ConsumerWidget {
  const SetupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
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
              Text('Configure Your Program',
                  style: Theme.of(context).textTheme.displayMedium),
              const SizedBox(height: 8),
              Text(
                'Select your training frequency and enter your training maxes.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),
              Text('Training Frequency',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _FrequencySelector(
                selected: setupState.selectedFrequency,
                onSelected: notifier.selectFrequency,
              ),
              const SizedBox(height: 32),
              Text('Training Maxes',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 12),
              _TrainingMaxesInput(
                maxes: setupState.trainingMaxes,
                onMaxUpdated: notifier.updateTrainingMax,
              ),
              const SizedBox(height: 24),
              if (setupState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: Colors.redAccent.withAlpha(100)),
                  ),
                  child: Text(setupState.errorMessage!,
                      style: const TextStyle(color: Colors.redAccent)),
                ),
                const SizedBox(height: 16),
              ],
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
                      onPressed: (setupState.isValid && !setupState.isSaving)
                          ? () async {
                              await notifier.saveAndGenerate();
                              if (context.mounted &&
                                  ref.read(setupProvider).errorMessage ==
                                      null) {
                                context.go('/today');
                              }
                            }
                          : null,
                      child: setupState.isSaving
                          ? const SizedBox(
                              width: 20,
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

class _FrequencySelector extends StatelessWidget {
  const _FrequencySelector(
      {required this.selected, required this.onSelected});
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color:
              isSelected ? const Color(0xFF5A9FFF) : const Color(0xFF1E1E1E),
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

class _TrainingMaxesInput extends StatelessWidget {
  const _TrainingMaxesInput(
      {required this.maxes, required this.onMaxUpdated});
  final Map<String, double> maxes;
  final void Function(String, double) onMaxUpdated;

  @override
  Widget build(BuildContext context) {
    const lifts = [
      ('squat', 'Squat'),
      ('bench_press', 'Bankdrücken'),
      ('deadlift', 'Deadlift'),
      ('overhead_press', 'Schulterdrücken'),
    ];
    return Column(
      children: [
        for (final (id, name) in lifts) ...[
          _MaxInput(
            liftId: id,
            displayName: name,
            currentMax: maxes[id],
            onChanged: (v) => onMaxUpdated(id, v),
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
  final String liftId;
  final String displayName;
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
            hintText: 'Enter max in kg',
            suffixText: 'kg',
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
