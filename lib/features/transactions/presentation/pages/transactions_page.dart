import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/add_transaction_sheet.dart';
import '../../../../shared/widgets/main_drawer.dart';
import '../../../../shared/widgets/transaction_card.dart';
import '../../../../shared/widgets/transaction_details_sheet.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../transactions/data/models/transaction_model.dart';
import '../providers/transactions_provider.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionsProvider);
    final accountsById = {for (final a in ref.watch(accountsProvider)) a.id: a};
    final isMobile = Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;

    // Split parents that need review are shown in the list; all other split
    // parents are hidden (their children appear as individual rows instead).
    final visible = all
        .where((t) => !t.isSplitParent || t.requiresUserReview)
        .toList();

    final filtered = _query.isEmpty
        ? visible
        : visible
            .where((t) =>
                t.title.toLowerCase().contains(_query.toLowerCase()) ||
                t.category.toLowerCase().contains(_query.toLowerCase()))
            .toList();

    // Group by relative date label
    final grouped = <String, List<TransactionModel>>{};
    for (final t in filtered) {
      final key = TransactionCard.relativeDate(t.date);
      grouped.putIfAbsent(key, () => []).add(t);
    }

    // Budget totals exclude split parents (ghost rows) — only real leaf
    // transactions and unsplit transactions are counted.
    final budgetable = all.where((t) => !t.isSplitParent);
    final totalIncome =
        budgetable.where((t) => t.isIncome && !t.pending).fold(0.0, (s, t) => s + t.amount);
    final totalExpenses =
        budgetable.where((t) => t.isExpense && !t.pending).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddTransactionSheet(context),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(56),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: SearchBar(
              hintText: 'Search transactions…',
              leading: const Icon(Icons.search),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        ),
      ),
      drawer: isMobile ? const MainDrawer() : null,
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'fab_transactions',
        onPressed: () => _showAddSheet(context),
        icon: const Icon(Icons.add),
        label: const Text('Add'),
      ),
      body: grouped.isEmpty
          ? const Center(child: Text('No transactions found'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
              children: [
                // Summary row
                Row(
                  children: [
                    Expanded(
                      child: _SummaryTile(
                        label: 'Income',
                        value: formatCurrency(totalIncome),
                        color: const Color(0xFF4CAF50),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _SummaryTile(
                        label: 'Expenses',
                        value: formatCurrency(totalExpenses),
                        color: const Color(0xFFEF5350),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Grouped list
                for (final entry in grouped.entries) ...[
                  Padding(
                    padding: const EdgeInsets.only(bottom: 4, top: 8),
                    child: Text(
                      entry.key,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                            color: Theme.of(context)
                                .colorScheme
                                .onSurfaceVariant,
                          ),
                    ),
                  ),
                  ...entry.value.map(
                    (t) => TransactionCard(
                      transaction: t,
                      account: t.accountId != null ? accountsById[t.accountId] : null,
                      onTap: () => showTransactionDetails(context, ref, t),
                      onCategoryTap: () => showCategoryPicker(context, ref, t),
                      onDismissed: () => ref
                          .read(transactionsProvider.notifier)
                          .removeTransaction(t.id),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showAddTransactionSheet(context);
  }
}

class _SummaryTile extends StatelessWidget {
  const _SummaryTile(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: tt.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
            const SizedBox(height: 2),
            Text(value,
                style:
                    tt.titleSmall?.copyWith(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }
}

