import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/constants/app_colors.dart';
import '../../core/errors/app_exception.dart';
import '../../core/utils/receipt_parser.dart';
import '../../core/widgets/state_views.dart';
import '../../data/local/demo_data.dart';
import '../../data/repositories/receipt_repository.dart';
import '../../data/repositories/repository_provider.dart';
import '../../models/receipt_model.dart';
import '../../models/user_model.dart';
import '../../navigation/app_router.dart';
import 'ocr_service.dart';
import 'scan_result.dart';

/// Halaman Pindai Struk: kamera + bingkai, galeri, OCR, lalu ke validasi.
class ScannerScreen extends StatefulWidget {
  const ScannerScreen({super.key, required this.user});

  final UserModel user;

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> with WidgetsBindingObserver {
  final ImagePicker _picker = ImagePicker();
  final OcrService _ocr = OcrService();

  CameraController? _controller;
  bool _initializing = true;
  String? _cameraError;
  bool _torchOn = false;

  XFile? _captured;
  bool _processing = false;
  String _processingLabel = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Lepas kamera saat aplikasi di latar belakang, nyalakan lagi saat kembali.
    if (state == AppLifecycleState.inactive) {
      final c = _controller;
      if (c != null && mounted) {
        // Lepas dari UI dulu agar CameraPreview tidak memakai controller yang sudah dibuang.
        setState(() => _controller = null);
        c.dispose();
      }
    } else if (state == AppLifecycleState.resumed &&
        _controller == null &&
        _captured == null &&
        !_processing) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    setState(() {
      _initializing = true;
      _cameraError = null;
    });
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (!mounted) return;
        setState(() {
          _cameraError = 'Kamera tidak tersedia di perangkat ini. '
              'Kamu tetap bisa memilih gambar struk dari galeri.';
          _initializing = false;
        });
        return;
      }
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );
      final controller = CameraController(camera, ResolutionPreset.high, enableAudio: false);
      await controller.initialize();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _torchOn = false;
        _initializing = false;
      });
    } on CameraException catch (e) {
      if (!mounted) return;
      final denied = e.code.startsWith('CameraAccess');
      setState(() {
        _cameraError = denied
            ? 'Izin kamera ditolak. Aktifkan izin kamera di Pengaturan, '
                'atau pilih gambar struk dari galeri.'
            : 'Kamera tidak dapat dibuka (${e.description ?? e.code}). '
                'Kamu bisa memilih gambar dari galeri.';
        _initializing = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _cameraError = 'Kamera tidak dapat dibuka. Kamu bisa memilih gambar dari galeri.';
        _initializing = false;
      });
    }
  }

  Future<void> _toggleTorch() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized) return;
    try {
      await c.setFlashMode(_torchOn ? FlashMode.off : FlashMode.torch);
      setState(() => _torchOn = !_torchOn);
    } catch (_) {
      if (mounted) showAppSnackBar(context, 'Flash tidak tersedia di perangkat ini.', error: true);
    }
  }

  Future<void> _capture() async {
    final c = _controller;
    if (c == null || !c.value.isInitialized || c.value.isTakingPicture) return;
    try {
      final file = await c.takePicture();
      if (_torchOn) {
        await c.setFlashMode(FlashMode.off);
        _torchOn = false;
      }
      if (mounted) setState(() => _captured = file);
    } on CameraException catch (e) {
      if (mounted) {
        showAppSnackBar(context, 'Gagal mengambil foto: ${e.description ?? e.code}',
            error: true);
      }
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final file = await _picker.pickImage(source: ImageSource.gallery);
      if (file != null && mounted) setState(() => _captured = file);
    } catch (e) {
      if (mounted) showAppSnackBar(context, 'Galeri tidak dapat dibuka: $e', error: true);
    }
  }

  void _retake() {
    setState(() => _captured = null);
    if (_controller == null) _initCamera();
  }

  // --------------------------------------------------------------------------
  // Proses: OCR -> parsing -> klasifikasi -> halaman validasi
  // --------------------------------------------------------------------------

  Future<void> _useCaptured() async {
    final path = _captured?.path;
    if (path == null) return;

    setState(() {
      _processing = true;
      _processingLabel = 'Membaca teks struk...';
    });

    String rawText;
    try {
      rawText = await _ocr.recognize(path);
    } catch (e) {
      if (!mounted) return;
      setState(() => _processing = false);
      _showOcrFailedDialog(
          'Pembacaan teks gagal. Pastikan struk terang dan tidak buram.\n($e)');
      return;
    }

    final parsed = ReceiptParser.parse(rawText);
    if (!mounted) return;
    if (parsed.isEmpty) {
      setState(() => _processing = false);
      _showOcrFailedDialog(
          'Teks pada gambar tidak terbaca sebagai struk. Coba foto ulang dengan '
          'pencahayaan lebih baik, atau isi data secara manual.');
      return;
    }
    await _goToValidation(imagePath: path, rawText: rawText, parsed: parsed);
  }

  Future<void> _goToValidation({
    required String? imagePath,
    required String rawText,
    required ParsedReceipt parsed,
    bool isDemoSample = false,
  }) async {
    setState(() {
      _processing = true;
      _processingLabel = 'Mengklasifikasikan barang...';
    });

    ClassificationResult? classification;
    if (parsed.items.isNotEmpty) {
      try {
        classification = await AppRepositories.instance.receipts
            .classifyItems(parsed.items.map((i) => i.name).toList());
      } on AppException catch (e) {
        if (mounted) {
          showAppSnackBar(
              context, 'Klasifikasi gagal: ${e.message}. Pilih kategori secara manual.',
              error: true);
        }
      } catch (e) {
        if (mounted) {
          showAppSnackBar(
              context, 'Klasifikasi gagal: $e. Pilih kategori secara manual.',
              error: true);
        }
      }
    }
    if (!mounted) return;
    setState(() => _processing = false);

    // Catatan: tanpa parameter tipe <ReceiptModel>. AppRouter membuat
    // MaterialPageRoute<dynamic>, sehingga pushNamed<ReceiptModel> memicu
    // error tipe dan halaman validasi tidak pernah terbuka.
    debugPrint('[STRUKKU] buka halaman validasi: ${parsed.items.length} barang, '
        'total=${parsed.totalAmount}, klasifikasi=${classification?.predictions.length}');
    Object? result;
    try {
      result = await Navigator.pushNamed(
        context,
        AppRoutes.validation,
        arguments: ValidationArgs(
          user: widget.user,
          scan: ScanResult(
            imagePath: imagePath,
            rawText: rawText,
            parsed: parsed,
            classification: classification,
            isDemoSample: isDemoSample,
          ),
        ),
      );
    } catch (e, st) {
      debugPrint('[STRUKKU] gagal membuka halaman validasi: $e\n$st');
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Halaman validasi gagal dibuka'),
          content: SingleChildScrollView(child: Text('$e')),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
          ],
        ),
      );
      return;
    }
    debugPrint('[STRUKKU] kembali dari halaman validasi: ${result.runtimeType}');

    // Jika struk tersimpan, tutup halaman pindai dan kembali ke Beranda.
    if (result is ReceiptModel && mounted) Navigator.pop(context, result);
  }

  void _showOcrFailedDialog(String message) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Struk belum terbaca'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _retake();
            },
            child: const Text('Ulangi'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _goToValidation(
                  imagePath: _captured?.path, rawText: '', parsed: const ParsedReceipt());
            },
            child: const Text('Isi Manual'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _goToValidation(
                imagePath: _captured?.path,
                rawText: DemoData.sampleReceiptText,
                parsed: ReceiptParser.parse(DemoData.sampleReceiptText),
                isDemoSample: true,
              );
            },
            child: const Text('Pakai Contoh Demo'),
          ),
        ],
      ),
    );
  }

  // --------------------------------------------------------------------------
  // UI
  // --------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.scannerEdge,
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 1.0,
            colors: [AppColors.scannerCenter, AppColors.scannerEdge],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  _buildTopBar(),
                  Expanded(child: _buildFrameArea()),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Text(
                      _captured != null
                          ? 'Struk berhasil dipindai'
                          : 'Posisikan seluruh struk di dalam bingkai',
                      style: const TextStyle(color: Colors.white, fontSize: 12.5),
                    ),
                  ),
                  _buildBottomBar(),
                  const SizedBox(height: 18),
                ],
              ),
              if (_processing)
                Positioned.fill(
                  child: Container(
                    color: const Color(0xB3000000),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Colors.white),
                          const SizedBox(height: 16),
                          Text(_processingLabel,
                              style: const TextStyle(color: Colors.white, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _circleButton(IconData icon, VoidCallback? onTap, {String? tooltip, Color? color}) {
    return Tooltip(
      message: tooltip ?? '',
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 40,
          height: 40,
          decoration: const BoxDecoration(color: Color(0x33FFFFFF), shape: BoxShape.circle),
          child: Icon(icon, color: color ?? Colors.white, size: 20),
        ),
      ),
    );
  }

  Widget _buildTopBar() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _circleButton(Icons.close, _processing ? null : () => Navigator.pop(context),
              tooltip: 'Tutup'),
          const Text('Pindai Struk',
              style: TextStyle(
                  color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700)),
          _circleButton(
            _torchOn ? Icons.flash_on : Icons.flash_off,
            (_controller != null && _captured == null && !_processing) ? _toggleTorch : null,
            tooltip: 'Flash',
            color: _torchOn ? const Color(0xFFFFD54F) : Colors.white,
          ),
        ],
      ),
    );
  }

  Widget _buildFrameArea() {
    return LayoutBuilder(builder: (context, box) {
      final width = (box.maxWidth - 60).clamp(200.0, 340.0).toDouble();
      final height = (box.maxHeight - 16).clamp(200.0, 560.0).toDouble();

      Widget content;
      if (_captured != null) {
        content = Padding(
          padding: const EdgeInsets.all(18),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.scanGreen, width: 4),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Image.file(File(_captured!.path), fit: BoxFit.contain),
          ),
        );
      } else if (_initializing || _controller == null) {
        content = const Center(child: CircularProgressIndicator(color: Colors.white));
      } else if (_cameraError != null) {
        content = Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.no_photography_outlined, color: Colors.white70, size: 44),
                const SizedBox(height: 12),
                Text(_cameraError!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, height: 1.4)),
                const SizedBox(height: 16),
                FilledButton.icon(
                  onPressed: _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Pilih dari Galeri'),
                  style: FilledButton.styleFrom(minimumSize: const Size(200, 46)),
                ),
                TextButton(
                  onPressed: _initCamera,
                  child: const Text('Coba buka kamera lagi',
                      style: TextStyle(color: Colors.white70)),
                ),
              ],
            ),
          ),
        );
      } else {
        final c = _controller!;
        final size = c.value.previewSize;
        content = ClipRect(
          child: FittedBox(
            fit: BoxFit.cover,
            child: SizedBox(
              // previewSize berorientasi landscape; tukar untuk potret.
              width: size?.height ?? 1,
              height: size?.width ?? 1,
              child: CameraPreview(c),
            ),
          ),
        );
      }

      return Center(
        child: SizedBox(
          width: width,
          height: height,
          child: Stack(
            children: [
              Positioned.fill(child: ClipRRect(
                  borderRadius: BorderRadius.circular(6), child: content)),
              const Positioned.fill(child: IgnorePointer(child: CustomPaint(painter: _FramePainter()))),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildBottomBar() {
    final hasImage = _captured != null;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _squareButton(Icons.photo_library_outlined, _processing ? null : _pickFromGallery,
              'Galeri'),
          if (hasImage)
            FilledButton(
              onPressed: _processing ? null : _useCaptured,
              style: FilledButton.styleFrom(
                minimumSize: const Size(150, 50),
                shape: const StadiumBorder(),
              ),
              child: const Text('Gunakan Foto'),
            )
          else
            GestureDetector(
              onTap: (_controller != null && !_processing) ? _capture : null,
              child: Container(
                width: 74,
                height: 74,
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _controller != null ? Colors.white : Colors.white38,
                  ),
                ),
              ),
            ),
          _squareButton(Icons.refresh, _processing ? null : (hasImage ? _retake : _initCamera),
              hasImage ? 'Ulangi' : 'Muat ulang kamera'),
        ],
      ),
    );
  }

  Widget _squareButton(IconData icon, VoidCallback? onTap, String tooltip) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: const Color(0x33FFFFFF),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: Colors.white, size: 22),
        ),
      ),
    );
  }
}

/// Empat sudut bingkai putih (area penempatan struk).
class _FramePainter extends CustomPainter {
  const _FramePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;
    const len = 30.0;
    const r = 8.0;

    Path corner(double x, double y, double dx, double dy) => Path()
      ..moveTo(x, y + dy * len)
      ..lineTo(x, y + dy * r)
      ..quadraticBezierTo(x, y, x + dx * r, y)
      ..lineTo(x + dx * len, y);

    canvas.drawPath(corner(0, 0, 1, 1), paint);
    canvas.drawPath(corner(size.width, 0, -1, 1), paint);
    canvas.drawPath(corner(0, size.height, 1, -1), paint);
    canvas.drawPath(corner(size.width, size.height, -1, -1), paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
