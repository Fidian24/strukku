import 'package:flutter/services.dart';

/// Format angka, mata uang Rupiah, dan tanggal berbahasa Indonesia
/// (tanpa package intl agar tidak bentrok versi).
class Fmt {
  Fmt._();

  static const List<String> _months = [
    'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
    'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember',
  ];
  static const List<String> _monthsShort = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des',
  ];

  /// 1250000 -> "1.250.000"
  static String number(num value) {
    final negative = value < 0;
    final digits = value.abs().round().toString();
    final grouped = digits.replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'), (m) => '.');
    return negative ? '-$grouped' : grouped;
  }

  /// 1250000 -> "Rp1.250.000" (sesuai tampilan Figma)
  static String rupiah(num value) => 'Rp${number(value)}';

  /// 20 Okt 2026
  static String shortDate(DateTime d) =>
      '${d.day} ${_monthsShort[d.month - 1]} ${d.year}';

  /// 21 Oktober 2026
  static String longDate(DateTime d) =>
      '${d.day} ${_months[d.month - 1]} ${d.year}';

  /// Oktober 2026
  static String monthYear(DateTime d) => '${_months[d.month - 1]} ${d.year}';

  /// 0.5 -> "50%"
  static String percent(double fraction) => '${(fraction * 100).round()}%';

  static String greeting(DateTime now) {
    final h = now.hour;
    if (h < 11) return 'Selamat pagi,';
    if (h < 15) return 'Selamat siang,';
    if (h < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  /// Mengubah teks nominal menjadi angka.
  /// "22.500" -> 22500, "Rp 22.500" -> 22500, "22.500,50" -> 22500.5
  static double? parseAmount(String input) {
    final s = input.replaceAll(RegExp(r'[^0-9.,]'), '');
    if (s.isEmpty) return null;
    final comma = s.lastIndexOf(',');
    // Koma dengan 1-2 digit di belakangnya dianggap pemisah desimal.
    if (comma != -1 && s.length - comma - 1 <= 2) {
      final intPart = s.substring(0, comma).replaceAll(RegExp(r'[.,]'), '');
      final dec = s.substring(comma + 1);
      return double.tryParse(
          '${intPart.isEmpty ? '0' : intPart}.${dec.isEmpty ? '0' : dec}');
    }
    return double.tryParse(s.replaceAll(RegExp(r'[.,]'), ''));
  }
}

/// Memformat input angka menjadi berpemisah ribuan saat mengetik (22500 -> 22.500).
class ThousandsInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue, TextEditingValue newValue) {
    var digits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length > 12) digits = digits.substring(0, 12);
    if (digits.isEmpty) {
      return const TextEditingValue(text: '');
    }
    final formatted = Fmt.number(int.parse(digits));
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: formatted.length),
    );
  }
}
