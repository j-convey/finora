import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/providers/hide_amounts_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../domain/entities/report_summary.dart';

/// Summary statistics card shown at the bottom of each report tab.
class ReportSummaryCard extends ConsumerWidget {
  const ReportSummaryCard({
    super.key,
    required this.summary,
    required this.tab,
  });

  final ReportSummary summary;

  /// 0 = Cash Flow, 1 = Spending, 2 = Income.
  final int tab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hidden = ref.watch(hideAmountsProvider);

    String mask(String value) => hidden ? '••••••' : value;

    return Card(
      color: cs.surfaceContainerLow,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Summary', style: tt.titleSmall),
            const Divider(height: 20),
            _Row(
              label: 'Total transactions',
              value: '${summary.transactionCount}',
            ),
            if (tab == 0) ...[
              _Row(
                label: 'Total income',
                value: mask('+${formatCurrency(summary.totalIncome)}'),
                valueColor: const Color(0xFF4CAF50),
              ),
              _Row(
                label: 'Total expenses',
                value: mask(formatCurrency(summary.totalExpenses)),
                valueColor: const Color(0xFFEF5350),
              ),
              _Row(
                label: 'Net cash flow',
                value: mask(
                    '${summary.netCashFlow >= 0 ? '+' : ''}${formatCurrency(summary.netCashFlow)}'),
                valueColor: summary.netCashFlow >= 0
                    ? const Color(0xFF4CAF50)
                    : const Color(0xFFEF5350),
              ),
              _Row(
                label: 'Savings rate',
                value: '${(summary.savingsRate * 100).toStringAsFixed(1)}%',
              ),
            ],
            if (tab == 1 && summary.largestExpense != null)
              _Row(
                label: 'Largest expense',
                value: mask(formatCurrency(summary.largestExpense!.amount)),
                valueColor: const Color(0xFFEF5350),
              ),
            if (tab == 2 && summary.largestIncome != null)
              _Row(
                label: 'Largest income',
                value:
                    mask('+${formatCurrency(summary.largestIncome!.amount)}'),
                valueColor: const Color(0xFF4CAF50),
              ),
          ],
        ),
      ),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value, this.valueColor});

  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
          ),
          Text(
            value,
            style: tt.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}
