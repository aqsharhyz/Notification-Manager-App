# 04. Bug Fixes, Edge Cases & Platform Quirks

> **Navigation**: [← 03. UI/UX Fixes](03_UI_UX_FIXES.md) | **04. Bug Fixes** | [Docs Index →](README.md)

Dokumen ini mendokumentasikan perbaikan celah teknis (*bug fixes*), penanganan error tidak tertangani (*unhandled exceptions*), dan perilaku khusus sistem operasi Android / vendor OEM.

---

## 1. Penanganan PendingIntent Invalidation & Fallback Crash

### Masalah:
- `pendingIntent.send()` sering melempar `CanceledException` jika notifikasi aslinya di status bar telah dihapus atau ditutup oleh pengguna atau sistem Android.
- Di `MainActivity.kt` lines 65-68, error di-log tapi tidak memberikan sinyal yang jelas ke Flutter untuk mencoba fallback launching via `packageManager.getLaunchIntentForPackage()`.

### Solusi Bug Fix:
- Perbaiki alur eksekusi di `MainActivity.kt`:
  ```kotlin
  val pendingIntent = MyNotificationListener.activePendingIntents[sbnKey]
  var launched = false
  if (pendingIntent != null) {
      try {
          pendingIntent.send()
          launched = true
      } catch (e: Exception) {
          Log.w("MainActivity", "PendingIntent canceled, falling back to package launcher")
          launched = false
      }
  }

  if (!launched) {
      val packageName = call.argument<String>("packageName")
      if (packageName != null) {
          val intent = packageManager.getLaunchIntentForPackage(packageName)
          if (intent != null) {
              startActivity(intent)
              launched = true
          }
      }
  }
  result.success(launched)
  ```

---

## 2. Race Condition Pembaruan State Antara Native & Flutter

### Masalah:
- Ketika ada lonjakan notifikasi masuk bersamaan (misal pesan grup WhatsApp bertubi-tubi), broadcast `NOTIFICATION_SAVED` dikirim secara paralel.
- Setiap pemanggilan memicu eksekusi `DatabaseHelper.getNotifications()`, menyebabkan lock konflik sementara pada SQLite file di Linux/Android filesystem.

### Solusi Bug Fix:
- Terapkan debouncing di `notification_provider.dart` sehingga hanya satu query yang dijalankan setelah jeda tenang 300-500ms.
- Gunakan flag `_isQuerying` untuk mencegah re-entry query tumpang tindih.

---

## 3. Penanganan Izin Restricted Settings di Android 13+ (API 33+)

### Masalah:
- Jika aplikasi di-install melalui file APK / sideloading (bukan dari Google Play Store), Android 13+ memblokir izin Accessibility dan Notification Listener secara otomatis dengan pesan *"Restricted setting"*. Pengguna tidak bisa menyalakan toggle.

### Solusi Bug Fix:
- Tambahkan deteksi status apakah izin berada dalam keadaan terblokir oleh Restricted Settings.
- Berikan tombol petunjuk:
  1. Buka *Pengaturan HP* → *Aplikasi* → *manage_notif_app*.
  2. Tap ikon **tiga titik (menu)** di pojok kanan atas.
  3. Pilih **"Izinkan setelan terbatas" (Allow restricted settings)**.
  4. Kembali ke aplikasi dan berikan izin seperti biasa.

---

## 4. Normalisasi String SharedPreferences Key Format

### Masalah:
- Native Kotlin membaca file XML SharedPreferences dengan key literal `"flutter.auto_remove_settings_v1"`.
- Jika key SharedPreferences di-update di sisi Flutter tanpa memperhatikan format prefix bawaan plugin `shared_preferences`, native Kotlin akan mendapatkan nilai `null` dan aturan filter/retensi gagal diterapkan di latar belakang.

### Solusi Bug Fix:
- Tetapkan konstanta statis bersama dan tambahkan fallback handling serta default value yang aman jika JSON gagal di-parse.

---

## 5. Memory Leak pada Large BLOB Icon Rendering

### Masalah:
- `Image.memory()` yang me-render byte array icon berulang-ulang di dalam ListView dapat menyebabkan jank pada thread UI dan lonjakan memory usage (heap allocation) saat scroll cepat.

### Solusi Bug Fix:
- Tentukan `cacheWidth: 84` dan `cacheHeight: 84` (3x target render 28x28 dp) pada `Image.memory` untuk membatasi ukuran decoding bitmap di memory pool Flutter Engine.
- Gunakan memoization / memory cache singleton di Dart agar byte array icon yang sama tidak di-decode ulang setiap kali item di-recycle.

---

## 6. Matriks Penanganan Perilaku Agresif OEM (Battery Killer)

| Vendor OEM | Perilaku Default OS | Solusi Mitigasi Aplikasi |
| :--- | :--- | :--- |
| **Xiaomi (MIUI / HyperOS)** | Mematikan service saat layar terkunci | Panduan Autostart + Penghemat Baterai "Tanpa Pembatasan" |
| **Samsung (One UI)** | Menempatkan app ke "Sleeping Apps" setelah 3 hari | Minta pengecualian `ACTION_REQUEST_IGNORE_BATTERY_OPTIMIZATIONS` |
| **OPPO / Realme (ColorOS)** | Memblokir background activity secara agresif | Panduan "Allow Background Activity" di App Info |
| **Vivo (Funtouch OS)** | Mematikan koneksi listener saat RAM rendah | Kunci aplikasi di daftar recent apps (Lock icon) |

---

> **Kembali ke Indeks**: [← Kembali ke Dokumentasi Utama](README.md)
