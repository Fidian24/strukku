import 'package:flutter/material.dart';

import '../../models/receipt_model.dart';
import '../constants/app_colors.dart';
import '../utils/formatters.dart';
import 'category_icon_box.dart';

/// Pilih ikon struk dari nama merchant, jika tidak cocok pakai kategori utama.
IconData receiptIcon(ReceiptModel r) {
  final m = r.merchantName.toLowerCase();
  if (m.contains('kopi') || m.contains('coffee') || m.contains('cafe')) {
    return Icons.local_cafe_outlined;
  }
  if (m.contains('grab') || m.contains('gojek') || m.contains('kai') || m.contains('bus')) {
    return Icons.directions_bus_outlined;
  }
  if (m.contains('apotek') || m.contains('kimia') || m.contains('guardian')) {
    return Icons.favorite_border;
  }
  return Icons.shopping_bag_outlined;
}

/// Satu baris struk (merchant, tanggal, total) seperti pada Figma.
class ReceiptTile extends StatelessWidget {
  const ReceiptTile({super.key, required this.receipt, this.onTap});

  final ReceiptModel receipt;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            children: [
              CategoryIconBox(icon: receiptIcon(receipt)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(receipt.merchantName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.navy)),
                    const SizedBox(height: 2),
                    Text(Fmt.shortDate(receipt.transactionDate),
                        style: const TextStyle(
                            color: AppColors.textGrey, fontSize: 12.5)),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(Fmt.rupiah(receipt.totalAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 15,
                      color: AppColors.navy)),
            ],
          ),
        ),
      ),
    );
  }
}
