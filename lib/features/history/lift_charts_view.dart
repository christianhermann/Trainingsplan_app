import 'dart:math' as math;
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import 'lift_history_screen.dart';

class LiftChartsView extends StatelessWidget {
  const LiftChartsView({super.key, required this.entries});

  final List<LiftHistoryEntry> entries;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    // Filter valid entries with reps and sort chronologically (oldest to newest)
    final chronological = entries
        .where((e) => e.log.repsOnLastSet != null)
        .toList()
      ..sort((a, b) {
        final aDate = a.completedAt ?? DateTime(2000);
        final bDate = b.completedAt ?? DateTime(2000);
        return aDate.compareTo(bDate);
      });

    if (chronological.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            'Not enough rep-out data to display progression charts yet.\nLog your AMRAP sets to see visual trends!',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Calculations
    double maxE1rm = 0;
    int totalRepDiff = 0;
    int bestRepDiff = -999;

    final e1rmSpots = <FlSpot>[];
    final diffBars = <BarChartGroupData>[];

    for (int i = 0; i < chronological.length; i++) {
      final entry = chronological[i];
      final reps = entry.log.repsOnLastSet ?? 0;
      final target = entry.prescription.repOutTarget;
      final weight = entry.prescription.workingWeight;

      // Epley formula: weight * (1 + reps / 30)
      final e1rm = reps > 0 ? weight * (1.0 + reps / 30.0) : weight;
      if (e1rm > maxE1rm) maxE1rm = e1rm;
      e1rmSpots.add(FlSpot(i.toDouble(), (e1rm * 10).roundToDouble() / 10));

      final diff = reps - target;
      totalRepDiff += diff;
      if (diff > bestRepDiff) bestRepDiff = diff;

      diffBars.add(BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: diff.toDouble(),
            color: diff >= 0
                ? const Color(0xFF2E7D32)
                : const Color(0xFFC62828),
            width: 14,
            borderRadius: BorderRadius.circular(3),
          ),
        ],
      ));
    }

    final avgDiff = totalRepDiff / chronological.length;
    final minE1rm = e1rmSpots.map((s) => s.y).reduce(math.min);
    final chartMinY = (minE1rm * 0.9 / 5).floor() * 5.0;
    final chartMaxY = (maxE1rm * 1.08 / 5).ceil() * 5.0;

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        // ── Summary KPI Cards ──────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _MetricCard(
                label: 'Peak E1RM',
                value: '${maxE1rm.toStringAsFixed(1)} kg',
                subtitle: 'Estimated max',
                icon: Icons.fitness_center_rounded,
                accentColor: cs.primary,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Avg Rep Delta',
                value: '${avgDiff >= 0 ? "+" : ""}${avgDiff.toStringAsFixed(1)}',
                subtitle: 'vs. SBS plan',
                icon: Icons.trending_up_rounded,
                accentColor: avgDiff >= 0 ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _MetricCard(
                label: 'Best Set',
                value: '${bestRepDiff >= 0 ? "+" : ""}$bestRepDiff reps',
                subtitle: 'over target',
                icon: Icons.emoji_events_rounded,
                accentColor: Colors.amber,
              ),
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Chart 1: Estimated 1RM Progression (LineChart) ─────────────────
        Text(
          'Estimated 1RM Progression',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Calculated using Epley formula: Weight × (1 + Reps / 30)',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
            child: SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: chartMinY,
                  maxY: chartMaxY,
                  lineBarsData: [
                    LineChartBarData(
                      spots: e1rmSpots,
                      isCurved: true,
                      curveSmoothness: 0.25,
                      color: cs.primary,
                      barWidth: 3.5,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, percent, barData, index) {
                          return FlDotCirclePainter(
                            radius: 4,
                            color: cs.primary,
                            strokeWidth: 2,
                            strokeColor: cs.surface,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: cs.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          final idx = spot.x.toInt();
                          final entry = chronological[idx];
                          final reps = entry.log.repsOnLastSet ?? 0;
                          final weight = entry.prescription.workingWeight;
                          return LineTooltipItem(
                            'Session ${idx + 1}\n${spot.y} kg\n(${weight.toStringAsFixed(1)}kg × $reps reps)',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: cs.outlineVariant.withValues(alpha: 0.35),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 42,
                        getTitlesWidget: (val, meta) => Text(
                          '${val.toInt()}kg',
                          style: TextStyle(
                            fontSize: 10,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < chronological.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'S${idx + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 24),

        // ── Chart 2: Plan vs. Actual Rep Difference (BarChart) ─────────────
        Text(
          'Target vs. Actual AMRAP Delta',
          style: tt.titleMedium?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        Text(
          'Difference from prescribed rep-out goal (Green = exceeded, Red = below)',
          style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
        ),
        const SizedBox(height: 12),
        Card(
          elevation: 1,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 20, 16, 12),
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  barGroups: diffBars,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: BarTouchData(
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final idx = group.x.toInt();
                        final entry = chronological[idx];
                        final target = entry.prescription.repOutTarget;
                        final done = entry.log.repsOnLastSet ?? 0;
                        final diff = done - target;
                        final diffStr = diff >= 0 ? '+$diff' : '$diff';
                        return BarTooltipItem(
                          'Session ${idx + 1}\n$diffStr reps\nPlan: $target · Done: $done',
                          const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        );
                      },
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (val) => FlLine(
                      color: val == 0
                          ? cs.outline
                          : cs.outlineVariant.withValues(alpha: 0.3),
                      strokeWidth: val == 0 ? 1.5 : 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        getTitlesWidget: (val, meta) => Text(
                          val > 0 ? '+${val.toInt()}' : '${val.toInt()}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: val > 0
                                ? const Color(0xFF2E7D32)
                                : (val < 0
                                    ? const Color(0xFFC62828)
                                    : cs.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (val, meta) {
                          final idx = val.toInt();
                          if (idx >= 0 && idx < chronological.length) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'S${idx + 1}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: cs.onSurfaceVariant,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.label,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
  });

  final String label;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: cs.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: accentColor),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurfaceVariant,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: cs.onSurface,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              color: cs.onSurfaceVariant.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}
