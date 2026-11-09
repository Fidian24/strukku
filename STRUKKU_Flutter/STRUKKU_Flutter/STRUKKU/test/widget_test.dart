import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:strukku/core/errors/app_exception.dart';
import 'package:strukku/core/theme/app_theme.dart';
import 'package:strukku/data/repositories/auth_repository.dart';
import 'package:strukku/features/auth/auth_screen.dart';
import 'package:strukku/models/user_model.dart';

/// Repository palsu agar widget dapat diuji tanpa SQLite/backend.
class _FakeAuthRepository implements AuthRepository {
  int registerCalls = 0;

  @override
  Future<UserModel> login({required String email, required String password}) async {
    if (email == 'a@b.co' && password == 'Passw0rd1') {
      return UserModel(id: 1, email: email, fullName: 'Uji Coba', createdAt: DateTime(2026));
    }
    throw AppException('Email atau password salah');
  }

  @override
  Future<UserModel> register({
    required String fullName,
    required String email,
    required String password,
  }) async {
    registerCalls++;
    return UserModel(id: 2, email: email, fullName: fullName, createdAt: DateTime(2026));
  }

  @override
  Future<UserModel?> currentUser() async => null;

  @override
  Future<void> logout() async {}
}

Future<void> _pump(WidgetTester tester, _FakeAuthRepository repo,
    {ValueChanged<UserModel>? onAuth}) async {
  // Ukuran layar ponsel 390 x 844 dp.
  tester.view.physicalSize = const Size(1170, 2532);
  tester.view.devicePixelRatio = 3.0;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(MaterialApp(
    theme: AppTheme.light,
    home: AuthScreen(authRepository: repo, onAuthenticated: onAuth ?? (_) {}),
  ));
}

void main() {
  testWidgets('Login kosong menampilkan pesan validasi', (tester) async {
    await _pump(tester, _FakeAuthRepository());

    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pump();

    expect(find.text('Email wajib diisi'), findsOneWidget);
    expect(find.text('Password wajib diisi'), findsOneWidget);
  });

  testWidgets('Login berhasil memanggil onAuthenticated', (tester) async {
    UserModel? result;
    await _pump(tester, _FakeAuthRepository(), onAuth: (u) => result = u);

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.co');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Passw0rd1');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(result?.email, 'a@b.co');
  });

  testWidgets('Login gagal menampilkan pesan error dari repository', (tester) async {
    await _pump(tester, _FakeAuthRepository());

    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'a@b.co');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'salah12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Login'));
    await tester.pumpAndSettle();

    expect(find.text('Email atau password salah'), findsOneWidget);
  });

  testWidgets('Register: konfirmasi password harus sama', (tester) async {
    final repo = _FakeAuthRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    expect(find.text('Konfirmasi Password'), findsWidgets);

    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Nadia');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'nadia@mail.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Passw0rd1');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Konfirmasi Password'), 'Beda12345');
    await tester.tap(find.widgetWithText(FilledButton, 'Buat Akun'));
    await tester.pump();

    expect(find.text('Konfirmasi password tidak sama'), findsOneWidget);
    expect(repo.registerCalls, 0);
  });

  testWidgets('Register berhasil kembali ke Login dengan pesan sukses', (tester) async {
    final repo = _FakeAuthRepository();
    await _pump(tester, repo);

    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, 'Full Name'), 'Nadia');
    await tester.enterText(find.widgetWithText(TextFormField, 'Email'), 'nadia@mail.com');
    await tester.enterText(find.widgetWithText(TextFormField, 'Password'), 'Passw0rd1');
    await tester.enterText(
        find.widgetWithText(TextFormField, 'Konfirmasi Password'), 'Passw0rd1');
    await tester.tap(find.widgetWithText(FilledButton, 'Buat Akun'));
    await tester.pumpAndSettle();

    expect(repo.registerCalls, 1);
    expect(find.text('Akun berhasil dibuat. Silakan login.'), findsOneWidget);
  });
}
