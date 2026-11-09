import 'package:flutter/material.dart';

/// Lima kategori standar STRUKKU beserta tampilannya.
class AppCategories {
  AppCategories._();

  static const String fnb = 'F&B';
  static const String kesehatan = 'Kesehatan';
  static const String transportasi = 'Transportasi';
  static const String belanja = 'Belanja';
  static const String lainnya = 'Lainnya';

  /// Urutan sama dengan seed database (id 1..5).
  static const List<String> names = [fnb, kesehatan, transportasi, belanja, lainnya];

  static const Map<String, int> seedIds = {
    fnb: 1,
    kesehatan: 2,
    transportasi: 3,
    belanja: 4,
    lainnya: 5,
  };

  // Kategori dari backend (strukku_backend/app/data/category_catalog.json).
  static const String makanan = 'Makanan';
  static const String minuman = 'Minuman';
  static const String rumahTangga = 'Kebutuhan Rumah Tangga';
  static const String perawatanDiri = 'Perawatan Diri';

  static const Map<String, String> descriptions = {
    makanan: 'Makanan, camilan, dan bahan pangan',
    minuman: 'Minuman kemasan, kopi, teh, susu, dan air mineral',
    rumahTangga: 'Perlengkapan kebersihan dan kebutuhan rumah sehari-hari',
    perawatanDiri: 'Produk kebersihan badan, kosmetik, dan perawatan diri',
    fnb: 'Makanan, minuman, dan bahan pangan',
    kesehatan: 'Obat, vitamin, dan kebutuhan medis',
    transportasi: 'Ojek, taksi, BBM, dan angkutan umum',
    belanja: 'Pakaian dan kebutuhan rumah tangga',
    lainnya: 'Pengeluaran di luar kategori utama',
  };

  /// Warna segmen grafik distribusi (sesuai Figma).
  static Color colorOf(String name) {
    switch (name) {
      case makanan:
        return const Color(0xFF2563EB);
      case minuman:
        return const Color(0xFF14B8A6);
      case rumahTangga:
        return const Color(0xFF60A5FA);
      case perawatanDiri:
        return const Color(0xFFA855F7);
      case fnb:
        return const Color(0xFF2160DD);
      case transportasi:
        return const Color(0xFF1E9FAE);
      case kesehatan:
        return const Color(0xFF709CE0);
      case belanja:
        return const Color(0xFF9AA5B5);
      default:
        return const Color(0xFFCCD5E3);
    }
  }

  static IconData iconOf(String name) {
    switch (name) {
      case makanan:
      case fnb:
        return Icons.restaurant_outlined;
      case minuman:
        return Icons.local_cafe_outlined;
      case rumahTangga:
        return Icons.home_outlined;
      case perawatanDiri:
        return Icons.spa_outlined;
      case kesehatan:
        return Icons.favorite_border;
      case transportasi:
        return Icons.directions_bus_outlined;
      case belanja:
        return Icons.shopping_bag_outlined;
      default:
        return Icons.more_horiz;
    }
  }
}
