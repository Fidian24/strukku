import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_categories.dart';
import '../../models/dashboard_model.dart';
import '../../models/receipt_item_model.dart';
import '../../models/receipt_model.dart';
import '../local/app_database.dart';
import 'receipt_repository.dart';

/// Repository MODE LOKAL/DEMO.
///
/// - Penyimpanan: SQLite lokal (data benar-benar tersimpan di perangkat).
/// - Klasifikasi: SIMULASI berbasis kata kunci (bukan model TF-IDF/Naive Bayes).
///   Model ML asli ada di backend Python. Hasil simulasi selalu ditandai
///   "simulasi" di UI.
class MockReceiptRepository implements ReceiptRepository {
  // --------------------------------------------------------------------------
  // Klasifikasi simulasi
  // --------------------------------------------------------------------------

  /// Aturan demo: kata kunci -> kategori + confidence tetap.
  /// "vitamin" sengaja diberi 0.62 agar peringatan kuning (seperti di Figma)
  /// dapat dicoba. Barang yang tidak cocok -> "Lainnya" dengan confidence rendah.
  static const List<_Rule> _rules = [
    _Rule(['vitamin'], AppCategories.kesehatan, 0.62),
    _Rule(
        ['paracetamol', 'obat', 'masker', 'betadine', 'plester', 'sanitizer', 'antiseptik'],
        AppCategories.kesehatan,
        0.90),
    _Rule(
        ['pertalite', 'pertamax', 'solar', 'bensin', 'bbm', 'parkir', 'tol', 'grab',
          'gojek', 'ojek', 'taksi', 'tiket kereta'],
        AppCategories.transportasi,
        0.93),
    _Rule(
        ['kaos', 'baju', 'celana', 'sepatu', 'sabun', 'shampoo', 'deterjen', 'tisu', 'lampu'],
        AppCategories.belanja,
        0.88),
    _Rule(['pulsa', 'donasi', 'admin', 'pajak', 'iuran'], AppCategories.lainnya, 0.80),
    _Rule(
        ['roti', 'susu', 'kopi', 'teh', 'nasi', 'ayam', 'mie', 'mineral', 'telur', 'beras',
          'gula', 'minyak', 'snack', 'coklat', 'keju', 'yogurt', 'bakso', 'es', 'burger',
          'pizza', 'daging', 'bawang', 'air'],
        AppCategories.fnb,
        0.92),
  ];

  static const double _unknownConfidence = 0.40;

  @override
  Future<ClassificationResult> classifyItems(List<String> itemNames) async {
    // Simulasi waktu proses server.
    await Future<void>.delayed(const Duration(milliseconds: 600));

    final predictions = itemNames.map((name) {
      final lower = name.toLowerCase();
      final tokens = lower.split(RegExp(r'[^a-z0-9]+'));
      for (final rule in _rules) {
        final hit = rule.keywords.any(
            (k) => k.contains(' ') ? lower.contains(k) : tokens.contains(k));
        if (hit) {
          return ItemPrediction(
              itemName: name, categoryName: rule.category, confidence: rule.confidence);
        }
      }
      return ItemPrediction(
          itemName: name,
          categoryName: AppCategories.lainnya,
          confidence: _unknownConfidence);
    }).toList();

    return ClassificationResult(predictions: predictions, isSimulated: true);
  }

  // --------------------------------------------------------------------------
  // Penyimpanan & query (SQLite)
  // --------------------------------------------------------------------------

  @override
  Future<ReceiptModel> saveReceipt(ReceiptModel receipt) async {
    final db = await AppDatabase.instance;
    return db.transaction<ReceiptModel>((txn) async {
      final receiptId = await txn.insert('receipts', {
        'user_id': receipt.userId,
        'merchant_name': receipt.merchantName,
        'transaction_date': receipt.transactionDate.toIso8601String(),
        'total_amount': receipt.totalAmount,
        'image_url': receipt.imageUrl,
        'created_at': receipt.createdAt.toIso8601String(),
      });
      for (final item in receipt.items) {
        await txn.insert('receipt_items', item.toDbMap(receiptId));
      }
      return receipt.copyWith(id: receiptId);
    });
  }

