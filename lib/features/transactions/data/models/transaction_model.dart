import '../../domain/entities/transaction.dart';

class TransactionModel extends Transaction {
  const TransactionModel({
    required super.id,
    required super.title,
    required super.amount,
    required super.type,
    required super.category,
    required super.date,
    super.accountId,
    super.notes,
    super.originalDescription,
    super.merchantName,
    super.providerTransactionId,
    super.pending = false,
    super.isSplitParent = false,
    super.parentTransactionId,
    super.requiresUserReview = false,
    super.createdAt,
    super.updatedAt,
  });

  factory TransactionModel.fromJson(Map<String, dynamic> json) => TransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: TransactionType.fromString(json['type'] as String),
        category: (json['category'] as String?) ?? 'Uncategorized',
        date: DateTime.parse(json['date'] as String),
        accountId: json['account_id'] as String?,
        notes: json['notes'] as String?,
        originalDescription: json['original_description'] as String?,
        merchantName: json['merchant_name'] as String?,
        providerTransactionId: json['provider_transaction_id'] as String?,
        pending: json['pending'] as bool? ?? false,
        isSplitParent: json['is_split_parent'] as bool? ?? false,
        parentTransactionId: json['parent_transaction_id'] as String?,
        requiresUserReview: json['requires_user_review'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );
}
