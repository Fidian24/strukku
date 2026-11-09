import 'package:flutter/material.dart';

import '../features/dashboard/receipts_screen.dart';
import '../features/scanner/scan_result.dart';
import '../features/scanner/scanner_screen.dart';
import '../features/validation/validation_screen.dart';
import '../models/user_model.dart';

/// Nama rute halaman di luar bottom navigation.
class AppRoutes {
  AppRoutes._();

  static const String scanner = '/scanner';
  static const String validation = '/validation';
  static const String receipts = '/receipts';
}

/// Argumen untuk halaman Koreksi & Validasi.
class ValidationArgs {
  const ValidationArgs({required this.user, required this.scan});

  final UserModel user;
  final ScanResult scan;
}

/// Pembuat rute terpusat. Halaman utama (Beranda/Kategori/Profil) diatur
/// oleh MainShell; rute di sini adalah halaman yang dibuka di atasnya.
class AppRouter {
  AppRouter._();

  static Route<dynamic>? generate(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.scanner:
        final user = settings.arguments as UserModel;
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => ScannerScreen(user: user),
        );
      case AppRoutes.validation:
        final args = settings.arguments as ValidationArgs;
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => ValidationScreen(user: args.user, scan: args.scan),
        );
      case AppRoutes.receipts:
        final user = settings.arguments as UserModel;
        return MaterialPageRoute<dynamic>(
          settings: settings,
          builder: (_) => ReceiptsScreen(user: user),
        );
    }
    return null;
  }
}
