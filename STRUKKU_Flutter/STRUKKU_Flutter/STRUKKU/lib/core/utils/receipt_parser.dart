import 'formatters.dart';

/// Satu baris barang hasil parsing teks OCR.
class ParsedItem {
  const ParsedItem(this.name, this.price);

  final String name;
  final double price;
}

/// Hasil parsing teks OCR struk. Semua field boleh null jika tidak ditemukan.
class ParsedReceipt {
  const ParsedReceipt({
    this.merchantName,
    this.transactionDate,
    this.totalAmount,
    this.items = const [],
  });

  final String? merchantName;
  final DateTime? transactionDate;
  final double? totalAmount;
  final List<ParsedItem> items;

  bool get isEmpty =>
      merchantName == null &&
      transactionDate == null &&
      totalAmount == null &&
      items.isEmpty;
}

/// Parsing teks mentah OCR menjadi merchant, tanggal, total, dan daftar barang
/// menggunakan aturan regex (tahap "Smart Parsing" pada flowchart).
class ReceiptParser {
  ReceiptParser._();

  static final RegExp _isoDate = RegExp(r'(\d{4})-(\d{1,2})-(\d{1,2})');
  static final RegExp _textDate =
      RegExp(r'(\d{1,2})\s+([A-Za-z]{3,9})\.?,?\s+(\d{4})');
  static final RegExp _numericDate =
      RegExp(r'(\d{1,2})[/\-.](\d{1,2})[/\-.](\d{2,4})');
  static final RegExp _numberToken = RegExp(r'^[\d.,]+$');
  static final RegExp _rpPrefix = RegExp(r'\bRp\.?\s*', caseSensitive: false);

  /// Baris yang bukan barang (ringkasan pembayaran, metode bayar, info struk).
  static final RegExp _skipLine = RegExp(
    r'\b(total|subtotal|sub total|grand total|tunai|cash|kembali|kembalian|change|bayar|'
    r'ppn|pajak|tax|pb1|diskon|discount|disc|kasir|cashier|npwp|telp|tel|phone|hp|wa|'
    r'kartu|debit|kredit|credit|card|qris|member|edc|transfer|bca|bri|bni|mandiri|cimb|'
    r'btn|bsi|permata|ovo|gopay|go-pay|dana|shopeepay|linkaja|flazz|brizzi|tapcash|'
    r'e-money|emoney|visa|mastercard|service|biaya|pembulatan|rounding|sisa|receipt|'
    r'order|bill|invoice|collected|table|meja|notes?|admin|saldo|poin|point|voucher)\b'
    r'|terima kasih|thank|struk|harga jual|jumlah item|total item|www\.|\.com|\S+@\S+\.\S+',
    caseSensitive: false,
  );

  /// Baris alamat toko (OCR sering membaca "Jl." sebagai "J1." / "Ji.").
  static final RegExp _addressLine = RegExp(
    r'(^|[\s,])(j[l1i]\.|jl\b|jln\b|jalan\b|kec\.|kec\b|kecamatan|kel\.|kelurahan|'
    r'kab\.|kabupaten|kota\b|provinsi|desa\b|blok\b|ruko\b|gedung|'
    r'jawa|sumatera|sumatra|kalimantan|sulawesi|bali\b|papua|dki\b|diy\b|'
    r'rt\.?\s*\d|rw\.?\s*\d|no\.\s*\d)'
    r'|,\s*\d{5}\b',
    caseSensitive: false,
  );

  /// Token jumlah / harga satuan di akhir nama, mis. "x1", "2x", "3", "@3.500".
  static final RegExp _qtyToken =
      RegExp(r'^(x\d+|\d+x|x|@[\d.,]*|\d{1,3})$', caseSensitive: false);

  static bool _isNonItem(String line) =>
      _skipLine.hasMatch(line) || _addressLine.hasMatch(line);

  static const Map<String, int> _monthByPrefix = {
    'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4, 'mei': 5, 'may': 5, 'jun': 6,
    'jul': 7, 'agu': 8, 'aug': 8, 'sep': 9, 'okt': 10, 'oct': 10,
    'nov': 11, 'des': 12, 'dec': 12,
  };

  static ParsedReceipt parse(String rawText) {
    final lines = rawText
        .split(RegExp(r'[\r\n]+'))
        .map((l) => l.trim())
        .where((l) => l.isNotEmpty)
        .toList();

    final merchant = _findMerchant(lines);
    final items = <ParsedItem>[];
    var previousWasItem = false;
    for (final line in lines) {
      if (line == merchant) {
        previousWasItem = false;
        continue;
      }
      final item = _parseItemLine(line);
      if (item != null) {
        items.add(item);
        previousWasItem = true;
        continue;
      }
      // Lanjutan nama barang di baris berikutnya (mis. "Lotus Biscoff" lalu
      // "Freshmilk"): baris pendek tanpa angka tepat setelah baris barang.
      if (previousWasItem && _isNameContinuation(line)) {
        final last = items.removeLast();
        items.add(ParsedItem('${last.name} $line', last.price));
      }
      previousWasItem = false;
    }

    return ParsedReceipt(
      merchantName: merchant,
      transactionDate: _findDate(lines),
      totalAmount: _findTotal(lines),
      items: items,
    );
  }

