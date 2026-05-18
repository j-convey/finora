class NetWorthHistoryEntry {
  const NetWorthHistoryEntry({required this.date, required this.netWorth});

  final DateTime date;
  final double netWorth;

  factory NetWorthHistoryEntry.fromJson(Map<String, dynamic> json) =>
      NetWorthHistoryEntry(
        date: DateTime.parse(json['date'] as String),
        netWorth: (json['net_worth'] as num).toDouble(),
      );
}

class NetWorthHistory {
  const NetWorthHistory({required this.entries});

  final List<NetWorthHistoryEntry> entries;

  double get currentNetWorth => entries.isEmpty ? 0 : entries.last.netWorth;

  double get previousNetWorth => entries.isEmpty ? 0 : entries.first.netWorth;

  double get netWorthChange => currentNetWorth - previousNetWorth;

  double get netWorthChangePercentage {
    if (previousNetWorth == 0) return 0;
    return (netWorthChange / previousNetWorth.abs()) * 100;
  }
}
