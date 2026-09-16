import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
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

    test('AutoRemoveSettings model with duplicate prevention serialization', () {
      final settings = AutoRemoveSettings(
        retentionHours: 168,
        blockedApps: ['com.junk.app'],
        blockedKeywords: ['promo'],
        excludedAppsFromRetention: ['com.whatsapp'],
        excludedKeywordsFromRetention: ['Bank', 'OTP'],
        ignoreDuplicates: true,
        autoDeleteDuplicates: true,
      );

      final jsonStr = settings.toJson();
      final decoded = AutoRemoveSettings.fromJson(jsonStr);

      expect(decoded.retentionHours, 168);
      expect(decoded.blockedApps, contains('com.junk.app'));
      expect(decoded.blockedKeywords, contains('promo'));
      expect(decoded.excludedAppsFromRetention, contains('com.whatsapp'));
      expect(decoded.excludedKeywordsFromRetention, contains('Bank'));
      expect(decoded.ignoreDuplicates, true);
      expect(decoded.autoDeleteDuplicates, true);
      expect(decoded.keepAliveNotificationEnabled, true);

      final toggled = decoded.copyWith(
        ignoreDuplicates: false,
        autoDeleteDuplicates: false,
        keepAliveNotificationEnabled: false,
      );
      expect(toggled.ignoreDuplicates, false);
      expect(toggled.autoDeleteDuplicates, false);
      expect(toggled.keepAliveNotificationEnabled, false);
    });

    test('DatabaseHelper prevents inserting duplicates when ignoreDuplicates is enabled', () async {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllNotifications();

      final notif1 = NotificationItem(
        packageName: 'com.telegram.messenger',
        appName: 'Telegram',
        title: 'John Doe',
        body: 'Meeting at 3 PM',
        timestamp: DateTime.now(),
      );

      // First insert should succeed
      final id1 = await dbHelper.insertNotification(notif1, ignoreDuplicates: true);
      expect(id1, greaterThan(0));

      // Duplicate insert with same package, title, and body should return 0 (skipped)
      final duplicate = NotificationItem(
        packageName: 'com.telegram.messenger',
        appName: 'Telegram',
        title: 'John Doe',
        body: 'Meeting at 3 PM',
        timestamp: DateTime.now().add(const Duration(seconds: 10)),
      );
      final id2 = await dbHelper.insertNotification(duplicate, ignoreDuplicates: true);
      expect(id2, 0);

      // Total count in database should still be 1
      final rows = await dbHelper.getNotifications();
      expect(rows.length, 1);
    });

    test('DatabaseHelper deleteDuplicates removes duplicates keeping the latest', () async {
      final dbHelper = DatabaseHelper.instance;
      await dbHelper.clearAllNotifications();

      // Insert duplicates directly with ignoreDuplicates: false to simulate legacy or existing duplicates
      final baseTime = DateTime.now();
      await dbHelper.insertNotification(
        NotificationItem(
          packageName: 'com.whatsapp',
          appName: 'WhatsApp',
          title: 'Alice',
          body: 'Hello',
          timestamp: baseTime.subtract(const Duration(minutes: 5)),
        ),
        ignoreDuplicates: false,
      );
      await dbHelper.insertNotification(
        NotificationItem(
          packageName: 'com.whatsapp',
          appName: 'WhatsApp',
          title: 'Alice',
          body: 'Hello',
          timestamp: baseTime.subtract(const Duration(minutes: 2)),
        ),
        ignoreDuplicates: false,
      );
      await dbHelper.insertNotification(
        NotificationItem(
          packageName: 'com.whatsapp',
          appName: 'WhatsApp',
          title: 'Alice',
          body: 'Hello',
          timestamp: baseTime,
        ),
        ignoreDuplicates: false,
      );

      // Insert another distinct notification
      await dbHelper.insertNotification(
        NotificationItem(
          packageName: 'com.slack',
          appName: 'Slack',
          title: 'Bob',
          body: 'Sprint planning',
          timestamp: baseTime,
        ),
        ignoreDuplicates: false,
      );

      // Before delete, 4 rows exist
      final beforeRows = await dbHelper.getNotifications();
      expect(beforeRows.length, 4);

      // Run deleteDuplicates
      final deletedCount = await dbHelper.deleteDuplicates();
      expect(deletedCount, 2);

      // After delete, exactly 2 unique notifications remain
      final afterRows = await dbHelper.getNotifications();
      expect(afterRows.length, 2);
      expect(afterRows.any((r) => r.packageName == 'com.whatsapp' && r.body == 'Hello'), true);
      expect(afterRows.any((r) => r.packageName == 'com.slack' && r.body == 'Sprint planning'), true);
    });
  });
}
