import 'package:flutter_riverpod/flutter_riverpod.dart';

enum TransactionSort {
  latest('Latest'),
  oldest('Oldest'),
  largest('Largest'),
  smallest('Smallest');

  const TransactionSort(this.label);
  final String label;
}

class TransactionFilters {
  const TransactionFilters({
    this.accountId,
    this.category,
    this.month,
    this.year,
    this.sortBy = TransactionSort.latest,
    this.search = '',
  });

  final String? accountId;
  final String? category;
  final int? month;
  final int? year;
  final TransactionSort sortBy;
  final String search;

  TransactionFilters copyWith({
    String? accountId,
    bool clearAccountId = false,
    String? category,
    bool clearCategory = false,
    int? month,
    bool clearMonth = false,
    int? year,
    bool clearYear = false,
    TransactionSort? sortBy,
    String? search,
  }) {
    return TransactionFilters(
      accountId: clearAccountId ? null : accountId ?? this.accountId,
      category: clearCategory ? null : category ?? this.category,
      month: clearMonth ? null : month ?? this.month,
      year: clearYear ? null : year ?? this.year,
      sortBy: sortBy ?? this.sortBy,
      search: search ?? this.search,
    );
  }

  bool get hasFilters =>
      accountId != null || category != null || month != null || year != null;
}

final transactionFiltersProvider =
    StateProvider<TransactionFilters>((ref) => const TransactionFilters());
