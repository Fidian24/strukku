import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// OCR on-device memakai Google ML Kit Text Recognition (tanpa internet).
class OcrService {
  /// Mengembalikan teks mentah gambar. Baris kiri-kanan yang sejajar
  /// (nama barang di kiri, harga di kanan) digabung menjadi satu baris
  /// agar mudah diparsing oleh ReceiptParser.
  Future<String> recognize(String imagePath) async {
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    try {
      final result = await recognizer.processImage(InputImage.fromFilePath(imagePath));

      final lines = <TextLine>[
        for (final block in result.blocks) ...block.lines,
      ];
      if (lines.isEmpty) return '';

      // Urutkan dari atas ke bawah, lalu kelompokkan yang sebaris.
      lines.sort((a, b) =>
          a.boundingBox.center.dy.compareTo(b.boundingBox.center.dy));
      final rows = <List<TextLine>>[];
      for (final line in lines) {
        if (rows.isNotEmpty) {
          // Bandingkan dengan elemen terakhir di baris & pakai tinggi yang
          // lebih kecil, supaya judul berhuruf besar (nama toko) tidak
          // tergabung dengan baris alamat di bawahnya saat foto agak miring.
          final ref = rows.last.last.boundingBox;
          final box = line.boundingBox;
          final minHeight = box.height < ref.height ? box.height : ref.height;
          if ((box.center.dy - ref.center.dy).abs() < minHeight * 0.5) {
            rows.last.add(line);
            continue;
          }
        }
        rows.add([line]);
      }

      return rows.map((row) {
        row.sort((a, b) => a.boundingBox.left.compareTo(b.boundingBox.left));
        return row.map((l) => l.text).join(' ');
      }).join('\n');
    } finally {
      await recognizer.close();
    }
  }
}
