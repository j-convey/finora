import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/transaction_card.dart';
import '../../../../shared/widgets/transaction_details_sheet.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../domain/entities/report_summary.dart';
import '../providers/reports_provider.dart';

/// Draggable bottom sheet that lists every transaction belonging to
/// [category] within the currently selected report period.
///
/// Set [isExpense] to true for spending slices, false for income slices.
class CategoryTransactionsSheet extends ConsumerWidget {
  const CategoryTransactionsSheet({
    super.key,
    required this.category,
    required this.isExpense,
  });

  final ReportCategory category;
  final bool isExpense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final period = ref.watch(reportPeriodProvider);
    final start = period.start;
    final allTxns = ref.watch(transactionsProvider);
    final accountsById = {
      for (final a in ref.watch(accountsProvider)) a.id: a,
    };

    final txns = allTxns.where((t) {
      if (t.pending) return false;
      if (start != null && t.date.isBefore(start)) return false;
      if (isExpense ? !t.isExpense : !t.isIncome) return false;
      return t.category == category.name;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));

    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return DraggableScrollableSheet(
      initialChildSize: 0.6,
      minChildSize: 0.35,
      maxChildSize: 0.92,
      expand: false,
      builder: (_, controller) => Column(
        children: [
          // ── Drag handle ──────────────────────────────────────────────────
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.symmetric(vertical: 12),
            decoration: BoxDecoration(
              color: cs.onSurfaceVariant.withAlpha(80),
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // ── Header ───────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Row(
              children: [
                Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: category.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    category.name,
                    style: tt.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      formatCurrency(category.amount),
                      style: tt.titleSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${txns.length} transaction${txns.length == 1 ? '' : 's'}',
                      style: tt.labelSmall
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const Divider(height: 1),

          // ── Transaction list ──────────────────────────────────────────────
          Expanded(
            child: txns.isEmpty
                ? Center(
                    child: Text(
                      'No transactions found',
                      style: tt.bodyMedium
                          ?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  )
                : ListView.builder(
                    controller: controller,
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: txns.length,
                    itemBuilder: (context, i) {
                      final t = txns[i];
                      return TransactionCard(
                        transaction: t,
                        account: t.accountId != null
                            ? accountsById[t.accountId]
                            : null,
                        onTap: () =>
                            showTransactionDetails(context, ref, t),
                        onCategoryTap: () =>
                            showCategoryPicker(context, ref, t),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
