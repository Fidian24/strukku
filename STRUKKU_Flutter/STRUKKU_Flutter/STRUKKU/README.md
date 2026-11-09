# STRUKKU

Aplikasi Flutter untuk otomatisasi pencatatan transaksi keuangan dari struk belanja:
**pindai struk -> OCR (Google ML Kit) -> parsing regex -> klasifikasi kategori -> koreksi pengguna -> simpan -> dashboard**.

Desain mengikuti dokumen *Progres Task 2.0* (flowchart, ERD, mockup Figma).
Secara default aplikasi berjalan **tanpa backend** (mode demo/lokal). Integrasi FastAPI sudah disiapkan tetapi **nonaktif**.

> **Status verifikasi:** proyek ini ditulis di lingkungan tanpa Flutter/Android SDK, sehingga
> `flutter pub get`, `flutter analyze`, `flutter test`, dan `flutter build apk` **belum dijalankan**.
> Jalankan langkah di bawah di komputer Anda; jika ada error kompilasi, laporkan pesannya agar dapat diperbaiki.

## 1. Persyaratan

- Flutter SDK stabil terbaru (Dart >= 3.4; Flutter >= 3.22) dan Android SDK.
- Android Studio dengan plugin **Flutter** dan **Dart**.
- Android Emulator (API 24+) atau HP Android.

## 2. Membuka dan menyiapkan proyek

1. Ekstrak `STRUKKU_Flutter_Android_Studio.zip`.
2. Android Studio -> **File > Open** -> pilih folder `STRUKKU`.
3. **Langkah satu kali** — buat file build Gradle Android. Folder `android/` di ZIP berisi manifest (izin kamera),
   `MainActivity`, dan resource, tetapi file Gradle (`build.gradle.kts`, `settings.gradle.kts`, Gradle wrapper)
   dibuat oleh Flutter agar cocok dengan versi Flutter Anda. Di terminal (Terminal di Android Studio), dari folder `STRUKKU`:

   ```bash
   flutter create . --project-name strukku --org com.strukku --platforms=android
   ```

   Perintah ini hanya menambah file yang belum ada dan tidak menimpa file yang sudah ada.
   Setelah selesai, pastikan `android/app/src/main/AndroidManifest.xml` masih memuat izin `CAMERA`
   (cadangannya ada di `docs/AndroidManifest.main.backup.xml`).
4. Ambil dependency:

   ```bash
   flutter pub get
   ```

Jika Gradle meminta `minSdk` lebih tinggi, ubah `minSdk` di `android/app/build.gradle(.kts)`
(paket `camera` dan ML Kit membutuhkan minimal 21).

## 3. Menjalankan di emulator

1. Buat emulator di **Device Manager** (mis. Pixel 6, API 34).
2. Untuk menguji kamera: **Advanced Settings > Camera > Back camera = `VirtualScene` atau `Webcam0`**.
3. Pilih emulator di toolbar, lalu **Run** (atau `flutter run`).

Masuk dengan **akun demo** (tombol "Mode demo: isi akun demo" di halaman Login):

| Email | Password |
|---|---|
| `satria@gmail.com` | `Strukku123` |

Akun demo berisi 24 struk Oktober 2026 (total Rp1.250.000) yang cocok dengan mockup Figma.
Akun yang Anda daftarkan sendiri mulai dari kosong.

## 4. Menguji kamera dan galeri

- **Kamera:** tekan tombol kamera di Beranda, izinkan akses kamera, arahkan ke struk, tekan shutter, lalu **Gunakan Foto**.
  Pada emulator dengan `VirtualScene`, teks struk tidak akan terbaca; gunakan galeri atau `Webcam0` yang diarahkan ke struk.
- **Galeri:** tekan ikon galeri di halaman Pindai. Untuk memasukkan foto struk ke emulator, seret file gambar
  ke jendela emulator (masuk ke galeri), lalu pilih.
- Jika OCR tidak menemukan teks struk, muncul dialog dengan pilihan **Ulangi**, **Isi Manual**, atau **Pakai Contoh Demo**.
- Jika izin kamera ditolak atau kamera tidak ada, ditampilkan pesan dan tombol **Pilih dari Galeri**.

## 5. Mode demo tanpa backend

Default (`useFastApi = false`):

- Login/registrasi lokal (password disimpan sebagai hash + salt di SQLite).
- Struk tersimpan di **SQLite** di perangkat (struktur sama dengan PostgreSQL).
- OCR memakai Google ML Kit di perangkat (butuh gambar yang jelas).
- Klasifikasi kategori adalah **simulasi berbasis kata kunci** dan ditandai "Mode demo" di layar validasi.
  Ini **bukan** model TF-IDF + Naive Bayes; model asli berada di backend Python.
- Data demo: `lib/data/local/demo_data.dart`.

## 6. Mengaktifkan FastAPI nanti

Backend belum tersedia, jadi bagian ini nonaktif dan **belum diuji terhadap server mana pun**.

- Saklar: `lib/core/constants/app_config.dart` -> `useFastApi`, atau `--dart-define=USE_FASTAPI=true`.
- Base URL: `lib/data/remote/api_config.dart` (emulator: `http://10.0.2.2:8000`; HP fisik: `http://IP_LAPTOP:8000`;
  `localhost` di emulator **bukan** komputer Anda).
- Endpoint & JSON usulan: `docs/API_CONTRACT_DRAFT.md` (rancangan, sesuaikan dengan backend asli; cari komentar `TODO`).

## 7. Database PostgreSQL

```bash
createdb strukku
psql -d strukku -f database/schema_postgresql.sql
psql -d strukku -f database/seed_categories.sql
```

Detail: `database/README_DATABASE.md`.

## 8. Pengujian

```bash
flutter analyze
flutter test
flutter build apk --debug
```

Test mencakup parsing struk, format/validator, hash password, model & JSON, data demo (24 struk, Rp1.250.000,
total per kategori), dan widget Login/Register.

## 9. Package utama

| Package | Fungsi |
|---|---|
| `camera` | Pratinjau kamera, shutter, flash |
| `image_picker` | Memilih gambar dari galeri |
| `google_mlkit_text_recognition` | OCR on-device |
| `sqflite`, `path`, `path_provider` | SQLite lokal dan penyimpanan foto |
| `shared_preferences` | Sesi login |
| `crypto` | Hash password SHA-256 + salt |
| `http` | Klien FastAPI (nonaktif default) |

Struktur folder: `docs/PROJECT_STRUCTURE.md`.

## 10. Batasan yang disengaja

- Ambang confidence (`lowConfidenceThreshold = 0.70`) adalah pilihan implementasi, bukan ketentuan dokumen.
- Tidak ada fitur batas anggaran per kategori (tidak ada di ERD).
- Halaman Profil sengaja sederhana (dokumen tidak memberi mockup-nya).
- Font: memakai font bawaan Material, bukan font Figma.
 