import 'formatters.dart';

/// Validator formulir (dipakai oleh TextFormField.validator).
/// Mengembalikan pesan error, atau null jika input valid.
class Validators {
  Validators._();

  static final RegExp _emailRe = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]{2,}$');

  static String? required(String? v, String fieldName) {
    if (v == null || v.trim().isEmpty) return '$fieldName wajib diisi';
    return null;
  }

  static String? email(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Email wajib diisi';
    if (!_emailRe.hasMatch(s)) return 'Format email belum lengkap';
    return null;
  }

  static String? fullName(String? v) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return 'Nama lengkap wajib diisi';
    if (s.length < 2) return 'Nama minimal 2 karakter';
    return null;
  }

  /// Minimal 8 karakter, mengandung huruf dan angka.
  static String? password(String? v) {
    final s = v ?? '';
    if (s.isEmpty) return 'Password wajib diisi';
    if (s.length < 8) return 'Password minimal 8 karakter';
    if (!RegExp(r'[A-Za-z]').hasMatch(s) || !RegExp(r'\d').hasMatch(s)) {
      return 'Password harus mengandung huruf dan angka';
    }
    return null;
  }

  static String? confirmPassword(String? v, String original) {
    if (v == null || v.isEmpty) return 'Konfirmasi password wajib diisi';
    if (v != original) return 'Konfirmasi password tidak sama';
    return null;
  }

  /// Nominal rupiah harus berupa angka lebih dari 0.
  static String? amount(String? v, String fieldName) {
    final s = v?.trim() ?? '';
    if (s.isEmpty) return '$fieldName wajib diisi';
    final n = Fmt.parseAmount(s);
    if (n == null) return '$fieldName tidak valid';
    if (n <= 0) return '$fieldName harus lebih dari 0';
    return null;
  }
}
