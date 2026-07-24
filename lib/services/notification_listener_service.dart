import 'dart:async';
import 'package:flutter/services.dart';
import '../models/notification_item.dart';
import 'settings_service.dart';

class NotificationListenerManager {
  static final NotificationListenerManager instance = NotificationListenerManager._init();
  static const MethodChannel _channel = MethodChannel('com.example.manage_notif_app/notifications');

  NotificationListenerManager._init();

  Future<bool> isPermissionGranted() async {
    try {
      final bool? isGranted = await _channel.invokeMethod<bool>('isPermissionGranted');
      return isGranted ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<void> requestPermission() async {
    try {
      await _channel.invokeMethod<void>('requestPermission');
    } on PlatformException catch (_) {
      // Handle error if any
    }
  }

  Future<bool> fetchActiveNotifications() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('fetchActiveNotifications');
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> launchNotificationAction({required String sbnKey, required String packageName}) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('launchNotificationAction', {
        'sbnKey': sbnKey,
        'packageName': packageName,
      });
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  void startListening({
    required Function(NotificationItem) onSaved,
    required SettingsService settingsService,
  }) {
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onNotificationSaved') {
        onSaved(NotificationItem(
          packageName: '',
          appName: '',
          title: '',
          body: '',
          timestamp: DateTime.now(),
        ));
      }
    });
  }

  void stopListening() {
    _channel.setMethodCallHandler(null);
  }
}
