import 'package:flutter/material.dart';

import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/strukku_logo.dart';
import 'data/repositories/repository_provider.dart';
import 'features/auth/auth_screen.dart';
import 'features/auth/session_controller.dart';
import 'navigation/app_router.dart';
import 'navigation/main_shell.dart';

/// Akar aplikasi. Halaman awal ditentukan oleh status sesi:
/// belum login -> AuthScreen, sudah login -> MainShell.
class StrukkuApp extends StatefulWidget {
  const StrukkuApp({super.key, required this.session});

  final SessionController session;

  @override
  State<StrukkuApp> createState() => _StrukkuAppState();
}

class _StrukkuAppState extends State<StrukkuApp> {
  @override
  void initState() {
    super.initState();
    widget.session.restore();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'STRUKKU',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.generate,
      home: ListenableBuilder(
        listenable: widget.session,
        builder: (context, _) {
          final session = widget.session;
          if (session.restoring) return const _SplashScreen();
          final user = session.user;
          if (user == null) {
            return AuthScreen(
              authRepository: AppRepositories.instance.auth,
              onAuthenticated: session.setUser,
            );
          }
          return MainShell(
            // key agar state tab di-reset ketika berganti akun
            key: ValueKey(user.id),
            user: user,
            onLogout: session.logout,
          );
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            StrukkuLogo(size: 44),
            SizedBox(height: 24),
            SizedBox(
              width: 26,
              height: 26,
              child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
            ),
          ],
        ),
      ),
    );
  }
}
