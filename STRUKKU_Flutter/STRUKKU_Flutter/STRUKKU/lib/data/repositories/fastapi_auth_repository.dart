import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import '../../models/category_model.dart';
import '../../models/user_model.dart';
import '../remote/api_routes.dart';
import '../remote/fastapi_client.dart';
import 'auth_repository.dart';
import 'category_repository.dart';

/// Autentikasi via backend STRUKKU (FastAPI).
///
/// POST /auth/login    {"email","password"}
///   -> {"access_token","refresh_token","token_type","expires_in","user":{...}}
/// POST /auth/register {"full_name","email","password"}
///   -> TokenOut (verifikasi email nonaktif) atau
///      {"message","email_verification_required":true,"user":{...}}
class FastApiAuthRepository implements AuthRepository {
  FastApiAuthRepository(this._client);

  final FastApiClient _client;
  static const String _userKey = 'api_user_json';

  @override
  Future<UserModel> login({required String email, required String password}) async {
    final data = await _client.post(ApiRoutes.login,
        body: {'email': email.trim(), 'password': password}, auth: false);
    if (data is! Map<String, dynamic> ||
        data['access_token'] is! String ||
        data['user'] is! Map<String, dynamic>) {
      throw AppException('Respons login dari server tidak sesuai format.');
    }
    await _client.saveTokens(
      access: data['access_token'] as String,
      refresh: data['refresh_token'] as String?,
    );
    final user = UserModel.fromJson(data['user'] as Map<String, dynamic>);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userKey, jsonEncode(user.toJson()));
    return user;
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final data = await _client.post(ApiRoutes.register, auth: false, body: {
      'full_name': fullName.trim(),
      'email': email.trim(),
      'password': password,
    });
    // Layar register kembali ke Login setelah sukses, jadi token dari
    // respons register sengaja tidak disimpan (pengguna login ulang).
    if (data is Map<String, dynamic> && data['user'] is Map<String, dynamic>) {
      if (data['email_verification_required'] == true) {
        throw AppException(
          'Akun dibuat, tetapi server mewajibkan verifikasi email. '
          'Set REQUIRE_EMAIL_VERIFICATION=false di .env backend untuk pengembangan.',
          code: 'EMAIL_VERIFICATION_REQUIRED',
        );
      }
      return UserModel.fromJson(data['user'] as Map<String, dynamic>);
    }
    return UserModel(
        id: 0, email: email.trim(), fullName: fullName.trim(), createdAt: DateTime.now());
  }

  @override
  Future<UserModel?> currentUser() async {
    await _client.loadTokens();
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString(_userKey);
    if (_client.accessToken == null || userJson == null) return null;

    final cached = UserModel.fromJson(jsonDecode(userJson) as Map<String, dynamic>);
    // Pastikan sesi masih berlaku (token diperbarui otomatis bila perlu).
    try {
      final data = await _client.get(ApiRoutes.me);
      if (data is Map<String, dynamic>) {
        final fresh = UserModel.fromJson(data);
        await prefs.setString(_userKey, jsonEncode(fresh.toJson()));
        return fresh;
      }
      return cached;
    } on AppException catch (e) {
      if (e.statusCode == 401) {
        await logout();
        return null;
      }
      // Server mati / tidak terjangkau: tetap masuk dengan data tersimpan.
      return cached;
    }
  }

  @override
  Future<void> logout() async {
    final refresh = _client.refreshToken;
    if (refresh != null && _client.accessToken != null) {
      try {
        await _client.post(ApiRoutes.logout, body: {'refresh_token': refresh}, auth: false);
      } catch (_) {
        // Abaikan: token lokal tetap dihapus.
      }
    }
    await _client.clearTokens();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userKey);
  }
}

/// Kategori via backend: GET /categories
/// -> [{"id","key","name","icon","color","description","sort_order"}]
class FastApiCategoryRepository implements CategoryRepository {
  FastApiCategoryRepository(this._client);

  final FastApiClient _client;
  List<CategoryModel>? _cache;

  @override
  Future<List<CategoryModel>> getCategories() async {
    final cached = _cache;
    if (cached != null) return cached;
    final data = await _client.get(ApiRoutes.categories);
    final list = (data is Map ? data['categories'] : data) as List? ?? const [];
    final result =
        list.map((e) => CategoryModel.fromJson(e as Map<String, dynamic>)).toList();
    _cache = result;
    return result;
  }
}
