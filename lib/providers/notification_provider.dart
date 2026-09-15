import 'dart:io';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import '../models/notification_item.dart';
import '../models/auto_remove_settings.dart';
import '../services/database_helper.dart';
import '../services/settings_service.dart';
import '../services/notification_listener_service.dart';

class NotificationProvider with ChangeNotifier {
  final SettingsService _settingsService = SettingsService();

  List<NotificationItem> _notifications = [];
  List<Map<String, String>> _availableApps = [];
  AutoRemoveSettings _settings = AutoRemoveSettings();

  String _searchQuery = '';
  List<String> _selectedAppsFilter = [];
  DateTimeRange? _selectedDateRange;
  bool _isLoading = false;
  bool _isPermissionGranted = false;
  ThemeMode _themeMode = ThemeMode.system;

  List<NotificationItem> get notifications => _notifications;
  List<Map<String, String>> get availableApps => _availableApps;
  AutoRemoveSettings get settings => _settings;

  String get searchQuery => _searchQuery;
  List<String> get selectedAppsFilter => _selectedAppsFilter;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  bool get isLoading => _isLoading;
  bool get isPermissionGranted => _isPermissionGranted;
  ThemeMode get themeMode => _themeMode;

  NotificationProvider() {
    init();
  }

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final index = prefs.getInt('theme_mode_index') ?? ThemeMode.system.index;
      _themeMode = ThemeMode.values[index];
      notifyListeners();
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }

    await checkPermission();
    await loadSettings();
    await loadNotifications();
    _startListener();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('theme_mode_index', mode.index);
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
    }
  }

  Future<void> checkPermission() async {
    _isPermissionGranted = await NotificationListenerManager.instance.isPermissionGranted();
    notifyListeners();
  }

  Future<void> requestPermission() async {
    await NotificationListenerManager.instance.requestPermission();
    await checkPermission();
  }

  Future<bool> fetchActiveNotifications() async {
    final success = await NotificationListenerManager.instance.fetchActiveNotifications();
    if (success) {
      await loadNotifications();
    }
    return success;
  }

  Future<void> loadSettings() async {
    _settings = await _settingsService.loadSettings();
    notifyListeners();
  }

  Future<void> updateSettings(AutoRemoveSettings newSettings) async {
    _settings = newSettings;
    await _settingsService.saveSettings(newSettings);
    notifyListeners();
    await runCleanupNow();
  }

  Future<void> loadNotifications() async {
    _isLoading = true;
    notifyListeners();

    try {
      final dbPath = await getDatabasesPath();
      final path = join(dbPath, 'manage_notifications.db');
      final exists = await File(path).exists();
      debugPrint('[DIAGNOSTIC] SQLite DB Path: $path');
      debugPrint('[DIAGNOSTIC] SQLite DB Exists: $exists');

      _notifications = await DatabaseHelper.instance.getNotifications(
        searchQuery: _searchQuery,
        appFilter: _selectedAppsFilter,
        dateRange: _selectedDateRange,
      );

      final allRows = await DatabaseHelper.instance.getNotifications();
      debugPrint('[DIAGNOSTIC] SQLite Loaded Rows (Filtered): ${_notifications.length}');
      debugPrint('[DIAGNOSTIC] SQLite Loaded Rows (All): ${allRows.length}');

      _availableApps = await DatabaseHelper.instance.getUniqueApps();
      debugPrint('[DIAGNOSTIC] SQLite Unique Apps Count: ${_availableApps.length}');
    } catch (e) {
      debugPrint('Error loading notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void _startListener() {
    NotificationListenerManager.instance.startListening(
      onSaved: (NotificationItem newItem) {
        // Trigger live refresh when new notification arrives
        loadNotifications();
      },
      settingsService: _settingsService,
    );
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    loadNotifications();
  }

  void setSelectedAppsFilter(List<String> apps) {
    _selectedAppsFilter = apps;
    loadNotifications();
  }

  void setSelectedDateRange(DateTimeRange? range) {
    _selectedDateRange = range;
    loadNotifications();
  }

  void clearFilters() {
    _searchQuery = '';
    _selectedAppsFilter = [];
    _selectedDateRange = null;
    loadNotifications();
  }

  Future<void> deleteNotification(int id) async {
    await DatabaseHelper.instance.deleteNotification(id);
    await loadNotifications();
  }

  Future<bool> launchNotificationAction(NotificationItem item) async {
    return await NotificationListenerManager.instance.launchNotificationAction(
      sbnKey: item.channelId ?? '',
      packageName: item.packageName,
    );
  }

  Future<void> clearAll() async {
    await DatabaseHelper.instance.clearAllNotifications();
    await loadNotifications();
  }

  Future<void> runCleanupNow() async {
    _isLoading = true;
    notifyListeners();

    // 1. Purge blocked apps/keywords
    await DatabaseHelper.instance.purgeBlockedNotifications(
      blockedApps: _settings.blockedApps,
      blockedKeywords: _settings.blockedKeywords,
    );

    // 2. Purge retention hours with exclude rules
    if (_settings.retentionHours > 0) {
      await DatabaseHelper.instance.purgeRetentionOlderThan(
        retentionHours: _settings.retentionHours,
        excludedApps: _settings.excludedAppsFromRetention,
        excludedKeywords: _settings.excludedKeywordsFromRetention,
      );
    }

    await loadNotifications();
  }

  Future<String?> exportToExcel() async {
    try {
      final allNotifs = await DatabaseHelper.instance.getNotifications();
      if (allNotifs.isEmpty) return null;

      final excel = Excel.createExcel();
      final sheet = excel['Notifications'];
      excel.delete('Sheet1'); // Remove default sheet

      // Add Headers
      sheet.appendRow([
        TextCellValue('ID'),
        TextCellValue('App Name'),
        TextCellValue('Package Name'),
        TextCellValue('Title'),
        TextCellValue('Body'),
        TextCellValue('Timestamp'),
        TextCellValue('Is Read'),
        TextCellValue('Is Auto Removed')
      ]);

      // Add Rows
      for (final item in allNotifs) {
        sheet.appendRow([
          IntCellValue(item.id ?? 0),
          TextCellValue(item.appName),
          TextCellValue(item.packageName),
          TextCellValue(item.title),
          TextCellValue(item.body),
          TextCellValue(item.timestamp.toIso8601String()),
          IntCellValue(item.isRead ? 1 : 0),
          IntCellValue(item.isAutoRemoved ? 1 : 0)
        ]);
      }

      // Save file to a temporary directory
      final tempDir = await getTemporaryDirectory();
      final dateStr = DateTime.now().millisecondsSinceEpoch;
      final filePath = '${tempDir.path}/notifications_export_$dateStr.xlsx';
      final fileBytes = excel.save();
      
      if (fileBytes != null) {
        final file = File(filePath);
        await file.writeAsBytes(fileBytes);
        return filePath;
      }
      return null;
    } catch (e) {
      debugPrint('Error exporting to Excel: $e');
      return null;
    }
  }
}
