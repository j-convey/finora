import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/transaction_card.dart';
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
    final filtered = _query.isEmpty
        ? all
        : all
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

    final totalIncome =
        all.where((t) => t.isIncome && !t.pending).fold(0.0, (s, t) => s + t.amount);
    final totalExpenses =
        all.where((t) => t.isExpense && !t.pending).fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Transactions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/settings'),
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
      floatingActionButton: FloatingActionButton.extended(
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
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _AddTransactionSheet(),
    );
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

// ── Add Transaction Bottom Sheet ─────────────────────────────────────────────

class _AddTransactionSheet extends ConsumerStatefulWidget {
  const _AddTransactionSheet();

  @override
  ConsumerState<_AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<_AddTransactionSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String _category = 'Groceries';

  static const _categories = [
    'Groceries', 'Dining', 'Transport', 'Entertainment',
    'Utilities', 'Health', 'Shopping', 'Subscriptions',
    'Rent', 'Travel', 'Income',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text);
    if (_titleCtrl.text.isEmpty || amount == null) return;
    ref.read(transactionsProvider.notifier).addTransaction(
          TransactionModel(
            id: 'u${DateTime.now().millisecondsSinceEpoch}',
            title: _titleCtrl.text.trim(),
            amount: amount,
            type: _type,
            category: _category,
            date: DateTime.now(),
          ),
        );
    Navigator.pop(context); // ignore: use_build_context_synchronously
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Add Transaction',
                  style: Theme.of(context).textTheme.titleMedium),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Type toggle
          SegmentedButton<TransactionType>(
            segments: const [
              ButtonSegment(
                  value: TransactionType.expense, label: Text('Expense')),
              ButtonSegment(
                  value: TransactionType.income, label: Text('Income')),
              ButtonSegment(
                  value: TransactionType.transfer, label: Text('Transfer')),
            ],
            selected: {_type},
            onSelectionChanged: (s) => setState(() => _type = s.first),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _titleCtrl,
            decoration: const InputDecoration(
              labelText: 'Title',
              border: OutlineInputBorder(),
            ),
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountCtrl,
            decoration: const InputDecoration(
              labelText: 'Amount',
              prefixText: '\$',
              border: OutlineInputBorder(),
            ),
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
          ),
          const SizedBox(height: 12),
          InputDecorator(
            decoration: const InputDecoration(
              labelText: 'Category',
              border: OutlineInputBorder(),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: _category,
                isDense: true,
                items: _categories
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) => setState(() => _category = v!),
              ),
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: const Text('Save Transaction'),
          ),
        ],
      ),
    );
  }
}
