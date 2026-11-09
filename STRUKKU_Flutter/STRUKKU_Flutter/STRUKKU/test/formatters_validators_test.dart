import 'package:flutter_test/flutter_test.dart';
import 'package:strukku/core/utils/formatters.dart';
import 'package:strukku/core/utils/password_hasher.dart';
import 'package:strukku/core/utils/validators.dart';

void main() {
  group('Fmt', () {
    test('format angka dan rupiah', () {
      expect(Fmt.number(1250000), '1.250.000');
      expect(Fmt.number(0), '0');
      expect(Fmt.rupiah(55500), 'Rp55.500');
    });

    test('format tanggal Indonesia', () {
      expect(Fmt.shortDate(DateTime(2026, 10, 20)), '20 Okt 2026');
      expect(Fmt.longDate(DateTime(2026, 10, 21)), '21 Oktober 2026');
      expect(Fmt.monthYear(DateTime(2026, 10, 1)), 'Oktober 2026');
    });

    test('persen', () {
      expect(Fmt.percent(0.5), '50%');
      expect(Fmt.percent(0.0625), '6%');
    });

    test('parseAmount', () {
      expect(Fmt.parseAmount('22.500'), 22500);
      expect(Fmt.parseAmount('Rp 22.500'), 22500);
      expect(Fmt.parseAmount('22,500'), 22500);
      expect(Fmt.parseAmount('22.500,50'), 22500.5);
      expect(Fmt.parseAmount('abc'), isNull);
      expect(Fmt.parseAmount(''), isNull);
    });
  });

  group('Validators', () {
    test('email', () {
      expect(Validators.email(''), isNotNull);
      expect(Validators.email('nadia@'), isNotNull);
      expect(Validators.email('satria@gmail.com'), isNull);
    });

    test('password', () {
      expect(Validators.password('abc'), isNotNull);
      expect(Validators.password('abcdefgh'), isNotNull); // tanpa angka
      expect(Validators.password('12345678'), isNotNull); // tanpa huruf
      expect(Validators.password('Strukku123'), isNull);
    });

    test('konfirmasi password', () {
      expect(Validators.confirmPassword('beda', 'Strukku123'), isNotNull);
      expect(Validators.confirmPassword('Strukku123', 'Strukku123'), isNull);
    });

    test('nominal', () {
      expect(Validators.amount('', 'Total'), isNotNull);
      expect(Validators.amount('0', 'Total'), isNotNull);
      expect(Validators.amount('55.500', 'Total'), isNull);
    });
  });

  group('PasswordHasher', () {
    test('hash bukan teks asli dan dapat diverifikasi', () {
      final stored = PasswordHasher.hash('Strukku123');
      expect(stored.contains('Strukku123'), isFalse);
      expect(PasswordHasher.verify('Strukku123', stored), isTrue);
      expect(PasswordHasher.verify('salah123', stored), isFalse);
    });

    test('salt berbeda menghasilkan hash berbeda', () {
      expect(PasswordHasher.hash('Strukku123') == PasswordHasher.hash('Strukku123'), isFalse);
    });
  });
}
