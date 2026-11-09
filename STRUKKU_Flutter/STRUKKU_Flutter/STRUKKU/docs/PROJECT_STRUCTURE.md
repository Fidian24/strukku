# Struktur Proyek STRUKKU

```
STRUKKU/
├── android/                    Konfigurasi Android (manifest, MainActivity, resource)
├── assets/                     images/, icons/, illustrations/
├── database/                   schema_postgresql.sql, seed_categories.sql, README_DATABASE.md
├── docs/                       API_CONTRACT_DRAFT.md, PROJECT_STRUCTURE.md
├── lib/
│   ├── main.dart               Titik masuk: memilih repository, menjalankan app
│   ├── app.dart                MaterialApp, gerbang login (Auth <-> MainShell)
│   ├── core/
│   │   ├── app_state.dart      State bersama (versi data, bulan terpilih)
│   │   ├── constants/          app_colors, app_config (useFastApi, ambang confidence), app_categories
│   │   ├── errors/             AppException
│   │   ├── theme/              app_theme
│   │   ├── utils/              formatters, validators, password_hasher, receipt_parser (regex)
│   │   └── widgets/            logo, input, tombol, banner, state kosong/error, tile struk
│   ├── data/
│   │   ├── local/              app_database (SQLite), demo_data (DATA DEMO)
│   │   ├── remote/             api_config, api_routes, fastapi_client   (NONAKTIF default)
│   │   └── repositories/       interface + implementasi lokal/mock + FastAPI + repository_provider
│   ├── models/                 user, category, receipt, receipt_item, dashboard
│   ├── features/
│   │   ├── auth/               Login/Register, session_controller
│   │   ├── dashboard/          Beranda, riwayat, detail struk, pemilih bulan
│   │   ├── scanner/            Kamera, galeri, OCR ML Kit
│   │   ├── validation/         Koreksi & Validasi Data
│   │   ├── categories/         Kategori Pengeluaran
│   │   └── profile/            Profil & keluar
│   └── navigation/             app_router (rute), main_shell (bottom navigation)
├── test/                       Pengujian parser, model, data demo, validator, widget
├── pubspec.yaml
└── analysis_options.yaml
```

## Alur data

```
Kamera/Galeri -> OCR (ML Kit, di perangkat) -> ReceiptParser (regex)
   -> ReceiptRepository.classifyItems  (mock: simulasi | FastAPI: model ML)
   -> ValidationScreen (koreksi pengguna) -> ReceiptRepository.saveReceipt
   -> AppState.notifyDataChanged -> Beranda/Kategori/Riwayat memuat ulang
```

## Pola repository (mode lokal <-> FastAPI)

UI hanya memakai interface `AuthRepository`, `CategoryRepository`, `ReceiptRepository`.
`AppRepositories.init()` (lib/data/repositories/repository_provider.dart) memilih implementasi
berdasarkan `AppConfig.useFastApi`:

| Mode | Auth | Kategori | Struk |
|---|---|---|---|
| Lokal/demo (default) | `LocalAuthRepository` (SQLite) | `LocalCategoryRepository` | `MockReceiptRepository` (SQLite + klasifikasi simulasi) |
| FastAPI | `FastApiAuthRepository` | `FastApiCategoryRepository` | `FastApiReceiptRepository` |

## Konfigurasi penting

| Hal | Lokasi |
|---|---|
| Aktifkan FastAPI | `lib/core/constants/app_config.dart` -> `useFastApi` |
| Ambang confidence (kuning) | `lib/core/constants/app_config.dart` -> `lowConfidenceThreshold` |
| Base URL API | `lib/data/remote/api_config.dart` |
| Data demo | `lib/data/local/demo_data.dart` |
| Aturan klasifikasi simulasi | `lib/data/repositories/mock_receipt_repository.dart` |
