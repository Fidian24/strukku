import 'receipt_item_model.dart';

/// Tabel receipts: id, user_id, merchant_name, transaction_date, total_amount,
/// image_url, created_at. `items` berasal dari tabel receipt_items.
class ReceiptModel {
  const ReceiptModel({
    this.id,
    required this.userId,
    required this.merchantName,
    required this.transactionDate,
    required this.totalAmount,
    this.imageUrl,
    required this.createdAt,
    this.items = const [],
  });

  final int? id;
  final int userId;
  final String merchantName;
  final DateTime transactionDate;
  final double totalAmount;
  final String? imageUrl;
  final DateTime createdAt;
  final List<ReceiptItemModel> items;

  /// Jumlah harga seluruh item (bisa berbeda dari total karena pajak/biaya lain).
  double get itemsSum => items.fold<double>(0, (s, i) => s + i.itemPrice);

  /// Kategori dominan (total harga item terbesar). Dipakai untuk memilih ikon.
  String? get mainCategoryName {
    if (items.isEmpty) return null;
    final totals = <String, double>{};
    for (final i in items) {
      totals[i.categoryName] = (totals[i.categoryName] ?? 0) + i.itemPrice;
    }
    return totals.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  ReceiptModel copyWith({int? id, List<ReceiptItemModel>? items, String? imageUrl}) =>
      ReceiptModel(
        id: id ?? this.id,
        userId: userId,
        merchantName: merchantName,
        transactionDate: transactionDate,
        totalAmount: totalAmount,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt,
        items: items ?? this.items,
      );

  factory ReceiptModel.fromJson(Map<String, dynamic> json) => ReceiptModel(
        id: (json['id'] as num?)?.toInt(),
        userId: (json['user_id'] as num).toInt(),
        merchantName: json['merchant_name'] as String,
        transactionDate: DateTime.parse('${json['transaction_date']}'),
        totalAmount: (json['total_amount'] as num).toDouble(),
        imageUrl: json['image_url'] as String?,
        createdAt: DateTime.tryParse('${json['created_at']}') ?? DateTime.now(),
        items: ((json['items'] as List?) ?? const [])
            .map((e) => ReceiptItemModel.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  Map<String, dynamic> toJson() => {
        if (id != null) 'id': id,
        'user_id': userId,
        'merchant_name': merchantName,
        'transaction_date': transactionDate.toIso8601String(),
        'total_amount': totalAmount,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
        'items': items.map((i) => i.toJson()).toList(),
      };
}
