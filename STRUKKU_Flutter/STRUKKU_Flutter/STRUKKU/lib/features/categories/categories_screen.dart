import 'package:flutter/material.dart';

import '../../core/app_state.dart';
import '../../core/constants/app_categories.dart';
import '../../core/constants/app_colors.dart';
import '../../core/utils/formatters.dart';
import '../../core/widgets/category_icon_box.dart';
import '../../core/widgets/state_views.dart';
import '../../data/repositories/repository_provider.dart';
import '../../models/category_model.dart';
import '../../models/dashboard_model.dart';
import '../../models/user_model.dart';

/// Halaman Kategori Pengeluaran: total & persentase tiap kategori.
/// Angka dihitung dari transaksi tersimpan (bukan nilai statis).
class CategoriesScreen extends StatefulWidget {
  const CategoriesScreen({super.key, required this.user, required this.onBack});

  final UserModel user;
  final VoidCallback onBack;

  @override
  State<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends State<CategoriesScreen> {
  List<CategoryModel> _categories = [];
  DashboardModel? _data;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    AppState.dataVersion.addListener(_load);
    AppState.selectedMonth.addListener(_load);
    _load();
  }

  @override
  void dispose() {
    AppState.dataVersion.removeListener(_load);
    AppState.selectedMonth.removeListener(_load);
    super.dispose();
  }

  Future<void> _load() async {
    final repos = AppRepositories.instance;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final month = AppState.selectedMonth.value ??
          await repos.receipts.latestMonthWithData(widget.user.id) ??
          DateTime.now();
      final results = await Future.wait<Object>([
        repos.categories.getCategories(),
        repos.receipts.getDashboard(widget.user.id, month),
      ]);
      if (!mounted) return;
      setState(() {
        _categories = results[0] as List<CategoryModel>;
        _data = results[1] as DashboardModel;
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
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(8, 8, 20, 4),
          child: Row(
            children: [
              IconButton(
                tooltip: 'Kembali ke Beranda',
                onPressed: widget.onBack,
                icon: const Icon(Icons.arrow_back, color: AppColors.navy),
              ),
              const Text('Kategori Pengeluaran',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.navy)),
            ],
          ),
        ),
        Expanded(child: _buildBody()),
      ],
    );
  }

  Widget _buildBody() {
    if (_loading && _data == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null && _data == null) {
      return Center(child: ErrorState(message: _error!, onRetry: _load));
    }
    final data = _data!;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
        children: [
          const Text(
              'Kenali ke mana uangmu pergi. Setiap item struk dikelompokkan ke kategori yang sesuai.',
              style: TextStyle(fontSize: 13.5, color: AppColors.textGrey, height: 1.4)),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.primarySoft,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(Fmt.monthYear(data.month),
                    style: const TextStyle(fontSize: 13.5, color: AppColors.textGrey)),
                Text(Fmt.rupiah(data.totalAmount),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary)),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Kategori standar',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.navy)),
              Text('${_categories.length} kategori',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          for (final c in _categories)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _CategoryCard(
                category: c,
                total: data.totalFor(c.name),
                fraction: data.fractionFor(c.name),
              ),
            ),
          const SizedBox(height: 4),
          const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(Icons.crop_free, size: 20, color: AppColors.textGrey),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                    'Kategori diprediksi otomatis per item. Kamu tetap bisa mengubahnya saat validasi struk.',
                    style: TextStyle(fontSize: 12, color: AppColors.textGrey, height: 1.4)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.total,
    required this.fraction,
  });

  final CategoryModel category;
  final double total;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final description = category.description.isNotEmpty
        ? category.description
        : (AppCategories.descriptions[category.name] ?? '');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CategoryIconBox(categoryName: category.name),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(category.name,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 2),
                Text(description,
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
                const SizedBox(height: 8),
                Text(Fmt.rupiah(total),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.primary)),
              ],
            ),
          ),
          Text(Fmt.percent(fraction),
              style: const TextStyle(fontSize: 12, color: AppColors.textGrey)),
        ],
      ),
    );
  }
}
