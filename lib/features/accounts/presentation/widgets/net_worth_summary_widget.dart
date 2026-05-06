import 'package:flutter/material.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../data/models/net_worth_history_model.dart';

class NetWorthSummaryWidget extends StatelessWidget {
  const NetWorthSummaryWidget({required this.history, super.key});

  final NetWorthHistory history;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final isPositive = history.netWorthChange >= 0;
    final changeColor =
        isPositive ? const Color(0xFF4CAF50) : const Color(0xFFEF5350);

    return Card(
      color: cs.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('NET WORTH',
                style: tt.labelSmall
                    ?.copyWith(color: cs.onPrimaryContainer.withAlpha(178))),
            const SizedBox(height: 8),
            Text(formatCurrency(history.currentNetWorth),
                style: tt.headlineMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(
                  isPositive ? Icons.trending_up : Icons.trending_down,
                  color: changeColor,
                  size: 16,
                ),
                const SizedBox(width: 4),
                Flexible(
                  child: Text(
                    '${isPositive ? '+' : ''}${formatCurrency(history.netWorthChange)} (${isPositive ? '+' : ''}${history.netWorthChangePercentage.toStringAsFixed(1)}%)',
                    style: tt.labelSmall?.copyWith(color: changeColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    '1 month change',
                    style: tt.labelSmall
                        ?.copyWith(color: cs.onPrimaryContainer.withAlpha(178)),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
