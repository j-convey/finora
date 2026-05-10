/// A reimbursement link between an expense transaction and an income
/// transaction. Amounts are always positive decimals (never integer cents).
class ReimbursementModel {
  const ReimbursementModel({
    required this.id,
    required this.expenseTransactionId,
    required this.incomeTransactionId,
    required this.amount,
    this.notes,
    this.createdByUserId,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String expenseTransactionId;
  final String incomeTransactionId;
  final double amount;
  final String? notes;
  final int? createdByUserId;
  final DateTime createdAt;
  final DateTime updatedAt;

  factory ReimbursementModel.fromJson(Map<String, dynamic> json) =>
      ReimbursementModel(
        id: json['id'] as String,
        expenseTransactionId: json['expense_transaction_id'] as String,
        incomeTransactionId: json['income_transaction_id'] as String,
        amount: (json['amount'] as num).toDouble(),
        notes: json['notes'] as String?,
        createdByUserId: json['created_by_user_id'] as int?,
        createdAt: DateTime.parse(json['created_at'] as String),
        updatedAt: DateTime.parse(json['updated_at'] as String),
      );

  ReimbursementModel copyWith({double? amount, String? notes}) =>
      ReimbursementModel(
        id: id,
        expenseTransactionId: expenseTransactionId,
        incomeTransactionId: incomeTransactionId,
        amount: amount ?? this.amount,
        notes: notes ?? this.notes,
        createdByUserId: createdByUserId,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}

/// Response from `GET /transactions/{id}/reimbursements`.
/// Includes the reimbursement links plus running allocation totals so the
/// client can render a capacity indicator without a second request.
class ReimbursementListResponse {
  const ReimbursementListResponse({
    required this.transactionId,
    required this.transactionAmount,
    required this.allocatedAmount,
    required this.remainingAmount,
    required this.reimbursements,
  });

  final String transactionId;

  /// Full amount of the queried transaction (always positive).
  final double transactionAmount;

  /// Sum of all linked reimbursement amounts.
  final double allocatedAmount;

  /// `transactionAmount - allocatedAmount` (≥ 0).
  final double remainingAmount;

  /// All reimbursement link objects, ordered by `created_at` ascending.
  final List<ReimbursementModel> reimbursements;

  factory ReimbursementListResponse.fromJson(Map<String, dynamic> json) =>
      ReimbursementListResponse(
        transactionId: json['transaction_id'] as String,
        transactionAmount: (json['transaction_amount'] as num).toDouble(),
        allocatedAmount: (json['allocated_amount'] as num).toDouble(),
        remainingAmount: (json['remaining_amount'] as num).toDouble(),
        reimbursements: (json['reimbursements'] as List<dynamic>)
            .map((j) =>
                ReimbursementModel.fromJson(j as Map<String, dynamic>))
            .toList(),
      );
}
