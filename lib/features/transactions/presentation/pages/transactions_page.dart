import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/utils/currency_formatter.dart';
import 'package:finora/shared/widgets/add_transaction_sheet.dart';
import 'package:finora/shared/widgets/main_drawer.dart';
import 'package:finora/shared/widgets/transaction_card.dart';
import 'package:finora/shared/widgets/transaction_details_sheet.dart';
import 'package:finora/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:finora/features/transactions/domain/entities/transaction.dart';
import 'package:finora/features/transactions/presentation/providers/categories_provider.dart';
import 'package:finora/features/transactions/presentation/providers/transaction_filters_provider.dart';
import 'package:finora/features/transactions/presentation/providers/transactions_provider.dart';

class TransactionsPage extends ConsumerStatefulWidget {
  const TransactionsPage({super.key});

  @override
  ConsumerState<TransactionsPage> createState() => _TransactionsPageState();
}

class _TransactionsPageState extends ConsumerState<TransactionsPage> {
  @override
  Widget build(BuildContext context) {
    final all = ref.watch(transactionsProvider);
    final filters = ref.watch(transactionFiltersProvider);
    final accounts = ref.watch(accountsProvider);
    final accountsById = {for (final a in accounts) a.id: a};
    final isMobile = Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;

    // 1. Filter
    var filtered = all.where((t) {
      // Split parents that need review are shown in the list; all other split
      // parents are hidden (their children appear as individual rows instead).
      if (t.isSplitParent && !t.requiresUserReview) return false;

      // Search
      if (filters.search.isNotEmpty) {
        final q = filters.search.toLowerCase();
        final match = t.title.toLowerCase().contains(q) ||
            t.category.toLowerCase().contains(q);
        if (!match) return false;
      }

      // Account
      if (filters.accountId != null && t.accountId != filters.accountId) {
        return false;
      }

      // Category
      if (filters.category != null && t.category != filters.category) {
        return false;
      }

      // Month
      if (filters.month != null && t.date.month != filters.month) {
        return false;
      }

      // Year
      if (filters.year != null && t.date.year != filters.year) {
        return false;
      }

      return true;
    }).toList();

    // 2. Sort
    switch (filters.sortBy) {
      case TransactionSort.latest:
        filtered.sort((a, b) => b.date.compareTo(a.date));
      case TransactionSort.oldest:
        filtered.sort((a, b) => a.date.compareTo(b.date));
      case TransactionSort.largest:
        filtered.sort((a, b) => b.amount.compareTo(a.amount));
      case TransactionSort.smallest:
        filtered.sort((a, b) => a.amount.compareTo(b.amount));
    }

    // 3. Grouping (only if sorted by date)
    final isSortedByDate = filters.sortBy == TransactionSort.latest ||
        filters.sortBy == TransactionSort.oldest;

    final grouped = <String, List<Transaction>>{};
    if (isSortedByDate) {
      for (final t in filtered) {
        final key = TransactionCard.relativeDate(t.date);
        grouped.putIfAbsent(key, () => []).add(t);
      }
    }

    // Budget totals exclude split parents (ghost rows) and transfers.
    // Only real leaf transactions and unsplit transactions are counted.
    final budgetable = all.where((t) => !t.isSplitParent && t.type != TransactionType.transfer);
    final totalIncome = budgetable
        .where((t) => t.isIncome && !t.pending)
        .fold(0.0, (s, t) => s + t.amount);
    final totalExpenses = budgetable
        .where((t) => t.isExpense && !t.pending)
        .fold(0.0, (s, t) => s + t.amount);

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
            icon: Icon(
              filters.hasFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
              color: filters.hasFilters ? Theme.of(context).colorScheme.primary : null,
            ),
            tooltip: 'Filter & Sort',
            onPressed: () => _showFilterSheet(context),
          ),
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
              onChanged: (v) => ref
                  .read(transactionFiltersProvider.notifier)
                  .update((s) => s.copyWith(search: v)),
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
      body: filtered.isEmpty
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

