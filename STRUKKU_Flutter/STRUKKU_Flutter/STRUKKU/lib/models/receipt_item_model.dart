/// Tabel receipt_items: id, receipt_id, category_id, item_name, item_price,
/// confidence_score, is_user_corrected.
class ReceiptItemModel {
  const ReceiptItemModel({
    this.id,
    this.receiptId,
    required this.categoryId,
    this.categoryName = '',
    required this.itemName,
    required this.itemPrice,
    this.confidenceScore,
    this.isUserCorrected = false,
  });

  final int? id;
  final int? receiptId;
  final int categoryId;

  /// Nama kategori (hasil JOIN, untuk tampilan). Bukan kolom tabel.
  final String categoryName;
  final String itemName;
  final double itemPrice;

  /// Probabilitas prediksi ML (0..1). null untuk item yang ditambah manual.
  final double? confidenceScore;
  final bool isUserCorrected;

  factory ReceiptItemModel.fromJson(Map<String, dynamic> json) {
    final corrected = json['is_user_corrected'];
    return ReceiptItemModel(
      id: (json['id'] as num?)?.toInt(),
      receiptId: (json['receipt_id'] as num?)?.toInt(),
      categoryId: (json['category_id'] as num).toInt(),
      categoryName: (json['category_name'] as String?) ?? '',
      itemName: json['item_name'] as String,
      itemPrice: (json['item_price'] as num).toDouble(),
      confidenceScore: (json['confidence_score'] as num?)?.toDouble(),
      isUserCorrected: corrected == true || corrected == 1,
    );
  }

  /// Format JSON untuk API (boolean asli).
  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        if (receiptId != null) 'receipt_id': receiptId,
        'category_id': categoryId,
        'item_name': itemName,
        'item_price': itemPrice,
        'confidence_score': confidenceScore,
        'is_user_corrected': isUserCorrected,
      };

  /// Format baris SQLite (boolean disimpan sebagai 0/1).
  Map<String, Object?> toDbMap(int receiptId) => {
        'receipt_id': receiptId,
        'category_id': categoryId,
        'item_name': itemName,
        'item_price': itemPrice,
        'confidence_score': confidenceScore,
        'is_user_corrected': isUserCorrected ? 1 : 0,
      };
}
