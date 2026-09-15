# 03. UI/UX Fixes & Interaction Design

> **Navigation**: [← 02. App Logic](02_APP_LOGIC_FIXES.md) | **03. UI/UX Fixes** | [04. Bug Fixes →](04_BUG_FIXES.md)

Dokumen ini berfokus pada penyempurnaan pengalaman pengguna (*user experience*), kejelasan hierarki visual, pemfilteran instan, dan penanganan UX khusus vendor (terutama Xiaomi MIUI/HyperOS).

---

## 1. Panduan Izin Khusus OEM (Xiaomi / MIUI / HyperOS)

### Masalah Pengguna:
- Pada perangkat Xiaomi Redmi Note 10S, pengguna sering mengira aplikasi rusak karena setelah layar mati, notifikasi baru tidak terekam.
- Penyebabnya adalah sistem MIUI mematikan service latar belakang kecuali **Autostart** dan **Battery Saver: No Restrictions** diaktifkan secara manual.
- Di Android 13/14, sideloaded app juga sering terkena dialog *"Restricted Settings"*.

### Solusi UX:
- Sediakan **Permission Health Center Widget / Card**:
  - Tampilkan 3 lampu indikator status:
    1. `Notification Access` (Wajib)
    2. `Battery Optimization Exemption` (Disarankan)
    3. `Autostart Permission` (Khusus Xiaomi/MIUI)
  - Sediakan tombol langsung *"Panduan Xiaomi / MIUI"* dengan langkah ilustratif (buka info aplikasi → centang Mulai Otomatis → pilih Penghemat Baterai: Tidak ada pembatasan).

---

## 2. Peningkatan Visual Hierarchy pada Kartu Notifikasi

### Masalah:
- `NotificationCard` saat ini menampilkan ikon, judul, isi, dan waktu dalam layout yang padat, teks panjang terpotong mendadak, dan tidak ada pembeda visual antar kategori notifikasi.

### Solusi UX:
- **Header Kartu**:
  - Ikon aplikasi (ukuran 28x28 dengan rounded squircle).
  - Nama aplikasi dalam format badge kecil berlatar abu-abu halus / accent.
  - Waktu relatif di pojok kanan atas (`Baru saja`, `5m lalu`, `Kemarin 14:20`).
- **Body Kartu**:
  - Judul ditebalkan (`FontWeight.w600`) dengan maksimal 1 baris.
  - Isi pesan (`FontWeight.w400`) dengan maksimal 2 baris preview.
  - Tap kartu memicu ekspansi accordion untuk membaca isi pesan panjang dan melihat detail timestamp lengkap.
- **Micro-Actions**:
  - Swipe ke kiri: Hapus cepat dari database lokal.
  - Long press / Action button: Salin teks ke clipboard atau buka aplikasi target.

---

## 3. Preset Filter Tanggal Cepat (Quick Date Filters)

### Masalah:
- Pengguna harus membuka kalender `DateTimeRange` hanya untuk melihat notifikasi hari ini atau kemarin, yang memakan waktu dan banyak klik.

### Solusi UX:
- Sediakan barisan horizontal chip filter cepat di bawah search bar:
  - `Semua` | `Hari Ini` | `Kemarin` | `7 Hari Terakhir` | `Kustom (Kalender)`
- Status chip aktif memiliki warna latar primer yang kontras.

---

## 4. Refactoring & Restrukturisasi Settings Screen

### Masalah:
- `settings_screen.dart` memiliki ~770 baris dengan dialog input berulang-ulang untuk Blocked Apps, Blocked Keywords, Excluded Apps, dan Excluded Keywords.
- Teks bantuan tidak menjelaskan perbedaan nyata antara "Daftar Blokir" vs "Whitelist Retensi".

### Solusi UX:
- Pisahkan menjadi 2 tab / segmen yang jelas:
  1. **Tab Aturan Retensi (Auto-Clean)**:
     - Durasi simpan (1 Jam, 24 Jam, 7 Hari, 30 Hari, Selamanya).
     - Whitelist Pengecualian (App/Kata Kunci yang TIDAK BOLEH dihapus oleh pembersihan otomatis).
  2. **Tab Privasi & Filter (Blacklist)**:
     - Aplikasi yang diblokir (tidak akan dicatat sama sekali).
     - Kata kunci yang disensor/diabaikan.
- Gunakan reusable input chip editor dengan autocomplete dari daftar aplikasi yang pernah dicatat.

---

## 5. Alur & Feedback Export Excel yang Transparan

### Masalah:
- Menekan tombol export langsung menghasilkan file di background tanpa ada indikator progres saat data ribuan.

### Solusi UX:
- Tampilkan modal pilihan export:
  - *"Export Semua Data (1.240 notifikasi)"*
  - *"Export Sesuai Filter Saat Ini (45 notifikasi)"*
- Tampilkan `CircularProgressIndicator` dengan teks *"Menyiapkan file spreadsheet..."*.
- Tampilkan opsi dialog Share Sheet bawaan OS setelah file siap.

---

## 6. Standar Tipografi & Desain Dark Theme

Untuk menciptakan tampilan profesional dan nyaman di mata saat kondisi malam:
- **Surface Elevation**: Hindari warna hitam pekat `#000000` merata. Gunakan palet dark elevation:
  - Background: `#121212`
  - Card Surface: `#1E1E1E`
  - Dialog / Sheet: `#252525`
  - Border Stroke: `rgba(255, 255, 255, 0.08)`
- **Aksen & Kontras**:
  - Warna primer: Indigo / Biru modern (`#4F46E5` atau `#3B82F6`)
  - Teks utama: `Colors.white.withOpacity(0.92)`
  - Teks sekunder/waktu: `Colors.white.withOpacity(0.60)`

---

## 7. State Kosong & Feedback Aksi (Empty States & Haptics)

- **Search Not Found**: Tampilkan ilustrasi atau ikon kaca pembesar dengan teks *"Tidak ada notifikasi yang cocok dengan kata kunci"* dan tombol *"Reset Filter"*.
- **Database Kosong**: Tampilkan status siap dengan petunjuk *"Menunggu notifikasi masuk... Pastikan izin akses notifikasi telah aktif."*
- **Haptic Feedback**: Berikan getaran halus (`HapticFeedback.lightImpact()`) saat notifikasi berhasil dihapus atau disalin ke clipboard.

---

> **Lanjut Membaca**: [04. Bug Fixes, Edge Cases & Platform Quirks →](04_BUG_FIXES.md)
