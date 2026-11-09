import 'package:flutter_test/flutter_test.dart';
import 'package:strukku/core/utils/receipt_parser.dart';

void main() {
  const sample = 'INDOMARET\n'
      'Jl. Raya Malang No. 12\n'
      '21 Oktober 2026 08:42\n'
      'Roti Tawar 500g 22.500\n'
      'Susu UHT 1L 18.000\n'
      'Vitamin C 10 tablet 15.000\n'
      'TOTAL 55.500\n'
      'TUNAI 60.000\n'
      'KEMBALI 4.500';

  group('ReceiptParser', () {
    test('mengambil merchant, tanggal, total, dan item', () {
      final r = ReceiptParser.parse(sample);
      expect(r.merchantName, 'INDOMARET');
      expect(r.transactionDate, DateTime(2026, 10, 21));
      expect(r.totalAmount, 55500);
      expect(r.items.map((i) => i.name).toList(),
          ['Roti Tawar 500g', 'Susu UHT 1L', 'Vitamin C 10 tablet']);
      expect(r.items.map((i) => i.price).toList(), [22500, 18000, 15000]);
    });

    test('baris tunai/kembali/alamat tidak dianggap barang', () {
      final r = ReceiptParser.parse(sample);
      expect(r.items.length, 3);
    });

    test('format tanggal numerik dan singkatan bulan', () {
      expect(ReceiptParser.parse('TOKO\n05/10/2026\nKopi 12.000').transactionDate,
          DateTime(2026, 10, 5));
      expect(ReceiptParser.parse('TOKO\n5 Okt 2026\nKopi 12.000').transactionDate,
          DateTime(2026, 10, 5));
      expect(ReceiptParser.parse('TOKO\n2026-10-05\nKopi 12.000').transactionDate,
          DateTime(2026, 10, 5));
    });

    test('tanggal tidak valid ditolak', () {
      expect(ReceiptParser.parse('TOKO\n31/02/2026\nKopi 12.000').transactionDate, isNull);
    });

    test('total tidak ditemukan -> null (tidak ditebak)', () {
      final r = ReceiptParser.parse('TOKO\nKopi 12.000');
      expect(r.totalAmount, isNull);
      expect(r.items.length, 1);
    });

    test('teks tanpa struk -> isEmpty', () {
      expect(ReceiptParser.parse('').isEmpty, isTrue);
      expect(ReceiptParser.parse('   \n  ').isEmpty, isTrue);
    });

    test('subtotal tidak dipakai sebagai total', () {
      final r = ReceiptParser.parse('TOKO\nKopi 12.000\nSUBTOTAL 12.000\nTOTAL 13.200');
      expect(r.totalAmount, 13200);
    });
  });
}
