import '../../core/utils/receipt_parser.dart';
import '../../data/repositories/receipt_repository.dart';

/// Data yang dikirim dari halaman Pindai ke halaman Koreksi & Validasi.
class ScanResult {
  const ScanResult({
    required this.imagePath,
    required this.rawText,
    required this.parsed,
    required this.classification,
    this.isDemoSample = false,
  });

  /// Lokasi foto struk (null jika diisi manual tanpa gambar).
  final String? imagePath;

  /// Teks mentah hasil OCR.
  final String rawText;

  /// Hasil parsing regex (merchant, tanggal, total, item).
  final ParsedReceipt parsed;

  /// Hasil klasifikasi kategori; null jika klasifikasi gagal/dilewati.
  final ClassificationResult? classification;

  /// true jika memakai contoh struk demo (bukan hasil OCR gambar).
  final bool isDemoSample;
}
