import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/split_input_model.dart';
import '../../data/models/transaction_model.dart';
import '../../data/datasources/split_transaction_service.dart';

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

  void clear() {
    state = [];
  }

  Future<void> updateCategory(String id, String category) async {
    // Optimistic update
    state = state
        .map((t) => t.id == id ? t.copyWith(category: category) : t)
        .toList();
    try {
      final dio = _ref.read(apiClientProvider);
      await dio.patch<void>(
        '/api/transactions/$id',
        data: {'category': category},
      );
    } catch (_) {
      // Revert on failure by re-syncing
      await sync();
    }
  }

  Future<void> updateNotes(String id, String notes) async {
    // Optimistic update
    state = state
        .map((t) => t.id == id ? t.copyWith(notes: notes) : t)
        .toList();
    try {
      final dio = _ref.read(apiClientProvider);
      await dio.patch<void>(
        '/api/transactions/$id',
        data: {'notes': notes},
      );
    } catch (_) {
      // Revert on failure by re-syncing
      await sync();
    }
  }

  Future<void> updateType(String id, TransactionType type) async {
    // Optimistic update
    state = state
        .map((t) => t.id == id ? t.copyWith(type: type) : t)
        .toList();
    try {
      final dio = _ref.read(apiClientProvider);
      final typeString = switch (type) {
        TransactionType.income => 'income',
        TransactionType.expense => 'expense',
        TransactionType.transfer => 'transfer',
      };
      await dio.patch<void>(
        '/api/transactions/$id',
        data: {'type': typeString},
      );
    } catch (_) {
      // Revert on failure by re-syncing
      await sync();
    }
  }

  /// Splits [transactionId] into the given [splits] (≥ 2 items).
  /// On success the parent row is marked as split-parent in local state
  /// and all returned child rows are appended.
  Future<void> splitTransaction(
    String transactionId,
    List<SplitInputModel> splits,
  ) async {
    final dio = _ref.read(apiClientProvider);
    final service = SplitTransactionService(dio);
    final children = await service.splitTransaction(transactionId, splits);
    // Mark parent as split parent
    state = state
        .map((t) => t.id == transactionId ? t.copyWith(isSplitParent: true) : t)
        .toList();
    // Append child splits (de-duplicate in case of retry)
    final existingIds = state.map((t) => t.id).toSet();
    final newChildren = children.where((c) => !existingIds.contains(c.id)).toList();
    state = [...state, ...newChildren];
  }

  /// Removes all child splits from [transactionId], restoring the parent to a
  /// normal unsplit transaction.
  Future<void> unsplitTransaction(String transactionId) async {
    final dio = _ref.read(apiClientProvider);
    final service = SplitTransactionService(dio);
    await service.unsplitTransaction(transactionId);
    // Remove all children belonging to this parent
    state = state.where((t) => t.parentTransactionId != transactionId).toList();
    // Restore parent to normal
    state = state
        .map((t) => t.id == transactionId ? t.copyWith(isSplitParent: false) : t)
        .toList();
  }

  /// Clears the [requiresUserReview] flag on [transactionId] after the user
  /// has acknowledged or resolved the split re-reconciliation prompt.
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
    StateNotifierProvider<TransactionsNotifier, List<TransactionModel>>(
  (ref) => TransactionsNotifier(ref),
);

