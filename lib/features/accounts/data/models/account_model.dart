import 'dart:ui';
import '../../domain/entities/account.dart';

class AccountModel extends Account {
  const AccountModel({
    required super.id,
    required super.name,
    required super.type,
    required super.balance,
    super.availableBalance,
    super.institutionName,
    super.color,
    super.updatedAt,
  });

  factory AccountModel.fromJson(Map<String, dynamic> json) => AccountModel(
        id: json['id'] as String,
        name: json['name'] as String,
        type: AccountType.fromString(json['type'] as String),
        balance: (json['balance'] as num).toDouble(),
        availableBalance: json['available_balance'] != null
            ? (json['available_balance'] as num).toDouble()
            : null,
        institutionName: json['institution_name'] as String?,
        color:
            json['color'] != null ? _hexToColor(json['color'] as String) : null,
        updatedAt: json['updated_at'] != null
            ? DateTime.tryParse(json['updated_at'] as String)
            : null,
      );

  static Color _hexToColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse(h.length == 6 ? 'FF$h' : h, radix: 16));
  }
}
