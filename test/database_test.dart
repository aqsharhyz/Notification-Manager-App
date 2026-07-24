import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite/sqflite.dart';
import 'package:manage_notif_app/models/notification_item.dart';
import 'package:manage_notif_app/models/auto_remove_settings.dart';
import 'package:manage_notif_app/services/database_helper.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  group('Notification Database & Rules Unit Tests', () {
    test('NotificationItem serialization and copyWith', () {
      final now = DateTime.now();
      final item = NotificationItem(
        id: 1,
        packageName: 'com.whatsapp',
        appName: 'WhatsApp',
        title: 'New Message',
        body: 'Hello World',
        timestamp: now,
      );

      final map = item.toMap();
      expect(map['package_name'], 'com.whatsapp');
      expect(map['title'], 'New Message');

      final fromMap = NotificationItem.fromMap(map);
      expect(fromMap.packageName, 'com.whatsapp');
      expect(fromMap.appName, 'WhatsApp');
      expect(fromMap.title, 'New Message');
    });

    test('AutoRemoveSettings model & JSON serialization', () {
      final settings = AutoRemoveSettings(
        retentionDays: 7,
        blockedApps: ['com.junk.app'],
        blockedKeywords: ['promo'],
        excludedAppsFromRetention: ['com.whatsapp'],
        excludedKeywordsFromRetention: ['Bank', 'OTP'],
      );

      final jsonStr = settings.toJson();
      final decoded = AutoRemoveSettings.fromJson(jsonStr);

      expect(decoded.retentionDays, 7);
      expect(decoded.blockedApps, contains('com.junk.app'));
      expect(decoded.blockedKeywords, contains('promo'));
      expect(decoded.excludedAppsFromRetention, contains('com.whatsapp'));
      expect(decoded.excludedKeywordsFromRetention, contains('Bank'));
    });
  });
}
