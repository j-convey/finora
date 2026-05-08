import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/transactions/data/models/transaction_model.dart';
import '../../features/transactions/presentation/providers/categories_provider.dart';
import '../../features/transactions/presentation/providers/transactions_provider.dart';

class AddTransactionSheet extends ConsumerStatefulWidget {
  const AddTransactionSheet({super.key});

  @override
  ConsumerState<AddTransactionSheet> createState() =>
      _AddTransactionSheetState();
}

class _AddTransactionSheetState extends ConsumerState<AddTransactionSheet> {
  final _titleCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  TransactionType _type = TransactionType.expense;
  String? _category;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final amount = double.tryParse(_amountCtrl.text);
    if (_titleCtrl.text.isEmpty || amount == null) return;
    final categories = ref.read(categoriesProvider);
    final selectedCategory = _category ?? (categories.isNotEmpty ? categories.first : 'Uncategorized');
    ref.read(transactionsProvider.notifier).addTransaction(
          TransactionModel(
            id: 'u${DateTime.now().millisecondsSinceEpoch}',
            title: _titleCtrl.text.trim(),
            amount: amount,
            type: _type,
            category: selectedCategory,
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
      child: SingleChildScrollView(
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
          Consumer(builder: (context, ref, _) {
            final categories = ref.watch(categoriesProvider);
            final selected = _category ?? (categories.isNotEmpty ? categories.first : null);
            return InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Category',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selected,
                  isDense: true,
                  items: categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => _category = v),
                ),
              ),
            );
          }),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _save,
            child: const Text('Save Transaction'),
          ),
        ],
        ),
      ),
    );
  }
}

void showAddTransactionSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    builder: (_) => const AddTransactionSheet(),
  );
}
