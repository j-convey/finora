import 'dart:ui';

enum AccountType {
  checking,
  savings,
  creditCard,
  investment,
  cash;

  static AccountType fromString(String value) => switch (value) {
    'checking' => AccountType.checking,
    'savings' => AccountType.savings,
    'credit_card' => AccountType.creditCard,
    'investment' => AccountType.investment,
    'cash' => AccountType.cash,
    _ => AccountType.checking,
  };

  String toJson() => switch (this) {
    AccountType.checking => 'checking',
    AccountType.savings => 'savings',
    AccountType.creditCard => 'credit_card',
    AccountType.investment => 'investment',
    AccountType.cash => 'cash',
  };
}

class Account {
  const Account({
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
  final double? availableBalance;
  final String? institutionName;
  final Color? color;
  final DateTime? updatedAt;

  Account copyWith({
    String? name,
    AccountType? type,
    double? balance,
    double? availableBalance,
    String? institutionName,
    Color? color,
    DateTime? updatedAt,
  }) => Account(
    id: id,
    name: name ?? this.name,
    type: type ?? this.type,
    balance: balance ?? this.balance,
    availableBalance: availableBalance ?? this.availableBalance,
    institutionName: institutionName ?? this.institutionName,
    color: color ?? this.color,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
