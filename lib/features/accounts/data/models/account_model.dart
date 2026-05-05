import 'package:flutter/material.dart';

enum AccountType { checking, savings, creditCard, investment, cash }

class AccountModel {
  const AccountModel({
    required this.id,
    required this.name,
    required this.type,
    required this.balance,
    this.availableBalance,
    this.institutionName,
    this.color,
    this.updatedAt,
  });

  final String id;
  final String name;
  final AccountType type;
  final double balance;
  // ── Fields added by server v2 ──────────────────────────────
  final double? availableBalance;
  final String? institutionName;
  final Color? color;
  final DateTime? updatedAt;

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: _typeFromString(json['type'] as String),
        balance: (json['balance'] as num).toDouble(),
        availableBalance: json['available_balance'] != null
            ? (json['available_balance'] as num).toDouble()
            : null,
        institutionName: json['institution_name'] as String?,
        color: json['color'] != null ? _hexToColor(json['color'] as String) : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  static AccountType _typeFromString(String s) => switch (s) {
        'checking' => AccountType.checking,
        'savings' => AccountType.savings,
        'credit_card' => AccountType.creditCard,
        'investment' => AccountType.investment,
        'cash' => AccountType.cash,
        _ => AccountType.checking,
      };

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }

  static String labelForType(AccountType type) => switch (type) {
        AccountType.checking => 'Checking',
        AccountType.savings => 'Savings',
        AccountType.creditCard => 'Credit Card',
        AccountType.investment => 'Investment',
        AccountType.cash => 'Cash',
      };

  static IconData iconForType(AccountType type) => switch (type) {
        AccountType.checking => Icons.account_balance_wallet_outlined,
        AccountType.savings => Icons.savings_outlined,
        AccountType.creditCard => Icons.credit_card_outlined,
        AccountType.investment => Icons.trending_up_outlined,
        AccountType.cash => Icons.money_outlined,
      };
}
