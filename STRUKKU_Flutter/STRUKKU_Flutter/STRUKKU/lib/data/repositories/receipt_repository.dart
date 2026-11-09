import '../../models/dashboard_model.dart';
import '../../models/receipt_model.dart';

/// Prediksi kategori untuk satu nama barang.
class ItemPrediction {
  const ItemPrediction({
    required this.itemName,
    required this.categoryName,
    required this.confidence,
  });

  final String itemName;
  final String categoryName;

  /// Probabilitas 0..1 (confidence_score).
  final double confidence;
}

/// Hasil klasifikasi seluruh barang pada satu struk.
class ClassificationResult {
  const ClassificationResult({required this.predictions, required this.isSimulated});

  /// Urutan sama dengan daftar nama barang yang dikirim.
  final List<ItemPrediction> predictions;

  /// true jika hasil berasal dari simulasi (mode demo), bukan model ML asli.
  final bool isSimulated;
}

/// Kontrak data struk. Implementasi: MockReceiptRepository (lokal/demo)
/// dan FastApiReceiptRepository (backend Python, nonaktif secara default).
abstract class ReceiptRepository {
  /// Mengklasifikasikan nama-nama barang menjadi kategori + confidence.
  Future<ClassificationResult> classifyItems(List<String> itemNames);

  /// Menyimpan struk beserta item (termasuk koreksi kategori pengguna).
  Future<ReceiptModel> saveReceipt(ReceiptModel receipt);

  /// Riwayat struk, terbaru lebih dulu. [month] opsional untuk filter bulan.
  Future<List<ReceiptModel>> getReceipts(int userId, {DateTime? month});

  /// Ringkasan pengeluaran satu bulan (Beranda & Kategori).
  Future<DashboardModel> getDashboard(int userId, DateTime month);

  /// Bulan terbaru yang memiliki data (awal bulan), atau null jika belum ada.
  Future<DateTime?> latestMonthWithData(int userId);

  /// Daftar bulan yang memiliki data, terbaru lebih dulu.
  Future<List<DateTime>> availableMonths(int userId);

  Future<int> countReceipts(int userId);

  Future<void> deleteReceipt(int userId, int receiptId);
}
