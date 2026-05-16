import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:finora/core/network/api_client.dart';
import 'package:finora/features/transactions/data/models/split_input_model.dart';
import 'package:finora/features/transactions/domain/entities/transaction.dart';
import 'package:finora/features/transactions/domain/repositories/i_transactions_repository.dart';
import 'package:finora/features/transactions/data/repositories/transactions_repository_impl.dart';

final transactionsRepositoryProvider = Provider<ITransactionsRepository>((ref) {
  final dio = ref.watch(apiClientProvider);
  return TransactionsRepositoryImpl(dio);
});

class TransactionsNotifier extends StateNotifier<List<Transaction>> {
  TransactionsNotifier(this._ref) : super([]);

  final Ref _ref;

  Future<void> sync() async {
    final repository = _ref.read(transactionsRepositoryProvider);
    state = await repository.getTransactions();
  }

  void addTransaction(Transaction transaction) {
    state = [transaction, ...state];
  }

  void removeTransaction(String id) {
    state = state.where((t) => t.id != id).toList();
  }

  void clear() {
    state = [];
  }

  Future<void> updateCategory(String id, int categoryId, String categoryName) async {
    final repository = _ref.read(transactionsRepositoryProvider);
    // Optimistic update — show the new name immediately.
    state = state
        .map((t) => t.id == id ? t.copyWith(category: categoryName) : t)
        .toList();
    try {
      await repository.updateTransaction(id, {'category_id': categoryId});
    } catch (e) {
      await sync();
      rethrow;
    }
  }

  Future<void> updateNotes(String id, String notes) async {
    final repository = _ref.read(transactionsRepositoryProvider);
    // Optimistic update
    state = state
        .map((t) => t.id == id ? t.copyWith(notes: notes) : t)
        .toList();
    try {
      await repository.updateTransaction(id, {'notes': notes});
    } catch (e) {
      await sync();
      rethrow;
    }
  }

  Future<void> updateType(String id, TransactionType type) async {
    final repository = _ref.read(transactionsRepositoryProvider);
    // Optimistic update
    state = state
        .map((t) => t.id == id ? t.copyWith(type: type) : t)
        .toList();
    try {
      await repository.updateTransaction(id, {'type': type.toJson()});
    } catch (_) {
      await sync();
    }
  }

  Future<void> splitTransaction(
    String transactionId,
    List<SplitInputModel> splits,
  ) async {
    final repository = _ref.read(transactionsRepositoryProvider);
    final children = await repository.splitTransaction(transactionId, splits);
    // Mark parent as split parent
    state = state
        .map((t) => t.id == transactionId ? t.copyWith(isSplitParent: true) : t)
        .toList();
    // Append child splits (de-duplicate in case of retry)
    final existingIds = state.map((t) => t.id).toSet();
    final newChildren = children.where((c) => !existingIds.contains(c.id)).toList();
    state = [...state, ...newChildren];
  }

  Future<void> unsplitTransaction(String transactionId) async {
    final repository = _ref.read(transactionsRepositoryProvider);
    await repository.unsplitTransaction(transactionId);
    // Remove all children belonging to this parent
    state = state.where((t) => t.parentTransactionId != transactionId).toList();
    // Restore parent to normal
    state = state
        .map((t) => t.id == transactionId ? t.copyWith(isSplitParent: false) : t)
        .toList();
  }

  void clearReviewFlag(String transactionId) {
    state = state
        .map(
          (t) => t.id == transactionId
              ? t.copyWith(requiresUserReview: false)
              : t,
        )
        .toList();
  }
}

final transactionsProvider =
    StateNotifierProvider<TransactionsNotifier, List<Transaction>>(
  (ref) => TransactionsNotifier(ref),
);
