import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/transaction_model.dart';

class TransactionsNotifier extends StateNotifier<List<TransactionModel>> {
  TransactionsNotifier(this._ref) : super([]);

  final Ref _ref;

  Future<void> sync() async {
    final dio = _ref.read(apiClientProvider);
    final response = await dio.get<List<dynamic>>('/api/transactions');
    state = (response.data ?? [])
        .map((j) => TransactionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  void addTransaction(TransactionModel transaction) {
    state = [transaction, ...state];
  }

  void removeTransaction(String id) {
    state = state.where((t) => t.id != id).toList();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
  (ref) => TransactionsNotifier(ref),
);

