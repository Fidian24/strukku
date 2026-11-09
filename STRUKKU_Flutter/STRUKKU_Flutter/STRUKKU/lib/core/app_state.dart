import 'package:flutter/foundation.dart';

/// State bersama sederhana antar-halaman (tanpa package tambahan).
class AppState {
  AppState._();

  /// Dinaikkan setiap kali data struk berubah (simpan/hapus) agar
  /// Beranda, Kategori, dan Riwayat memuat ulang datanya.
  static final ValueNotifier<int> dataVersion = ValueNotifier<int>(0);

  /// Bulan yang sedang dilihat. null = otomatis (bulan terbaru yang punya data).
  static final ValueNotifier<DateTime?> selectedMonth =
      ValueNotifier<DateTime?>(null);

  static void notifyDataChanged({DateTime? month}) {
    if (month != null) selectedMonth.value = DateTime(month.year, month.month);
    dataVersion.value++;
  }

  static void reset() {
    selectedMonth.value = null;
    dataVersion.value++;
  }
}
