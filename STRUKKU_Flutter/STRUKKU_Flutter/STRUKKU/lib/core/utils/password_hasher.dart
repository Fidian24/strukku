import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';

/// Hash password SHA-256 + salt acak. Format tersimpan: "salt:hash".
/// Password asli tidak pernah disimpan.
///
/// Catatan: ini untuk akun lokal/mode demo. Saat backend FastAPI aktif,
/// hashing (bcrypt/argon2) sebaiknya dilakukan di server.
class PasswordHasher {
  PasswordHasher._();

  static String hash(String password, {String? salt}) {
    final s = salt ?? _randomSalt();
    final digest = sha256.convert(utf8.encode('$s:$password'));
    return '$s:$digest';
  }

  static bool verify(String password, String stored) {
    final i = stored.indexOf(':');
    if (i < 1) return false;
    final salt = stored.substring(0, i);
    return hash(password, salt: salt) == stored;
  }

  static String _randomSalt() {
    final random = Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64UrlEncode(bytes);
  }
}
