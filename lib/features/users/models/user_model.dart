import '../../../core/utils/helpers.dart';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.phone,
    required this.isActive,
    required this.createdAt,
  });

  final String id;
  final String name;
  final String email;
  final String role;
  final String phone;
  final bool isActive;
  final DateTime? createdAt;

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      isActive: AppHelpers.parseBool(json['is_active'], fallback: true),
      createdAt: DateTime.tryParse(json['created_at']?.toString() ?? ''),
    );
  }

  UserModel copyWith({
    String? name,
    String? email,
    String? role,
    String? phone,
    bool? isActive,
  }) {
    return UserModel(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      phone: phone ?? this.phone,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt,
    );
  }
}
