import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

enum BannerType { success, warning, error, info }

/// Kotak informasi berwarna (sukses / peringatan kuning / error / info).
class StatusBanner extends StatelessWidget {
  const StatusBanner({
    super.key,
    required this.type,
    required this.message,
    this.title,
  });

  final BannerType type;
  final String? title;
  final String message;

  @override
  Widget build(BuildContext context) {
    late final Color bg, border, fg;
    late final IconData icon;
    switch (type) {
      case BannerType.success:
        bg = AppColors.successBg;
        border = const Color(0xFFCDEBD9);
        fg = AppColors.successText;
        icon = Icons.check_circle_outline;
        break;
      case BannerType.warning:
        bg = AppColors.warningBg;
        border = AppColors.warningBorder;
        fg = AppColors.warningText;
        icon = Icons.warning_amber_rounded;
        break;
      case BannerType.error:
        bg = const Color(0xFFFDECEC);
        border = const Color(0xFFF5C6C6);
        fg = AppColors.danger;
        icon = Icons.error_outline;
        break;
      case BannerType.info:
        bg = AppColors.primarySoft;
        border = const Color(0xFFD3E2FB);
        fg = AppColors.primaryDark;
        icon = Icons.info_outline;
        break;
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: fg, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Text(title!,
                      style: TextStyle(
                          color: fg, fontWeight: FontWeight.w700, fontSize: 14)),
                if (title != null) const SizedBox(height: 2),
                Text(message, style: TextStyle(color: fg, fontSize: 12.5, height: 1.35)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
