import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'setup_provider.dart';
import '../../domain/models/enums.dart';

/// Setup screen for initial configuration.
/// Allows frequency selection and training max entry.
class SetupScreen extends ConsumerWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final setupState = ref.watch(setupProvider);
    final setupNotifier = ref.read(setupProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        title: const Text('Setup'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                'Configure Your Program',
                style: Theme.of(context).textTheme.displayMedium,
              ),
              const SizedBox(height: 8),
              Text(
                'Select your training frequency and enter your training maxes',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 32),

              // Frequency Selection
              Text(
                'Training Frequency',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _FrequencySelector(
                selected: setupState.selectedFrequency,
                onSelected: (freq) => setupNotifier.selectFrequency(freq),
              ),
              const SizedBox(height: 32),

              // Training Maxes
              Text(
                'Training Maxes',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 12),
              _TrainingMaxesInput(
                maxes: setupState.trainingMaxes,
                onMaxUpdated: (liftId, value) =>
                    setupNotifier.updateTrainingMax(liftId, value),
              ),
              const SizedBox(height: 32),

              // Error message
              if (setupState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.redAccent.withAlpha(40),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.redAccent.withAlpha(100),
                    ),
                  ),
                  child: Text(
                    setupState.errorMessage!,
                    style: const TextStyle(color: Colors.redAccent),
                  ),
                ),
                const SizedBox(height: 24),
              ],

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setupNotifier.clearAllMaxes();
                      },
                      child: const Text('Reset'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: setupState.isValid
                          ? () {
                              // TODO: Save setup to database
                              // TODO: Navigate to today screen
                              context.go('/today');
                            }
                          : null,
                      child: const Text('Continue'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

/// Frequency selection widget.
class _FrequencySelector extends StatelessWidget {
  final ProgramFrequency? selected;
  final void Function(ProgramFrequency) onSelected;

  const _FrequencySelector({
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    const frequencies = [
      (ProgramFrequency.two, '2x'),
      (ProgramFrequency.three, '3x'),
      (ProgramFrequency.four, '4x'),
      (ProgramFrequency.five, '5x'),
      (ProgramFrequency.six, '6x'),
    ];

    return GridView.count(
      crossAxisCount: 3,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      childAspectRatio: 1.2,
      children: [
        for (final (freq, label) in frequencies)
          _FrequencyButton(
            label: label,
            subtitle: '${freq.index + 2} days/week',
            isSelected: selected == freq,
            onTap: () => onSelected(freq),
          ),
      ],
    );
  }
}

/// Single frequency selection button.
class _FrequencyButton extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool isSelected;
  final VoidCallback onTap;

  const _FrequencyButton({
    required this.label,
    required this.subtitle,
    required this.isSelected,
    required this.onTap,
  });

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
            Text(
              label,
              style: Theme.of(context).textTheme.displayMedium?.copyWith(
                    color: isSelected
                        ? const Color(0xFFFFFFFF)
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

/// Training maxes input widget.
class _TrainingMaxesInput extends StatelessWidget {
  final Map<String, double> maxes;
  final void Function(String, double) onMaxUpdated;

  const _TrainingMaxesInput({
    required this.maxes,
    required this.onMaxUpdated,
  });

  @override
  Widget build(BuildContext context) {
    const mainLifts = [
      ('squat', 'Squat'),
      ('bench_press', 'Bench Press'),
      ('deadlift', 'Deadlift'),
      ('overhead_press', 'Overhead Press'),
    ];

    return Column(
      children: [
        for (final (liftId, displayName) in mainLifts) ...[
          _TrainingMaxInput(
            liftId: liftId,
            displayName: displayName,
            currentMax: maxes[liftId],
            onChanged: (value) => onMaxUpdated(liftId, value),
          ),
          const SizedBox(height: 12),
        ],
      ],
    );
  }
}

/// Single training max input field.
class _TrainingMaxInput extends StatefulWidget {
  final String liftId;
  final String displayName;
  final double? currentMax;
  final void Function(double) onChanged;

  const _TrainingMaxInput({
    required this.liftId,
    required this.displayName,
    required this.currentMax,
    required this.onChanged,
  });

  @override
  State<_TrainingMaxInput> createState() => _TrainingMaxInputState();
}

class _TrainingMaxInputState extends State<_TrainingMaxInput> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(
      text: widget.currentMax != null ? widget.currentMax.toString() : '',
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.displayName,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller: _controller,
          keyboardType:
              const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            hintText: 'Enter max in kg',
            suffixText: 'kg',
            suffixStyle: Theme.of(context).textTheme.bodyMedium,
          ),
          onChanged: (value) {
            final parsed = double.tryParse(value);
            if (parsed != null) {
              widget.onChanged(parsed);
            }
          },
        ),
      ],
    );
  }
}

