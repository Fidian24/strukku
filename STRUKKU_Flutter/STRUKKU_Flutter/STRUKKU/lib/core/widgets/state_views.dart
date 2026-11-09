import 'package:flutter/material.dart';

import '../constants/app_colors.dart';

/// Tampilan kosong (belum ada data).
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.title,
    required this.message,
    this.icon = Icons.receipt_long_outlined,
  });

  final String title;
  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 36, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
                color: AppColors.primarySoft, shape: BoxShape.circle),
            child: Icon(icon, size: 32, color: AppColors.primary),
          ),
          const SizedBox(height: 14),
          Text(title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontWeight: FontWeight.w700, fontSize: 16, color: AppColors.navy)),
          const SizedBox(height: 6),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.textGrey, height: 1.4)),
        ],
      ),
    );
  }
}

/// Tampilan error dengan tombol coba lagi.
class ErrorState extends StatelessWidget {
  const ErrorState({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 44, color: AppColors.textGrey),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: AppColors.navy)),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Coba Lagi'),
            style: OutlinedButton.styleFrom(minimumSize: const Size(160, 46)),
          ),
        ],
      ),
    );
  }
}

void showAppSnackBar(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      content: Text(message),
      behavior: SnackBarBehavior.floating,
      backgroundColor: error ? AppColors.danger : AppColors.navy,
    ));
}
