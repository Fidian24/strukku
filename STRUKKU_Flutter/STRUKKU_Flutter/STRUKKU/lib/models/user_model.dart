/// Tabel users: id, email, password_hash, full_name, created_at.
/// password_hash sengaja tidak disimpan di model sisi aplikasi.
class UserModel {
  const UserModel({
    required this.id,
    required this.email,
    required this.fullName,
    required this.createdAt,
  });

  final int id;
  final String email;
  final String fullName;
  final DateTime createdAt;

  String get initial =>
      fullName.trim().isEmpty ? '?' : fullName.trim()[0].toUpperCase();

  String get firstName => fullName.trim().split(RegExp(r'\s+')).first;

  factory UserModel.fromJson(Map<String, dynamic> json) => UserModel(
        id: (json['id'] as num).toInt(),
        email: json['email'] as String,
        fullName: json['full_name'] as String,
        createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'email': email,
        'full_name': fullName,
        'created_at': createdAt.toIso8601String(),
      };
}
