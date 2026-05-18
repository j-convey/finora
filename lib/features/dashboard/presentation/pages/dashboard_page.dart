import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers/shell_index_provider.dart';
import '../../../../core/providers/hide_amounts_provider.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../../../../shared/widgets/masked_amount.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/presentation/providers/accounts_provider.dart';
import '../../../budgets/presentation/providers/budgets_provider.dart';
import '../../../subscriptions/presentation/providers/subscriptions_provider.dart';
import '../../../transactions/domain/entities/transaction.dart';
import '../../../transactions/presentation/extensions/transaction_ui_extension.dart';
import '../../../transactions/presentation/providers/categories_provider.dart';
import '../../../transactions/presentation/providers/transactions_provider.dart';
import '../../../../shared/widgets/responsive_layout.dart';
import '../../../../shared/widgets/transaction_details_sheet.dart';
import '../../../../shared/widgets/add_transaction_sheet.dart';
import '../../../../shared/widgets/main_drawer.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(transactionsProvider.notifier).sync();
      ref.read(accountsProvider.notifier).sync();
      ref.read(budgetsProvider.notifier).sync();
      ref.read(subscriptionsProvider.notifier).sync();
      ref.read(categoryGroupsProvider.notifier).sync();
    });
  }

  @override
  Widget build(BuildContext context) {
    final accounts = ref.watch(accountsProvider);
    final transactions = ref.watch(transactionsProvider);
    final isMobile =
        Theme.of(context).platform == TargetPlatform.android ||
        Theme.of(context).platform == TargetPlatform.iOS;

    final netWorth = accounts.fold(0.0, (s, a) => s + a.balance);

    // Spending sparkline — daily cumulative expense totals this month
    final now = DateTime.now();

    // Filter all summaries to the current month so header totals and chart
    // Y-axis always show the same data set.
    final monthIncome = transactions
        .where(
          (t) =>
              t.isIncome &&
              !t.pending &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (s, t) => s + t.amount);
    final monthExpenses = transactions
        .where(
          (t) =>
              t.isExpense &&
              !t.pending &&
              t.date.year == now.year &&
              t.date.month == now.month,
        )
        .fold(0.0, (s, t) => s + t.amount);

    final budgetCard = _BudgetCard(
      income: monthIncome,
      expenses: monthExpenses,
      onSeeAll: () => ref.read(shellIndexProvider.notifier).state = 4,
    );

    final spendingCard = const _SpendingCard();

    final netWorthCard = _NetWorthCard(netWorth: netWorth);

    final accountsById = {for (final a in accounts) a.id: a};
    final transactionsCard = _RecentTransactionsCard(
      transactions: transactions.take(5).toList(),
      accountsById: accountsById,
      onSeeAll: () => ref.read(shellIndexProvider.notifier).state = 2,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dashboard'),
        leading: isMobile
            ? Builder(
                builder: (context) => IconButton(
                  icon: const Icon(Icons.menu),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              )
            : null,
        actions: [
          Consumer(
            builder: (context, ref, _) {
              final hidden = ref.watch(hideAmountsProvider);
              return IconButton(
                icon: Icon(
                  hidden
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                ),
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
        ],
      ),
      drawer: isMobile ? const MainDrawer() : null,
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ResponsiveLayout(
            mobileBreakpoint: 720,
            mobile: _NarrowLayout(
              budgetCard: budgetCard,
              spendingCard: spendingCard,
              netWorthCard: netWorthCard,
              transactionsCard: transactionsCard,
            ),
            desktop: _WideLayout(
              budgetCard: budgetCard,
              spendingCard: spendingCard,
              netWorthCard: netWorthCard,
              transactionsCard: transactionsCard,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Layout variants ──────────────────────────────────────────────────────────

class _WideLayout extends StatelessWidget {
  const _WideLayout({
    required this.budgetCard,
    required this.spendingCard,
    required this.netWorthCard,
    required this.transactionsCard,
  });

  final Widget budgetCard;
  final Widget spendingCard;
  final Widget netWorthCard;
  final Widget transactionsCard;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            children: [budgetCard, const SizedBox(height: 16), netWorthCard],
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            children: [
              spendingCard,
              const SizedBox(height: 16),
              transactionsCard,
            ],
          ),
        ),
      ],
    );
  }
}

class _NarrowLayout extends StatelessWidget {
  const _NarrowLayout({
    required this.budgetCard,
    required this.spendingCard,
    required this.netWorthCard,
    required this.transactionsCard,
  });

  final Widget budgetCard;
  final Widget spendingCard;
  final Widget netWorthCard;
  final Widget transactionsCard;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        budgetCard,
        const SizedBox(height: 16),
        spendingCard,
        const SizedBox(height: 16),
        netWorthCard,
        const SizedBox(height: 16),
        transactionsCard,
      ],
    );
  }
}

