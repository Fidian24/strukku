import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../core/utils/password_hasher.dart';
import '../../models/user_model.dart';
import '../local/app_database.dart';

/// Kontrak autentikasi. Implementasi: lokal (SQLite) atau FastAPI.
abstract class AuthRepository {
  Future<UserModel> login({required String email, required String password});

  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  });

  /// Pengguna yang sesi loginnya masih tersimpan (null jika belum login).
  Future<UserModel?> currentUser();

  Future<void> logout();
}

/// Autentikasi lokal (mode demo): akun disimpan di tabel users SQLite,
/// password disimpan sebagai hash + salt (bukan teks biasa).
class LocalAuthRepository implements AuthRepository {
  static const String _sessionKey = 'session_user_id';

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final db = await AppDatabase.instance;
    final normalized = email.trim().toLowerCase();

    final existing = await db.query('users',
        where: 'email = ?', whereArgs: [normalized], limit: 1);
    if (existing.isNotEmpty) {
      throw AppException('Email sudah terdaftar. Silakan login.');
    }

    final now = DateTime.now();
    final id = await db.insert('users', {
      'email': normalized,
      'password_hash': PasswordHasher.hash(password),
      'full_name': fullName.trim(),
      'created_at': now.toIso8601String(),
    });
    return UserModel(
        id: id, email: normalized, fullName: fullName.trim(), createdAt: now);
  }

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final db = await AppDatabase.instance;
    final rows = await db.query('users',
        where: 'email = ?', whereArgs: [email.trim().toLowerCase()], limit: 1);

    if (rows.isEmpty ||
        !PasswordHasher.verify(password, rows.first['password_hash'] as String)) {
      throw AppException('Email atau password salah');
    }

    final user = UserModel.fromJson(rows.first);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_sessionKey, user.id);
    return user;
  }

  @override
  Future<UserModel?> currentUser() async {
    final prefs = await SharedPreferences.getInstance();
    final id = prefs.getInt(_sessionKey);
    if (id == null) return null;

    final db = await AppDatabase.instance;
    final rows = await db.query('users', where: 'id = ?', whereArgs: [id], limit: 1);
    return rows.isEmpty ? null : UserModel.fromJson(rows.first);
  }

  @override
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
  }
}
