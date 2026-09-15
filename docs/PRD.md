# Product Requirements Document (PRD) & Implementation Plan

A Flutter application designed to listen to system notifications on Android, save them locally in a structured SQLite database, display them in a searchable and filterable list UI, and automatically manage notification retention based on configurable auto-remove & whitelist rules.

## User Feedback & Core Requirements

1. **Saved First Policy**: Incoming notifications matching auto-remove rules are **saved to the database first**, then marked or purged according to user settings, ensuring an accurate history/audit log.
2. **Auto-Start on Reboot**: Background notification listening service is configured with `RECEIVE_BOOT_COMPLETED` so it automatically re-attaches and starts listening when the device reboots.
3. **Retention Exclude List (Whitelist)**: User can specify apps or keywords that are **excluded from auto-removal** (retention cleanup policy), keeping important notifications safe from being purged.
4. **App Launcher Icon Display**: Retrieve actual launcher icons from target apps and display them in the notification card, falling back to a text avatar if unavailable.
5. **Direct Notification Launch Action**: Tap on a notification card to directly open the target app at the specific notification location/screen (via Android `PendingIntent`) or launch the app's home screen.
6. **1 Hour Auto-Delete Retention**: Flexible retention policy supporting hours instead of days (e.g. 1 hour, 1 day, 7 days, etc.).
7. **App Search & Sort Filters**: App filter list sorted by notification volume (most notifications first) and filterable via search query without redundant calculations.
8. **Dark Theme Support**: Premium dark theme mode with light/dark/system mode selector.
9. **Excel Export**: Export saved notifications to an `.xlsx` spreadsheet and share/save via system share sheet.

---

## Technical Specifications & Architecture

### Dependencies & Configuration

#### [MODIFY] [pubspec.yaml](file:///Volumes/Code/Benefits/manage_notif_app/pubspec.yaml)
Add packages for database storage, notification listening, state management, app info, and UI:
- `sqflite` & `path`: Local SQLite database storage and performant SQL filtering/searching.
- `provider`: App state management for live updates.
- `shared_preferences`: Persist user auto-cleanup rules and preferences.
- `intl`: Date formatting and relative time calculation (e.g., "5m ago", "Yesterday").
- `excel`: Excel sheet generation (`.xlsx`).
- `share_plus`: File sharing and trigger native OS share sheet.
- `path_provider`: Locate application directories to store temporary files before sharing.

#### [MODIFY] [AndroidManifest.xml](file:///Volumes/Code/Benefits/manage_notif_app/android/app/src/main/AndroidManifest.xml)
- Declare `BIND_NOTIFICATION_LISTENER_SERVICE` permission and background service registration.
- Declare `RECEIVE_BOOT_COMPLETED` permission and `BootReceiver` so notification service re-attaches automatically when device reboots.
- Add `QUERY_ALL_PACKAGES` permission to fetch app labels and icons for notification filtering.

---

### Core Models & Database

#### [NEW] [notification_item.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/models/notification_item.dart)
Define data model for saved notifications:
- Fields: `id`, `packageName`, `appName`, `title`, `body`, `timestamp` (DateTime), `isRead` (bool), `channelId` (stores `sbn.key`), `isAutoRemoved` (bool), `appIcon` (Uint8List? representing actual icon bytes).

#### [NEW] [auto_remove_settings.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/models/auto_remove_settings.dart)
Define model for user auto-cleanup & whitelist rules:
- `retentionHours` (int: e.g. 1 hour, 24 hours, 168 hours, or 0 for unlimited).
- `blockedApps` (List<String> of package names to auto-remove/purge).
- `blockedKeywords` (List<String> of keywords to auto-remove/purge).
- `excludedAppsFromRetention` (List<String> of package names **never** purged by retention).
- `excludedKeywordsFromRetention` (List<String> of keywords **never** purged by retention).

#### [NEW] [database_helper.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/services/database_helper.dart)
SQLite database helper managing table `notifications` (version 2 schema with `app_icon BLOB` column):
- CRUD methods: `insertNotification`, `getNotifications(searchQuery, appFilters, dateRange)`, `deleteNotification`, `clearAllNotifications`.
- `getUniqueApps()`: Returns apps sorted by notification count descending.
- Retention & Cleanup methods with Exclude (Whitelist) protection:
  - `purgeRetentionOlderThan(int retentionHours, List<String> excludedApps, List<String> excludedKeywords)`: Purges entries older than threshold **unless** package name is in `excludedApps` or title/body contains any `excludedKeywords`.

---

### Services & Providers

#### [NEW] [settings_service.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/services/settings_service.dart)
Manage loading/saving `AutoRemoveSettings` to `SharedPreferences`.

#### [NEW] [notification_listener_service.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/services/notification_listener_service.dart)
- Initialize system notification listener with auto-restart capability.
- Handle incoming notification events:
  1. **Saved First**: Write incoming notification to SQLite database via `DatabaseHelper`, saving the icon blob and the `sbn.key`.
  2. Cache active `PendingIntents` in memory for tap-to-open actions.
  3. Execute retention cleanup.

#### [NEW] [notification_provider.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/providers/notification_provider.dart)
Provider class managing list state:
- Holds current list of notifications, theme mode, search query, selected app filter list, and date range filter.
- Exposes Excel export methods utilizing `excel` and `share_plus` packages.

---

### UI Components & Screens

#### [NEW] [main_screen.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/screens/main_screen.dart)
Main view containing:
- **Top Bar**: Title, Permission Status indicator badge, settings link.
- **Search Bar**: Real-time keyword filter input.
- **Filter Chips Row**: App selection filter button, Date range dropdown/chip, active filter badges.
- **Notification List**: Scrollable list of notification cards with empty state.

#### [NEW] [notification_card.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/widgets/notification_card.dart)
Widget rendering individual notification item:
- App Icon image (retrieved from database) or text fallback avatar.
- Tap action to launch direct notification location inside the target app.
- Title & Body preview.
- Relative Timestamp (e.g., "10m ago").
- Quick actions: Copy content, Delete.

#### [NEW] [filter_bottom_sheet.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/widgets/filter_bottom_sheet.dart)
Bottom sheet for advanced filtering:
- App multiselect list sorted by frequency.
- Date range presets (Today, Last 7 days, Last 30 days, Custom range).

#### [NEW] [settings_screen.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/screens/settings_screen.dart)
Settings view for auto-remove, auto-restart, and rule management:
- **Permission Card**: Check permission status & button to open Notification Access settings.
- **Theme Settings**: Dropdown to select Light/Dark/System theme.
- **Retention Period**: Dropdown to select auto-delete threshold (1 hour, 1 day, 3 days, 7 days, 14 days, 30 days, Never).
- **Excel Export Button**: Export saved notifications to spreadsheets and share.
- **Exclude List (Whitelist from Auto-Delete)**: Add apps/keywords protected from retention.
- **Auto-Remove Rules**: Interface to add/remove apps or keywords for automatic removal.

#### [NEW] [splash_screen.dart](file:///Volumes/Code/Benefits/manage_notif_app/lib/screens/splash_screen.dart)
- Displays app icon/logo for 500ms with scale and fade animation before transiting to Main Screen.

---

## Verification Plan

### Automated Tests
- Database unit tests (`test/database_test.dart`):
  - Verify auto-delete retention and whitelists work with `retentionHours`.
  - Run `flutter analyze` and `flutter test`.

### Manual Verification
- Test on Android emulator / device:
  1. Toggle Light/Dark modes in settings.
  2. Tap "Export to Excel" and share it to ensure file format validity.
  3. Verify tap redirection triggers target app screen opening.
