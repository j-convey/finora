import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../data/models/net_worth_history_model.dart';

class NetWorthChartWidget extends StatelessWidget {
  const NetWorthChartWidget({required this.history, super.key});

  final NetWorthHistory history;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    if (history.entries.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: Text('No history data available',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        ),
      );
    }

    final netWorths = history.entries.map((e) => e.netWorth).toList();
    final minNetWorth = netWorths.fold<double>(
        netWorths.first, (prev, v) => v < prev ? v : prev);
    final maxNetWorth = netWorths.fold<double>(
        netWorths.first, (prev, v) => v > prev ? v : prev);

    final diff = maxNetWorth - minNetWorth;
    // Ensure we don't have too many labels. Aim for ~4-5 labels max.
    final chartInterval = diff > 1000 ? diff / 4 : 500.0;

    final spots = history.entries.asMap().entries.map((entry) {
      return FlSpot(entry.key.toDouble(), entry.value.netWorth);
    }).toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Net Worth Performance',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 240, // Increased height for better visibility
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: chartInterval,
                    getDrawingHorizontalLine: (value) {
                      return FlLine(
                        color: cs.outlineVariant.withAlpha(76),
                        strokeWidth: 0.8,
                      );
                    },
                  ),
                  titlesData: FlTitlesData(
                    show: true,
                    topTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 32,
                        interval: (history.entries.length / 5).clamp(1, 100),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= history.entries.length) {
                            return const SizedBox.shrink();
                          }
                          final date = history.entries[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 10),
                            child: Text(
                              '${date.month}/${date.day}',
                              style: Theme.of(context).textTheme.labelSmall,
                            ),
                          );
                        },
                      ),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 52, // Give space for labels like "$17.5K"
                        interval: chartInterval,
                        getTitlesWidget: (value, meta) {
                          // Skip labels that are too close to avoid clutter
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: Text(
                              value >= 1000
                                  ? '\$${(value / 1000).toStringAsFixed(1)}K'
                                  : '\$${value.toStringAsFixed(0)}',
                              style: Theme.of(context).textTheme.labelSmall,
                              textAlign: TextAlign.right,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: (history.entries.length - 1).toDouble(),
                  minY: minNetWorth == maxNetWorth
                      ? minNetWorth - 5000
                      : minNetWorth - (diff * 0.1), // Add 10% padding
                  maxY: minNetWorth == maxNetWorth
                      ? maxNetWorth + 5000
                      : maxNetWorth + (diff * 0.1), // Add 10% padding
                  lineBarsData: [
                    LineChartBarData(
                      spots: spots,
                      isCurved: true,
                      color: cs.primary,
                      barWidth: 2.5,
                      dotData: FlDotData(
                        show: false,
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: cs.primary.withAlpha(76),
                      ),
                    ),
                  ],
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => cs.surface,
                      tooltipBorder: BorderSide(color: cs.outline),
                      getTooltipItems: (touchedSpots) {
                        return touchedSpots.map((spot) {
                          return LineTooltipItem(
                            '\$${spot.y.toStringAsFixed(2)}',
                            TextStyle(color: cs.onSurface),
                          );
                        }).toList();
                      },
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
