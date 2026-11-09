import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

import '../../core/constants/app_categories.dart';
import '../../core/constants/app_config.dart';
import '../../core/utils/password_hasher.dart';
import 'demo_data.dart';

/// Database SQLite lokal (mode demo/offline).
///
/// Struktur tabel SENGAJA sama dengan database utama PostgreSQL
/// (database/schema_postgresql.sql): users, categories, receipts, receipt_items.
/// Perbedaan hanya pada tipe data bawaan SQLite:
///   - DECIMAL  -> NUMERIC (disimpan sebagai angka rupiah)
///   - TIMESTAMP -> TEXT ISO-8601
///   - BOOLEAN  -> INTEGER 0/1
class AppDatabase {
  AppDatabase._();

  static Database? _db;
  static const String _fileName = 'strukku.db';

  static Future<Database> get instance async => _db ??= await _open();

  static Future<Database> _open() async {
    final path = p.join(await getDatabasesPath(), _fileName);
    return openDatabase(
      path,
      version: 1,
      onConfigure: (db) async {
        // Aktifkan foreign key + ON DELETE CASCADE.
        await db.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: _onCreate,
    );
  }

  static Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        email         TEXT NOT NULL UNIQUE,
        password_hash TEXT NOT NULL,
        full_name     TEXT NOT NULL,
        created_at    TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE categories (
        id          INTEGER PRIMARY KEY AUTOINCREMENT,
        name        TEXT NOT NULL UNIQUE,
        description TEXT
      )''');

    await db.execute('''
      CREATE TABLE receipts (
        id               INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id          INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
        merchant_name    TEXT NOT NULL,
        transaction_date TEXT NOT NULL,
        total_amount     NUMERIC NOT NULL,
        image_url        TEXT,
        created_at       TEXT NOT NULL
      )''');

    await db.execute('''
      CREATE TABLE receipt_items (
        id                INTEGER PRIMARY KEY AUTOINCREMENT,
        receipt_id        INTEGER NOT NULL REFERENCES receipts(id) ON DELETE CASCADE,
        category_id       INTEGER NOT NULL REFERENCES categories(id),
        item_name         TEXT NOT NULL,
        item_price        NUMERIC NOT NULL,
        confidence_score  REAL,
        is_user_corrected INTEGER NOT NULL DEFAULT 0
      )''');

    await db.execute(
        'CREATE INDEX idx_receipts_user_date ON receipts(user_id, transaction_date)');
    await db.execute(
        'CREATE INDEX idx_receipt_items_receipt ON receipt_items(receipt_id)');
    await db.execute(
        'CREATE INDEX idx_receipt_items_category ON receipt_items(category_id)');

    await _seedCategories(db);
    await _seedDemoAccount(db);
  }

  /// Lima kategori awal (sama dengan database/seed_categories.sql).
  static Future<void> _seedCategories(Database db) async {
    for (final name in AppCategories.names) {
      await db.insert('categories', {
        'id': AppCategories.seedIds[name],
        'name': name,
        'description': AppCategories.descriptions[name],
      });
    }
  }

  /// Akun demo + 24 struk demo (lihat demo_data.dart).
  static Future<void> _seedDemoAccount(Database db) async {
    final now = DateTime.now().toIso8601String();
    final userId = await db.insert('users', {
      'email': AppConfig.demoEmail,
      'password_hash': PasswordHasher.hash(AppConfig.demoPassword),
      'full_name': AppConfig.demoFullName,
      'created_at': now,
    });

    for (var n = 0; n < DemoData.receipts.length; n++) {
      final r = DemoData.receipts[n];
      final date = DateTime(DemoData.year, DemoData.month, r.day, 8 + (n % 11), (n * 7) % 60);
      final receiptId = await db.insert('receipts', {
        'user_id': userId,
        'merchant_name': r.merchant,
        'transaction_date': date.toIso8601String(),
        'total_amount': r.total,
        'image_url': null,
        'created_at': date.toIso8601String(),
      });
      for (final i in r.items) {
        await db.insert('receipt_items', {
          'receipt_id': receiptId,
          'category_id': AppCategories.seedIds[i.category],
          'item_name': i.name,
          'item_price': i.price,
          'confidence_score': i.confidence,
          'is_user_corrected': i.corrected ? 1 : 0,
        });
      }
    }
  }
}
