# Product Requirements Document (PRD) & Implementation Plan

A Flutter application designed to listen to system notifications on Android, save them locally in a structured SQLite database, display them in a searchable and filterable list UI, and automatically manage notification retention based on configurable auto-remove & whitelist rules.

## User Feedback & Core Requirements

1. **Saved First Policy**: Incoming notifications matching auto-remove rules are **saved to the database first**, then marked or purged according to user settings, ensuring an accurate history/audit log.
2. **Auto-Start on Reboot**: Background notification listening service is configured with `RECEIVE_BOOT_COMPLETED` so it automatically re-attaches and starts listening when the device reboots.
3. **Retention Exclude List (Whitelist)**: User can specify apps or keywords that are **excluded from auto-removal days** (retention cleanup policy), keeping important notifications safe from being purged.

---

## Technical Specifications & Architecture

### Dependencies & Configuration

#### [MODIFY] [pubspec.yaml](file:///Volumes/Code/Benefits/manage_notif_app/pubspec.yaml)
Add packages for database storage, notification listening, state management, app info, and UI:
- `sqflite` & `path`: Local SQLite database storage and performant SQL filtering/searching.
- `notifications_listener_service`: Catch system notification events in background/foreground.
- `provider`: App state management for live updates.
- `shared_preferences`: Persist user auto-cleanup rules and preferences.
- `intl`: Date formatting and relative time calculation (e.g., "5m ago", "Yesterday").

#### [MODIFY] [AndroidManifest.xml](file:///Volumes/Code/Benefits/manage_notif_app/android/app/src/main/AndroidManifest.xml)
- Declare `BIND_NOTIFICATION_LISTENER_SERVICE` permission and background service registration.
- Declare `RECEIVE_BOOT_COMPLETED` permission and `BootReceiver` so notification service re-attaches automatically when device reboots.
- Add `QUERY_ALL_PACKAGES` permission to fetch app labels and icons for notification filtering.

---

### Core Models & Database

#### [NEW] [notification_item.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/models/notification_item.dart)
Define data model for saved notifications:
- Fields: `id`, `packageName`, `appName`, `title`, `body`, `timestamp` (DateTime), `isRead` (bool), `channelId`, `isAutoRemoved` (bool).

#### [NEW] [auto_remove_settings.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/models/auto_remove_settings.dart)
Define model for user auto-cleanup & whitelist rules:
- `retentionDays` (int: e.g. 1, 3, 7, 14, 30 days, or 0 for unlimited).
- `blockedApps` (List<String> of package names to auto-remove/purge).
- `blockedKeywords` (List<String> of keywords to auto-remove/purge).
- `excludedAppsFromRetention` (List<String> of package names **never** purged by retention days).
- `excludedKeywordsFromRetention` (List<String> of keywords **never** purged by retention days).

#### [NEW] [database_helper.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/services/database_helper.dart)
SQLite database helper managing table `notifications`:
- CRUD methods: `insertNotification`, `getNotifications(searchQuery, appFilters, dateRange)`, `deleteNotification`, `clearAllNotifications`.
- Retention & Cleanup methods with Exclude (Whitelist) protection:
  - `purgeOlderThan(Duration duration, List<String> excludedApps, List<String> excludedKeywords)`: Purges entries older than threshold **unless** package name is in `excludedApps` or title/body contains any `excludedKeywords`.
  - `purgeByApp(String packageName)`.
  - `purgeByKeyword(String keyword)`.

---

### Services & Providers

#### [NEW] [settings_service.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/services/settings_service.dart)
Manage loading/saving `AutoRemoveSettings` (including exclude/whitelist rules) to `SharedPreferences`.

#### [NEW] [notification_listener_service.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/services/notification_listener_service.dart)
- Initialize system notification listener with auto-restart capability on boot.
- Handle incoming notification events:
  1. **Saved First**: Write incoming notification to SQLite database via `DatabaseHelper`.
  2. Check auto-remove app/keyword rules (if matched, process auto-purge or flag).
  3. Execute retention cleanup respecting `excludedAppsFromRetention` and `excludedKeywordsFromRetention`.

#### [NEW] [notification_provider.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/providers/notification_provider.dart)
Provider class managing list state:
- Holds current list of notifications, search query, selected app filter list, and date range filter.
- Exposes functions for `search()`, `applyFilter()`, `resetFilters()`, `deleteNotification()`, and `refresh()`.

---

### UI Components & Screens

#### [NEW] [main_screen.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/screens/main_screen.dart)
Main view containing:
- **Top Bar**: Title, Permission Status indicator badge, link to Settings screen.
- **Search Bar**: Real-time keyword filter input.
- **Filter Chips Row**: App selection filter button, Date range dropdown/chip, active filter badges.
- **Notification List**: Infinite/scrollable list of notification cards with empty state.
- **Swipe-to-delete** or tap to view full notification details.

#### [NEW] [notification_card.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/widgets/notification_card.dart)
Widget rendering individual notification item:
- App Icon + App Name
- Title & Body preview
- Relative Timestamp (e.g., "10m ago")
- Quick actions: Copy content, Delete.

#### [NEW] [filter_bottom_sheet.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/widgets/filter_bottom_sheet.dart)
Bottom sheet for advanced filtering:
- App multiselect list.
- Date range picker (Today, Last 7 days, Last 30 days, Custom range).

#### [NEW] [settings_screen.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/screens/settings_screen.dart)
Settings view for auto-remove, auto-restart, and rule management:
- **Permission Card**: Check permission status & button to open Notification Access settings.
- **Retention Period**: Dropdown to select auto-delete threshold (1 day, 3 days, 7 days, 14 days, 30 days, Never).
- **Exclude List (Whitelist from Auto-Delete)**: Add apps or keywords that will **NEVER** be purged by the retention period.
- **Auto-Remove Rules**: Interface to add/remove apps or keywords for automatic removal.
- **Manual Actions**: Buttons for "Run Cleanup Now" and "Clear All Data".

#### [MODIFY] [main.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/main.dart)
Initialize `MultiProvider`, setup SQLite DB, and set `MainScreen` as home route.

---

## Verification Plan

### Automated Tests
- Unit tests for `AutoRemoveSettings` and exclude/whitelist logic:
  - Verify notifications containing excluded keywords or from excluded apps are NOT purged when `purgeOlderThan()` is called.
  - Verify saved-first contract guarantees every notification gets inserted before post-processing.
- Database tests (`test/database_test.dart`):
  - Insertion, query with LIKE filter, app package filter, date filtering, whitelist retention exclusion, and bulk delete.

### Manual Verification
- Test on Android emulator / device:
  1. Grant Notification Access permission in Android Settings.
  2. Reboot emulator (`adb reboot`) and verify notification service re-starts automatically.
  3. Send a test notification (e.g. by sending an SMS to the emulator, or triggering a notification from another app).
  4. Verify notification is saved first in DB.
  5. Add app/keyword to Exclude List, set retention to 1 day -> verify excluded notifications are kept while other old notifications are purged.
