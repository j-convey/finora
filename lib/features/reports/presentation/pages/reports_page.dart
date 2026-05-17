import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/providers/hide_amounts_provider.dart';
import 'package:finora/core/utils/currency_formatter.dart';
import 'package:finora/shared/widgets/transaction_card.dart';
import 'package:finora/shared/widgets/transaction_details_sheet.dart';
import 'package:finora/features/accounts/presentation/providers/accounts_provider.dart';
import 'package:finora/features/transactions/domain/entities/transaction.dart';
import 'package:finora/features/reports/domain/entities/report_period.dart';
import 'package:finora/features/reports/domain/entities/report_summary.dart';
import 'package:finora/features/reports/presentation/providers/reports_provider.dart';
import 'package:finora/features/reports/presentation/widgets/cash_flow_chart.dart';
import 'package:finora/features/reports/presentation/widgets/category_legend_tile.dart';
import 'package:finora/features/reports/presentation/widgets/category_transactions_sheet.dart';
import 'package:finora/features/reports/presentation/widgets/donut_chart.dart';
import 'package:finora/features/reports/presentation/widgets/report_summary_card.dart';
import 'package:finora/shared/widgets/add_transaction_sheet.dart';
import 'package:finora/shared/widgets/main_drawer.dart';

class ReportsPage extends ConsumerStatefulWidget {
  const ReportsPage({super.key});

  @override
  ConsumerState<ReportsPage> createState() => _ReportsPageState();
}

// ── Page shell ────────────────────────────────────────────────────────────────

class _ReportsPageState extends ConsumerState<ReportsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final period = ref.watch(reportPeriodProvider);
    final summary = ref.watch(reportSummaryProvider);
    final isMobilePlatform =
        Theme.of(context).platform == TargetPlatform.android ||
            Theme.of(context).platform == TargetPlatform.iOS;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cash Flow'),
        leading: isMobilePlatform
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          _PeriodPickerButton(current: period),
          Consumer(
            builder: (context, ref, _) {
              final hidden = ref.watch(hideAmountsProvider);
              return IconButton(
                icon: Icon(hidden
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined),
                tooltip: hidden ? 'Show amounts' : 'Hide amounts',
                onPressed: () =>
                    ref.read(hideAmountsProvider.notifier).state = !hidden,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => showAddTransactionSheet(context),
          ),
          const SizedBox(width: 8),
        ],
        bottom: TabBar(
          controller: _tabs,
          tabs: const [
            Tab(text: 'Cash Flow'),
            Tab(text: 'Spending'),
            Tab(text: 'Income'),
          ],
        ),
      ),
      drawer: isMobilePlatform ? const MainDrawer() : null,
      body: TabBarView(
        controller: _tabs,
        children: [
          _CashFlowTab(summary: summary),
          _CategoryTab(
            categories: summary.spendingByCategory,
            total: summary.totalExpenses,
            summary: summary,
            centerLabel: 'Expenses',
            recentTransactions: summary.recentExpenses,
            tab: 1,
          ),
          _CategoryTab(
            categories: summary.incomeByCategory,
            total: summary.totalIncome,
            summary: summary,
            centerLabel: 'Income',
            recentTransactions: summary.recentIncome,
            tab: 2,
          ),
        ],
      ),
    );
  }
}

// ── Period picker ─────────────────────────────────────────────────────────────

class _PeriodPickerButton extends ConsumerWidget {
  const _PeriodPickerButton({required this.current});

  final ReportPeriod current;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<ReportPeriod>(
      initialValue: current,
      onSelected: (p) => ref.read(reportPeriodProvider.notifier).state = p,
      itemBuilder: (_) => ReportPeriod.values
          .map((p) => PopupMenuItem(value: p, child: Text(p.label)))
          .toList(),
      child: Chip(
        avatar: const Icon(Icons.calendar_today_outlined, size: 14),
        label: Text(current.label, style: const TextStyle(fontSize: 12)),
        visualDensity: VisualDensity.compact,
        padding: EdgeInsets.zero,
      ),
    );
  }
}

// ── Cash Flow tab ─────────────────────────────────────────────────────────────

class _CashFlowTab extends ConsumerWidget {
  const _CashFlowTab({required this.summary});

