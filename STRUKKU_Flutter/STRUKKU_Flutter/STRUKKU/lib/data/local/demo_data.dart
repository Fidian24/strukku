import '../../core/constants/app_categories.dart';
import '../../core/constants/app_config.dart';

/// ============================================================================
/// DATA DEMO (hanya untuk mode lokal/demo, TIDAK berasal dari backend).
/// Ganti/hapus file ini saat backend FastAPI sudah aktif.
///
/// Dirancang agar cocok dengan mockup Figma (Oktober 2026):
///   total Rp1.250.000 | 24 struk | F&B 625.000 | Transportasi 250.000
///   Kesehatan 187.500 | Belanja 125.000 | Lainnya 62.500
/// ============================================================================
class DemoItem {
  const DemoItem(this.name, this.price, this.category,
      {this.confidence = 0.92, this.corrected = false});

  final String name;
  final int price;
  final String category;
  final double confidence;
  final bool corrected;
}

class DemoReceipt {
  const DemoReceipt(this.merchant, this.day, this.items);

  final String merchant;
  final int day; // tanggal pada bulan demo
  final List<DemoItem> items;

  int get total => items.fold<int>(0, (s, i) => s + i.price);
}

class DemoData {
  DemoData._();

  static const int year = 2026;
  static const int month = 10;

  static const String fnb = AppCategories.fnb;
  static const String kes = AppCategories.kesehatan;
  static const String trans = AppCategories.transportasi;
  static const String belanja = AppCategories.belanja;
  static const String lain = AppCategories.lainnya;

  static const String demoEmail = AppConfig.demoEmail;

  /// Teks struk contoh (dipakai tombol "Pakai Contoh Demo" saat OCR gagal).
  static const String sampleReceiptText = 'INDOMARET\n'
      'Jl. Raya Malang No. 12\n'
      '21 Oktober 2026 08:42\n'
      'Roti Tawar 500g 22.500\n'
      'Susu UHT 1L 18.000\n'
      'Vitamin C 10 tablet 15.000\n'
      'TOTAL 55.500\n'
      'TUNAI 60.000\n'
      'KEMBALI 4.500';

