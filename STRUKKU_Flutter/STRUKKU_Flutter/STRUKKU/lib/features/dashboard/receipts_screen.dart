import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/widgets/receipt_tile.dart';
import '../../core/widgets/state_views.dart';
import '../../data/repositories/repository_provider.dart';
import '../../models/receipt_model.dart';
import '../../models/user_model.dart';
import 'receipt_detail_sheet.dart';

/// Riwayat seluruh struk ("Lihat semua" di Beranda).
class ReceiptsScreen extends StatefulWidget {
  const ReceiptsScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<ReceiptsScreen> createState() => _ReceiptsScreenState();
}

class _ReceiptsScreenState extends State<ReceiptsScreen> {
  List<ReceiptModel> _receipts = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppState.dataVersion.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppState.dataVersion.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final list = await AppRepositories.instance.receipts.getReceipts(widget.user.id);
      if (!mounted) return;
      setState(() {
        _receipts = list;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_loading && _receipts.isEmpty) {
      body = const Center(child: CircularProgressIndicator());
    } else if (_error != null && _receipts.isEmpty) {
      body = Center(child: ErrorState(message: _error!, onRetry: _load));
    } else if (_receipts.isEmpty) {
      body = const Center(
        child: EmptyState(
          title: 'Belum ada struk',
          message: 'Struk yang kamu simpan akan muncul di sini.',
        ),
      );
    } else {
      body = RefreshIndicator(
        onRefresh: _load,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          itemCount: _receipts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 10),
          itemBuilder: (context, i) {
            final r = _receipts[i];
            return ReceiptTile(
              receipt: r,
              onTap: () => showReceiptDetailSheet(context, user: widget.user, receipt: r),
            );
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Semua Struk')),
      body: body,
    );
  }
}
