import 'package:flutter/material.dart';

import 'package:finora/features/transactions/domain/entities/transaction.dart';
import 'package:finora/features/reports/domain/entities/report_period.dart';
import 'package:finora/features/reports/domain/entities/report_summary.dart';

// ── Colour palette ────────────────────────────────────────────────────────────

const _palette = <Color>[
  Color(0xFF5C6BC0),
  Color(0xFF66BB6A),
  Color(0xFFFFCA28),
  Color(0xFFEF5350),
  Color(0xFFEC407A),
  Color(0xFFAB47BC),
  Color(0xFF42A5F5),
  Color(0xFF26A69A),
  Color(0xFFFF7043),
  Color(0xFF26C6DA),
  Color(0xFFD4E157),
  Color(0xFF8D6E63),
  Color(0xFF78909C),
  Color(0xFFFFB300),
  Color(0xFF00ACC1),
];

/// Returns a stable, deterministic colour for a category name.
Color categoryColor(String name) =>
    _palette[name.hashCode.abs() % _palette.length];

// ── Month abbreviations ───────────────────────────────────────────────────────

const _monthAbbr = [
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

/// Derives a [ReportSummary] from a list of transactions and a [ReportPeriod].
///
/// Pure business logic — no Riverpod, no Dio, no Flutter widget dependencies.
/// Fully unit-testable in isolation.
class BuildReportSummaryUseCase {
  const BuildReportSummaryUseCase();

  ReportSummary call(List<Transaction> all, ReportPeriod period) {
    final start = period.start;

    // Only settled transactions within the selected period.
    final txns = all.where((t) {
      if (t.pending) return false;
      if (start == null) return true;
      return !t.date.isBefore(start);
    }).toList()..sort((a, b) => b.date.compareTo(a.date)); // newest first

    // Exclude transfers from budget totals.
    final budgetableTransactions = txns
        .where(
          (t) => t.type != TransactionType.transfer && t.category != 'Transfer',
        )
        .toList();

    final expenseList = budgetableTransactions
        .where((t) => t.isExpense)
        .toList();
    final incomeList = budgetableTransactions.where((t) => t.isIncome).toList();

    // ── Totals ──────────────────────────────────────────────────────────────
    double income = 0;
    double expenses = 0;

    for (final t in expenseList) {
      expenses += t.amount;
    }
    for (final t in incomeList) {
      income += t.amount;
    }

    final largestExpense = expenseList.isEmpty
        ? null
        : expenseList.fold<Transaction>(
            expenseList.first,
            (prev, e) => e.amount > prev.amount ? e : prev,
          );
    final largestIncome = incomeList.isEmpty
        ? null
        : incomeList.fold<Transaction>(
            incomeList.first,
            (prev, e) => e.amount > prev.amount ? e : prev,
          );

    // ── Spending by category ─────────────────────────────────────────────────
    final spendMap = <String, (double, int)>{};
    for (final t in expenseList) {
      final prev = spendMap[t.category] ?? (0.0, 0);
      spendMap[t.category] = (prev.$1 + t.amount, prev.$2 + 1);
    }
    final spendingByCategory =
        (spendMap.entries.toList()
              ..sort((a, b) => b.value.$1.compareTo(a.value.$1)))
            .map(
              (e) => ReportCategory(
                name: e.key,
                amount: e.value.$1,
                percentage: expenses > 0 ? e.value.$1 / expenses * 100 : 0,
                color: categoryColor(e.key),
                count: e.value.$2,
              ),
            )
            .toList();

    // ── Income by category ───────────────────────────────────────────────────
    final incomeMap = <String, (double, int)>{};
    for (final t in incomeList) {
      final prev = incomeMap[t.category] ?? (0.0, 0);
      incomeMap[t.category] = (prev.$1 + t.amount, prev.$2 + 1);
    }
    final incomeByCategory =
        (incomeMap.entries.toList()
              ..sort((a, b) => b.value.$1.compareTo(a.value.$1)))
            .map(
              (e) => ReportCategory(
                name: e.key,
                amount: e.value.$1,
                percentage: income > 0 ? e.value.$1 / income * 100 : 0,
                color: categoryColor(e.key),
                count: e.value.$2,
              ),
            )
            .toList();

    // ── Monthly cash flow (for bar chart) ────────────────────────────────────
    final flowMap = <String, (double, double)>{}; // key → (income, expenses)
    for (final t in budgetableTransactions) {
      final key = '${t.date.year}-${t.date.month.toString().padLeft(2, '0')}';
      final prev = flowMap[key] ?? (0.0, 0.0);
      if (t.isIncome) {
        flowMap[key] = (prev.$1 + t.amount, prev.$2);
      } else if (t.isExpense) {
        flowMap[key] = (prev.$1, prev.$2 + t.amount);
      }
    }
    final monthlyFlow = (flowMap.keys.toList()..sort()).map((k) {
      final parts = k.split('-');
      final month = int.parse(parts[1]);
      final year = parts[0];
      final data = flowMap[k]!;
      return MonthlyFlow(
        label: '${_monthAbbr[month - 1]} ${year.substring(2)}',
        income: data.$1,
        expenses: data.$2,
      );
    }).toList();

    return ReportSummary(
      totalIncome: income,
      totalExpenses: expenses,
      transactionCount: budgetableTransactions.length,
      largestExpense: largestExpense,
      largestIncome: largestIncome,
      spendingByCategory: spendingByCategory,
      incomeByCategory: incomeByCategory,
      monthlyFlow: monthlyFlow,
      recentExpenses: expenseList.take(5).toList(),
      recentIncome: incomeList.take(5).toList(),
    );
  }
}
