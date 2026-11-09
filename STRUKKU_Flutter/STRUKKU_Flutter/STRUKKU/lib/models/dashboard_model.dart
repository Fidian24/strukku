import 'receipt_model.dart';

/// Total pengeluaran satu kategori pada satu bulan.
class CategoryTotal {
  const CategoryTotal({required this.categoryName, required this.total});

  final String categoryName;
  final double total;

  factory CategoryTotal.fromJson(Map<String, dynamic> json) => CategoryTotal(
        categoryName: json['category_name'] as String,
        total: (json['total'] as num).toDouble(),
      );

  Map<String, dynamic> toJson() => {'category_name': categoryName, 'total': total};
}

/// Ringkasan pengeluaran satu bulan untuk Beranda & Kategori.
class DashboardModel {
  const DashboardModel({
    required this.month,
    required this.totalAmount,
    required this.receiptCount,
    this.categoryTotals = const [],
    this.recentReceipts = const [],
  });

  final DateTime month;

  /// Jumlah total_amount seluruh struk pada bulan tersebut.
  final double totalAmount;
  final int receiptCount;
  final List<CategoryTotal> categoryTotals;
  final List<ReceiptModel> recentReceipts;

  /// Jumlah seluruh total kategori (dasar perhitungan persentase).
  double get categorySum => categoryTotals.fold<double>(0, (s, c) => s + c.total);

  double totalFor(String categoryName) {
    for (final c in categoryTotals) {
      if (c.categoryName == categoryName) return c.total;
    }
    return 0;
  }

  /// Kontribusi kategori terhadap total (0..1).
  double fractionFor(String categoryName) {
    final sum = categorySum;
    return sum <= 0 ? 0 : totalFor(categoryName) / sum;
  }

  factory DashboardModel.fromJson(Map<String, dynamic> json) => DashboardModel(
        // Format API: "YYYY-MM" (contoh: "2026-10").
        month: DateTime.parse('${json['month']}-01'),
        totalAmount: (json['total_amount'] as num).toDouble(),
        receiptCount: (json['receipt_count'] as num).toInt(),
        categoryTotals: ((json['category_totals'] as List?) ?? const [])
            .map((e) => CategoryTotal.fromJson(e as Map<String, dynamic>))
            .toList(),
        recentReceipts: ((json['recent_receipts'] as List?) ?? const [])
            .map((e) => ReceiptModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );
}
