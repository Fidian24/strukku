import 'package:flutter/material.dart';

import '../constants/app_categories.dart';
import '../constants/app_colors.dart';

/// Kotak ikon biru muda (dipakai di kartu kategori & daftar struk).
class CategoryIconBox extends StatelessWidget {
  const CategoryIconBox({super.key, this.icon, this.categoryName, this.size = 44});

  final IconData? icon;
  final String? categoryName;
  final double size;

  @override
  Widget build(BuildContext context) {
    final data = icon ??
        (categoryName != null ? AppCategories.iconOf(categoryName!) : Icons.receipt_long_outlined);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Icon(data, color: AppColors.primary, size: size * 0.5),
    );
  }
}
