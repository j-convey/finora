import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/features/transactions/presentation/providers/transactions_provider.dart';
import 'package:finora/features/reports/domain/entities/report_period.dart';
import 'package:finora/features/reports/domain/entities/report_summary.dart';
import 'package:finora/features/reports/domain/usecases/build_report_summary_usecase.dart';

// ── Providers ─────────────────────────────────────────────────────────────────

final reportPeriodProvider =
    StateProvider<ReportPeriod>((ref) => ReportPeriod.last30Days);

/// Derives a [ReportSummary] from [transactionsProvider] for the selected
/// [reportPeriodProvider]. Re-computes automatically when either changes.
final reportSummaryProvider = Provider<ReportSummary>((ref) {
  final period = ref.watch(reportPeriodProvider);
  final transactions = ref.watch(transactionsProvider);
  return const BuildReportSummaryUseCase()(transactions, period);
});
