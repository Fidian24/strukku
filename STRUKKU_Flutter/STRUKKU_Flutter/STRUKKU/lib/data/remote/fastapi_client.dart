import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/errors/app_exception.dart';
import 'api_config.dart';
import 'api_routes.dart';

/// Klien HTTP untuk backend STRUKKU (FastAPI, JSON).
///
/// - Menambahkan prefix `/api/v1` dan header `Authorization: Bearer ...`.
/// - Menyimpan access_token + refresh_token di SharedPreferences.
/// - Jika access token kedaluwarsa (401), otomatis memanggil
///   `POST /auth/refresh` satu kali lalu mengulang request.
/// - Error backend `{"detail": "...", "code": "..."}` diubah menjadi AppException.
class FastApiClient {
  FastApiClient({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  static const String _accessKey = 'api_access_token';
  static const String _refreshKey = 'api_refresh_token';

  String? accessToken;
  String? refreshToken;

  /// Dipanggil ketika sesi tidak bisa diperpanjang (refresh token habis/dicabut).
  /// Diisi dari main.dart agar aplikasi kembali ke layar login.
  void Function()? onSessionExpired;

  Future<void>? _refreshing;

  // --------------------------------------------------------------- token
  Future<void> loadTokens() async {
    final prefs = await SharedPreferences.getInstance();
    accessToken = prefs.getString(_accessKey);
    refreshToken = prefs.getString(_refreshKey);
  }

  Future<void> saveTokens({required String access, String? refresh}) async {
    accessToken = access;
    if (refresh != null) refreshToken = refresh;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accessKey, access);
    if (refreshToken != null) await prefs.setString(_refreshKey, refreshToken!);
  }

  Future<void> clearTokens() async {
    accessToken = null;
    refreshToken = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_accessKey);
    await prefs.remove(_refreshKey);
  }

  // ---------------------------------------------------------------- HTTP
  Uri _uri(String path, [Map<String, String>? query]) {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.apiPrefix}$path');
    return (query == null || query.isEmpty) ? uri : uri.replace(queryParameters: query);
  }

  /// URL lengkap untuk path dari backend (mis. `image_url` = "/api/v1/receipts/1/image").
  String absoluteUrl(String path) =>
      path.startsWith('http') ? path : '${ApiConfig.baseUrl}$path';

  Map<String, String> get authHeaders => {
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      };

  Map<String, String> get _jsonHeaders => {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        ...authHeaders,
      };

  Future<dynamic> get(String path, {Map<String, String>? query, Duration? timeout}) =>
      _send(() => _client.get(_uri(path, query), headers: _jsonHeaders),
          timeout: timeout);

  Future<dynamic> post(String path,
          {Object? body, Duration? timeout, bool auth = true}) =>
      _send(
        () => _client.post(_uri(path),
            headers: _jsonHeaders, body: jsonEncode(body ?? const {})),
        timeout: timeout,
        retryOnUnauthorized: auth,
      );

  Future<dynamic> put(String path, {Object? body}) => _send(
      () => _client.put(_uri(path), headers: _jsonHeaders, body: jsonEncode(body ?? const {})));

  Future<dynamic> delete(String path) =>
      _send(() => _client.delete(_uri(path), headers: _jsonHeaders));

  /// Unggah satu file (multipart/form-data, field [field]).
  Future<dynamic> upload(String path, String filePath,
      {String field = 'file', Duration? timeout}) {
    return _send(() async {
      final req = http.MultipartRequest('POST', _uri(path))
        ..headers.addAll({'Accept': 'application/json', ...authHeaders})
        ..files.add(await http.MultipartFile.fromPath(field, filePath));
      return http.Response.fromStream(await _client.send(req));
    }, timeout: timeout ?? ApiConfig.longTimeout);
  }

  Future<dynamic> _send(
    Future<http.Response> Function() request, {
    Duration? timeout,
    bool retryOnUnauthorized = true,
  }) async {
    var res = await _raw(request, timeout);

    // Access token kedaluwarsa -> perbarui dengan refresh token, ulangi sekali.
    if (res.statusCode == 401 && retryOnUnauthorized && refreshToken != null) {
      final ok = await _tryRefresh();
      if (ok) {
        res = await _raw(request, timeout);
      }
    }

    final data = _decode(res);
    if (res.statusCode >= 200 && res.statusCode < 300) return data;

    if (res.statusCode == 401 && retryOnUnauthorized && accessToken != null) {
      await clearTokens();
      onSessionExpired?.call();
      throw AppException('Sesi login berakhir. Silakan login kembali.',
          statusCode: 401, code: 'SESSION_EXPIRED');
    }

    throw AppException(
      _detail(data) ?? 'Server mengembalikan kesalahan (kode ${res.statusCode}).',
      statusCode: res.statusCode,
      code: data is Map ? data['code']?.toString() : null,
    );
  }

  Future<http.Response> _raw(
      Future<http.Response> Function() request, Duration? timeout) async {
    try {
      return await request().timeout(timeout ?? ApiConfig.timeout);
    } on TimeoutException {
      throw AppException(
          'Server tidak merespons. Periksa alamat API (${ApiConfig.baseUrl}).');
    } on SocketException {
      throw AppException(
          'Tidak dapat terhubung ke server (${ApiConfig.baseUrl}). '
          'Pastikan backend berjalan dengan --host 0.0.0.0 dan alamatnya benar.');
    } on http.ClientException catch (e) {
      throw AppException('Koneksi ke server gagal: ${e.message}');
    }
  }

  Future<bool> _tryRefresh() async {
    // Jika beberapa request gagal bersamaan, cukup satu proses refresh.
    final running = _refreshing;
    if (running != null) {
      await running;
      return accessToken != null;
    }
    final completer = Completer<void>();
    _refreshing = completer.future;
    try {
      final res = await _client
          .post(_uri(ApiRoutes.refresh),
              headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
              body: jsonEncode({'refresh_token': refreshToken}))
          .timeout(ApiConfig.timeout);
      final data = _decode(res);
      if (res.statusCode == 200 && data is Map && data['access_token'] is String) {
        await saveTokens(
          access: data['access_token'] as String,
          refresh: data['refresh_token'] as String?,
        );
        return true;
      }
      return false;
    } catch (_) {
      return false;
    } finally {
      completer.complete();
      _refreshing = null;
    }
  }

  dynamic _decode(http.Response res) {
    try {
      final text = utf8.decode(res.bodyBytes);
      if (text.trim().isEmpty) return null;
      return jsonDecode(text);
    } on FormatException {
      return null;
    }
  }

  /// Format error backend: {"detail": "...", "code": "..."}; FastAPI bawaan: {"detail": [...]}.
  String? _detail(dynamic data) {
    if (data is! Map) return null;
    final detail = data['detail'] ?? data['message'];
    if (detail is String) return detail;
    if (detail is List) {
      final msgs = detail
          .map((e) => e is Map ? e['msg']?.toString() : e.toString())
          .whereType<String>()
          .toList();
      if (msgs.isNotEmpty) return msgs.join('\n');
    }
    return null;
  }
}
