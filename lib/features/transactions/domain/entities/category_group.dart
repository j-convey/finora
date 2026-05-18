import 'category_item.dart';

/// Represents a grouped set of categories as returned by the /api/categories endpoint.
///
/// Example JSON:
/// { "group": "Food & Dining", "type": "expense", "categories": [{"id": 48, "name": "Groceries"}, ...] }
class CategoryGroup {
  const CategoryGroup({
    required this.group,
    required this.type,
    required this.categories,
  });

  final String group;
  final String type; // 'income', 'expense', or 'transfer'
  final List<CategoryItem> categories;

  factory CategoryGroup.fromJson(Map<String, dynamic> json) => CategoryGroup(
    group: json['group'] as String,
    type: json['type'] as String,
    categories: (json['categories'] as List<dynamic>)
        .map(CategoryItem.fromJson)
        .where((c) => c.name.isNotEmpty)
        .toList(),
  );
}