  /// 24 struk. Urutan bebas; aplikasi mengurutkan berdasarkan tanggal.
  static const List<DemoReceipt> receipts = [
    DemoReceipt('INDOMARET', 20, [
      DemoItem('Roti Tawar 500g', 22500, fnb, confidence: 0.95),
      DemoItem('Susu UHT 1L', 18000, fnb, confidence: 0.93),
      DemoItem('Vitamin C 10 tablet', 15000, kes, confidence: 0.62),
    ]),
    DemoReceipt('Kopi Kenangan', 19, [
      DemoItem('Kopi Susu Kenangan', 48000, fnb, confidence: 0.97),
    ]),
    DemoReceipt('Grab', 18, [
      DemoItem('GrabBike', 32000, trans, confidence: 0.96),
    ]),
    DemoReceipt('Alfamart', 17, [
      DemoItem('Telur Ayam 1kg', 30000, fnb),
      DemoItem('Minyak Goreng 1L', 18500, fnb),
    ]),
    DemoReceipt('Warung Makan Bu Sri', 16, [
      DemoItem('Nasi Ayam Geprek', 25000, fnb, confidence: 0.94),
      DemoItem('Es Teh', 5000, fnb, confidence: 0.91),
    ]),
    DemoReceipt('SPBU Pertamina', 15, [
      DemoItem('Pertalite 8 L', 80000, trans, confidence: 0.98),
    ]),
    DemoReceipt('Superindo', 14, [
      DemoItem('Beras 5kg', 72000, fnb),
      DemoItem('Gula Pasir 1kg', 17000, fnb),
      DemoItem('Kopi Sachet', 12500, fnb),
    ]),
    DemoReceipt('Apotek K24', 14, [
      DemoItem('Paracetamol 500mg', 8500, kes, confidence: 0.96),
      DemoItem('Vitamin D3', 65000, kes, confidence: 0.88),
      DemoItem('Masker Medis', 15000, kes, confidence: 0.90),
    ]),
    DemoReceipt('Janji Jiwa', 13, [
      DemoItem('Es Kopi Susu', 24000, fnb, confidence: 0.95),
    ]),
    DemoReceipt('Indomaret', 12, [
      DemoItem('Air Mineral 1.5L', 8000, fnb),
      DemoItem('Roti Coklat', 12000, fnb),
      DemoItem('Yogurt Cup', 14000, fnb),
      DemoItem('Snack Keripik', 11500, fnb),
      DemoItem('Teh Botol', 6500, fnb),
    ]),
    DemoReceipt('Matahari', 12, [
      DemoItem('Kaos Polos Hitam', 75000, belanja, confidence: 0.89),
      DemoItem('Kaos Kaki 3 Pasang', 20000, belanja, confidence: 0.86),
    ]),
    DemoReceipt('Grab', 11, [
      DemoItem('GrabCar', 55000, trans, confidence: 0.96),
    ]),
    DemoReceipt('Warung Bakso Pak Min', 10, [
      DemoItem('Bakso Spesial', 28000, fnb),
      DemoItem('Es Jeruk', 7000, fnb),
    ]),
    DemoReceipt('Ace Hardware', 10, [
      DemoItem('Lampu LED', 30000, belanja, confidence: 0.84),
    ]),
    DemoReceipt('Roti O', 9, [
      DemoItem('Roti Boy', 15000, fnb),
      DemoItem('Kopi Hitam', 10000, fnb),
    ]),
    DemoReceipt('Guardian', 9, [
      DemoItem('Hand Sanitizer', 25000, kes),
      DemoItem('Betadine', 18000, kes),
      DemoItem('Plester Luka', 12000, kes),
    ]),
    DemoReceipt('Superindo', 8, [
      DemoItem('Ayam Fillet 500g', 45000, fnb),
      DemoItem('Susu UHT 1L', 18000, fnb),
      DemoItem('Keju Slice', 25000, fnb),
    ]),
    DemoReceipt('Alfamart', 8, [
      DemoItem('Pulsa Telkomsel', 50000, lain, confidence: 0.81),
      DemoItem('Biaya Admin', 2500, lain, confidence: 0.78),
      DemoItem('Donasi Kotak Amal', 10000, lain, confidence: 0.75),
    ]),
    DemoReceipt('Gojek', 7, [
      DemoItem('GoRide', 28000, trans, confidence: 0.95),
    ]),
    DemoReceipt('Kimia Farma', 6, [
      DemoItem('Obat Batuk Sirup', 29000, kes, confidence: 0.93),
    ]),
    DemoReceipt('Indomaret', 5, [
      DemoItem('Snack Kentang', 12000, fnb),
      DemoItem('Coklat Batang', 18000, fnb),
    ]),
    DemoReceipt('Superindo', 2, [
      DemoItem('Daging Sapi 500g', 65000, fnb),
      DemoItem('Bawang Merah', 12500, fnb),
    ]),
    DemoReceipt('KAI Commuter', 2, [
      DemoItem('Tiket Kereta Lokal', 55000, trans, confidence: 0.80),
    ]),
    DemoReceipt('Warung Makan Bu Sri', 1, [
      DemoItem('Nasi Pecel', 20000, fnb),
      DemoItem('Es Teh', 5000, fnb),
    ]),
  ];

  /// Total seluruh struk demo (Rp1.250.000).
  static int get totalAmount => receipts.fold<int>(0, (s, r) => s + r.total);

  /// Total demo per kategori.
  static Map<String, int> get categoryTotals {
    final result = <String, int>{};
    for (final r in receipts) {
      for (final i in r.items) {
        result[i.category] = (result[i.category] ?? 0) + i.price;
      }
    }
    return result;
  }
}
