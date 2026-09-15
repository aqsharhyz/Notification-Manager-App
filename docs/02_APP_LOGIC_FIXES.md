# 02. Application Logic Fixes & Architecture

> **Navigation**: [← 01. Business Logic](01_BUSINESS_LOGIC_FIXES.md) | **02. App Logic** | [03. UI/UX Fixes →](03_UI_UX_FIXES.md)

Dokumen ini berfokus pada arsitektur teknis, manajemen konkurensi SQLite, sinkronisasi native-to-Flutter, deduplikasi event, dan paginasi data.

---

## 1. Normalisasi Penyimpanan Ikon Aplikasi (Icon Storage Decoupling)

### Masalah:
- `MyNotificationListener.kt` mengompres launcher icon menjadi byte PNG dan menyimpannya di kolom `app_icon BLOB` pada **setiap baris notifikasi**.
- Jika terdapat 2.000 notifikasi, SQLite menyimpan 2.000 byte array ikon, membuat ukuran database membengkak ratusan megabyte dan memperlambat I/O SQLite.

### Solusi Arsitektural:
1. Pisahkan tabel ikon:
   ```sql
   CREATE TABLE app_icons (
       package_name TEXT PRIMARY KEY,
       app_name TEXT NOT NULL,
       icon_blob BLOB,
       updated_at INTEGER NOT NULL
   );
   ```
2. Tabel `notifications` hanya menyimpan metadata teks dan foreign reference `package_name`.
3. Di sisi UI/Dart, gunakan memory cache (`Map<String, Uint8List>`) untuk icon per package name agar tidak membebani query SQL.

---

## 2. Manajemen Concurrency Database & Single Source of Truth

### Masalah:
- Android native (`MyNotificationListener.kt`) membuka file DB secara langsung (`SQLiteDatabase.openOrCreateDatabase(...)`), sementara Flutter menggunakan plugin `sqflite`.
- Ketika ada burst notifikasi, native membuka dan menutup database berulang kali, berpotensi memicu `SQLiteDatabaseLockedException`.
- Skema tabel didefinisikan ganda: di `MyNotificationListener.kt` (lines 140-159) dan `DatabaseHelper.dart` (lines 33-59).

### Solusi Arsitektural:
1. Pastikan SQLite WAL mode (`enableWriteAheadLogging()`) aktif di native maupun Dart.
2. Gunakan single instance helper di native (`openDatabase` dikelola oleh singleton connection pool di service lifecycle, bukan open-close pada setiap notification event).
3. Sinkronkan skema database: pastikan skema versi 2/3 dikontrol dengan file migrasi yang seragam.

---

## 3. Throttling & Debouncing Broadcast ke UI

### Masalah:
- Setiap kali `saveAndCleanupNotification` selesai, native mengirim `sendBroadcast("com.example.manage_notif_app.NOTIFICATION_SAVED")`.
- `MainActivity.kt` meneruskan ke MethodChannel `onNotificationSaved`.
- `NotificationProvider.dart` langsung memanggil `loadNotifications()` yang mengeksekusi `SELECT *`.
- Pada banjir pesan (10 pesan dalam 1 detik), UI melakukan query ulang 10 kali ke SQLite, menyebabkan UI freezing dan FPS drop drastis.

### Solusi:
- Tambahkan **Debounce Timer (300ms - 500ms)** di sisi Dart:
  ```dart
  Timer? _refreshDebounce;
  void onNotificationReceived() {
    _refreshDebounce?.cancel();
    _refreshDebounce = Timer(const Duration(milliseconds: 400), () {
      loadNotifications();
    });
  }
  ```

---

## 4. Paginasi Data (Cursor / Limit-Offset Querying)

### Masalah:
- `DatabaseHelper.getNotifications()` mengambil seluruh data tanpa limit.
- List view me-render seluruh koleksi, memicu memori tinggi saat data mencapai > 1.000 item.

### Solusi:
- Tambahkan parameter `limit = 50` dan `offset`:
  ```dart
  Future<List<NotificationItem>> getNotifications({
    int limit = 50,
    int offset = 0,
    String? searchQuery,
    List<String>? appFilter,
    DateTimeRange? dateRange,
  });
  ```
- Implementasikan infinite scrolling dengan controller listener pada `NotificationProvider`.

---

## 5. Boot Receiver & Service Re-Binding

### Masalah:
- Belum ada kelas `BroadcastReceiver` native yang menangani event reboot, meskipun izin `RECEIVE_BOOT_COMPLETED` ada di manifest.

### Solusi:
- Buat `BootReceiver.kt`:
  ```kotlin
  class BootReceiver : BroadcastReceiver() {
      override fun onReceive(context: Context, intent: Intent) {
          if (intent.action == Intent.ACTION_BOOT_COMPLETED || intent.action == "android.intent.action.QUICKBOOT_POWERON") {
              // Verifikasi dan pastikan status notification listener aktif
          }
      }
  }
  ```
- Daftarkan receiver di `AndroidManifest.xml`.

---

## 6. Kontrak MethodChannel Native ↔ Flutter

Saluran komunikasi utama: `com.example.manage_notif_app/notifications`

| Method Call | Arah | Parameter | Return Type | Deskripsi |
| :--- | :--- | :--- | :--- | :--- |
| `isPermissionGranted` | Dart → Native | - | `bool` | Memeriksa apakah `NotificationManagerCompat` mengizinkan listener |
| `requestPermission` | Dart → Native | - | `void` | Membuka layar pengaturan Notification Listener Android |
| `fetchActiveNotifications` | Dart → Native | - | `bool` | Memaksa capture semua notifikasi aktif di status bar |
| `launchNotificationAction` | Dart → Native | `sbnKey`, `packageName` | `bool` | Menjalankan `PendingIntent` atau fallback launcher |
| `isIgnoringBatteryOptimizations` | Dart → Native | - | `bool` | Status pengecualian optimasi baterai (Doze mode) |
| `requestIgnoreBatteryOptimizations`| Dart → Native | - | `void` | Menampilkan prompt OS pengecualian hemat baterai |
| `onNotificationSaved` | Native → Dart | - | Event Callback | Broadcast event saat notifikasi baru berhasil disimpan ke SQLite |

---

> **Lanjut Membaca**: [03. UI/UX Fixes & Interaction Design →](03_UI_UX_FIXES.md)
