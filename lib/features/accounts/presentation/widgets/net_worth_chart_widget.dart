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

    final minNetWorth =
        history.entries.map((e) => e.netWorth).reduce((a, b) => a < b ? a : b);
    final maxNetWorth =
        history.entries.map((e) => e.netWorth).reduce((a, b) => a > b ? a : b);

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
              height: 200,
              child: LineChart(
                LineChartData(
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxNetWorth - minNetWorth) / 4,
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
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= history.entries.length) {
                            return const Text('');
                          }
                          final date = history.entries[index].date;
                          return Padding(
                            padding: const EdgeInsets.only(top: 8),
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
                        getTitlesWidget: (value, meta) {
                          return Text(
                            '\$${(value / 1000).toStringAsFixed(0)}K',
                            style: Theme.of(context).textTheme.labelSmall,
                          );
                        },
                        interval: (maxNetWorth - minNetWorth) / 4,
                      ),
                    ),
                  ),
                  borderData: FlBorderData(
                    show: false,
                  ),
                  minX: 0,
                  maxX: (history.entries.length - 1).toDouble(),
                  minY: minNetWorth * 0.98,
                  maxY: maxNetWorth * 1.02,
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