// ── Budget card ──────────────────────────────────────────────────────────────

class _BudgetCard extends StatelessWidget {
  const _BudgetCard({
    required this.income,
    required this.expenses,
    required this.onSeeAll,
  });

  final double income;
  final double expenses;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final now = DateTime.now();
    final monthLabel = '${_monthName(now.month)} ${now.year}';

    // Use income as the budget ceiling for the progress bars
    final incomeBudget = income > 0 ? income : 1.0;
    final expenseBudget = income > 0 ? income : 1.0;
    final incomeProgress = (income / incomeBudget).clamp(0.0, 1.0);
    final expenseProgress = (expenses / expenseBudget).clamp(0.0, 1.0);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Budget',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      monthLabel,
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                TextButton(onPressed: onSeeAll, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 20),
            _BudgetRow(
              label: 'Income',
              amount: income,
              budget: incomeBudget,
              progress: incomeProgress,
              positive: true,
            ),
            const SizedBox(height: 16),
            _BudgetRow(
              label: 'Expenses',
              amount: expenses,
              budget: expenseBudget,
              progress: expenseProgress,
              positive: false,
            ),
          ],
        ),
      ),
    );
  }

  static String _monthName(int month) => const [
    '',
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month];
}

class _BudgetRow extends ConsumerWidget {
  const _BudgetRow({
    required this.label,
    required this.amount,
    required this.budget,
    required this.progress,
    required this.positive,
  });

