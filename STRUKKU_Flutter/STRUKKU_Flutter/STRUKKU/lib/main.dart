import 'package:flutter/material.dart';

import 'app.dart';
import 'data/repositories/repository_provider.dart';
import 'features/auth/session_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Pilih implementasi repository: FastAPI (default) atau lokal/demo.
  // Lihat lib/core/constants/app_config.dart (useFastApi).
  AppRepositories.init();

  final session = SessionController(AppRepositories.instance.auth);
  // Jika token tidak bisa diperpanjang, kembalikan pengguna ke layar Login.
  AppRepositories.instance.client?.onSessionExpired = session.expire;
  runApp(StrukkuApp(session: session));
}
