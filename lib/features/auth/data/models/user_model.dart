class UserModel {
  const UserModel({
    required this.id,
    required this.householdId,
    required this.email,
    this.fullName,
    this.profilePictureUrl,
    required this.isActive,
    required this.createdAt,
  });

  final int id;
  final int householdId;
  final String email;
  final String? fullName;
  final String? profilePictureUrl;
  final bool isActive;
  final DateTime createdAt;

  String get displayName => fullName?.isNotEmpty == true ? fullName! : email;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: json['id'] as int,
        householdId: json['household_id'] as int,
        email: json['email'] as String,
        fullName: json['full_name'] as String?,
        profilePictureUrl: json['profile_picture_url'] as String?,
        isActive: json['is_active'] as bool? ?? true,
        createdAt: DateTime.parse(json['created_at'] as String),
      );
}