  final String label;
  final double amount;
  final double budget;
  final double progress;
  final bool positive;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hidden = ref.watch(hideAmountsProvider);
    final remaining = budget - amount;
    final barColor = positive ? const Color(0xFF4CAF50) : cs.primary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: tt.bodyMedium),
            Text(
              hidden ? '•••••• budget' : '${formatCurrency(budget)} budget',
              style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 8,
            backgroundColor: cs.surfaceContainerHighest,
            valueColor: AlwaysStoppedAnimation<Color>(barColor),
          ),
        ),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Flexible(
              child: Text(
                hidden
                    ? '•••••• ${positive ? 'earned' : 'spent'}'
                    : '${formatCurrency(amount)} ${positive ? 'earned' : 'spent'}',
                style: tt.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                hidden
                    ? '•••••• remaining'
                    : '${formatCurrency(remaining)} remaining',
                style: tt.bodySmall?.copyWith(color: const Color(0xFF4CAF50)),
                textAlign: TextAlign.end,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Spending card ─────────────────────────────────────────────────────────────

enum _SpendingPeriod { thisMonth, quarter, year }

class _SpendingCard extends ConsumerStatefulWidget {
  const _SpendingCard();

  @override
  ConsumerState<_SpendingCard> createState() => _SpendingCardState();
}

class _SpendingCardState extends ConsumerState<_SpendingCard> {
  _SpendingPeriod _period = _SpendingPeriod.thisMonth;

  static const _periodLabels = {
    _SpendingPeriod.thisMonth: 'This month',
    _SpendingPeriod.quarter: 'This quarter',
    _SpendingPeriod.year: 'This year',
  };

  static const _monthAbbr = [
    '',
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];

  // ── Data builders ────────────────────────────────────────────────────────

  /// Returns (chartData, totalSpend, xLabelBuilder) for the current period.
  (List<double>, double, String? Function(int)) _buildChartData(List txns) {
    final now = DateTime.now();

    switch (_period) {
      case _SpendingPeriod.thisMonth:
        final daysInMonth = DateUtils.getDaysInMonth(now.year, now.month);
        final daily = List<double>.filled(daysInMonth, 0);
        for (final t in txns) {
          if (t.isExpense &&
              !t.pending &&
              t.date.year == now.year &&
              t.date.month == now.month) {
            daily[t.date.day - 1] += t.amount;
          }
        }
        // Cumulative
        double running = 0;
        final cumulative = <double>[];
        for (final d in daily) {
          running += d;
          cumulative.add(running);
        }
        // Trim trailing zeros past today
        final today = now.day;
        final trimmed = cumulative.sublist(
          0,
          today.clamp(1, cumulative.length),
        );

        String? labelBuilder(int i) {
          final day = i + 1;
          if (day == 1 || day % 7 == 0 || day == today) {
            return '${_monthAbbr[now.month]} $day';
          }
          return null;
        }

        return (trimmed, running, labelBuilder);

      case _SpendingPeriod.quarter:
        // Last 3 calendar months including current
        final months = List.generate(3, (i) {
          final offset = 2 - i;
          var m = now.month - offset;
          var y = now.year;
          while (m <= 0) {
            m += 12;
            y -= 1;
          }
          return (y, m);
        });

        final totals = <double>[];
        double total = 0;
        for (final (y, m) in months) {
          double sum = 0;
          for (final t in txns) {
            if (t.isExpense &&
                !t.pending &&
                t.date.year == y &&
                t.date.month == m) {
              sum += t.amount;
            }
          }
          totals.add(sum);
          total += sum;
        }

        String? labelBuilder(int i) => _monthAbbr[months[i].$2];
        return (totals, total, labelBuilder);

      case _SpendingPeriod.year:
        // Jan through current month this year
        final totals = <double>[];
        double total = 0;
        for (int m = 1; m <= now.month; m++) {
          double sum = 0;
          for (final t in txns) {
            if (t.isExpense &&
                !t.pending &&
                t.date.year == now.year &&
                t.date.month == m) {
              sum += t.amount;
            }
          }
          totals.add(sum);
          total += sum;
        }
        String? labelBuilder(int i) => _monthAbbr[i + 1];
        return (totals, total, labelBuilder);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final transactions = ref.watch(transactionsProvider);

    final (chartData, totalSpend, labelBuilder) = _buildChartData(transactions);

    final subtitleSuffix = _periodLabels[_period]!.toLowerCase();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Consumer(
                    builder: (context, ref, _) {
                      final hidden = ref.watch(hideAmountsProvider);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Spending',
                            style: tt.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            hidden
                                ? '•••••• $subtitleSuffix'
                                : '${formatCurrency(totalSpend)} $subtitleSuffix',
                            style: tt.bodySmall?.copyWith(
                              color: cs.onSurfaceVariant,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                PopupMenuButton<_SpendingPeriod>(
                  initialValue: _period,
                  onSelected: (p) => setState(() => _period = p),
                  itemBuilder: (_) => _SpendingPeriod.values
                      .map(
                        (p) => PopupMenuItem(
                          value: p,
                          child: Text(_periodLabels[p]!),
                        ),
                      )
                      .toList(),
                  child: Chip(
                    label: Text(
                      _periodLabels[_period]!,
                      style: const TextStyle(fontSize: 12),
                    ),
                    visualDensity: VisualDensity.compact,
                    padding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: chartData.isEmpty || chartData.every((v) => v == 0)
                  ? Center(
                      child: Text(
                        'No spending data',
                        style: tt.bodySmall?.copyWith(
                          color: cs.onSurfaceVariant,
                        ),
                      ),
                    )
                  : _LineChart(
                      data: chartData,
                      lineColor: cs.primary,
                      fillColor: cs.primary.withAlpha(40),
                      labelColor: cs.onSurfaceVariant,
                      xLabelBuilder: labelBuilder,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Full line chart with axes ─────────────────────────────────────────────────

class _LineChart extends StatelessWidget {
  const _LineChart({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.labelColor,
    this.xLabelBuilder,
  });

  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final Color labelColor;

  /// Return a string label for data index [i], or null to skip.
  final String? Function(int i)? xLabelBuilder;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        data: data,
        lineColor: lineColor,
        fillColor: fillColor,
        labelColor: labelColor,
        xLabelBuilder: xLabelBuilder,
      ),
      size: Size.infinite,
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({
    required this.data,
    required this.lineColor,
    required this.fillColor,
    required this.labelColor,
    this.xLabelBuilder,
  });

  final List<double> data;
  final Color lineColor;
  final Color fillColor;
  final Color labelColor;
  final String? Function(int i)? xLabelBuilder;

  static const _yPadLeft = 56.0; // room for Y-axis labels
  static const _xPadBottom = 20.0; // room for X-axis labels
  static const _yGridLines = 4;

  String _formatAxisValue(double v) {
    if (v >= 1000000) return '\$${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return '\$${(v / 1000).toStringAsFixed(1)}K';
    return '\$${v.toStringAsFixed(0)}';
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;
    final maxVal = data.fold<double>(
      data.first,
      (prev, v) => v > prev ? v : prev,
    );
    if (maxVal == 0) return;

    final chartLeft = _yPadLeft;
    final chartBottom = size.height - _xPadBottom;
    final chartWidth = size.width - chartLeft;
    final chartHeight = chartBottom;

    final labelStyle = TextStyle(
      color: labelColor,
      fontSize: 10,
      fontFamily: 'sans-serif',
    );

    final gridPaint = Paint()
      ..color = labelColor.withAlpha(30)
      ..strokeWidth = 1;

    // ── Y-axis grid lines and labels ────────────────────────────
    for (int i = 0; i <= _yGridLines; i++) {
      final fraction = i / _yGridLines;
      final y = chartBottom - fraction * chartHeight;
      final value = fraction * maxVal;

      // Grid line
      canvas.drawLine(Offset(chartLeft, y), Offset(size.width, y), gridPaint);

      // Y label (right-aligned before chart area)
      final label = _formatAxisValue(value);
      final tp = _buildTextPainter(label, labelStyle);
      tp.layout(maxWidth: chartLeft - 4);
      tp.paint(canvas, Offset(chartLeft - tp.width - 4, y - tp.height / 2));
    }

    // ── Plot line and fill ───────────────────────────────────────
    final xStep = chartWidth / (data.length - 1).clamp(1, double.infinity);

    Path linePath = Path();
    Path fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = chartLeft + i * xStep;
      final y = chartBottom - (data[i] / maxVal) * chartHeight;
      if (i == 0) {
        linePath.moveTo(x, y);
        fillPath.moveTo(x, chartBottom);
        fillPath.lineTo(x, y);
      } else {
        linePath.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo(chartLeft + (data.length - 1) * xStep, chartBottom);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      linePath,
      Paint()
        ..color = lineColor
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    // ── X-axis labels ────────────────────────────────────────────
    if (xLabelBuilder != null) {
      for (int i = 0; i < data.length; i++) {
        final label = xLabelBuilder!(i);
        if (label == null) continue;
        final x = chartLeft + i * xStep;
        final tp = _buildTextPainter(label, labelStyle);
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, chartBottom + 4));
      }
    }
  }

  TextPainter _buildTextPainter(String text, TextStyle style) {
    return TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
    );
  }

  @override
  bool shouldRepaint(_LineChartPainter old) =>
      old.data != data || old.lineColor != lineColor;
}

// ── Net Worth card ────────────────────────────────────────────────────────────

class _NetWorthCard extends ConsumerWidget {
  const _NetWorthCard({required this.netWorth});

  final double netWorth;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final hidden = ref.watch(hideAmountsProvider);
    const gain = 23331.71;
    const gainPct = 3.5;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MaskedAmount(
                      netWorth,
                      style: tt.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          size: 14,
                          color: Color(0xFF4CAF50),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          hidden
                              ? '•••••• (••••%)'
                              : '${formatCurrency(gain)} ($gainPct%)',
                          style: tt.bodySmall?.copyWith(
                            color: const Color(0xFF4CAF50),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Text(
                  'Net Worth',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              height: 160,
              child: _LineChart(
                data: _mockNetWorthPoints(netWorth),
                lineColor: const Color(0xFF26C6DA),
                fillColor: const Color(0xFF26C6DA).withAlpha(40),
                labelColor: cs.onSurfaceVariant,
                xLabelBuilder: (i) {
                  // Label roughly every 7 points (1 month = 30 points)
                  return (i % 7 == 0) ? 'Day ${i + 1}' : null;
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Generates a smooth upward curve from ~95% of netWorth to netWorth.
  static List<double> _mockNetWorthPoints(double netWorth) {
    const points = 30;
    final start = netWorth * 0.95;
    return List.generate(points, (i) {
      final t = i / (points - 1);
      // slight S-curve
      final eased = t < 0.5 ? 2 * t * t : 1 - (-2 * t + 2) * (-2 * t + 2) / 2;
      return start + (netWorth - start) * eased;
    });
  }
}

// ── Recent Transactions card ──────────────────────────────────────────────────

class _RecentTransactionsCard extends StatelessWidget {
  const _RecentTransactionsCard({
    required this.transactions,
    required this.accountsById,
    required this.onSeeAll,
  });

  final List<Transaction> transactions;
  final Map<String, Account> accountsById;
  final VoidCallback onSeeAll;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Transactions',
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Most recent',
                      style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
                TextButton(onPressed: onSeeAll, child: const Text('See all')),
              ],
            ),
            const SizedBox(height: 12),
            if (transactions.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Center(
                  child: Text(
                    'No transactions',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                ),
              )
            else
              ...transactions.map(
                (t) => _TransactionRow(
                  transaction: t,
                  account: t.accountId != null
                      ? accountsById[t.accountId]
                      : null,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TransactionRow extends ConsumerWidget {
  const _TransactionRow({required this.transaction, this.account});

  final Transaction transaction;
  final Account? account;

  static String _accountLabel(Account a) {
    final institution = a.institutionName?.isNotEmpty == true
        ? a.institutionName!
        : null;
    final parts = [if (institution != null) institution, a.name];
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final isIncome = transaction.isIncome;
    final amountColor = transaction.pending
        ? cs.onSurfaceVariant
        : isIncome
        ? const Color(0xFF4CAF50)
        : cs.onSurface;
    final prefix = isIncome ? '+' : '-';

    return InkWell(
      onTap: () => showTransactionDetails(context, ref, transaction),
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: cs.surfaceContainerHighest,
              child: Icon(
                transaction.icon,
                size: 18,
                color: cs.onSurfaceVariant,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.merchantName ?? transaction.title,
                    style: tt.bodyMedium,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    transaction.category,
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                  if (account != null)
                    Text(
                      _accountLabel(account!),
                      style: tt.labelSmall?.copyWith(
                        color: cs.onSurfaceVariant.withAlpha(178),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            Text(
              '$prefix${formatCurrency(transaction.amount)}',
              style: tt.bodyMedium?.copyWith(
                color: amountColor,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right, size: 16, color: cs.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}
