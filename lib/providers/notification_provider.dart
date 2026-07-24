import 'package:flutter/material.dart';
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

  List<NotificationItem> get notifications => _notifications;
  List<Map<String, String>> get availableApps => _availableApps;
  AutoRemoveSettings get settings => _settings;

  String get searchQuery => _searchQuery;
  List<String> get selectedAppsFilter => _selectedAppsFilter;
  DateTimeRange? get selectedDateRange => _selectedDateRange;
  bool get isLoading => _isLoading;
  bool get isPermissionGranted => _isPermissionGranted;

  NotificationProvider() {
    init();
  }

  Future<void> init() async {
    await checkPermission();
    await loadSettings();
    await loadNotifications();
    _startListener();
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
      _notifications = await DatabaseHelper.instance.getNotifications(
        searchQuery: _searchQuery,
        appFilter: _selectedAppsFilter,
        dateRange: _selectedDateRange,
      );

      _availableApps = await DatabaseHelper.instance.getUniqueApps();
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

    // 2. Purge retention days with exclude rules
    if (_settings.retentionDays > 0) {
      await DatabaseHelper.instance.purgeRetentionOlderThan(
        retentionDays: _settings.retentionDays,
        excludedApps: _settings.excludedAppsFromRetention,
        excludedKeywords: _settings.excludedKeywordsFromRetention,
      );
    }

    await loadNotifications();
  }
}
