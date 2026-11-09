import 'package:flutter/material.dart';

import '../features/categories/categories_screen.dart';
import '../features/dashboard/dashboard_screen.dart';
import '../features/profile/profile_screen.dart';
import '../models/user_model.dart';
import 'app_router.dart';

/// Kerangka utama setelah login: Bottom Navigation (Beranda, Kategori, Profil).
class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user, required this.onLogout});

  final UserModel user;
  final Future<void> Function() onLogout;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;

  Future<void> _openScanner() async {
    await Navigator.pushNamed(context, AppRoutes.scanner, arguments: widget.user);
    // Data diperbarui lewat AppState.notifyDataChanged saat struk disimpan;
    // kembali ke tab Beranda agar struk baru langsung terlihat.
    if (mounted) setState(() => _index = 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            DashboardScreen(user: widget.user, onScan: _openScanner),
            CategoriesScreen(user: widget.user, onBack: () => setState(() => _index = 0)),
            ProfileScreen(user: widget.user, onLogout: widget.onLogout),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Color(0xFFEDF0F5))),
        ),
        child: NavigationBar(
          selectedIndex: _index,
          onDestinationSelected: (i) => setState(() => _index = i),
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home_rounded),
              label: 'Beranda',
            ),
            NavigationDestination(
              icon: Icon(Icons.grid_view_outlined),
              selectedIcon: Icon(Icons.grid_view_rounded),
              label: 'Kategori',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline),
              selectedIcon: Icon(Icons.person),
              label: 'Profil',
            ),
          ],
        ),
      ),
    );
  }
}
