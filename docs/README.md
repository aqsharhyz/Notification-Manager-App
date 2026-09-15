# Notification Manager Documentation Center

Selamat datang di pusat dokumentasi teknis dan arsitektur aplikasi **Notification Manager (`manage_notif_app`)**. Dokumentasi ini mencakup spesifikasi produk, aturan bisnis inti, arsitektur teknis, desain antarmuka, hingga panduan penanganan edge cases dan vendor OEM Android.

---

## 📚 Indeks Dokumentasi

| Dokumen | Kategori | Ringkasan Topik Utama |
| :--- | :--- | :--- |
| **[PRD.md](PRD.md)** | *Product Requirements* | Spesifikasi fitur v1 & v2, dependensi, skema SQLite v2, dan rencana verifikasi. |
| **[01. Business Logic Fixes](01_BUSINESS_LOGIC_FIXES.md)** | *Domain Logic* | Kebijakan 3-tier (Blacklist vs Audit vs Purge), hierarki prioritas aturan, klasifikasi notifikasi, dan kepatuhan privasi data. |
| **[02. Application Logic Fixes](02_APP_LOGIC_FIXES.md)** | *Architecture & Data* | Normalisasi tabel `app_icons`, manajemen konkurensi SQLite WAL, debouncing broadcast native-to-Dart, paginasi limit-offset, dan kontrak MethodChannel. |
| **[03. UI/UX Fixes](03_UI_UX_FIXES.md)** | *Interface & UX* | Widget Permission Health (Xiaomi/MIUI), hierarki visual kartu notifikasi, preset filter tanggal cepat, restrukturisasi tab pengaturan, dan standar Dark Mode. |
| **[04. Bug Fixes & Quirks](04_BUG_FIXES.md)** | *Edge Cases & Stability* | Fallback `PendingIntent.send()` saat invalidasi, mitigasi lock database, izin Android 13+ *Restricted Settings*, optimasi memori image decoding, dan matriks OEM battery killer. |

---

## 🏛️ Arsitektur Tingkat Tinggi (High-Level Architecture)

```mermaid
graph TD
    subgraph Android Native (Kotlin)
        NL[MyNotificationListener] -->|1. Capture SBN| DB_N[(SQLite DB: notifications)]
        NL -->|2. Cache PendingIntent| PI_MAP[Memory Cache: activePendingIntents]
        NL -->|3. Broadcast| BC[Intent: NOTIFICATION_SAVED]
        BR[BootReceiver] -->|On Boot Completed| NL
        MA[MainActivity] -->|MethodChannel| DART[Flutter Engine]
    end

    subgraph Flutter / Dart
        BC -->|MethodChannel onNotificationSaved| NP[NotificationProvider]
        NP -->|Debounced 400ms Query| DB_H[DatabaseHelper]
        DB_H -->|Read SQLite| DB_N
        NP -->|State Updates| UI_MAIN[MainScreen]
        UI_MAIN -->|Render Cards| NC[NotificationCard]
        UI_MAIN -->|Tap Action| MA
        NP -->|Generate .xlsx| EXCEL[Excel Export Service]
    end
```

---

## 📋 Matriks Status Pengembangan & Rilis

| Fitur / Modul | Versi Rilis | Status | Lokasi Implementasi Utama |
| :--- | :---: | :---: | :--- |
| **SQLite Schema v2 (Icon BLOB support)** | v1.1.0 | ✅ Selesai | [database_helper.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/services/database_helper.dart) |
| **Saved-First Policy (Logging Audit Trail)** | v1.1.0 | ✅ Selesai | [MyNotificationListener.kt](file:///Volumes/Code/Benefits/manage_notif_app/android/app/src/main/kotlin/com/example/manage_notif_app/MyNotificationListener.kt) |
| **Retention by Hours (1h, 24h, 7d, Never)** | v1.1.0 | ✅ Selesai | [database_helper.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/services/database_helper.dart) |
| **Whitelist Exclude Protection (Apps & Keywords)** | v1.1.0 | ✅ Selesai | [auto_remove_settings.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/models/auto_remove_settings.dart) |
| **Direct PendingIntent Launching + Fallback** | v1.1.0 | ✅ Selesai | [MainActivity.kt](file:///Volumes/Code/Benefits/manage_notif_app/android/app/src/main/kotlin/com/example/manage_notif_app/MainActivity.kt) |
| **Spreadsheet (.xlsx) Export & System Share** | v1.1.0 | ✅ Selesai | [notification_provider.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/providers/notification_provider.dart) |
| **Dark Theme Support (System / Light / Dark)** | v1.1.0 | ✅ Selesai | [main.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/main.dart) |
| **Battery Optimization Exemption Check** | v1.1.0 | ✅ Selesai | [MainActivity.kt](file:///Volumes/Code/Benefits/manage_notif_app/android/app/src/main/kotlin/com/example/manage_notif_app/MainActivity.kt) |
| **Debounce Throttling pada Burst Notifikasi** | v1.2.0 | 🔄 In-Progress | [02_APP_LOGIC_FIXES.md](02_APP_LOGIC_FIXES.md#3-throttling--debouncing-broadcast-ke-ui) |
| **Icon Storage Decoupling (Tabel app_icons)** | v1.2.0 | 📋 Direncanakan | [02_APP_LOGIC_FIXES.md](02_APP_LOGIC_FIXES.md#1-normalisasi-penyimpanan-ikon-aplikasi-icon-storage-decoupling) |
| **3-Tier Blacklist vs Audit vs Purge Policy** | v1.2.0 | 📋 Direncanakan | [01_BUSINESS_LOGIC_FIXES.md](01_BUSINESS_LOGIC_FIXES.md#1-definisi-kebijakan-pemfilteran-blacklist-vs-auto-purge-vs-audit) |
| **Preset Filter Tanggal Cepat (Quick Chips)** | v1.2.0 | 📋 Direncanakan | [03_UI_UX_FIXES.md](03_UI_UX_FIXES.md#3-preset-filter-tanggal-cepat-quick-date-filters) |
| **Limit-Offset Pagination (Infinite Scroll)** | v1.3.0 | 📋 Direncanakan | [02_APP_LOGIC_FIXES.md](02_APP_LOGIC_FIXES.md#4-paginasi-data-cursor--limit-offset-querying) |

---

## 🔗 Pintasan Navigasi Cepat

- Mulai dari [PRD.md](PRD.md) untuk memahami latar belakang dan arsitektur dasar.
- Pelajari aturan bisnis di [01. Business Logic Fixes](01_BUSINESS_LOGIC_FIXES.md).
- Telusuri implementasi data dan konkurensi di [02. Application Logic Fixes](02_APP_LOGIC_FIXES.md).
- Periksa panduan visual di [03. UI/UX Fixes](03_UI_UX_FIXES.md).
- Tinjau kestabilan dan trik platform Android di [04. Bug Fixes & Quirks](04_BUG_FIXES.md).
