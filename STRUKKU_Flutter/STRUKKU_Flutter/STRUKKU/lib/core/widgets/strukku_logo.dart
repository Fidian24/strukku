import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Logo STRUKKU: kotak biru berisi ikon struk + teks.
class StrukkuLogo extends StatelessWidget {
  const StrukkuLogo({super.key, this.size = 36});

  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(size * 0.28),
          ),
          child: Icon(Icons.receipt_long_outlined, color: Colors.white, size: size * 0.58),
        ),
        const SizedBox(width: 10),
        Text(
          'STRUKKU',
          style: TextStyle(
            fontSize: size * 0.62,
            fontWeight: FontWeight.w800,
            color: AppColors.navy,
            letterSpacing: 0.3,
          ),
        ),
      ],
    );
  }
}
