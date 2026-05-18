/// Represents one line item in a split-transaction request body.
class SplitInputModel {
  const SplitInputModel({
    required this.title,
    required this.amount,
    this.categoryId,
    this.notes,
  });

  final String title;
  final double amount;

  /// When omitted the server inherits the parent's category.
  final int? categoryId;
  final String? notes;

  Map<String, dynamic> toJson() => {
    'title': title,
    'amount': amount,
    if (categoryId != null) 'category_id': categoryId,
    if (notes != null && notes!.isNotEmpty) 'notes': notes,
  };
}
