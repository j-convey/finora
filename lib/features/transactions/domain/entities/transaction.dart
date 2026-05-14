enum TransactionType {
  income,
  expense,
  transfer;

  static TransactionType fromString(String value) => switch (value) {
        'income' => TransactionType.income,
        'transfer' => TransactionType.transfer,
        _ => TransactionType.expense,
      };

  String toJson() => switch (this) {
        TransactionType.income => 'income',
        TransactionType.expense => 'expense',
        TransactionType.transfer => 'transfer',
      };
}

class Transaction {
  const Transaction({
    required this.id,
    required this.title,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.accountId,
    this.notes,
    this.originalDescription,
    this.merchantName,
    this.providerTransactionId,
    this.pending = false,
    this.isSplitParent = false,
    this.parentTransactionId,
    this.requiresUserReview = false,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String title;
  final double amount;
  final TransactionType type;
  final String category;
  final DateTime date;
  final String? accountId;
  final String? notes;
  final String? originalDescription;
  final String? merchantName;
  final String? providerTransactionId;
  final bool pending;
  final bool isSplitParent;
  final String? parentTransactionId;
  final bool requiresUserReview;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;
  bool get isSplitChild => parentTransactionId != null;

  Transaction copyWith({
    String? title,
    double? amount,
    TransactionType? type,
    String? category,
    DateTime? date,
    String? accountId,
    String? notes,
    bool? isSplitParent,
    bool? requiresUserReview,
  }) =>
      Transaction(
        id: id,
        title: title ?? this.title,
        amount: amount ?? this.amount,
        type: type ?? this.type,
        category: category ?? this.category,
        date: date ?? this.date,
        accountId: accountId ?? this.accountId,
        notes: notes ?? this.notes,
        originalDescription: originalDescription,
        merchantName: merchantName,
        providerTransactionId: providerTransactionId,
        pending: pending,
        isSplitParent: isSplitParent ?? this.isSplitParent,
        parentTransactionId: parentTransactionId,
        requiresUserReview: requiresUserReview ?? this.requiresUserReview,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );
}
