import '../../data/models/split_input_model.dart';
import '../entities/transaction.dart';

abstract class ITransactionsRepository {
  Future<List<Transaction>> getTransactions();
  Future<void> updateTransaction(String id, Map<String, dynamic> data);
  Future<List<Transaction>> splitTransaction(
    String transactionId,
    List<SplitInputModel> splits,
  );
  Future<void> unsplitTransaction(String transactionId);
}
