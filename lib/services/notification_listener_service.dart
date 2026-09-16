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

  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool? isIgnoring = await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return isIgnoring ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('requestIgnoreBatteryOptimizations');
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isListenerConnected() async {
    try {
      final bool? isConnected = await _channel.invokeMethod<bool>('isListenerConnected');
      return isConnected ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> rebindListenerService() async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('rebindListenerService');
      return success ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> isKeepAliveRunning() async {
    try {
      final bool? isRunning = await _channel.invokeMethod<bool>('isKeepAliveRunning');
      return isRunning ?? false;
    } on PlatformException catch (_) {
      return false;
    }
  }

  Future<bool> setKeepAliveService(bool enabled) async {
    try {
      final bool? success = await _channel.invokeMethod<bool>('setKeepAliveService', {'enabled': enabled});
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
