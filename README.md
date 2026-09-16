# Notification Manager (`manage_notif_app`)

A feature-rich Flutter application for Android designed to capture, log, filter, auto-manage, and export system notifications into a local SQLite database.

---

## 🌟 Key Features

- **Saved-First Policy**: Incoming system notifications are saved directly to local storage before applying auto-purge rules, ensuring a full audit trail.
- **Auto-Start on Reboot**: Configured with `RECEIVE_BOOT_COMPLETED` so the background notification listener re-attaches automatically upon device reboot.
- **Flexible Retention & Whitelisting**:
  - Set auto-delete retention thresholds from **1 hour**, **1 day**, **7 days**, **30 days**, or **Never**.
  - Maintain **App & Keyword Whitelists** (Exclude lists) to prevent critical notifications from being auto-purged.
- **App Launcher Icon Integration**: Displays actual launcher icons of the target application in notification cards, falling back to clean text avatars if unavailable.
- **Direct App Launching**: Tap notification cards to trigger cached `PendingIntent` instances or app launcher shortcuts to open the target notification or screen.
- **Search & Multi-Filter**:
  - Search title & content in real time.
  - Filter notifications by app (sorted by volume) or date range presets (Today, Last 7 Days, Last 30 Days, Custom Range).
- **Excel Spreadsheet Export**: Export logged notifications into `.xlsx` spreadsheet files and share them via native OS share sheets.
- **Dark & Light Themes**: Full dark theme support with Light, Dark, and System Default mode selectors.

---

## 🏗 Architecture & Code Structure

The project follows a clean service/provider pattern:

```
lib/
├── models/
│   ├── notification_item.dart        # Data model for saved notifications (includes icon BLOB)
│   └── auto_remove_settings.dart     # Configuration model for retention and whitelist rules
├── services/
│   ├── database_helper.dart         # SQLite helper for notifications DB (schema v2)
│   ├── notification_listener_service.dart # Background service for system notification catching
│   └── settings_service.dart        # SharedPreferences persistence for app settings
├── providers/
│   └── notification_provider.dart   # Main app state, search/filter state, and Excel export logic
├── screens/
│   ├── splash_screen.dart           # Animated initial splash view
│   ├── main_screen.dart             # Main notification list, search, and active filters
│   └── settings_screen.dart         # Retention rules, whitelists, permissions, and theme settings
└── widgets/
    ├── notification_card.dart       # Individual notification UI card with tap-to-open
    └── filter_bottom_sheet.dart     # Advanced filtering sheet by app and date range
```

---

## 🛠 Tech Stack & Dependencies

- **Framework**: [Flutter](https://flutter.dev) (Dart SDK `^3.12.1`)
- **Target Platform**: Android (requires `BIND_NOTIFICATION_LISTENER_SERVICE`)
- **Database**: [`sqflite`](https://pub.dev/packages/sqflite) & [`path`](https://pub.dev/packages/path)
- **State Management**: [`provider`](https://pub.dev/packages/provider)
- **Preferences**: [`shared_preferences`](https://pub.dev/packages/shared_preferences)
- **Formatting & Exporting**: [`excel`](https://pub.dev/packages/excel), [`share_plus`](https://pub.dev/packages/share_plus), [`path_provider`](https://pub.dev/packages/path_provider), [`intl`](https://pub.dev/packages/intl)

---

## 🚀 Getting Started

### Prerequisites

- Flutter SDK `^3.12.1` or higher installed.
- Android Studio / VS Code with Flutter & Dart extensions.
- Android device or emulator running API 21 (Android 5.0) or higher.

### Setup Instructions

1. **Clone the repository**:
   ```bash
   git clone <repository-url>
   cd manage_notif_app
   ```

2. **Install dependencies**:
   ```bash
   flutter pub get
   ```

3. **Run the application**:
   ```bash
   flutter run
   ```

4. **Grant Permissions**:
   - Open the app settings tab in the application.
   - Tap **Enable Notification Access** to grant the app permission to capture system notifications (`BIND_NOTIFICATION_LISTENER_SERVICE`).

---

## 🧪 Testing

Run unit tests (database, retention policy, whitelist filtering):

```bash
flutter test
```

---

## 📄 Documentation

A comprehensive documentation suite is maintained in the [`docs/`](docs/) directory:

- **[Documentation Center](docs/README.md)**: Master index, system architecture diagrams, and roadmap status matrix.
- **[Product Requirements Document (PRD)](docs/PRD.md)**: Complete functional requirements, database models, and verification plans.
- **[01. Business Logic Fixes](docs/01_BUSINESS_LOGIC_FIXES.md)**: 3-tier filtering (Blacklist vs Audit vs Purge), priority resolution, and notification classification.
- **[02. Application Logic Fixes](docs/02_APP_LOGIC_FIXES.md)**: SQLite concurrency, icon decoupling, UI debouncing, pagination, and MethodChannel API contracts.
- **[03. UI/UX Fixes](docs/03_UI_UX_FIXES.md)**: Xiaomi MIUI permission widgets, card hierarchy, quick date presets, and dark theme design tokens.
- **[04. Bug Fixes & Platform Quirks](docs/04_BUG_FIXES.md)**: PendingIntent fallback launching, database race conditions, Android 13+ Restricted Settings, and OEM battery-killer workarounds.
