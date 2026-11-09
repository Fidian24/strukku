import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../data/repositories/repository_provider.dart';
import '../../models/user_model.dart';

/// Profil sederhana: avatar, nama, email, info akun, dan tombol keluar.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key, required this.user, required this.onLogout});

  final UserModel user;
  final Future<void> Function() onLogout;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _receiptCount;

  @override
  void initState() {
    super.initState();
    AppState.dataVersion.addListener(_loadCount);
    _loadCount();
  }

  @override
  void dispose() {
    AppState.dataVersion.removeListener(_loadCount);
    super.dispose();
  }

  Future<void> _loadCount() async {
    try {
      final n = await AppRepositories.instance.receipts.countReceipts(widget.user.id);
      if (mounted) setState(() => _receiptCount = n);
    } catch (_) {
      if (mounted) setState(() => _receiptCount = null);
    }
  }

  Future<void> _confirmLogout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar dari akun?'),
        content: const Text('Kamu perlu login lagi untuk membuka catatan keuanganmu.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Keluar', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok == true) await widget.onLogout();
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 11),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
              child: Text(label,
                  style: const TextStyle(fontSize: 13.5, color: AppColors.textGrey))),
          Flexible(
            child: Text(value,
                textAlign: TextAlign.right,
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w700, color: AppColors.navy)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      children: [
        const Text('Profil',
            style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w800, color: AppColors.navy)),
        const SizedBox(height: 20),
        Center(
          child: Column(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppColors.primarySoft,
                child: Text(user.initial,
                    style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ),
              const SizedBox(height: 12),
              Text(user.fullName,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
              const SizedBox(height: 2),
              Text(user.email, style: const TextStyle(color: AppColors.textGrey)),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              _infoRow(Icons.event_outlined, 'Akun dibuat', Fmt.longDate(user.createdAt)),
              const Divider(height: 1, color: AppColors.border),
              _infoRow(Icons.receipt_long_outlined, 'Struk tersimpan',
                  _receiptCount?.toString() ?? '-'),
              const Divider(height: 1, color: AppColors.border),
              _infoRow(Icons.storage_outlined, 'Sumber data', AppRepositories.modeLabel),
            ],
          ),
        ),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: _confirmLogout,
          icon: const Icon(Icons.logout, color: AppColors.danger),
          label: const Text('Keluar', style: TextStyle(color: AppColors.danger)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: Color(0xFFF1C4C4)),
            backgroundColor: const Color(0xFFFFF7F7),
          ),
        ),
      ],
    );
  }
}
