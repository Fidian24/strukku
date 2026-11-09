/// Konfigurasi global aplikasi.
class AppConfig {
  AppConfig._();

  static const String appName = 'STRUKKU';

  /// MODE DATA.
  /// true (default) = pakai backend FastAPI strukku_backend
  ///                  (alamat server: lib/data/remote/api_config.dart).
  /// false          = mode lokal/demo: SQLite di perangkat + klasifikasi simulasi.
  ///
  /// Kembali ke mode demo tanpa mengubah kode:
  ///   flutter run --dart-define=USE_FASTAPI=false
  static const bool useFastApi =
      bool.fromEnvironment('USE_FASTAPI', defaultValue: true);

  /// Ambang confidence. Prediksi dengan confidence di bawah nilai ini
  /// ditandai kuning ("Periksa") di halaman Koreksi & Validasi Data.
  /// Nilai ini pilihan implementasi (belum ditentukan dokumen); ubah sesuai kebutuhan.
  static const double lowConfidenceThreshold = 0.70;

  /// Akun demo yang dibuat otomatis di database lokal (mode demo).
  static const String demoEmail = 'satria@gmail.com';
  static const String demoPassword = 'Strukku123';
  static const String demoFullName = 'Satria Pratama';
}
