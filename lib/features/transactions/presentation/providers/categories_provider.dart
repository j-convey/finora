import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';

/// Default fallback categories used when the server is unreachable
/// or returns an empty list.
const _fallbackCategories = <String>[
  'Groceries', 'Dining', 'Transport', 'Entertainment',
  'Utilities', 'Health', 'Shopping', 'Subscriptions',
  'Rent', 'Travel', 'Income', 'Transfer', 'Uncategorized',
];

class CategoriesNotifier extends StateNotifier<List<String>> {
  CategoriesNotifier(this._ref) : super(_fallbackCategories);

  final Ref _ref;

  Future<void> sync() async {
    try {
      final dio = _ref.read(apiClientProvider);
      final response = await dio.get<List<dynamic>>('/api/categories');
      final fetched = (response.data ?? [])
          .map((e) => e.toString())
          .where((s) => s.isNotEmpty)
          .toList();
      if (fetched.isNotEmpty) {
        state = fetched;
      }
    } catch (_) {
      // Keep current (or fallback) list on failure
    }
  }

  void clear() {
    state = _fallbackCategories;
  }
}

final categoriesProvider =
    StateNotifierProvider<CategoriesNotifier, List<String>>(
  (ref) => CategoriesNotifier(ref),
);
