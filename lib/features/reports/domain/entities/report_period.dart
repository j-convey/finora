/// Date-range presets available in the period picker.
enum ReportPeriod {
  thisMonth('This month'),
  last30Days('Last 30 days'),
  last3Months('Last 3 months'),
  last6Months('Last 6 months'),
  thisYear('This year'),
  allTime('All time');

  const ReportPeriod(this.label);

  final String label;

  /// Inclusive start of the period, or [null] for all time.
  DateTime? get start {
    final now = DateTime.now();
    return switch (this) {
      ReportPeriod.thisMonth => DateTime(now.year, now.month, 1),
      ReportPeriod.last30Days => now.subtract(const Duration(days: 30)),
      ReportPeriod.last3Months => now.subtract(const Duration(days: 90)),
      ReportPeriod.last6Months => now.subtract(const Duration(days: 180)),
      ReportPeriod.thisYear => DateTime(now.year, 1, 1),
      ReportPeriod.allTime => null,
    };
  }
}