  static List<Object?> _monthArgs(int userId, DateTime month) => [
        userId,
        DateTime(month.year, month.month).toIso8601String(),
        DateTime(month.year, month.month + 1).toIso8601String(),
      ];

  static const String _monthWhere =
      'r.user_id = ? AND r.transaction_date >= ? AND r.transaction_date < ?';

  @override
  Future<List<ReceiptModel>> getReceipts(int userId, {DateTime? month}) async {
    final db = await AppDatabase.instance;

    final where = month == null
        ? 'r.user_id = ?'
        : _monthWhere;
    final args = month == null ? <Object?>[userId] : _monthArgs(userId, month);

    final receiptRows = await db.rawQuery(
        'SELECT r.* FROM receipts r WHERE $where '
        'ORDER BY r.transaction_date DESC, r.id DESC',
        args);
    if (receiptRows.isEmpty) return [];

    final itemRows = await db.rawQuery(
        'SELECT i.*, c.name AS category_name FROM receipt_items i '
        'JOIN receipts r ON r.id = i.receipt_id '
        'JOIN categories c ON c.id = i.category_id '
        'WHERE $where ORDER BY i.id',
        args);

    final itemsByReceipt = <int, List<ReceiptItemModel>>{};
    for (final row in itemRows) {
      final item = ReceiptItemModel.fromJson(row);
      itemsByReceipt.putIfAbsent(item.receiptId!, () => []).add(item);
    }

    return receiptRows.map((row) {
      final base = ReceiptModel.fromJson(row);
      return base.copyWith(items: itemsByReceipt[base.id] ?? const []);
    }).toList();
  }

  @override
  Future<DashboardModel> getDashboard(int userId, DateTime month) async {
    final db = await AppDatabase.instance;
    final args = _monthArgs(userId, month);

    final totalRows = await db.rawQuery(
        'SELECT COALESCE(SUM(r.total_amount), 0) AS total, COUNT(*) AS cnt '
        'FROM receipts r WHERE $_monthWhere',
        args);

    final categoryRows = await db.rawQuery(
        'SELECT c.name AS category_name, SUM(i.item_price) AS total '
        'FROM receipt_items i '
        'JOIN receipts r ON r.id = i.receipt_id '
        'JOIN categories c ON c.id = i.category_id '
        'WHERE $_monthWhere GROUP BY c.id, c.name ORDER BY total DESC',
        args);

    final receipts = await getReceipts(userId, month: month);

    return DashboardModel(
      month: DateTime(month.year, month.month),
      totalAmount: (totalRows.first['total'] as num).toDouble(),
      receiptCount: (totalRows.first['cnt'] as num).toInt(),
      categoryTotals: categoryRows.map(CategoryTotal.fromJson).toList(),
      recentReceipts: receipts.take(3).toList(),
    );
  }

  @override
  Future<DateTime?> latestMonthWithData(int userId) async {
    final months = await availableMonths(userId);
    return months.isEmpty ? null : months.first;
  }

  @override
  Future<List<DateTime>> availableMonths(int userId) async {
    final db = await AppDatabase.instance;
    final rows = await db.rawQuery(
        'SELECT DISTINCT substr(transaction_date, 1, 7) AS ym FROM receipts '
        'WHERE user_id = ? ORDER BY ym DESC',
        [userId]);
    return rows
        .map((r) => DateTime.tryParse('${r['ym']}-01'))
        .whereType<DateTime>()
        .toList();
  }

  @override
  Future<int> countReceipts(int userId) async {
    final db = await AppDatabase.instance;
    final count = Sqflite.firstIntValue(await db
        .rawQuery('SELECT COUNT(*) FROM receipts WHERE user_id = ?', [userId]));
    return count ?? 0;
  }

  @override
  Future<void> deleteReceipt(int userId, int receiptId) async {
    final db = await AppDatabase.instance;
    // receipt_items ikut terhapus (ON DELETE CASCADE).
    await db.delete('receipts',
        where: 'id = ? AND user_id = ?', whereArgs: [receiptId, userId]);
  }
}

class _Rule {
  const _Rule(this.keywords, this.category, this.confidence);

  final List<String> keywords;
  final String category;
  final double confidence;
}
