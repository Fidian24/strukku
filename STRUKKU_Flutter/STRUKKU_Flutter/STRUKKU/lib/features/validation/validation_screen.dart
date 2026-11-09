import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/app_state.dart';
import '../../core/constants/app_colors.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/formatters.dart';
import '../../core/utils/validators.dart';
import '../../core/widgets/app_text_field.dart';
import '../../core/widgets/primary_button.dart';
import '../../core/widgets/state_views.dart';
import '../../core/widgets/status_banner.dart';
import '../../data/repositories/repository_provider.dart';
import '../../models/category_model.dart';
import '../../models/receipt_item_model.dart';
import '../../models/receipt_model.dart';
import '../../models/user_model.dart';
import '../scanner/scan_result.dart';
import 'item_draft.dart';

/// Halaman Koreksi & Validasi Data (tahap 2 dari 3: Pindai - Validasi - Simpan).
/// Pengguna memeriksa hasil OCR + klasifikasi, mengoreksi, lalu menyimpan.
class ValidationScreen extends StatefulWidget {
  const ValidationScreen({super.key, required this.user, required this.scan});

  final UserModel user;
  final ScanResult scan;

  @override
  State<ValidationScreen> createState() => _ValidationScreenState();
}

class _ValidationScreenState extends State<ValidationScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _merchantCtl;
  late final TextEditingController _dateCtl;
  late final TextEditingController _totalCtl;

  List<CategoryModel> _categories = [];
  final List<ItemDraft> _items = [];
  DateTime? _date;
  bool _loading = true;
  String? _loadError;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final parsed = widget.scan.parsed;
    _merchantCtl = TextEditingController(text: parsed.merchantName ?? '');
    _date = parsed.transactionDate;
    _dateCtl = TextEditingController(text: _date == null ? '' : Fmt.longDate(_date!));
    _totalCtl = TextEditingController(
        text: parsed.totalAmount == null ? '' : Fmt.number(parsed.totalAmount!));
    _loadCategories();
  }

  @override
  void dispose() {
    _merchantCtl.dispose();
    _dateCtl.dispose();
    _totalCtl.dispose();
    for (final i in _items) {
      i.dispose();
    }
    super.dispose();
  }

  Future<void> _loadCategories() async {
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final cats = await AppRepositories.instance.categories.getCategories();
      if (!mounted) return;

      final byName = {for (final c in cats) c.name: c.id};
      final parsedItems = widget.scan.parsed.items;
      final cls = widget.scan.classification;
      // Prediksi sejajar dengan urutan item; abaikan jika jumlahnya tidak cocok.
      final predictions = (cls != null && cls.predictions.length == parsedItems.length)
          ? cls.predictions
          : null;

      for (final i in _items) {
        i.dispose();
      }
      _items.clear();
      for (var n = 0; n < parsedItems.length; n++) {
        final pred = predictions?[n];
        _items.add(ItemDraft(
          name: parsedItems[n].name,
          price: parsedItems[n].price,
          categoryId: pred == null ? null : byName[pred.categoryName],
          confidence: pred?.confidence,
        ));
      }

      setState(() {
        _categories = cats;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loadError = e.toString();
        _loading = false;
      });
    }
  }

  double get _itemsSum => _items.fold<double>(0, (s, i) => s + i.price);
  int get _needsCheckCount => _items.where((i) => i.needsCheck).length;

  String _categoryName(int id) =>
      _categories.firstWhere((c) => c.id == id, orElse: () => const CategoryModel(id: 0, name: '')).name;

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: (_date != null && !_date!.isAfter(now)) ? _date! : now,
      firstDate: DateTime(2000),
      lastDate: now,
      helpText: 'Tanggal transaksi',
    );
    if (picked != null) {
      setState(() {
        _date = picked;
        _dateCtl.text = Fmt.longDate(picked);
      });
    }
  }

  void _addItem() => setState(() => _items.add(ItemDraft(name: '')));

  void _removeItem(int index) {
    setState(() => _items.removeAt(index).dispose());
  }

  /// Salin foto ke penyimpanan aplikasi agar tidak hilang saat cache dibersihkan.
  /// TODO (mode FastAPI): unggah gambar ke server dan pakai URL dari respons.
  Future<String?> _persistImage(String? path) async {
    if (path == null) return null;
    try {
      final dir = await getApplicationDocumentsDirectory();
      final folder = Directory(p.join(dir.path, 'receipts'));
      await folder.create(recursive: true);
      final dest = p.join(folder.path,
          'receipt_${DateTime.now().millisecondsSinceEpoch}${p.extension(path)}');
      await File(path).copy(dest);
      return dest;
    } catch (_) {
      return path;
    }
  }

  Future<void> _save() async {
    final formOk = _formKey.currentState!.validate();
    if (_items.isEmpty) {
      showAppSnackBar(context, 'Tambahkan minimal satu barang.', error: true);
      return;
    }
    if (_items.any((i) => i.categoryId == null)) {
      showAppSnackBar(context, 'Pilih kategori untuk setiap barang.', error: true);
      setState(() {}); // tampilkan penanda "Pilih"
      return;
    }
    if (!formOk) {
      showAppSnackBar(context, 'Periksa kembali data yang belum lengkap.', error: true);
      return;
    }

    setState(() => _saving = true);
    try {
      final now = DateTime.now();
      final imageUrl = await _persistImage(widget.scan.imagePath);

      final receipt = ReceiptModel(
        userId: widget.user.id,
        merchantName: _merchantCtl.text.trim(),
        transactionDate: _date!,
        // Total diambil dari isian pengguna (bisa berbeda dari jumlah item
        // karena pajak/biaya lain); tidak dipaksa sama.
        totalAmount: Fmt.parseAmount(_totalCtl.text)!,
        imageUrl: imageUrl,
        createdAt: now,
        items: [
          for (final i in _items)
            ReceiptItemModel(
              categoryId: i.categoryId!,
              categoryName: _categoryName(i.categoryId!),
              itemName: i.nameCtl.text.trim(),
              itemPrice: i.price,
              confidenceScore: i.confidence,
              isUserCorrected: i.isUserCorrected,
            ),
        ],
      );

      final saved = await AppRepositories.instance.receipts.saveReceipt(receipt);
      if (!mounted) return;

      AppState.notifyDataChanged(month: saved.transactionDate);
      showAppSnackBar(context, 'Struk berhasil disimpan.');
      Navigator.pop(context, saved);
    } on AppException catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'Gagal menyimpan: ${e.message}', error: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _saving = false);
      showAppSnackBar(context, 'Gagal menyimpan: $e', error: true);
    }
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Koreksi & Validasi Data')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: ErrorState(message: _loadError!, onRetry: _loadCategories))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    final sum = _itemsSum;
    final total = Fmt.parseAmount(_totalCtl.text);
    final hasDiff = total != null && _items.isNotEmpty && (total - sum).abs() > 0.5;
    final cls = widget.scan.classification;

    return Column(
      children: [
        Expanded(
          child: Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
              children: [
                const _StepIndicator(),
                const SizedBox(height: 14),
                _buildPreviewCard(),
                const SizedBox(height: 12),
                if (widget.scan.isDemoSample) ...[
                  const StatusBanner(
                    type: BannerType.info,
                    title: 'Contoh struk demo',
                    message: 'Data ini berasal dari contoh, bukan hasil pembacaan gambar.',
                  ),
                  const SizedBox(height: 12),
                ],
                if (cls != null && cls.isSimulated) ...[
                  const StatusBanner(
                    type: BannerType.info,
                    title: 'Mode demo',
                    message:
                        'Kategori diprediksi dengan simulasi, bukan model Machine Learning asli.',
                  ),
                  const SizedBox(height: 12),
                ],
                if (_needsCheckCount > 0) ...[
                  StatusBanner(
                    type: BannerType.warning,
                    title: '$_needsCheckCount kategori perlu diperiksa',
                    message:
                        'Prediksi belum pasti. Cek item bertanda kuning sebelum menyimpan.',
                  ),
                  const SizedBox(height: 14),
                ],
                AppTextField(
                  controller: _merchantCtl,
                  label: 'Nama Merchant',
                  textCapitalization: TextCapitalization.words,
                  validator: (v) => Validators.required(v, 'Nama merchant'),
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _dateCtl,
                  label: 'Tanggal',
                  readOnly: true,
                  onTap: _pickDate,
                  suffixIcon: const Icon(Icons.calendar_today_outlined,
                      size: 20, color: AppColors.textGrey),
                  validator: (_) => _date == null ? 'Tanggal transaksi wajib diisi' : null,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  controller: _totalCtl,
                  label: 'Total Nominal',
                  prefixText: 'Rp',
                  keyboardType: TextInputType.number,
                  inputFormatters: [ThousandsInputFormatter()],
                  onChanged: (_) => setState(() {}),
                  validator: (v) => Validators.amount(v, 'Total nominal'),
                ),
                const SizedBox(height: 22),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar belanja',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                    Text('${_items.length} item',
                        style: const TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ],
                ),
                const SizedBox(height: 10),
                if (_items.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                        'Belum ada barang terbaca. Tambahkan barang secara manual.',
                        style: TextStyle(color: AppColors.textGrey)),
                  ),
                for (var i = 0; i < _items.length; i++) _buildItemCard(i),
                OutlinedButton.icon(
                  onPressed: _addItem,
                  icon: const Icon(Icons.add),
                  label: const Text('Tambah Item'),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total ${_items.length} item',
                        style: const TextStyle(color: AppColors.textGrey, fontSize: 13.5)),
                    Text(Fmt.rupiah(sum),
                        style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: AppColors.navy)),
                  ],
                ),
                if (hasDiff)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                        'Total struk ${Fmt.rupiah(total)} berbeda dari jumlah item. '
                        'Biarkan jika ada pajak atau biaya lain; total tidak diubah otomatis.',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.warningText, height: 1.4)),
                  ),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildPreviewCard() {
    final path = widget.scan.imagePath;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primarySofter,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE3ECFB)),
      ),
      child: Row(
        children: [
          Container(
            width: 92,
            height: 104,
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: path != null
                ? Image.file(File(path),
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) =>
                        const Icon(Icons.image_not_supported_outlined, color: AppColors.textGrey))
                : const Icon(Icons.receipt_long_outlined, color: AppColors.textGrey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Hasil pindai struk',
                    style: TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.navy)),
                const SizedBox(height: 6),
                Text(
                    path == null
                        ? 'Diisi manual tanpa gambar'
                        : '${widget.scan.parsed.items.length} item terbaca dari gambar',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.textGrey)),
                const SizedBox(height: 10),
                if (path != null)
                  InkWell(
                    onTap: _showFullImage,
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('Lihat struk penuh',
                            style: TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primary)),
                        SizedBox(width: 4),
                        Icon(Icons.open_in_new, size: 14, color: AppColors.primary),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showFullImage() {
    final path = widget.scan.imagePath;
    if (path == null) return;
    showDialog<void>(
      context: context,
      builder: (ctx) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            InteractiveViewer(child: Image.file(File(path), fit: BoxFit.contain)),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: const Icon(Icons.close),
                style: IconButton.styleFrom(backgroundColor: Colors.white70),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    final warn = item.needsCheck;

    late final String info;
    if (item.categoryId == null) {
      info = 'Pilih kategori';
    } else if (item.isUserCorrected) {
      info = 'Dikoreksi manual';
    } else if (item.confidence != null) {
      info = 'Kategori otomatis \u00B7 ${Fmt.percent(item.confidence!)}';
    } else {
      info = 'Dipilih manual';
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.fromLTRB(14, 10, 8, 12),
      decoration: BoxDecoration(
        color: warn ? AppColors.warningBg : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: warn ? AppColors.warningBorder : AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: item.nameCtl,
                  validator: (v) => Validators.required(v, 'Nama barang'),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w700, color: AppColors.navy),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    hintText: 'Nama barang',
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              SizedBox(
                width: 118,
                child: TextFormField(
                  controller: item.priceCtl,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.right,
                  inputFormatters: [ThousandsInputFormatter()],
                  validator: (v) => Validators.amount(v, 'Harga'),
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                      fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.navy),
                  decoration: const InputDecoration(
                    isDense: true,
                    border: InputBorder.none,
                    prefixText: 'Rp',
                    hintText: '0',
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                  ),
                ),
              ),
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: 'Hapus item',
                  icon: const Icon(Icons.close, size: 18, color: AppColors.textGrey),
                  onPressed: () => _removeItem(index),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                width: 142,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                      color: warn ? AppColors.warningBorder : AppColors.border),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: item.categoryId,
                    isDense: true,
                    isExpanded: true,
                    hint: const Text('Pilih'),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.navy),
                    items: [
                      for (final c in _categories)
                        DropdownMenuItem<int>(value: c.id, child: Text(c.name)),
                    ],
                    // Mengganti kategori mengubah data & menandai koreksi manual.
                    onChanged: (v) {
                      if (v != null) setState(() => item.categoryId = v);
                    },
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Row(
                  children: [
                    if (warn) ...[
                      const Icon(Icons.warning_amber_rounded,
                          size: 16, color: AppColors.warningText),
                      const SizedBox(width: 4),
                    ],
                    Flexible(
                      child: Text(
                        warn && item.confidence != null
                            ? '${Fmt.percent(item.confidence!)} \u00B7 Periksa'
                            : info,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: item.isUserCorrected ? FontWeight.w700 : FontWeight.w500,
                          color: warn
                              ? AppColors.warningText
                              : (item.isUserCorrected
                                  ? AppColors.primary
                                  : AppColors.textGrey),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
                'Koreksi kategori akan disimpan untuk membantu prediksi selanjutnya.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11.5, color: AppColors.textGrey)),
            const SizedBox(height: 10),
            PrimaryButton(label: 'Save Data', loading: _saving, onPressed: _save),
          ],
        ),
      ),
    );
  }
}

/// Indikator tahap: Pindai (selesai) - Validasi (aktif) - Simpan.
class _StepIndicator extends StatelessWidget {
  const _StepIndicator();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Icon(Icons.check_circle_outline, size: 16, color: AppColors.primary),
        SizedBox(width: 4),
        Text('Pindai',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.primary)),
        _Line(),
        Text('2 Validasi',
            style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w800, color: AppColors.primary)),
        _Line(),
        Text('3 Simpan', style: TextStyle(fontSize: 12, color: AppColors.textGrey)),
      ],
    );
  }
}

class _Line extends StatelessWidget {
  const _Line();

  @override
  Widget build(BuildContext context) => Expanded(
        child: Container(
          height: 1,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          color: AppColors.border,
        ),
      );
}
