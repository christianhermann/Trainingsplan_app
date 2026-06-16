import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../data/catalogue/lift_catalogue.dart';
import 'edit_training_max_provider.dart';

const _mainSlots = [
  'squat',
  'bench_press',
  'deadlift',
  'overhead_press',
];

class EditTrainingMaxScreen extends ConsumerWidget {
  const EditTrainingMaxScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async    = ref.watch(editTmProvider);
    final notifier = ref.read(editTmProvider.notifier);

    ref.listen(editTmProvider, (_, next) {
      if (next.valueOrNull?.isDone == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Training maxes updated. Future workouts regenerated.'),
          ),
        );
        context.pop();
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Training Maxes')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error:   (e, _) => Center(child: Text('Error loading maxes: $e')),
        data:    (s) => _Body(state: s, notifier: notifier),
      ),
    );
  }
}

// ── Body ───────────────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.state, required this.notifier});
  final EditTmState    state;
  final EditTmNotifier notifier;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Update your training maxes below. All future (not yet completed) '
            'workouts will be regenerated with the new values.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.65)),
          ),
          const SizedBox(height: 24),

          for (final slotKey in _mainSlots) ...[
            _MaxField(
              slotKey:    slotKey,
              currentMax: state.trainingMaxes[slotKey],
              onChanged:  (v) => notifier.updateMax(slotKey, v),
            ),
            const SizedBox(height: 16),
          ],

          if (state.errorMessage != null) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color:        Colors.redAccent.withAlpha(40),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent.withAlpha(100)),
              ),
              child: Text(state.errorMessage!,
                  style: const TextStyle(color: Colors.redAccent)),
            ),
          ],

          const SizedBox(height: 24),

          ElevatedButton(
            onPressed: (state.isValid && !state.isSaving)
                ? notifier.save
                : null,
            child: state.isSaving
                ? const SizedBox(
                    width:  20,
                    height: 20,
                    child:  CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                : const Text('Save & Regenerate'),
          ),
        ],
      ),
    );
  }
}

// ── Single max input field ────────────────────────────────────────────────────

class _MaxField extends StatefulWidget {
  const _MaxField({
    required this.slotKey,
    required this.currentMax,
    required this.onChanged,
  });
  final String  slotKey;
  final double? currentMax;
  final void Function(double) onChanged;

  @override
  State<_MaxField> createState() => _MaxFieldState();
}

class _MaxFieldState extends State<_MaxField> {
  late final TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(
        text: widget.currentMax != null
            ? widget.currentMax! % 1 == 0
                ? widget.currentMax!.toInt().toString()
                : widget.currentMax!.toStringAsFixed(1)
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
        Text(
          liftDefaults[widget.slotKey] ?? widget.slotKey,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
        const SizedBox(height: 8),
        TextField(
          controller:   _ctrl,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration:   const InputDecoration(
            hintText:   'Enter max in kg',
            suffixText: 'kg',
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
