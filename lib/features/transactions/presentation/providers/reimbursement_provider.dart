import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/api_client.dart';
import '../../data/models/reimbursement_model.dart';
import '../../data/services/reimbursement_service.dart';

/// Provides and manages reimbursement data for a single transaction.
///
/// Keyed by `transactionId`. Auto-disposes when no longer watched so stale
/// data is not retained across navigation.
///
/// Usage:
/// ```dart
/// final asyncData = ref.watch(reimbursementProvider('txn_abc123'));
/// ```
final reimbursementProvider = AsyncNotifierProvider.autoDispose
    .family<ReimbursementNotifier, ReimbursementListResponse, String>(
  ReimbursementNotifier.new,
);

class ReimbursementNotifier
    extends AutoDisposeFamilyAsyncNotifier<ReimbursementListResponse, String> {
  /// [arg] is the `transactionId` passed via the family parameter.
  @override
  Future<ReimbursementListResponse> build(String arg) =>
      _service.listReimbursements(arg);

  ReimbursementService get _service =>
      ReimbursementService(ref.read(apiClientProvider));

  /// Links [incomeTransactionId] as a reimbursement of [expenseTransactionId]
  /// then refreshes the local state.
  Future<void> create({
    required String expenseTransactionId,
    required String incomeTransactionId,
    required double amount,
    String? notes,
  }) async {
    await _service.createReimbursement(
      expenseTransactionId: expenseTransactionId,
      incomeTransactionId: incomeTransactionId,
      amount: amount,
      notes: notes,
    );
    ref.invalidateSelf();
    await future;
  }

  /// Updates [reimbursementId]'s amount and/or notes then refreshes.
  Future<void> updateReimbursement(
    String reimbursementId, {
    double? amount,
    String? notes,
  }) async {
    await _service.updateReimbursement(
      reimbursementId,
      amount: amount,
      notes: notes,
    );
    ref.invalidateSelf();
    await future;
  }

  /// Removes [reimbursementId] and refreshes.
  Future<void> delete(String reimbursementId) async {
    await _service.deleteReimbursement(reimbursementId);
    ref.invalidateSelf();
    await future;
  }
}
