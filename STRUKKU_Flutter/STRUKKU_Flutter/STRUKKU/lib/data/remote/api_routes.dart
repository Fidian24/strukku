/// Endpoint backend STRUKKU (strukku_backend, FastAPI).
/// Semua path relatif terhadap ApiConfig.apiPrefix (`/api/v1`).
/// Referensi lengkap: strukku_backend/docs/API_FRONTEND.md atau http://<host>:8000/docs
class ApiRoutes {
  ApiRoutes._();

  static const String health = '/health';

  // Autentikasi
  static const String register = '/auth/register';
  static const String login = '/auth/login';
  static const String refresh = '/auth/refresh';
  static const String logout = '/auth/logout';
  static const String me = '/auth/me';

  // Kategori
  static const String categories = '/categories';

  // Klasifikasi kategori dari nama barang: {"texts": [...]}
  static const String classify = '/classify';

  // Pindai struk di server (multipart, field "file")
  static const String scans = '/scans';

  // Struk
  static const String receipts = '/receipts';
  static String receiptById(int id) => '/receipts/$id';

  // Dashboard & analitik
  static const String dashboard = '/dashboard';
  static const String analyticsMonthly = '/analytics/monthly';
}