  static bool _isNameContinuation(String line) {
    if (RegExp(r'\d').hasMatch(line)) return false;
    if (!RegExp(r'[A-Za-z]{3,}').hasMatch(line)) return false;
    if (_isNonItem(line)) return false;
    if (line.contains(':')) return false;
    return line.split(RegExp(r'\s+')).length <= 3;
  }

  /// Merchant = nama toko di bagian atas struk: baris berhuruf tanpa angka
  /// yang bukan alamat/info pembayaran. Jika tidak ada, pakai aturan lama.
  static String? _findMerchant(List<String> lines) {
    final top = lines.take(8);
    for (final line in top) {
      if (!RegExp(r'[A-Za-z]{3,}').hasMatch(line)) continue;
      if (RegExp(r'\d').hasMatch(line)) continue;
      if (_isNonItem(line)) continue;
      return line;
    }
    for (final line in lines) {
      if (!RegExp(r'[A-Za-z]{3,}').hasMatch(line)) continue;
      if (_isNonItem(line)) continue;
      if (_parseDate(line) != null) continue;
      if (_parseItemLine(line) != null) continue;
      return line;
    }
    return null;
  }

  static DateTime? _findDate(List<String> lines) {
    for (final line in lines) {
      if (line.toLowerCase().contains('total')) continue;
      final d = _parseDate(line);
      if (d != null) return d;
    }
    return null;
  }

  static DateTime? _parseDate(String line) {
    final iso = _isoDate.firstMatch(line);
    if (iso != null) {
      return _validDate(int.parse(iso.group(1)!), int.parse(iso.group(2)!),
          int.parse(iso.group(3)!));
    }
    final text = _textDate.firstMatch(line);
    if (text != null) {
      final month = _monthByPrefix[text.group(2)!.toLowerCase().substring(0, 3)];
      if (month != null) {
        return _validDate(
            int.parse(text.group(3)!), month, int.parse(text.group(1)!));
      }
    }
    final numeric = _numericDate.firstMatch(line);
    if (numeric != null) {
      var year = int.parse(numeric.group(3)!);
      if (year < 100) year += 2000;
      return _validDate(
          year, int.parse(numeric.group(2)!), int.parse(numeric.group(1)!));
    }
    return null;
  }

  /// Menolak tanggal tidak valid (misal 31/02/2026).
  static DateTime? _validDate(int year, int month, int day) {
    if (year < 2000 || month < 1 || month > 12 || day < 1 || day > 31) {
      return null;
    }
    final d = DateTime(year, month, day);
    return (d.year == year && d.month == month && d.day == day) ? d : null;
  }

  static double? _findTotal(List<String> lines) {
    for (final line in lines) {
      final low = line.toLowerCase();
      if (!low.contains('total')) continue;
      if (low.contains('subtotal') ||
          low.contains('sub total') ||
          low.contains('item') ||
          low.contains('qty')) {
        continue;
      }
      final amount = _lastAmount(line);
      if (amount != null && amount >= 100) return amount;
    }
    return null;
  }

  static double? _lastAmount(String line) {
    final tokens = line.replaceAll(_rpPrefix, '').trim().split(RegExp(r'\s+'));
    for (var i = tokens.length - 1; i >= 0; i--) {
      if (_numberToken.hasMatch(tokens[i])) return Fmt.parseAmount(tokens[i]);
    }
    return null;
  }

  /// Baris barang: "<nama> [qty] [harga satuan] <harga>". Angka terakhir = harga.
  static ParsedItem? _parseItemLine(String line) {
    if (_isNonItem(line)) return null;
    if (_parseDate(line) != null) return null;
    final tokens = line
        .replaceAll(_rpPrefix, ' ')
        .trim()
        .split(RegExp(r'\s+'))
        .where((t) => t.isNotEmpty && t.toLowerCase() != 'rp')
        .toList();
    var end = tokens.length;
    final numbers = <String>[];
    while (end > 0 && _numberToken.hasMatch(tokens[end - 1])) {
      end--;
      numbers.insert(0, tokens[end]);
    }
    if (numbers.isEmpty || end == 0) return null;

    // Buang penanda jumlah di akhir nama, mis. "Lotus Biscoff x1".
    var nameTokens = tokens.sublist(0, end);
    while (nameTokens.length > 1 && _qtyToken.hasMatch(nameTokens.last)) {
      nameTokens = nameTokens.sublist(0, nameTokens.length - 1);
    }
    final name = nameTokens.join(' ').replaceAll(RegExp(r'[,:;]+$'), '').trim();
    if (!RegExp(r'[A-Za-z]{2,}').hasMatch(name)) return null;

    final price = Fmt.parseAmount(numbers.last);
    if (price == null || price < 100) return null;
    return ParsedItem(name, price);
  }
}
