import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/state_views.dart';
import '../../data/repositories/repository_provider.dart';
import '../../models/receipt_item_model.dart';
import '../../models/receipt_model.dart';
import '../../models/user_model.dart';

/// Detail satu struk (item, kategori, confidence) + tombol hapus.
Future<void> showReceiptDetailSheet(
  BuildContext context, {
  required UserModel user,
  required ReceiptModel receipt,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: Colors.white,
    builder: (ctx) => _ReceiptDetail(user: user, receipt: receipt),
  );
}

class _ReceiptDetail extends StatelessWidget {
  const _ReceiptDetail({required this.user, required this.receipt});

  final UserModel user;
  final ReceiptModel receipt;

  Future<void> _delete(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus struk?'),
        content: Text('Struk ${receipt.merchantName} akan dihapus dari data Anda.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Hapus', style: TextStyle(color: AppColors.danger))),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    try {
      await AppRepositories.instance.receipts.deleteReceipt(user.id, receipt.id!);
      AppState.dataVersion.value++;
      if (context.mounted) {
        // Snackbar ditampilkan lewat ScaffoldMessenger root, jadi tetap terlihat
        // setelah sheet ditutup.
        showAppSnackBar(context, 'Struk dihapus.');
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) showAppSnackBar(context, 'Gagal menghapus: $e', error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.65,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, controller) => ListView(
        controller: controller,
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
        children: [
          Text(receipt.merchantName,
              style: const TextStyle(
                  fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 2),
          Text(Fmt.longDate(receipt.transactionDate),
              style: const TextStyle(color: AppColors.textGrey)),
          const SizedBox(height: 12),
          Text(Fmt.rupiah(receipt.totalAmount),
              style: const TextStyle(
                  fontSize: 28, fontWeight: FontWeight.w800, color: AppColors.primary)),
          const SizedBox(height: 18),
          Text('Daftar belanja (${receipt.items.length} item)',
              style: const TextStyle(fontWeight: FontWeight.w800, color: AppColors.navy)),
          const SizedBox(height: 8),
          for (final item in receipt.items) _ItemRow(item: item),
          if ((receipt.itemsSum - receipt.totalAmount).abs() > 0.5)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text(
                  'Jumlah item ${Fmt.rupiah(receipt.itemsSum)} berbeda dari total struk '
                  '(mis. pajak atau biaya lain).',
                  style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
            ),
          const SizedBox(height: 20),
          OutlinedButton.icon(
            onPressed: () => _delete(context),
            icon: const Icon(Icons.delete_outline, color: AppColors.danger),
            label: const Text('Hapus struk', style: TextStyle(color: AppColors.danger)),
          ),
        ],
      ),
    );
  }
}

class _ItemRow extends StatelessWidget {
  const _ItemRow({required this.item});

  final ReceiptItemModel item;

  @override
  Widget build(BuildContext context) {
    final info = item.isUserCorrected
        ? 'Dikoreksi manual'
        : item.confidenceScore != null
            ? 'Kategori otomatis \u00B7 ${Fmt.percent(item.confidenceScore!)}'
            : 'Dipilih manual';
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(AppCategories.iconOf(item.categoryName),
              color: AppCategories.colorOf(item.categoryName), size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.itemName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.navy)),
                Text('${item.categoryName} \u00B7 $info',
                    style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
              ],
            ),
          ),
          Text(Fmt.rupiah(item.itemPrice),
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.navy)),
        ],
      ),
    );
  }
}