                if (isSortedByDate)
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
                        account: t.accountId != null
                            ? accountsById[t.accountId]
                            : null,
                        onTap: () => showTransactionDetails(context, ref, t),
                        onCategoryTap: () =>
                            showCategoryPicker(context, ref, t),
                        onDismissed: () => ref
                            .read(transactionsProvider.notifier)
                            .removeTransaction(t.id),
                      ),
                    ),
                  ]
                else
                  // Flat list for non-date sorting
                  ...filtered.map(
                    (t) => TransactionCard(
                      transaction: t,
                      account:
                          t.accountId != null ? accountsById[t.accountId] : null,
                      onTap: () => showTransactionDetails(context, ref, t),
                      onCategoryTap: () => showCategoryPicker(context, ref, t),
                      onDismissed: () => ref
                          .read(transactionsProvider.notifier)
                          .removeTransaction(t.id),
                    ),
                  ),
              ],
            ),
    );
  }

  void _showAddSheet(BuildContext context) {
    showAddTransactionSheet(context);
  }

  void _showFilterSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => const _FilterSheet(),
    );
  }
}

class _FilterSheet extends ConsumerWidget {
  const _FilterSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filters = ref.watch(transactionFiltersProvider);
    final accounts = ref.watch(accountsProvider);
    final categories = ref.watch(categoriesProvider);
    final tt = Theme.of(context).textTheme;

    final currentYear = DateTime.now().year;
    final years = List.generate(5, (i) => currentYear - i);
    final months = [
      'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December'
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.9,
      expand: false,
      builder: (context, scrollController) => ListView(
        controller: scrollController,
        padding: const EdgeInsets.all(24),
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Filter & Sort', style: tt.headlineSmall),
              TextButton(
                onPressed: () {
                  ref.read(transactionFiltersProvider.notifier).state =
                      const TransactionFilters();
                },
                child: const Text('Reset'),
              ),
            ],
          ),
          const SizedBox(height: 24),

          // Sort By
          Text('Sort By', style: tt.titleSmall),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: TransactionSort.values.map((s) {
              final selected = filters.sortBy == s;
              return ChoiceChip(
                label: Text(s.label),
                selected: selected,
                onSelected: (v) => ref
                    .read(transactionFiltersProvider.notifier)
                    .update((state) => state.copyWith(sortBy: s)),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),

          // Account
          Text('Account', style: tt.titleSmall),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: filters.accountId,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Accounts', overflow: TextOverflow.ellipsis),
              ),
              ...accounts.map((a) => DropdownMenuItem(
                    value: a.id,
                    child: Text(a.name, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (v) => ref
                .read(transactionFiltersProvider.notifier)
                .update((s) => s.copyWith(accountId: v, clearAccountId: v == null)),
          ),
          const SizedBox(height: 24),

          // Category
          Text('Category', style: tt.titleSmall),
          const SizedBox(height: 12),
          DropdownButtonFormField<String?>(
            value: filters.category,
            isExpanded: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 12),
            ),
            items: [
              const DropdownMenuItem(
                value: null,
                child: Text('All Categories', overflow: TextOverflow.ellipsis),
              ),
              ...categories.map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c, overflow: TextOverflow.ellipsis),
                  )),
            ],
            onChanged: (v) => ref
                .read(transactionFiltersProvider.notifier)
                .update((s) => s.copyWith(category: v, clearCategory: v == null)),
          ),
          const SizedBox(height: 24),

          // Month & Year
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Month', style: tt.titleSmall),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: filters.month,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All', overflow: TextOverflow.ellipsis),
                        ),
                        ...List.generate(12, (i) => i + 1).map((m) =>
                            DropdownMenuItem(
                                value: m,
                                child: Text(months[m - 1],
                                    overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => ref
                          .read(transactionFiltersProvider.notifier)
                          .update((s) =>
                              s.copyWith(month: v, clearMonth: v == null)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Year', style: tt.titleSmall),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<int?>(
                      value: filters.year,
                      isExpanded: true,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(horizontal: 12),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: null,
                          child: Text('All', overflow: TextOverflow.ellipsis),
                        ),
                        ...years.map((y) => DropdownMenuItem(
                            value: y,
                            child: Text(y.toString(),
                                overflow: TextOverflow.ellipsis))),
                      ],
                      onChanged: (v) => ref
                          .read(transactionFiltersProvider.notifier)
                          .update((s) =>
                              s.copyWith(year: v, clearYear: v == null)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 40),
          FilledButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Apply Filters'),
          ),
          const SizedBox(height: 8),
        ],
      ),
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

