# IntegraTax

IntegraTax adalah aplikasi mobile Flutter untuk memantau sinkronisasi data Pajak Bumi dan Bangunan (PBB) antar instansi. Aplikasi ini dirancang sebagai dashboard monitoring untuk Administrator IT Bapenda agar dapat melihat status sinkronisasi, menerima alert, meninjau approval, dan membaca log aktivitas dari perangkat mobile.

## Anggota Kelompok

- Rafael Mahardika Arya Dewamurti (24/536279/PA/22755)
- Bobby Rahman Hartanto (24/539383/PA/22903)
- Davi Ezra Syandana (24/538363/PA/22841)
- Axelle Chandra (24/533796/PA/22614)

## Fitur Saat Ini

- Dashboard status sinkronisasi BPN, Disdukcapil, dan BPJS.
- Indikator status hijau, kuning, dan merah.
- Pull-to-refresh dengan dummy data.
- Grafik performa respon API 24 jam menggunakan `fl_chart`.
- Navigasi 4 tab sesuai SRS: Dashboard, Notifikasi, Approval, dan Log.
- Halaman detail sumber data saat card status diklik.
- Login dummy untuk simulasi autentikasi administrator.
- Provider dummy untuk Notifikasi, Approval, dan Log agar mudah diganti backend/API.
- Middleware Node.js minimal untuk mem-proxy request SIMPBB API.
- Halaman Objek Pajak SIMPBB untuk pencarian WP/NOP melalui middleware.

## Integrasi SIMPBB API

Base URL upstream SIMPBB:

```text
https://simpbb.technosmart.id/api/rpc
```

Semua request mengikuti format oRPC:

```json
{
  "json": {
    "param": "value"
  }
}
```

Endpoint middleware yang sudah tersedia:

- `GET /health`
- `POST /api/simpbb/search`
- `POST /api/simpbb/list-details`
- `POST /api/simpbb/proxy` untuk endpoint oRPC yang diizinkan

Catatan: dashboard sinkronisasi BPN, Disdukcapil, dan BPJS masih menggunakan dummy data karena endpoint status sinkronisasi real-time belum tersedia di dokumentasi API. Integrasi SIMPBB saat ini difokuskan untuk pencarian objek pajak dan list detail melalui middleware.

## Tech Stack

- Flutter 3.x
- Dart 3.x
- Riverpod untuk state management
- `http` untuk request API
- `fl_chart` untuk grafik
- `google_fonts` untuk typography
- Node.js + Express untuk middleware awal

## Struktur Utama

```text
lib/
  core/
    backend_client.dart
    theme.dart
  models/
    app_notification.dart
    approval_request.dart
    data_source.dart
    objek_pajak.dart
    sync_log.dart
  providers/
    auth_provider.dart
    dashboard_provider.dart
    mock_data_provider.dart
    simpbb_provider.dart
  screens/
    app_gate.dart
    dashboard_screen.dart
    login_screen.dart
    notification_screen.dart
    approval_screen.dart
    log_screen.dart
    source_detail_screen.dart
    simpbb_explorer_screen.dart
  widgets/
    performance_chart.dart
    status_card.dart
backend/
  package.json
  src/server.js
```

## Cara Menjalankan

Install dependency Flutter:

```bash
flutter pub get
```

Install dependency backend:

```bash
npm install --prefix backend
```

Jalankan middleware:

```bash
npm run dev --prefix backend
```

Middleware default berjalan di:

```text
http://localhost:3000
```

Run di Chrome:

```bash
flutter run -d chrome
```

Jika backend berjalan di URL lain:

```bash
flutter run -d chrome --dart-define=INTEGRATAX_API_BASE_URL=http://localhost:3000
```

Tampilkan tombol Objek Pajak SIMPBB/dev tool di dashboard:

```bash
flutter run -d chrome --dart-define=ENABLE_DEV_TOOLS=true
```

Run di Linux desktop:

```bash
flutter run -d linux
```

## Validasi

Jalankan static analysis:

```bash
flutter analyze
```

Jalankan test:

```bash
flutter test
```

Build debug web:

```bash
flutter build web --debug
```

Build debug Linux:

```bash
flutter build linux --debug
```

## Status Implementasi

Sudah tersedia:

- UI dashboard utama.
- Login dummy.
- Tab Notifikasi, Approval, dan Log.
- Source Detail.
- Middleware Node.js minimal.
- Halaman Objek Pajak SIMPBB via middleware.
- Model dan provider dummy yang siap diganti backend.

Belum tersedia:

- Login JWT sebenarnya.
- WebSocket real-time.
- Firebase Cloud Messaging.
- Database PostgreSQL untuk log dan approval.
- Endpoint status sinkronisasi real-time dari SIMPBB.
