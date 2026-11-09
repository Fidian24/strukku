# Menjalankan STRUKKU (Flutter + Backend FastAPI)

Aplikasi ini sekarang **terhubung ke backend `strukku_backend` secara default**.

## 1. Nyalakan backend dulu

Dobel klik `strukku_backend\jalankan_server.bat`, atau dari folder `strukku_backend`:

```bash
.venv\Scripts\activate
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Cek di browser laptop: http://127.0.0.1:8000/api/v1/health → harus `"status": "ok"`.

## 2. Jalankan aplikasi Flutter

| Perangkat | Perintah |
|---|---|
| Emulator Android | `flutter run` (otomatis ke `http://10.0.2.2:8000`) |
| Windows / Chrome | `flutter run` (otomatis ke `http://127.0.0.1:8000`) |
| HP fisik (Wi-Fi sama dengan laptop) | `flutter run --dart-define=API_BASE_URL=http://IP_LAPTOP:8000` |

IP laptop: jalankan `ipconfig`, lihat "IPv4 Address" (mis. `192.168.1.10`).
Jika HP tidak bisa terhubung, izinkan Python di Windows Firewall (jaringan Private).

Mode demo lama (tanpa server, data di HP): `flutter run --dart-define=USE_FASTAPI=false`

## 3. Alur yang terhubung ke server

| Layar | Endpoint backend |
|---|---|
| Daftar / Login | `POST /api/v1/auth/register`, `POST /api/v1/auth/login` |
| Pindai → kategori otomatis | `POST /api/v1/classify` (OCR tetap di HP, kategori dari model ML server) |
| Simpan struk | `POST /api/v1/receipts` |
| Beranda & Kategori | `GET /api/v1/dashboard?month=YYYY-MM`, `GET /api/v1/analytics/monthly` |
| Riwayat, detail, hapus | `GET /api/v1/receipts`, `GET/DELETE /api/v1/receipts/{id}` |

Token login (berlaku 30 menit) diperbarui otomatis dengan refresh token (7 hari).

## Masalah umum

- **"Tidak dapat terhubung ke server"**: backend belum jalan, tidak pakai `--host 0.0.0.0`,
  alamat salah (HP fisik wajib IP laptop), atau firewall.
- **"Email belum diverifikasi"**: set `REQUIRE_EMAIL_VERIFICATION=false` di `strukku_backend/.env`.
- Setelah mengubah kode, jalankan `flutter clean` lalu `flutter pub get` jika build bermasalah.
