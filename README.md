# STRUKKU

Aplikasi pencatatan transaksi keuangan dari foto struk belanja (OCR + klasifikasi kategori dengan Machine Learning).

| Folder | Isi |
|---|---|
| `strukku_backend_fixed/strukku_backend` | Backend API — Python 3.11 + FastAPI, OCR Tesseract, model `model_tfidf_mnb_v1.joblib` |
| `STRUKKU_Flutter/STRUKKU_Flutter/STRUKKU` | Aplikasi mobile Flutter (Android) |

## Menjalankan backend

```bash
cd strukku_backend_fixed/strukku_backend
py -m venv .venv
.\.venv\Scripts\Activate.ps1
python -m pip install -r requirements.txt
copy .env.example .env      # lalu isi nilainya
python -m uvicorn app.main:app --reload --host 0.0.0.0 --port 8000
```

Cek: http://127.0.0.1:8000/api/v1/health · Dokumentasi API: http://127.0.0.1:8000/docs

## Menjalankan aplikasi Flutter (HP Android via USB)

```bash
cd STRUKKU_Flutter/STRUKKU_Flutter/STRUKKU
flutter pub get
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Panduan lengkap: `STRUKKU_Flutter/STRUKKU_Flutter/STRUKKU/CARA_MENJALANKAN.md`.

> File `.env` berisi rahasia (password database, kunci JWT) dan **tidak** disimpan di repositori. Salin dari `.env.example`.
