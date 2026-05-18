import 'package:flutter/material.dart';

class BudgetModel {
  const BudgetModel({
    required this.id,
    required this.category,
    required this.allocated,
    required this.spent,
    required this.color,
    required this.icon,
  });

  final String id;
  final String category;
  final double allocated;
  final double spent;
  final Color color;
  final IconData icon;

  double get remaining => allocated - spent;
  double get progress => (spent / allocated).clamp(0.0, 1.0);
  bool get isOverBudget => spent > allocated;

  /// Hex string required by the server (e.g. "#66BB6A").
  String toColorHex() {
    final argb = color.toARGB32();
    final value = argb & 0xFFFFFF;
    return '#${value.toRadixString(16).padLeft(6, '0').toUpperCase()}';
  }

  BudgetModel copyWith({
    String? id,
    String? category,
    double? allocated,
    double? spent,
    Color? color,
    IconData? icon,
  }) => BudgetModel(
    id: id ?? this.id,
    category: category ?? this.category,
    allocated: allocated ?? this.allocated,
    spent: spent ?? this.spent,
    color: color ?? this.color,
    icon: icon ?? this.icon,
  );

  factory BudgetModel.fromJson(Map<String, dynamic> json) {
    final category = json['category'] as String;
    return BudgetModel(
      id: json['id'] as String,
      category: category,
      allocated: (json['allocated'] as num).toDouble(),
      spent: (json['spent'] as num).toDouble(),
      color: _hexToColor(json['color'] as String? ?? '#009688'),
      icon: iconForCategory(category),
    );
  }

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }

  static IconData iconForCategory(String category) => switch (category) {
    'Groceries' => Icons.shopping_basket_outlined,
    'Dining' => Icons.restaurant_outlined,
    'Transport' => Icons.directions_car_outlined,
    'Entertainment' => Icons.movie_outlined,
    'Utilities' => Icons.bolt_outlined,
    'Health' => Icons.favorite_border,
    'Shopping' => Icons.shopping_bag_outlined,
    'Subscriptions' => Icons.repeat_outlined,
    'Rent' => Icons.home_outlined,
    'Travel' => Icons.flight_outlined,
    _ => Icons.category_outlined,
  };
}
