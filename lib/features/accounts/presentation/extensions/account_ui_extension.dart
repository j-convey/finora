import 'package:flutter/material.dart';
import '../../domain/entities/account.dart';

extension AccountUI on Account {
  String get label => type.label;
  IconData get icon => type.icon;
}

extension AccountTypeUI on AccountType {
  String get label => switch (this) {
    AccountType.checking => 'Checking',
    AccountType.savings => 'Savings',
    AccountType.creditCard => 'Credit Card',
    AccountType.investment => 'Investment',
    AccountType.cash => 'Cash',
  };

  IconData get icon => switch (this) {
    AccountType.checking => Icons.account_balance_wallet_outlined,
    AccountType.savings => Icons.savings_outlined,
    AccountType.creditCard => Icons.credit_card_outlined,
    AccountType.investment => Icons.trending_up_outlined,
    AccountType.cash => Icons.money_outlined,
  };
}
