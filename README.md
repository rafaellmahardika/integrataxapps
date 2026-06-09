# IntegraTax

IntegraTax adalah prototype aplikasi Flutter untuk memantau sinkronisasi data Pajak Bumi dan Bangunan (PBB) antar instansi. Aplikasi ini dirancang sebagai dashboard monitoring untuk Administrator IT Bapenda agar dapat melihat status sinkronisasi, menerima alert, meninjau approval, membaca log aktivitas, dan mengeksplorasi data objek pajak SIMPBB melalui middleware.

> Status: Demo / Prototype. Dashboard, notifikasi, approval, dan log menggunakan data dummy. Fitur SIMPBB Explorer terhubung ke upstream SIMPBB melalui middleware Node.js. Project ini belum siap digunakan di lingkungan produksi dengan data pajak nyata.

## Daftar Isi

- [Anggota Kelompok](#anggota-kelompok)
- [Ringkasan Fitur](#ringkasan-fitur)
- [Tech Stack](#tech-stack)
- [Arsitektur](#arsitektur)
- [Struktur Project](#struktur-project)
- [Prasyarat](#prasyarat)
- [Instalasi](#instalasi)
- [Konfigurasi Environment](#konfigurasi-environment)
- [Cara Menjalankan](#cara-menjalankan)
- [Login Demo](#login-demo)
- [Integrasi SIMPBB API](#integrasi-simpbb-api)
- [Testing dan Validasi](#testing-dan-validasi)
- [Keamanan](#keamanan)
- [Status Implementasi](#status-implementasi)
- [Troubleshooting](#troubleshooting)
- [Roadmap Pengembangan](#roadmap-pengembangan)

## Anggota Kelompok

- Rafael Mahardika Arya Dewamurti (24/536279/PA/22755)
- Bobby Rahman Hartanto (24/539383/PA/22903)
- Davi Ezra Syandana (24/538363/PA/22841)
- Axelle Chandra (24/533796/PA/22614)

## Ringkasan Fitur

- Dashboard status sinkronisasi BPN, Disdukcapil, dan BPJS.
- Indikator status sinkronisasi: terhubung, sinkronisasi, gagal, dan offline.
- Pull-to-refresh untuk memperbarui data dashboard dummy.
- Grafik performa response time API 24 jam menggunakan `fl_chart`.
- Navigasi 4 tab: Dashboard, Notifikasi, Approval, dan Log.
- Halaman detail sumber data saat status card diklik.
- Login dummy untuk simulasi autentikasi Administrator IT.
- Provider dummy untuk notifikasi, approval, dan log aktivitas.
- Middleware Node.js untuk mem-proxy request ke SIMPBB API.
- SIMPBB Explorer untuk pencarian Objek Pajak berdasarkan nama WP/kata kunci.
- Penyembunyian sebagian NOP pada log untuk menjaga privasi tampilan.
- Unit test dan widget test untuk provider, model, dan flow UI.
- Backend API test menggunakan Jest dan Supertest.

## Tech Stack

### Frontend

- Flutter 3.x
- Dart 3.x
- Riverpod 2.x untuk state management
- `http` untuk komunikasi HTTP
- `fl_chart` untuk grafik performa
- `google_fonts` untuk typography

### Backend

- Node.js
- Express 4.x
- CORS
- Helmet untuk security headers
- Express Rate Limit untuk pembatasan request
- Jest dan Supertest untuk testing endpoint

## Arsitektur

IntegraTax memisahkan aplikasi menjadi frontend Flutter dan backend middleware.

```text
Flutter App
  -> Screens
  -> Riverpod Providers
  -> Repository / BackendClient
  -> Node.js Middleware
  -> SIMPBB API
```

Penjelasan layer:

- `Screens` menampilkan UI dan menerima interaksi user.
- `Providers` menyimpan state dan menjalankan logic aplikasi.
- `Models` mendefinisikan bentuk data yang digunakan UI dan provider.
- `BackendClient` menangani request HTTP dari Flutter ke middleware.
- `Node.js Middleware` menjadi gateway aman ke upstream SIMPBB API.
- `SIMPBB API` menjadi upstream eksternal untuk data objek pajak.

## Struktur Project

```text
integratax/
  lib/
    main.dart                    # Entry point aplikasi Flutter
    core/
      backend_client.dart        # HTTP client ke middleware, injectable untuk test
      theme.dart                 # Warna, typography, dan tema aplikasi
    models/
      app_notification.dart      # Model notifikasi aplikasi
      approval_request.dart      # Model request approval
      data_source.dart           # Model sumber data dan status sinkronisasi
      objek_pajak.dart           # Model response SIMPBB Objek Pajak
      sync_log.dart              # Model log aktivitas sinkronisasi
    providers/
      auth_provider.dart         # State login dummy
      dashboard_provider.dart    # State dashboard dan dummy data
      mock_data_provider.dart    # Notifikasi, approval, log, maskNop()
      simpbb_provider.dart       # Repository dan provider SIMPBB
    screens/
      app_gate.dart              # Menentukan login screen atau dashboard
      login_screen.dart          # Halaman login dummy
      dashboard_screen.dart      # Halaman dashboard utama
      notification_screen.dart   # Halaman notifikasi
      approval_screen.dart       # Halaman approval
      log_screen.dart            # Halaman log aktivitas
      source_detail_screen.dart  # Detail status sumber data
      simpbb_explorer_screen.dart # Pencarian Objek Pajak SIMPBB
      error_page.dart            # Komponen tampilan error
    widgets/
      performance_chart.dart     # Grafik performa response time
      status_card.dart           # Card status sumber data
  backend/
    src/server.js                # Express middleware untuk SIMPBB
    test/server.test.js          # Test API middleware
    .env.example                 # Template konfigurasi environment
    package.json                 # Script dan dependency backend
  test/
    widget_test.dart             # Widget test Flutter
    unit/
      auth_provider_test.dart
      mock_data_provider_test.dart
      objek_pajak_model_test.dart
      simpbb_provider_test.dart
  android/ ios/ web/ linux/ macos/ windows/
                                # Folder platform Flutter
```

## Prasyarat

Pastikan environment berikut sudah tersedia:

- Flutter SDK 3.x atau lebih baru
- Dart SDK 3.x atau lebih baru
- Node.js 18 atau lebih baru
- npm
- Git
- Chrome jika menjalankan Flutter Web

Cek instalasi Flutter:

```bash
flutter doctor
```

## Instalasi

Clone repository:

```bash
git clone https://github.com/rafaellmahardika/integrataxapps.git
cd integrataxapps
```

Install dependency Flutter:

```bash
flutter pub get
```

Install dependency backend:

```bash
npm install --prefix backend
```

## Konfigurasi Environment

Salin template environment backend:

```bash
cp backend/.env.example backend/.env
```

Variabel environment backend:

| Variabel | Wajib | Default | Keterangan |
|---|---:|---|---|
| `PORT` | Tidak | `3000` | Port middleware Express |
| `SIMPBB_BASE_URL` | Ya untuk production | `https://simpbb.technosmart.id/api/rpc` | Base URL upstream SIMPBB |
| `INTEGRATAX_API_KEY` | Ya untuk production | kosong | Secret header antara Flutter dan middleware |
| `ALLOWED_ORIGIN` | Ya untuk production | `http://localhost:3000` | Origin yang diizinkan oleh CORS |
| `NODE_ENV` | Tidak | `development` | Mode runtime backend |

> Jangan commit file `.env`. File tersebut berisi konfigurasi environment dan dapat berisi secret.

Konfigurasi Flutter dapat diberikan melalui `--dart-define`:

| Dart Define | Default | Keterangan |
|---|---|---|
| `INTEGRATAX_API_BASE_URL` | `http://localhost:3000` | Base URL middleware yang dipakai Flutter |
| `ENABLE_DEV_TOOLS` | `false` | Menampilkan tombol SIMPBB Explorer di dashboard |

## Cara Menjalankan

Gunakan dua terminal: satu untuk backend, satu untuk Flutter.

### 1. Jalankan Backend Middleware

Mode development dengan auto-restart:

```bash
npm run dev --prefix backend
```

Mode production-like:

```bash
npm start --prefix backend
```

Middleware default berjalan di:

```text
http://localhost:3000
```

Cek health endpoint:

```bash
curl http://localhost:3000/health
```

### 2. Jalankan Flutter Web

Run standar:

```bash
flutter run -d chrome
```

Run dengan backend lokal eksplisit:

```bash
flutter run -d chrome --dart-define=INTEGRATAX_API_BASE_URL=http://localhost:3000
```

Run dengan SIMPBB Explorer aktif:

```bash
flutter run -d chrome --dart-define=ENABLE_DEV_TOOLS=true --dart-define=INTEGRATAX_API_BASE_URL=http://localhost:3000
```

### 3. Jalankan Flutter Desktop Linux

```bash
flutter run -d linux
```

## Login Demo

Login masih berupa simulasi. Gunakan credential berikut untuk demo:

```text
Email: admin@bapenda.go.id
Password: integratax
```

Catatan:

- Password tidak divalidasi ke backend.
- Email hanya dicek kosong/tidak dan formatnya valid.
- Autentikasi production harus diganti dengan JWT, OAuth2, atau mekanisme auth resmi lain.

## Integrasi SIMPBB API

Base URL upstream SIMPBB:

```text
https://simpbb.technosmart.id/api/rpc
```

Semua request ke upstream mengikuti format oRPC:

```json
{
  "json": {
    "param": "value"
  }
}
```

Endpoint middleware:

| Endpoint | Method | Keterangan |
|---|---|---|
| `/health` | GET | Mengecek status middleware |
| `/api/simpbb/search` | POST | Mencari objek pajak berdasarkan nama WP/kata kunci |
| `/api/simpbb/list-details` | POST | Mengambil daftar objek pajak dengan filter |
| `/api/simpbb/proxy` | POST | Proxy terbatas ke endpoint oRPC yang diizinkan |

Endpoint oRPC yang diizinkan oleh proxy:

- `/wilayah/listPropinsi`
- `/objekPajak/search`
- `/objekPajak/listDetails`
- `/objekPajak/getByNop`

Contoh request search ke middleware:

```bash
curl -X POST http://localhost:3000/api/simpbb/search \
  -H "Content-Type: application/json" \
  -d '{"query":"BUDI","limit":5}'
```

## Testing dan Validasi

Static analysis Flutter:

```bash
flutter analyze
```

Flutter unit dan widget test:

```bash
flutter test
```

Flutter test dengan output detail:

```bash
flutter test --reporter expanded
```

Backend API test:

```bash
npm test --prefix backend
```

Build debug Flutter Web:

```bash
flutter build web --debug
```

Build debug Linux:

```bash
flutter build linux --debug
```

Audit dependency:

```bash
flutter pub outdated
npm audit --prefix backend
```

## Keamanan

Middleware dilengkapi beberapa lapisan keamanan:

- Helmet untuk security headers.
- CORS allowlist berdasarkan `ALLOWED_ORIGIN`.
- Rate limiting maksimum 60 request per menit per IP.
- Header `X-IntegraTax-Key` untuk autentikasi Flutter ke middleware jika `INTEGRATAX_API_KEY` diaktifkan.
- Proxy allowlist agar hanya endpoint SIMPBB tertentu yang dapat diakses.
- Guard untuk mencegah array diteruskan sebagai `params` proxy.
- Timeout 10 detik untuk request ke upstream SIMPBB.
- Limit body request sebesar 1MB.
- Error handler tidak mengirim stack trace ke client.

Catatan keamanan penting:

- Login saat ini masih dummy dan belum aman untuk production.
- SIMPBB Explorer dapat menampilkan data sensitif seperti nama WP, alamat, dan NOP.
- Akses data sensitif harus dibatasi dengan autentikasi dan otorisasi nyata.
- NOP pada log dimasking di client, tetapi production tetap membutuhkan masking dan audit di sisi server.
- File `.env` tidak boleh masuk repository.

## Status Implementasi

### Sudah Tersedia

- UI dashboard utama dengan label MODE DEMO.
- Login dummy dengan validasi field kosong dan format email.
- Tab Dashboard, Notifikasi, Approval, dan Log.
- Halaman detail sumber data.
- Provider dummy untuk dashboard, notifikasi, approval, dan log.
- Grafik performa 24 jam menggunakan `fl_chart`.
- Middleware Node.js untuk proxy SIMPBB.
- SIMPBB Explorer melalui middleware.
- BackendClient yang dapat di-inject untuk kebutuhan testing.
- Unit test dan widget test Flutter.
- API test backend dengan Jest dan Supertest.
- Masking NOP pada tampilan log.

### Belum Tersedia

- Autentikasi nyata menggunakan JWT, OAuth2, atau SSO.
- Database untuk menyimpan approval, log, dan notifikasi.
- Dashboard real-time dari endpoint produksi.
- WebSocket atau polling periodik untuk update otomatis.
- Push notification seperti Firebase Cloud Messaging.
- Pagination untuk notifikasi, approval, dan log.
- Role-based access control.
- Audit trail production-grade.

## Troubleshooting

### Flutter tidak bisa menemukan dependency

Jalankan ulang:

```bash
flutter pub get
```

### Backend dependency belum terinstall

Jalankan:

```bash
npm install --prefix backend
```

### SIMPBB Explorer gagal konek ke middleware

Pastikan backend sudah berjalan:

```bash
curl http://localhost:3000/health
```

Pastikan Flutter dijalankan dengan base URL yang benar:

```bash
flutter run -d chrome --dart-define=INTEGRATAX_API_BASE_URL=http://localhost:3000
```

### Tombol SIMPBB Explorer tidak muncul

Jalankan Flutter dengan:

```bash
flutter run -d chrome --dart-define=ENABLE_DEV_TOOLS=true
```

### Error CORS di Flutter Web

Pastikan `ALLOWED_ORIGIN` di backend sesuai dengan origin Flutter Web, atau jalankan backend dalam mode development untuk mengizinkan localhost.

### Upstream SIMPBB timeout

Middleware membatasi request upstream selama 10 detik. Jika timeout terjadi, cek koneksi internet, ketersediaan upstream SIMPBB, dan nilai `SIMPBB_BASE_URL`.

## Roadmap Pengembangan

- Mengganti dummy dashboard dengan API monitoring nyata.
- Menambahkan autentikasi dan otorisasi production-grade.
- Menambahkan database untuk log, approval, dan notifikasi.
- Menambahkan WebSocket atau scheduled polling untuk status real-time.
- Menambahkan push notification untuk alert kritis.
- Menambahkan audit trail dan access logging untuk data sensitif.
- Menambahkan pagination, filter, dan pencarian lanjutan.
- Meningkatkan responsive layout untuk tablet dan desktop web.

## Lisensi

Project ini dibuat untuk kebutuhan pembelajaran dan demonstrasi akademik.
