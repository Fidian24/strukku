import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/widgets/strukku_logo.dart';

/// Header halaman autentikasi: logo + ilustrasi struk + pil "Pindai. Cek. Simpan."
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 14, 20, 14),
          child: StrukkuLogo(),
        ),
        Container(
          height: 150,
          width: double.infinity,
          color: AppColors.primarySoft,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Transform.rotate(
                angle: -0.09,
                child: const _MiniReceipt(),
              ),
              Positioned(
                right: 18,
                bottom: 14,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: const [
                      BoxShadow(color: Color(0x332160DD), blurRadius: 10, offset: Offset(0, 4)),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.crop_free, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Pindai. Cek. Simpan.',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _MiniReceipt extends StatelessWidget {
  const _MiniReceipt();

  Widget _row(String name, String price) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(name, style: const TextStyle(fontSize: 9.5, color: AppColors.textGrey)),
            Text(price,
                style: const TextStyle(
                    fontSize: 9.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: const [
          BoxShadow(color: Color(0x1A2160DD), blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.shopping_bag_outlined, size: 13, color: AppColors.primary),
              SizedBox(width: 5),
              Text('INDOMARET',
                  style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 6),
          _row('Roti Tawar', '22.500'),
          _row('Susu UHT', '18.000'),
          _row('Vitamin C', '15.000'),
          const Divider(height: 10, color: AppColors.border),
          _row('TOTAL', 'Rp55.500'),
        ],
      ),
    );
  }
}
