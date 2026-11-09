import '../../core/constants/app_config.dart';
import '../remote/api_config.dart';
import '../remote/fastapi_client.dart';
import 'auth_repository.dart';
import 'category_repository.dart';
import 'fastapi_auth_repository.dart';
import 'fastapi_receipt_repository.dart';
import 'mock_receipt_repository.dart';
import 'receipt_repository.dart';

/// Titik tunggal pemilihan implementasi repository.
/// Mode ditentukan oleh AppConfig.useFastApi (default: true = backend FastAPI).
/// UI hanya mengenal interface (AuthRepository, ReceiptRepository, ...),
/// sehingga mengganti mode tidak mengubah kode tampilan.
class AppRepositories {
  AppRepositories._({
    required this.auth,
    required this.categories,
    required this.receipts,
    this.client,
  });

  final AuthRepository auth;
  final CategoryRepository categories;
  final ReceiptRepository receipts;

  /// Klien HTTP backend (null pada mode demo lokal).
  final FastApiClient? client;

  static late AppRepositories instance;

  static void init() {
    if (AppConfig.useFastApi) {
      final client = FastApiClient();
      instance = AppRepositories._(
        auth: FastApiAuthRepository(client),
        categories: FastApiCategoryRepository(client),
        receipts: FastApiReceiptRepository(client),
        client: client,
      );
    } else {
      instance = AppRepositories._(
        auth: LocalAuthRepository(),
        categories: LocalCategoryRepository(),
        receipts: MockReceiptRepository(),
      );
    }
  }

  static String get modeLabel =>
      AppConfig.useFastApi ? 'Server ${ApiConfig.baseUrl}' : 'Mode demo (lokal)';
}
