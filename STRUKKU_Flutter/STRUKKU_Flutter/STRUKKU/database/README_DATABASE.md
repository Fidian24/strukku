# Database STRUKKU

Struktur mengikuti **ERD & Data Dictionary** pada dokumen *Progres Task 2.0* (Lampiran 2):
empat tabel `users`, `categories`, `receipts`, `receipt_items`.

## File

| File | Isi |
|---|---|
| `schema_postgresql.sql` | Skema utama PostgreSQL (tabel, FK, index, komentar kolom) |
| `seed_categories.sql` | Lima kategori awal (ID 1..5) |

## Menyiapkan PostgreSQL

```bash
createdb strukku
psql -d strukku -f database/schema_postgresql.sql
psql -d strukku -f database/seed_categories.sql
```

## Relasi

```
users 1 ──< receipts 1 ──< receipt_items >── 1 categories
```

- `receipts.user_id` -> `users.id` (ON DELETE CASCADE)
- `receipt_items.receipt_id` -> `receipts.id` (ON DELETE CASCADE: item ikut terhapus bersama struk)
- `receipt_items.category_id` -> `categories.id` (ON DELETE RESTRICT: kategori yang dipakai tidak bisa dihapus)

## Keputusan desain

- **Nominal uang memakai `DECIMAL(15,2)`**, bukan FLOAT. `confidence_score` memakai `REAL` (FLOAT) sesuai dokumen
  dan dibatasi 0..1 dengan CHECK; `NULL` berarti item ditambahkan manual.
- **`password_hash`** menyimpan hash (bcrypt/argon2 di backend). Password asli tidak pernah disimpan.
- **Index**: `receipts(user_id, transaction_date DESC)` untuk riwayat & dashboard bulanan,
  `receipt_items(receipt_id)` dan `receipt_items(category_id)` untuk JOIN/agregasi, serta index parsial
  `is_user_corrected` untuk mengambil data koreksi saat retraining model.
- Tambahan kecil di luar dokumen: `UNIQUE` pada `categories.name` agar seed bisa dijalankan ulang tanpa duplikat.
- **Tidak ada tabel batas anggaran per kategori**, karena tidak ada di ERD. Fitur tersebut tidak diimplementasikan.

## Database lokal Flutter (mode demo)

Aplikasi memakai **SQLite** (`lib/data/local/app_database.dart`) dengan struktur yang sama.
Perbedaan hanya tipe bawaan SQLite: `DECIMAL` -> `NUMERIC`, `TIMESTAMP` -> teks ISO-8601, `BOOLEAN` -> `INTEGER 0/1`.
Seed kategori dan data demo ada di `lib/data/local/demo_data.dart`.

## Contoh query dashboard (untuk backend)

```sql
-- Total per kategori pada satu bulan
SELECT c.name, SUM(i.item_price) AS total
FROM receipt_items i
JOIN receipts   r ON r.id = i.receipt_id
JOIN categories c ON c.id = i.category_id
WHERE r.user_id = :user_id
  AND r.transaction_date >= :bulan_awal
  AND r.transaction_date <  :bulan_berikutnya
GROUP BY c.id, c.name
ORDER BY total DESC;
```