  final ReportSummary summary;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hidden = ref.watch(hideAmountsProvider);
    final isPositive = summary.netCashFlow >= 0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Net cash flow header card ──────────────────────────
        Card(
          color: isPositive
              ? const Color(0xFF4CAF50).withAlpha(20)
              : const Color(0xFFEF5350).withAlpha(20),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Net Cash Flow',
                        style: tt.labelMedium
                            ?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        hidden
                            ? '••••••'
                            : '${isPositive ? '+' : ''}${formatCurrency(summary.netCashFlow)}',
                        style: tt.headlineSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isPositive
                              ? const Color(0xFF4CAF50)
                              : const Color(0xFFEF5350),
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _InlineStat(
                      label: 'Income',
                      value: hidden
                          ? '••••••'
                          : '+${formatCurrency(summary.totalIncome)}',
                      color: const Color(0xFF4CAF50),
                    ),
                    const SizedBox(height: 4),
                    _InlineStat(
                      label: 'Expenses',
                      value: hidden
                          ? '••••••'
                          : formatCurrency(summary.totalExpenses),
                      color: const Color(0xFFEF5350),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // ── Monthly bar chart ──────────────────────────────────
        if (summary.monthlyFlow.isNotEmpty) ...[
          const SizedBox(height: 20),
          Row(
            children: [
              Text('Monthly breakdown', style: tt.titleSmall),
              const Spacer(),
              _LegendDot(color: const Color(0xFF4CAF50), label: 'Income'),
              const SizedBox(width: 12),
              _LegendDot(color: const Color(0xFFEF5350), label: 'Expenses'),
            ],
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 12, 8),
              child: CashFlowChart(months: summary.monthlyFlow),
            ),
          ),
        ],

        const SizedBox(height: 16),
        ReportSummaryCard(summary: summary, tab: 0),
      ],
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label,
            style: tt.labelSmall?.copyWith(color: color.withAlpha(180))),
        const SizedBox(width: 4),
        Text(value,
            style: tt.labelSmall
                ?.copyWith(color: color, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: tt.labelSmall),
      ],
    );
  }
}

// ── Spending / Income tab ─────────────────────────────────────────────────────

class _CategoryTab extends ConsumerStatefulWidget {
  const _CategoryTab({
    required this.categories,
    required this.total,
    required this.summary,
    required this.centerLabel,
    required this.recentTransactions,
    required this.tab,
  });

  final List<ReportCategory> categories;
  final double total;
  final ReportSummary summary;
  final String centerLabel;
  final List<Transaction> recentTransactions;

  /// 1 = Spending, 2 = Income.
  final int tab;

  @override
  ConsumerState<_CategoryTab> createState() => _CategoryTabState();
}

class _CategoryTabState extends ConsumerState<_CategoryTab> {
  bool _showAllCategories = false;

  void _showCategorySheet(BuildContext context, ReportCategory category) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => CategoryTransactionsSheet(
        category: category,
        isExpense: widget.tab == 1,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final accountsById = {for (final a in ref.watch(accountsProvider)) a.id: a};

    final displayedCats = _showAllCategories
        ? widget.categories
        : widget.categories.take(8).toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Donut chart ────────────────────────────────────────
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: DonutChart(
              categories: widget.categories,
              total: widget.total,
              centerLabel: widget.centerLabel,
              onSliceTapped: (cat) => _showCategorySheet(context, cat),
            ),
          ),
        ),

        // ── Category breakdown list ────────────────────────────
        if (widget.categories.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text('By category', style: tt.titleSmall),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  ...displayedCats.map((c) => CategoryLegendTile(category: c)),
                  if (widget.categories.length > 8) ...[
                    const Divider(height: 8),
                    TextButton(
                      onPressed: () => setState(
                          () => _showAllCategories = !_showAllCategories),
                      child: Text(
                        _showAllCategories
                            ? 'Show less'
                            : 'Show all ${widget.categories.length} categories',
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],

        // ── Summary card ───────────────────────────────────────
        const SizedBox(height: 16),
        ReportSummaryCard(summary: widget.summary, tab: widget.tab),

        // ── Recent transactions ────────────────────────────────
        if (widget.recentTransactions.isNotEmpty) ...[
          const SizedBox(height: 16),
          Text(
            widget.tab == 1 ? 'Recent Expenses' : 'Recent Income',
            style: tt.titleSmall,
          ),
          const SizedBox(height: 8),
          ...widget.recentTransactions.map((t) => TransactionCard(
                transaction: t,
                account: t.accountId != null ? accountsById[t.accountId] : null,
                onTap: () => showTransactionDetails(context, ref, t),
                onCategoryTap: () => showCategoryPicker(context, ref, t),
              )),
        ],
      ],
    );
  }
}
