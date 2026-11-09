import 'package:flutter/material.dart';

import '../../core/constants/app_colors.dart';
import '../../core/constants/app_config.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/status_banner.dart';
import '../../data/repositories/auth_repository.dart';
import '../../models/user_model.dart';
import 'auth_header.dart';

/// Halaman autentikasi gabungan: tab Login dan Register (sesuai Figma).
class AuthScreen extends StatefulWidget {
  const AuthScreen({
    super.key,
    required this.authRepository,
    required this.onAuthenticated,
  });

  final AuthRepository authRepository;
  final ValueChanged<UserModel> onAuthenticated;

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _loginKey = GlobalKey<FormState>();
  final _registerKey = GlobalKey<FormState>();

  final _loginEmail = TextEditingController();
  final _loginPassword = TextEditingController();
  final _regName = TextEditingController();
  final _regEmail = TextEditingController();
  final _regPassword = TextEditingController();
  final _regConfirm = TextEditingController();

  bool _isLogin = true;
  bool _loading = false;
  String? _error;
  String? _notice;

  @override
  void dispose() {
    for (final c in [
      _loginEmail, _loginPassword, _regName, _regEmail, _regPassword, _regConfirm,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  void _switchTab(bool login) {
    if (_isLogin == login) return;
    setState(() {
      _isLogin = login;
      _error = null;
      _notice = null;
    });
  }

  Future<void> _submitLogin() async {
    if (!_loginKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
      _notice = null;
    });
    try {
      final user = await widget.authRepository
          .login(email: _loginEmail.text, password: _loginPassword.text);
      if (!mounted) return;
      setState(() => _loading = false);
      widget.onAuthenticated(user);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _loading = false;
      });
    }
  }

  Future<void> _submitRegister() async {
    if (!_registerKey.currentState!.validate()) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await widget.authRepository.register(
        fullName: _regName.text,
        email: _regEmail.text,
        password: _regPassword.text,
      );
      if (!mounted) return;
      // Sesuai Figma: setelah daftar, kembali ke Login dengan pesan sukses.
      setState(() {
        _loading = false;
        _isLogin = true;
        _notice = 'Akun berhasil dibuat. Silakan login.';
        _loginEmail.text = _regEmail.text.trim();
        _loginPassword.clear();
        _regPassword.clear();
        _regConfirm.clear();
      });
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Terjadi kesalahan: $e';
        _loading = false;
      });
    }
  }

  void _fillDemo() {
    setState(() {
      _loginEmail.text = AppConfig.demoEmail;
      _loginPassword.text = AppConfig.demoPassword;
      _error = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AuthHeader(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AuthTabs(isLogin: _isLogin, onChanged: _switchTab),
                        const SizedBox(height: 22),
                        if (_isLogin) _buildLogin() else _buildRegister(),
                      ],
                    ),
                  ),
                  const Spacer(),
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 18),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.shield_outlined, size: 14, color: AppColors.textGrey),
                          SizedBox(width: 6),
                          Text('Catatan keuangan pribadi, hanya untukmu.',
                              style: TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _title(String text) => Text(text,
      style: const TextStyle(
          fontSize: 28,
          height: 1.15,
          fontWeight: FontWeight.w800,
          color: AppColors.navy));

  Widget _subtitle(String text) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 18),
        child: Text(text,
            style: const TextStyle(fontSize: 13.5, color: AppColors.textGrey)),
      );

  Widget _buildLogin() {
    return Form(
      key: _loginKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Selamat datang\nkembali'),
          _subtitle('Masuk untuk melanjutkan pencatatan keuanganmu.'),
          AppTextField(
            controller: _loginEmail,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _loginPassword,
            label: 'Password',
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.required(v, 'Password'),
          ),
          const SizedBox(height: 12),
          if (_notice != null) ...[
            StatusBanner(type: BannerType.success, message: _notice!),
            const SizedBox(height: 12),
          ],
          if (_error != null) ...[
            StatusBanner(type: BannerType.error, message: _error!),
            const SizedBox(height: 12),
          ],
          PrimaryButton(label: 'Login', loading: _loading, onPressed: _submitLogin),
          const SizedBox(height: 14),
          Center(
            child: _SwitchLink(
              prefix: 'Belum punya akun? ',
              action: 'Register sekarang',
              onTap: () => _switchTab(false),
            ),
          ),
          if (!AppConfig.useFastApi) ...[
            const SizedBox(height: 6),
            Center(
              child: TextButton(
                onPressed: _fillDemo,
                child: const Text('Mode demo: isi akun demo',
                    style: TextStyle(fontSize: 12.5)),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRegister() {
    return Form(
      key: _registerKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _title('Buat akun\nSTRUKKU'),
          _subtitle('Daftar agar semua struk dan pengeluaranmu tersimpan rapi.'),
          AppTextField(
            controller: _regName,
            label: 'Full Name',
            textCapitalization: TextCapitalization.words,
            textInputAction: TextInputAction.next,
            validator: Validators.fullName,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _regEmail,
            label: 'Email',
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            validator: Validators.email,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _regPassword,
            label: 'Password',
            hint: 'Minimal 8 karakter, huruf dan angka',
            isPassword: true,
            textInputAction: TextInputAction.next,
            validator: Validators.password,
          ),
          const SizedBox(height: 12),
          AppTextField(
            controller: _regConfirm,
            label: 'Konfirmasi Password',
            isPassword: true,
            textInputAction: TextInputAction.done,
            validator: (v) => Validators.confirmPassword(v, _regPassword.text),
          ),
          const SizedBox(height: 12),
          if (_error != null) ...[
            StatusBanner(type: BannerType.error, message: _error!),
            const SizedBox(height: 12),
          ],
          PrimaryButton(label: 'Buat Akun', loading: _loading, onPressed: _submitRegister),
          const SizedBox(height: 14),
          Center(
            child: _SwitchLink(
              prefix: 'Sudah punya akun? ',
              action: 'Login di sini',
              onTap: () => _switchTab(true),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthTabs extends StatelessWidget {
  const _AuthTabs({required this.isLogin, required this.onChanged});

  final bool isLogin;
  final ValueChanged<bool> onChanged;

  Widget _tab(String label, bool selected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          height: 40,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: selected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: selected
                ? const [BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2))]
                : null,
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: selected ? AppColors.primary : AppColors.textGrey)),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F4F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          _tab('Login', isLogin, () => onChanged(true)),
          _tab('Register', !isLogin, () => onChanged(false)),
        ],
      ),
    );
  }
}

class _SwitchLink extends StatelessWidget {
  const _SwitchLink({required this.prefix, required this.action, required this.onTap});

  final String prefix;
  final String action;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text.rich(TextSpan(children: [
        TextSpan(
            text: prefix,
            style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
        TextSpan(
            text: action,
            style: const TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.primary)),
      ])),
    );
  }
}
