import 'package:flutter/foundation.dart';

import '../../core/app_state.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/user_model.dart';

/// Menyimpan pengguna yang sedang login. Perubahan memicu pergantian
/// halaman Login <-> Beranda di app.dart.
class SessionController extends ChangeNotifier {
  SessionController(this._auth);

  final AuthRepository _auth;

  UserModel? user;
  bool restoring = true;

  /// Memulihkan sesi tersimpan saat aplikasi dibuka.
  Future<void> restore() async {
    try {
      user = await _auth.currentUser();
    } catch (_) {
      user = null; // database/sesi bermasalah -> minta login ulang
    }
    restoring = false;
    notifyListeners();
  }

  void setUser(UserModel value) {
    AppState.reset();
    user = value;
    notifyListeners();
  }

  /// Sesi habis di server (refresh token tidak berlaku) -> kembali ke Login.
  void expire() {
    if (user == null) return;
    user = null;
    AppState.reset();
    notifyListeners();
  }

  Future<void> logout() async {
    try {
      await _auth.logout();
    } catch (_) {
      // Tetap keluar walaupun server tidak terjangkau.
    }
    user = null;
    AppState.reset();
    notifyListeners();
  }
}
