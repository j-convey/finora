import 'package:dio/dio.dart';

import '../models/split_input_model.dart';
import '../models/transaction_model.dart';

/// Handles all API calls related to splitting and un-splitting transactions.
class SplitTransactionService {
  const SplitTransactionService(this._dio);

  final Dio _dio;

  /// Splits [transactionId] into the given [splits] (≥ 2 items whose amounts
  /// sum exactly to the parent's amount).
  ///
  /// Returns the newly-created child [TransactionModel] list on success.
  /// Throws [DioException] on validation or server errors.
  Future<List<TransactionModel>> splitTransaction(
    String transactionId,
    List<SplitInputModel> splits,
  ) async {
    final response = await _dio.post<List<dynamic>>(
      '/api/transactions/$transactionId/split',
      data: {'splits': splits.map((s) => s.toJson()).toList()},
    );
    return (response.data ?? [])
        .map((j) => TransactionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  /// Removes all child splits from [transactionId], restoring it to a normal
  /// unsplit transaction. Returns nothing (204 No Content expected).
  Future<void> unsplitTransaction(String transactionId) async {
    await _dio.delete<void>('/api/transactions/$transactionId/split');
  }
}
