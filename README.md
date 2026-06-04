# IntegraTax

IntegraTax adalah aplikasi mobile Flutter untuk memantau sinkronisasi data Pajak Bumi dan Bangunan (PBB) antar instansi. Aplikasi ini dirancang sebagai dashboard monitoring untuk Administrator IT Bapenda agar dapat melihat status sinkronisasi, menerima alert, meninjau approval, dan membaca log aktivitas dari perangkat mobile.

## Anggota Kelompok

- Rafael Mahardika Arya Dewamurti (24/536279/PA/22755)
- Bobby Rahman Hartanto (24/539383/PA/22903)
- Davi Ezra Syandana (24/538363/PA/22841)
- Axelle Chandra (24/533796/PA/22614)

> **⚠️ Status: Demo / Prototype** — Aplikasi ini menggunakan data dummy untuk dashboard, notifikasi, approval, dan log. Hanya SIMPBB Explorer yang terhubung ke upstream asli melalui middleware. **Jangan gunakan di lingkungan produksi dengan data pajak nyata.**

---

## Fitur Saat Ini

- Dashboard status sinkronisasi BPN, Disdukcapil, dan BPJS.
- Indikator status hijau, kuning, dan merah.
- Pull-to-refresh dengan dummy data.
- Grafik performa respon API 24 jam menggunakan `fl_chart`.
- Navigasi 4 tab: Dashboard, Notifikasi, Approval, dan Log.
- Halaman detail sumber data saat card status diklik.
- Login dummy untuk simulasi autentikasi administrator.
- Provider dummy untuk Notifikasi, Approval, dan Log.
- Middleware Node.js untuk mem-proxy request ke SIMPBB API.
- Halaman Objek Pajak SIMPBB untuk pencarian WP/NOP melalui middleware.
- NOP disamarkan sebagian di tampilan log (privacy: hanya 2 segmen pertama terlihat).

---

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

Endpoint middleware yang tersedia:

| Endpoint | Method | Keterangan |
|---|---|---|
| `/health` | GET | Status middleware |
| `/api/simpbb/search` | POST | Cari objek pajak berdasarkan nama WP |
| `/api/simpbb/list-details` | POST | Daftar objek pajak dengan filter |
| `/api/simpbb/proxy` | POST | Proxy ke endpoint oRPC yang diizinkan |

---

## Tech Stack

- Flutter 3.x / Dart 3.x
- Riverpod 2.x untuk state management
- `http` untuk request API
- `fl_chart` untuk grafik
- `google_fonts` untuk typography
- Node.js + Express 4.x untuk middleware
- `helmet` untuk security headers
- `express-rate-limit` untuk pembatasan request
- Jest + Supertest untuk backend API testing

---

## Struktur Utama

```text
lib/
  core/
    backend_client.dart   # HTTP client (cross-platform, injectable)
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
    mock_data_provider.dart   # Includes maskNop() privacy utility
    simpbb_provider.dart      # Injectable via backendClientProvider
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
  src/server.js           # Hardened Express middleware
  test/server.test.js     # 27 Jest+Supertest API tests
  .env.example            # Template konfigurasi environment
  package.json
test/
  widget_test.dart        # Widget tests (login, approval, log)
  unit/
    auth_provider_test.dart       # 13 unit tests
    mock_data_provider_test.dart  # 12 unit tests (maskNop + relativeTime)
    objek_pajak_model_test.dart   # 14 unit tests (model parsing)
```

---

## Cara Menjalankan

### 1. Install dependencies

```bash
flutter pub get
npm install --prefix backend
```

### 2. Konfigurasi environment backend

```bash
cp backend/.env.example backend/.env
# Edit backend/.env sesuai kebutuhan
```

Variabel penting di `backend/.env`:

| Variabel | Wajib | Keterangan |
|---|---|---|
| `PORT` | Tidak | Port middleware (default: 3000) |
| `SIMPBB_BASE_URL` | Ya (prod) | URL upstream SIMPBB API |
| `INTEGRATAX_API_KEY` | Ya (prod) | Secret key antara Flutter dan middleware |
| `ALLOWED_ORIGIN` | Ya (prod) | CORS origin yang diizinkan |
| `NODE_ENV` | Tidak | `development` atau `production` |

