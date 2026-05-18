import 'package:dio/dio.dart';

import '../models/reimbursement_model.dart';

/// Handles all API calls for the reimbursement engine.
///
/// All amounts are positive decimals (e.g. `65.00`), never integer cents.
class ReimbursementService {
  const ReimbursementService(this._dio);

  final Dio _dio;

  /// Returns all reimbursement links where [transactionId] appears on either
  /// side, plus allocation totals.
  Future<ReimbursementListResponse> listReimbursements(
    String transactionId,
  ) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/api/transactions/$transactionId/reimbursements',
    );
    return ReimbursementListResponse.fromJson(response.data!);
  }

  /// Links [incomeTransactionId] as a (partial) reimbursement of
  /// [expenseTransactionId]. Returns the created link on success.
  ///
  /// Throws [DioException] on validation or server errors. The response body
  /// for `422 over_reimbursement` contains `max_allowed` and `current_net`.
  Future<ReimbursementModel> createReimbursement({
    required String expenseTransactionId,
    required String incomeTransactionId,
    required double amount,
    String? notes,
  }) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/api/transactions/reimbursements',
      data: {
        'expense_transaction_id': expenseTransactionId,
        'income_transaction_id': incomeTransactionId,
        'amount': amount,
        if (notes != null && notes.isNotEmpty) 'notes': notes,
      },
    );
    return ReimbursementModel.fromJson(response.data!);
  }

  /// Updates the `amount` and/or `notes` on an existing reimbursement link.
  /// Pass `notes: null` to clear the note.
  Future<ReimbursementModel> updateReimbursement(
    String reimbursementId, {
    double? amount,
    String? notes,
  }) async {
    final response = await _dio.put<Map<String, dynamic>>(
      '/api/transactions/reimbursements/$reimbursementId',
      data: {if (amount != null) 'amount': amount, 'notes': notes},
    );
    return ReimbursementModel.fromJson(response.data!);
  }

  /// Permanently removes a reimbursement link (`204 No Content`).
  Future<void> deleteReimbursement(String reimbursementId) async {
    await _dio.delete<void>(
      '/api/transactions/reimbursements/$reimbursementId',
    );
  }
}
