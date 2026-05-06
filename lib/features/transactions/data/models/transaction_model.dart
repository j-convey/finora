import 'package:flutter/material.dart';

enum TransactionType { income, expense, transfer }

class TransactionModel {
  const TransactionModel({
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
  // ── Fields added by server v2 ──────────────────────────────
  final String? originalDescription;
  final String? merchantName;
  final String? providerTransactionId;
  final bool pending;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isIncome => type == TransactionType.income;
  bool get isExpense => type == TransactionType.expense;

  factory TransactionModel.fromJson(Map<String, dynamic> json) =>
      TransactionModel(
        id: json['id'] as String,
        title: json['title'] as String,
        amount: (json['amount'] as num).toDouble(),
        type: _typeFromString(json['type'] as String),
        category: json['category'] as String,
        date: DateTime.parse(json['date'] as String),
        accountId: json['account_id'] as String?,
        notes: json['notes'] as String?,
        originalDescription: json['original_description'] as String?,
        merchantName: json['merchant_name'] as String?,
        providerTransactionId: json['provider_transaction_id'] as String?,
        pending: json['pending'] as bool? ?? false,
        createdAt: json['created_at'] != null
            ? DateTime.tryParse(json['created_at'] as String)
            : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  TransactionModel copyWith({String? category}) => TransactionModel(
        id: id,
        title: title,
        amount: amount,
        type: type,
        category: category ?? this.category,
        date: date,
        accountId: accountId,
        notes: notes,
        originalDescription: originalDescription,
        merchantName: merchantName,
        providerTransactionId: providerTransactionId,
        pending: pending,
        createdAt: createdAt,
        updatedAt: updatedAt,
      );

  static TransactionType _typeFromString(String s) => switch (s) {
        'income' => TransactionType.income,
        'transfer' => TransactionType.transfer,
        _ => TransactionType.expense,
      };

  static const _categoryIcons = <String, IconData>{
    'Income': Icons.payments_outlined,
    'Groceries': Icons.shopping_basket_outlined,
    'Dining': Icons.restaurant_outlined,
    'Transport': Icons.directions_car_outlined,
    'Entertainment': Icons.movie_outlined,
    'Utilities': Icons.bolt_outlined,
    'Health': Icons.favorite_border,
    'Shopping': Icons.shopping_bag_outlined,
    'Travel': Icons.flight_outlined,
    'Rent': Icons.home_outlined,
    'Subscriptions': Icons.repeat_outlined,
    'Transfer': Icons.swap_horiz_outlined,
  };

  static IconData iconForCategory(String category) =>
      _categoryIcons[category] ?? Icons.attach_money_outlined;
}
