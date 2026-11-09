# Draft Kontrak API STRUKKU (FastAPI)

> **STATUS: RANCANGAN.** Backend Python belum diberikan, sehingga endpoint dan bentuk JSON di bawah
> adalah **usulan** yang harus disesuaikan dengan backend yang sebenarnya. Kode integrasi ada di
> `lib/data/remote/` dan `lib/data/repositories/fastapi_*.dart` dan **nonaktif secara default**
> (`AppConfig.useFastApi = false`). Tidak ada endpoint yang dianggap sudah berjalan.

Nama field JSON sengaja sama dengan kolom database (`database/schema_postgresql.sql`).
Semua request/response berformat JSON. Error mengikuti format FastAPI: `{"detail": "pesan"}`.
Setelah login, kirim header `Authorization: Bearer <access_token>`.

## Mengaktifkan di aplikasi

1. Jalankan backend (`uvicorn main:app --host 0.0.0.0 --port 8000`).
2. Pilih base URL (`lib/data/remote/api_config.dart`):
   - Android Emulator: `http://10.0.2.2:8000` (`localhost` di emulator = emulator itu sendiri, bukan komputer host)
   - HP fisik: `http://IP_LAPTOP:8000` (cek dengan `ipconfig`)
3. Jalankan:
   ```bash
   flutter run --dart-define=USE_FASTAPI=true --dart-define=API_BASE_URL=http://10.0.2.2:8000
   ```

## Endpoint usulan

| Method | Path | Keterangan |
|---|---|---|
| GET | `/health` | Cek server |
| POST | `/api/auth/register` | Registrasi |
| POST | `/api/auth/login` | Login, mengembalikan token |
| GET | `/api/categories` | Daftar kategori |
| POST | `/api/classify` | Klasifikasi nama item (TF-IDF + Multinomial Naive Bayes) |
| POST | `/api/receipts` | Simpan struk + item + koreksi |
| GET | `/api/receipts?month=YYYY-MM` | Riwayat struk (filter bulan opsional) |
| DELETE | `/api/receipts/{id}` | Hapus struk |
| GET | `/api/receipts/months` | Daftar bulan yang punya data |
| GET | `/api/dashboard?month=YYYY-MM` | Ringkasan bulanan |

## Contoh JSON

### POST /api/auth/register
```json
{ "full_name": "Satria Pratama", "email": "satria@gmail.com", "password": "Strukku123" }
```
Response `201` (body opsional):
```json
{ "id": 1, "email": "satria@gmail.com", "full_name": "Satria Pratama", "created_at": "2026-10-20T08:00:00" }
```

### POST /api/auth/login
```json
{ "email": "satria@gmail.com", "password": "Strukku123" }
```
Response `200`:
```json
{
  "access_token": "<jwt>",
  "user": { "id": 1, "email": "satria@gmail.com", "full_name": "Satria Pratama", "created_at": "2026-10-20T08:00:00" }
}
```

### GET /api/categories
```json
[ { "id": 1, "name": "F&B", "description": "Makanan, minuman, dan bahan pangan" } ]
```
(Aplikasi juga menerima `{"categories": [...]}`.)

### POST /api/classify
Request:
```json
{ "items": ["Roti Tawar 500g", "Susu UHT 1L", "Vitamin C 10 tablet"] }
```
Response (urutan sama dengan request):
```json
{
  "predictions": [
    { "item_name": "Roti Tawar 500g",     "category_name": "F&B",       "confidence_score": 0.95 },
    { "item_name": "Susu UHT 1L",         "category_name": "F&B",       "confidence_score": 0.93 },
    { "item_name": "Vitamin C 10 tablet", "category_name": "Kesehatan", "confidence_score": 0.62 }
  ]
}
```
`category_name` harus sama dengan nama pada tabel `categories`.

### POST /api/receipts
Request (OCR + parsing dilakukan di aplikasi; backend menerima hasil yang sudah divalidasi pengguna):
```json
{
  "user_id": 1,
  "merchant_name": "INDOMARET",
  "transaction_date": "2026-10-21T00:00:00.000",
  "total_amount": 55500.0,
  "image_url": null,
  "created_at": "2026-10-21T08:42:10.000",
  "items": [
    { "category_id": 1, "item_name": "Roti Tawar 500g", "item_price": 22500.0, "confidence_score": 0.95, "is_user_corrected": false },
    { "category_id": 2, "item_name": "Vitamin C 10 tablet", "item_price": 15000.0, "confidence_score": 0.62, "is_user_corrected": true }
  ]
}
```
Response `201`: objek struk lengkap (field sama dengan request + `id`, dan `items[].id`/`receipt_id`).
Catatan: backend sebaiknya mengambil `user_id` dari token, bukan dari body.

### GET /api/dashboard?month=2026-10
```json
{
  "month": "2026-10",
  "total_amount": 1250000,
  "receipt_count": 24,
  "category_totals": [
    { "category_name": "F&B", "total": 625000 },
    { "category_name": "Transportasi", "total": 250000 }
  ],
  "recent_receipts": [ { "id": 24, "user_id": 1, "merchant_name": "INDOMARET", "transaction_date": "2026-10-20T08:00:00", "total_amount": 55500, "image_url": null, "created_at": "2026-10-20T08:00:00", "items": [] } ]
}
```

### GET /api/receipts/months
```json
{ "months": ["2026-10", "2026-09"] }
```

## Hal yang perlu disepakati dengan developer backend

- Lokasi pemrosesan OCR: flowchart menempatkan Google ML Kit di perangkat (diimplementasikan di aplikasi);
  sequence diagram menggambarkan gambar diproses backend. Aplikasi saat ini: **OCR + parsing di perangkat,
  klasifikasi di backend**. Jika berubah, cukup ganti `ScannerScreen._useCaptured` dan repository.
- Skema autentikasi (JWT/refresh), unggah gambar struk (`image_url`), dan ambang confidence.
- Apakah backend menghitung ulang total/percentase atau hanya menyimpan.
