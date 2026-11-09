import 'package:flutter_test/flutter_test.dart';
import 'package:strukku/core/constants/app_categories.dart';
import 'package:strukku/data/local/demo_data.dart';
import 'package:strukku/models/dashboard_model.dart';
import 'package:strukku/models/receipt_item_model.dart';
import 'package:strukku/models/receipt_model.dart';

void main() {
  group('ReceiptModel', () {
    final receipt = ReceiptModel(
      id: 1,
      userId: 7,
      merchantName: 'INDOMARET',
      transactionDate: DateTime(2026, 10, 21),
      totalAmount: 55500,
      createdAt: DateTime(2026, 10, 21, 8, 42),
      items: const [
        ReceiptItemModel(
            categoryId: 1,
            categoryName: 'F&B',
            itemName: 'Roti Tawar 500g',
            itemPrice: 22500,
            confidenceScore: 0.95),
        ReceiptItemModel(
            categoryId: 2,
            categoryName: 'Kesehatan',
            itemName: 'Vitamin C 10 tablet',
            itemPrice: 15000,
            confidenceScore: 0.62,
            isUserCorrected: true),
      ],
    );

    test('JSON bolak-balik mempertahankan field', () {
      final copy = ReceiptModel.fromJson(receipt.toJson());
      expect(copy.merchantName, 'INDOMARET');
      expect(copy.totalAmount, 55500);
      expect(copy.items.length, 2);
      expect(copy.items[1].isUserCorrected, isTrue);
      expect(copy.items[1].confidenceScore, 0.62);
    });

    test('nama field JSON sesuai kolom database', () {
      final json = receipt.toJson();
      expect(json.keys, containsAll(['user_id', 'merchant_name', 'transaction_date', 'total_amount']));
      final item = (json['items'] as List).first as Map<String, dynamic>;
      expect(item.keys, containsAll(['category_id', 'item_name', 'item_price', 'confidence_score', 'is_user_corrected']));
    });

    test('itemsSum menjumlahkan harga item', () {
      expect(receipt.itemsSum, 37500);
    });
  });

  group('ReceiptItemModel.toDbMap', () {
    test('boolean disimpan sebagai 0/1', () {
      const item = ReceiptItemModel(
          categoryId: 1, itemName: 'Kopi', itemPrice: 1000, isUserCorrected: true);
      expect(item.toDbMap(5)['is_user_corrected'], 1);
      expect(item.toDbMap(5)['receipt_id'], 5);
    });
  });

  group('DashboardModel', () {
    final dash = DashboardModel(
      month: DateTime(2026, 10),
      totalAmount: 1000,
      receiptCount: 2,
      categoryTotals: const [
        CategoryTotal(categoryName: 'F&B', total: 500),
        CategoryTotal(categoryName: 'Belanja', total: 250),
      ],
    );

    test('persentase dihitung dari jumlah kategori', () {
      expect(dash.categorySum, 750);
      expect(dash.fractionFor('F&B'), closeTo(2 / 3, 1e-9));
      expect(dash.totalFor('Kesehatan'), 0);
      expect(dash.fractionFor('Kesehatan'), 0);
    });

    test('fromJson membaca bulan YYYY-MM', () {
      final d = DashboardModel.fromJson({
        'month': '2026-10',
        'total_amount': 100,
        'receipt_count': 1,
      });
      expect(d.month, DateTime(2026, 10));
      expect(d.categoryTotals, isEmpty);
    });
  });

  group('DemoData (konsisten dengan mockup Figma)', () {
    test('24 struk, total Rp1.250.000', () {
      expect(DemoData.receipts.length, 24);
      expect(DemoData.totalAmount, 1250000);
    });

    test('total per kategori', () {
      final t = DemoData.categoryTotals;
      expect(t[AppCategories.fnb], 625000);
      expect(t[AppCategories.transportasi], 250000);
      expect(t[AppCategories.kesehatan], 187500);
      expect(t[AppCategories.belanja], 125000);
      expect(t[AppCategories.lainnya], 62500);
    });

    test('tiga struk terbaru: Indomaret, Kopi Kenangan, Grab', () {
      final sorted = [...DemoData.receipts]..sort((a, b) => b.day.compareTo(a.day));
      expect(sorted[0].merchant, 'INDOMARET');
      expect(sorted[0].total, 55500);
      expect(sorted[1].merchant, 'Kopi Kenangan');
      expect(sorted[1].total, 48000);
      expect(sorted[2].merchant, 'Grab');
      expect(sorted[2].total, 32000);
    });

    test('seluruh kategori demo dikenal', () {
      for (final r in DemoData.receipts) {
        for (final i in r.items) {
          expect(AppCategories.names, contains(i.category));
        }
      }
    });
  });
}
