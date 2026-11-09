import 'package:flutter/foundation.dart';

/// Konfigurasi koneksi ke backend FastAPI (strukku_backend).
///
/// Jalankan backend dengan `--host 0.0.0.0` (atau dobel klik
/// `jalankan_server.bat` di folder strukku_backend).
///
/// Alamat dasar (base URL) dipilih otomatis:
///  - Android (emulator)       : http://10.0.2.2:8000
///                               (10.0.2.2 = laptop/host dari dalam emulator)
///  - Windows / Web / iOS sim. : http://127.0.0.1:8000
///
/// HP fisik (Wi-Fi yang sama dengan laptop) WAJIB memakai IP laptop, mis.:
///   flutter run --dart-define=API_BASE_URL=http://192.168.1.10:8000
/// (cek IP laptop dengan `ipconfig`, bagian "IPv4 Address").
class ApiConfig {
  ApiConfig._();

  static const String _override = String.fromEnvironment('API_BASE_URL');

  /// Alamat server tanpa prefix API, tanpa garis miring di akhir.
  static String get baseUrl {
    if (_override.isNotEmpty) return _override.replaceAll(RegExp(r'/+$'), '');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
      return 'http://10.0.2.2:8000';
    }
    return 'http://127.0.0.1:8000';
  }

  /// Prefix semua endpoint backend (settings.API_PREFIX di backend).
  static const String apiPrefix = '/api/v1';

  static const Duration timeout = Duration(seconds: 20);

  /// Klasifikasi / unggah gambar bisa lebih lama.
  static const Duration longTimeout = Duration(seconds: 60);
}
