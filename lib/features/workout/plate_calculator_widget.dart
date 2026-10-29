import 'package:flutter/material.dart';

/// Standard Olympic plate definition with official IPF/IWF competition colours.
class PlateSpec {
  const PlateSpec({
    required this.weight,
    required this.color,
    required this.heightFactor,
  });

  final double weight;
  final Color color;
  final double heightFactor; // 1.0 = 450mm full diameter (25kg/20kg)
}

const standardPlates = [
  PlateSpec(weight: 25.0, color: Color(0xFFD32F2F), heightFactor: 1.0),   // Red
  PlateSpec(weight: 20.0, color: Color(0xFF1976D2), heightFactor: 1.0),   // Blue
  PlateSpec(weight: 15.0, color: Color(0xFFFBC02D), heightFactor: 0.9),   // Yellow
  PlateSpec(weight: 10.0, color: Color(0xFF388E3C), heightFactor: 0.75),  // Green
  PlateSpec(weight: 5.0,  color: Color(0xFFE0E0E0), heightFactor: 0.55),  // White
  PlateSpec(weight: 2.5,  color: Color(0xFF424242), heightFactor: 0.45),  // Black
  PlateSpec(weight: 1.25, color: Color(0xFF757575), heightFactor: 0.38),  // Silver
  PlateSpec(weight: 0.5,  color: Color(0xFFBDBDBD), heightFactor: 0.32),  // Chrome
];

/// Result calculation per side.
class PlateBreakdown {
  const PlateBreakdown({
    required this.targetWeight,
    required this.barWeight,
    required this.weightPerSide,
    required this.platesPerSide,
    required this.actualLoadedWeight,
    required this.remainder,
  });

  final double targetWeight;
  final double barWeight;
  final double weightPerSide;
  final Map<PlateSpec, int> platesPerSide;
  final double actualLoadedWeight;
  final double remainder;

  static PlateBreakdown calculate({
    required double targetWeight,
    double barWeight = 20.0,
  }) {
    if (targetWeight <= barWeight) {
      return PlateBreakdown(
        targetWeight: targetWeight,
        barWeight: barWeight,
        weightPerSide: 0,
        platesPerSide: {},
        actualLoadedWeight: barWeight,
        remainder: 0,
      );
    }

    double neededPerSide = (targetWeight - barWeight) / 2.0;
    final plates = <PlateSpec, int>{};
    double currentPerSide = 0.0;

    for (final plate in standardPlates) {
      if (neededPerSide >= plate.weight) {
        final count = (neededPerSide / plate.weight).floor();
        plates[plate] = count;
        neededPerSide -= count * plate.weight;
        currentPerSide += count * plate.weight;
      }
    }

    final totalLoaded = barWeight + (currentPerSide * 2);
    final rem = targetWeight - totalLoaded;

    return PlateBreakdown(
      targetWeight: targetWeight,
      barWeight: barWeight,
      weightPerSide: currentPerSide,
      platesPerSide: plates,
      actualLoadedWeight: totalLoaded,
      remainder: rem.abs() < 0.01 ? 0 : rem,
    );
  }
}

/// Modal Sheet providing Barbell Plate Calculator & Warmup Set Ramp.
class PlateCalculatorSheet extends StatefulWidget {
  const PlateCalculatorSheet({
    super.key,
    required this.targetWeight,
    required this.liftName,
  });

  final double targetWeight;
  final String liftName;

  static void show(BuildContext context, {required double targetWeight, required String liftName}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => PlateCalculatorSheet(
        targetWeight: targetWeight,
        liftName: liftName,
      ),
    );
  }

  @override
  State<PlateCalculatorSheet> createState() => _PlateCalculatorSheetState();
}

class _PlateCalculatorSheetState extends State<PlateCalculatorSheet> {
  double _barWeight = 20.0;

  @override
  Widget build(BuildContext context) {
    final breakdown = PlateBreakdown.calculate(
      targetWeight: widget.targetWeight,
      barWeight: _barWeight,
    );
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        color: cs.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurfaceVariant.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Plate Calculator',
                      style: tt.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${widget.liftName} · Target ${widget.targetWeight} kg',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              // Bar weight selector
              SegmentedButton<double>(
                segments: const [
                  ButtonSegment(value: 20.0, label: Text('20 kg')),
                  ButtonSegment(value: 15.0, label: Text('15 kg')),
                ],
                selected: {_barWeight},
                onSelectionChanged: (val) => setState(() => _barWeight = val.first),
                style: const ButtonStyle(visualDensity: VisualDensity.compact),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Visual Barbell Sleeve Representation
          _BarbellSleeveGraphic(breakdown: breakdown),

          const SizedBox(height: 16),

          // Summary chip row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: cs.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Per side: ${breakdown.weightPerSide} kg',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  'Bar: ${_barWeight.toInt()} kg',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                Text(
                  'Total: ${breakdown.actualLoadedWeight} kg',
                  style: tt.bodyMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.primary,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Plate count breakdown chips
          if (breakdown.platesPerSide.isNotEmpty) ...[
            Text('Plates per side:', style: tt.labelMedium?.copyWith(color: cs.outline)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final entry in breakdown.platesPerSide.entries)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: entry.key.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: entry.key.color, width: 1.5),
                    ),
                    child: Text(
                      '${entry.value}× ${entry.key.weight} kg',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: cs.onSurface,
                      ),
                    ),
                  ),
              ],
            ),
          ] else
            Center(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Text('Only load the barbell (${_barWeight.toInt()} kg)',
                    style: tt.bodyMedium),
              ),
            ),

          const SizedBox(height: 20),

          // Warmup Sets Section
          _WarmupSection(targetWeight: widget.targetWeight, barWeight: _barWeight),
        ],
      ),
    );
  }
}

