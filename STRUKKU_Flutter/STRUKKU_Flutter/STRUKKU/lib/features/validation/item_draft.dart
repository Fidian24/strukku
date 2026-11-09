import 'package:flutter/material.dart';

import '../../core/constants/app_config.dart';
import '../../core/utils/formatters.dart';

/// Satu baris barang yang sedang diedit di halaman Koreksi & Validasi.
class ItemDraft {
  ItemDraft({
    required String name,
    double? price,
    this.categoryId,
    this.confidence,
  })  : originalCategoryId = categoryId,
        nameCtl = TextEditingController(text: name),
        priceCtl = TextEditingController(text: price == null ? '' : Fmt.number(price));

  final TextEditingController nameCtl;
  final TextEditingController priceCtl;

  /// Kategori terpilih saat ini (null = belum dipilih).
  int? categoryId;

  /// Kategori prediksi awal (null jika item ditambah manual / tanpa prediksi).
  final int? originalCategoryId;

  /// confidence_score prediksi ML (null untuk item manual).
  final double? confidence;

  double get price => Fmt.parseAmount(priceCtl.text) ?? 0;

  /// true jika pengguna mengganti kategori hasil prediksi (is_user_corrected).
  bool get isUserCorrected =>
      originalCategoryId != null &&
      categoryId != null &&
      categoryId != originalCategoryId;

  /// Perlu diperiksa: kategori belum dipilih, atau confidence di bawah ambang
  /// dan belum dikoreksi pengguna. (Ambang: AppConfig.lowConfidenceThreshold)
  bool get needsCheck {
    if (categoryId == null) return true;
    final c = confidence;
    return c != null && c < AppConfig.lowConfidenceThreshold && !isUserCorrected;
  }

  void dispose() {
    nameCtl.dispose();
    priceCtl.dispose();
  }
}
