import 'package:dio/dio.dart';
import '../../domain/entities/transaction.dart';
import '../../domain/repositories/i_transactions_repository.dart';
import '../models/transaction_model.dart';
import '../models/split_input_model.dart';

class TransactionsRepositoryImpl implements ITransactionsRepository {
  TransactionsRepositoryImpl(this._dio);

  final Dio _dio;

  @override
  Future<List<Transaction>> getTransactions() async {
    final response = await _dio.get<List<dynamic>>('/api/transactions');
    return (response.data ?? [])
        .map((j) => TransactionModel.fromJson(j as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> updateTransaction(String id, Map<String, dynamic> data) async {
    await _dio.patch<void>('/api/transactions/$id', data: data);
  }

  @override
  Future<List<Transaction>> splitTransaction(
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

  @override
  Future<void> unsplitTransaction(String transactionId) async {
    await _dio.delete<void>('/api/transactions/$transactionId/split');
  }
}
