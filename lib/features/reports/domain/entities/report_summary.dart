import 'package:flutter/material.dart';

import '../../../transactions/data/models/transaction_model.dart';

/// A single aggregated category bucket (spending or income).
class ReportCategory {
  const ReportCategory({
    required this.name,
    required this.amount,
    required this.percentage,
    required this.color,
    required this.count,
  });

  final String name;
  final double amount;

  /// Share of the total as a value from 0–100.
  final double percentage;
  final Color color;

  /// Number of transactions contributing to this bucket.
  final int count;
}

/// Income vs expense totals for a single calendar month.
class MonthlyFlow {
  const MonthlyFlow({
    required this.label,
    required this.income,
    required this.expenses,
  });

  /// Short label shown on the chart x-axis, e.g. "Apr 26".
  final String label;
  final double income;
  final double expenses;

  double get net => income - expenses;
}

/// Fully-derived report snapshot for the selected period.
class ReportSummary {
  const ReportSummary({
    required this.totalIncome,
    required this.totalExpenses,
    required this.transactionCount,
    required this.largestExpense,
    required this.largestIncome,
    required this.spendingByCategory,
    required this.incomeByCategory,
    required this.monthlyFlow,
    required this.recentExpenses,
    required this.recentIncome,
  });

  final double totalIncome;
  final double totalExpenses;
  final int transactionCount;
  final TransactionModel? largestExpense;
  final TransactionModel? largestIncome;
  final List<ReportCategory> spendingByCategory;
  final List<ReportCategory> incomeByCategory;

  /// Monthly buckets in chronological order for the Cash Flow chart.
  final List<MonthlyFlow> monthlyFlow;

  /// Up to 5 most recent settled expense transactions.
  final List<TransactionModel> recentExpenses;

  /// Up to 5 most recent settled income transactions.
  final List<TransactionModel> recentIncome;

  double get netCashFlow => totalIncome - totalExpenses;
  double get savingsRate => totalIncome > 0 ? netCashFlow / totalIncome : 0;
}