/// Draws an interactive graphic of one barbell sleeve loaded with plates.
class _BarbellSleeveGraphic extends StatelessWidget {
  const _BarbellSleeveGraphic({required this.breakdown});
  final PlateBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Collect all plates in order from inside to outside
    final platesToRender = <PlateSpec>[];
    for (final entry in breakdown.platesPerSide.entries) {
      for (int i = 0; i < entry.value; i++) {
        platesToRender.add(entry.key);
      }
    }

    return Container(
      height: 90,
      decoration: BoxDecoration(
        color: cs.surfaceContainerLow,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Stack(
        alignment: Alignment.centerLeft,
        children: [
          // Barbell collar / sleeve bar
          Positioned(
            left: 20,
            right: 20,
            child: Container(
              height: 12,
              decoration: BoxDecoration(
                color: Colors.grey.shade600,
                borderRadius: BorderRadius.circular(3),
              ),
            ),
          ),
          // Inside Collar Stopper
          Positioned(
            left: 30,
            child: Container(
              width: 14,
              height: 56,
              decoration: BoxDecoration(
                color: Colors.grey.shade400,
                borderRadius: BorderRadius.circular(3),
                border: Border.all(color: Colors.grey.shade700, width: 1),
              ),
            ),
          ),
          // Plates stacked on sleeve
          Positioned(
            left: 48,
            child: Row(
              children: [
                for (final plate in platesToRender)
                  Container(
                    margin: const EdgeInsets.only(right: 3),
                    width: plate.weight >= 15 ? 14 : 10,
                    height: 80 * plate.heightFactor,
                    decoration: BoxDecoration(
                      color: plate.color,
                      borderRadius: BorderRadius.circular(3),
                      border: Border.all(color: Colors.black45, width: 1),
                    ),
                    child: Center(
                      child: Text(
                        plate.weight >= 10
                            ? plate.weight.toInt().toString()
                            : plate.weight.toString(),
                        style: TextStyle(
                          fontSize: plate.weight >= 10 ? 8 : 7,
                          fontWeight: FontWeight.bold,
                          color: plate.weight == 5.0 || plate.weight == 0.5
                              ? Colors.black
                              : Colors.white,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Generates standard warmup ramp sets for barbell lifts.
List<({String pct, double weight, int reps})> calculateRamp({
  required double targetWeight,
  double barWeight = 20.0,
}) {
  if (targetWeight <= barWeight) return [];

  double round25(double w) => (w / 2.5).round() * 2.5;

  return [
    (pct: 'Bar', weight: barWeight, reps: 10),
    if (targetWeight * 0.5 > barWeight)
      (pct: '50%', weight: round25(targetWeight * 0.5), reps: 5),
    if (targetWeight * 0.7 > barWeight)
      (pct: '70%', weight: round25(targetWeight * 0.7), reps: 3),
    if (targetWeight * 0.85 > barWeight)
      (pct: '85%', weight: round25(targetWeight * 0.85), reps: 1),
  ];
}

/// Warmup Ramp Calculator.
class _WarmupSection extends StatelessWidget {
  const _WarmupSection({required this.targetWeight, required this.barWeight});
  final double targetWeight;
  final double barWeight;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final warmups = calculateRamp(targetWeight: targetWeight, barWeight: barWeight);

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      shape: const Border(),
      collapsedShape: const Border(),
      title: Row(
        children: [
          Icon(Icons.fitness_center, size: 16, color: cs.primary),
          const SizedBox(width: 8),
          Text(
            'Warmup Sets Ramp',
            style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
      children: [
        for (final w in warmups)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              children: [
                Container(
                  width: 55,
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    w.pct,
                    textAlign: TextAlign.center,
                    style: tt.labelSmall?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${w.weight} kg',
                  style: tt.bodyMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(width: 8),
                Text(
                  '× ${w.reps} reps',
                  style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
          ),
      ],
    );
  }
}
