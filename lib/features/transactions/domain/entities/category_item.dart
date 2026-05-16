/// A single selectable category item as returned by the /api/categories endpoint.
///
/// The server now requires [id] when updating a transaction's category
/// (`PATCH /api/transactions/{id}` with `{"category_id": item.id}`).
class CategoryItem {
  const CategoryItem({required this.id, required this.name});

  final int id;
  final String name;

  /// Parses from the API, which returns either an object
  /// `{"id": 1, "name": "Paychecks"}` or a legacy plain string (no ID).
  factory CategoryItem.fromJson(dynamic json) {
    if (json is Map<String, dynamic>) {
      return CategoryItem(
        id: (json['id'] as num).toInt(),
        name: json['name'] as String,
      );
    }
    // Legacy fallback: API returned a plain string with no ID.
    return CategoryItem(id: -1, name: json.toString());
  }
}
