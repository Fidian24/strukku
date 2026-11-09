/// Exception dengan pesan yang aman ditampilkan ke pengguna.
class AppException implements Exception {
  AppException(this.message, {this.statusCode, this.code});

  final String message;
  final int? statusCode;

  /// Kode error dari backend, mis. INVALID_CREDENTIALS, EMAIL_TAKEN.
  final String? code;

  @override
  String toString() => message;
}
