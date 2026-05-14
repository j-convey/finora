import 'package:flutter/material.dart';
import '../../domain/entities/transaction.dart';

extension TransactionUI on Transaction {
  IconData get icon => TransactionUIHelper.iconForCategory(category);
}

class TransactionUIHelper {
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
