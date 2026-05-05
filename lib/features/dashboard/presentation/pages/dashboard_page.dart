import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/providers/shell_index_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../budgets/data/models/budget_model.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../../shared/widgets/transaction_card.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final budgets = ref.watch(budgetsProvider);
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    final netWorth = accounts.fold(0.0, (s, a) => s + a.balance);
    final monthIncome = transactions
        .where((t) => t.isIncome && !t.pending)
        .fold(0.0, (s, t) => s + t.amount);
    final monthExpenses = transactions
        .where((t) => t.isExpense && !t.pending)
        .fold(0.0, (s, t) => s + t.amount);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bar_chart_outlined),
            tooltip: 'Reports',
            onPressed: () => context.push('/reports'),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            onPressed: () => context.push('/settings'),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          try {
            await Future.wait([
              ref.read(transactionsProvider.notifier).sync(),
              ref.read(accountsProvider.notifier).sync(),
              ref.read(budgetsProvider.notifier).sync(),
            ]);
          } catch (_) {}
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // ── Net Worth Card ──────────────────────────────────
            Card(
              color: cs.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Net Worth',
                      style: tt.labelLarge?.copyWith(
                        color: cs.onPrimaryContainer.withAlpha(178),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      formatCurrency(netWorth),
                      style: tt.headlineMedium?.copyWith(
                        color: cs.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        _StatChip(
                          label: 'Income',
                          value: formatCurrency(monthIncome),
                          icon: Icons.arrow_upward_rounded,
                          positive: true,
                        ),
                        const SizedBox(width: 12),
                        _StatChip(
                          label: 'Expenses',
                          value: formatCurrency(monthExpenses),
                          icon: Icons.arrow_downward_rounded,
                          positive: false,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── Budget Snapshot ─────────────────────────────────
            _SectionHeader(
              title: 'Budgets',
              onSeeAll: () => ref.read(shellIndexProvider.notifier).state = 3,
            ),
            const SizedBox(height: 8),
            ...budgets.take(3).map((b) => _BudgetRow(budget: b)),
            const SizedBox(height: 20),

            // ── Recent Transactions ─────────────────────────────
            _SectionHeader(
              title: 'Recent Transactions',
              onSeeAll: () => ref.read(shellIndexProvider.notifier).state = 1,
            ),
            const SizedBox(height: 8),
            ...transactions
                .take(5)
                .map((t) => TransactionCard(transaction: t)),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.onSeeAll});
  final String title;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          TextButton(onPressed: onSeeAll, child: const Text('See all')),
        ],
      );
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.label,
    required this.value,
    required this.icon,
    required this.positive,
  });
  final String label;
  final String value;
  final IconData icon;
  final bool positive;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final color = positive
        ? const Color(0xFF4CAF50)
        : const Color(0xFFEF5350);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: cs.onPrimaryContainer.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: tt.labelSmall?.copyWith(
                  color: cs.onPrimaryContainer.withAlpha(178),
                ),
              ),
              Text(
                value,
                style: tt.bodySmall?.copyWith(
                  color: cs.onPrimaryContainer,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BudgetRow extends StatelessWidget {
  const _BudgetRow({required this.budget});
  final BudgetModel budget;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final barColor = budget.isOverBudget ? cs.error : budget.color;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(budget.icon, size: 15, color: barColor),
                    const SizedBox(width: 6),
                    Text(budget.category, style: tt.bodyMedium),
                  ],
                ),
                Text(
                  '\$${budget.spent.toStringAsFixed(0)} / \$${budget.allocated.toStringAsFixed(0)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: budget.progress,
              backgroundColor: cs.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation(barColor),
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      ),
    );
  }
}