> **Jangan commit file `.env`** — sudah ditambahkan ke `.gitignore`.

### 3. Jalankan middleware

```bash
# Development (auto-restart on file change):
npm run dev --prefix backend

# Production:
npm start --prefix backend
```

Middleware default berjalan di `http://localhost:3000`.

### 4. Jalankan aplikasi Flutter

**Web (Chrome):**

```bash
flutter run -d chrome
```

**Dengan backend di URL custom:**

```bash
flutter run -d chrome --dart-define=INTEGRATAX_API_BASE_URL=http://localhost:3000
```

**Tampilkan SIMPBB Explorer di dashboard:**

```bash
flutter run -d chrome --dart-define=ENABLE_DEV_TOOLS=true
```

**Linux desktop:**

```bash
flutter run -d linux
```

---

## Validasi & Testing

### Static analysis

```bash
flutter analyze
```

### Flutter tests (unit + widget)

```bash
flutter test
# atau dengan output detail:
flutter test --reporter expanded
```

### Backend API tests (Jest + Supertest)

```bash
npm test --prefix backend
```

### Build debug

```bash
flutter build web --debug
flutter build linux --debug
```

### Dependency audit

```bash
flutter pub outdated
npm audit --prefix backend
```

---

## Keamanan

Middleware dilengkapi dengan perlindungan berikut:

- **Helmet** — security headers (X-Frame-Options, X-Content-Type-Options, CSP, dll.)
- **CORS allowlist** — hanya origin dari `ALLOWED_ORIGIN` yang diizinkan
- **Rate limiting** — maksimum 60 request/menit per IP
- **X-IntegraTax-Key** — autentikasi header antara Flutter dan middleware (aktif jika `INTEGRATAX_API_KEY` di-set)
- **Proxy allowlist** — `/api/simpbb/proxy` hanya mengizinkan 4 path SIMPBB yang sudah ditentukan
- **Array params guard** — input array ditolak pada proxy params
- **Upstream timeout** — request ke SIMPBB upstream dibatasi 10 detik
- **Body size limit** — maksimum 1MB per request

### ⚠️ Catatan Keamanan Penting

- **Autentikasi login saat ini adalah DUMMY** — siapapun dengan email dan password non-kosong dapat masuk. Ini harus diganti dengan autentikasi nyata (JWT/OAuth2) sebelum penggunaan produksi.
- **SIMPBB Explorer menampilkan data PII nyata** (nama WP, alamat, NOP). Akses harus dibatasi dengan autentikasi nyata.
- **NOP dalam log disamarkan** sebagian (`32.04.***.***.***.****.*`) di sisi klien. Penyamaran sisi server juga diperlukan untuk kepatuhan penuh.

---

## Status Implementasi

### ✅ Tersedia

- UI dashboard utama dengan MODE DEMO badge.
- Login dummy dengan validasi field kosong.
- Tab Notifikasi, Approval, Log, dan Source Detail.
- Middleware Node.js dengan keamanan lengkap.
- Halaman Objek Pajak SIMPBB via middleware.
- Model dan provider dummy yang siap diganti backend nyata.
- BackendClient injectable via Riverpod (testable).
- 57 Flutter tests + 27 backend API tests.
- NOP masking di tampilan log.
- Accessibility: Semantics pada bottom navigation.
- Feedback karakter minimum pada dialog penolakan approval.

### ❌ Belum Tersedia

- Login JWT / OAuth2 nyata.
- WebSocket real-time untuk dashboard.
- Firebase Cloud Messaging untuk notifikasi push.
- Database PostgreSQL untuk log dan approval.
- Endpoint status sinkronisasi real-time dari SIMPBB.
- Model `DataSource.fromJson()` untuk integrasi API dashboard nyata.
- Pagination pada daftar notifikasi, approval, dan log.
- Responsive layout untuk tablet/desktop web.
