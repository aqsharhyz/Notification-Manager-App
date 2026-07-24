import 'dart:async';
import 'package:flutter/material.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/notification_item.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();
  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDB('manage_notifications.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE notifications (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        package_name TEXT NOT NULL,
        app_name TEXT NOT NULL,
        title TEXT NOT NULL,
        body TEXT NOT NULL,
        timestamp INTEGER NOT NULL,
        is_read INTEGER DEFAULT 0,
        channel_id TEXT,
        is_auto_removed INTEGER DEFAULT 0
      )
    ''');

    await db.execute('CREATE INDEX idx_timestamp ON notifications(timestamp)');
    await db.execute('CREATE INDEX idx_package_name ON notifications(package_name)');
  }

  Future<int> insertNotification(NotificationItem item) async {
    final db = await database;
    return await db.insert('notifications', item.toMap());
  }

  Future<List<NotificationItem>> getNotifications({
    String? searchQuery,
    List<String>? appFilter,
    DateTimeRange? dateRange,
    bool includeAutoRemoved = true,
  }) async {
    final db = await database;

    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (!includeAutoRemoved) {
      whereClauses.add('is_auto_removed = 0');
    }

    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      final query = '%${searchQuery.trim().toLowerCase()}%';
      whereClauses.add('(LOWER(title) LIKE ? OR LOWER(body) LIKE ? OR LOWER(app_name) LIKE ? OR LOWER(package_name) LIKE ?)');
      whereArgs.addAll([query, query, query, query]);
    }

    if (appFilter != null && appFilter.isNotEmpty) {
      final placeholders = List.filled(appFilter.length, '?').join(',');
      whereClauses.add('package_name IN ($placeholders)');
      whereArgs.addAll(appFilter);
    }

    if (dateRange != null) {
      whereClauses.add('timestamp >= ? AND timestamp <= ?');
      whereArgs.add(dateRange.start.millisecondsSinceEpoch);
      whereArgs.add(dateRange.end.millisecondsSinceEpoch);
    }

    final whereString = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : null;

    final result = await db.query(
      'notifications',
      where: whereString,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'timestamp DESC',
    );

    return result.map((map) => NotificationItem.fromMap(map)).toList();
  }

  Future<List<Map<String, String>>> getUniqueApps() async {
    final db = await database;
    final result = await db.rawQuery('''
      SELECT DISTINCT package_name, app_name 
      FROM notifications 
      ORDER BY app_name ASC
    ''');

    return result.map((row) => {
      'package_name': row['package_name'] as String? ?? '',
      'app_name': row['app_name'] as String? ?? '',
    }).toList();
  }

  Future<int> deleteNotification(int id) async {
    final db = await database;
    return await db.delete(
      'notifications',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<int> clearAllNotifications() async {
    final db = await database;
    return await db.delete('notifications');
  }

  /// Purges notifications matching blocked apps or blocked keywords after saving
  Future<int> purgeBlockedNotifications({
    required List<String> blockedApps,
    required List<String> blockedKeywords,
  }) async {
    final db = await database;
    int deletedCount = 0;

    if (blockedApps.isNotEmpty) {
      final placeholders = List.filled(blockedApps.length, '?').join(',');
      deletedCount += await db.delete(
        'notifications',
        where: 'package_name IN ($placeholders)',
        whereArgs: blockedApps,
      );
    }

    for (final keyword in blockedKeywords) {
      if (keyword.trim().isEmpty) continue;
      final query = '%${keyword.trim().toLowerCase()}%';
      deletedCount += await db.delete(
        'notifications',
        where: '(LOWER(title) LIKE ? OR LOWER(body) LIKE ?)',
        whereArgs: [query, query],
      );
    }

    return deletedCount;
  }

  /// Purges notifications older than retention days UNLESS protected by exclude whitelist
  Future<int> purgeRetentionOlderThan({
    required int retentionDays,
    required List<String> excludedApps,
    required List<String> excludedKeywords,
  }) async {
    if (retentionDays <= 0) return 0; // 0 means retention disabled / keep forever

    final db = await database;
    final cutoffTimestamp = DateTime.now()
        .subtract(Duration(days: retentionDays))
        .millisecondsSinceEpoch;

    List<String> whereClauses = ['timestamp < ?'];
    List<dynamic> whereArgs = [cutoffTimestamp];

    // Exclude protected apps from retention purge
    if (excludedApps.isNotEmpty) {
      final placeholders = List.filled(excludedApps.length, '?').join(',');
      whereClauses.add('package_name NOT IN ($placeholders)');
      whereArgs.addAll(excludedApps);
    }

    // Exclude protected keywords from retention purge
    for (final keyword in excludedKeywords) {
      if (keyword.trim().isEmpty) continue;
      final query = '%${keyword.trim().toLowerCase()}%';
      whereClauses.add('LOWER(title) NOT LIKE ? AND LOWER(body) NOT LIKE ?');
      whereArgs.addAll([query, query]);
    }

    return await db.delete(
      'notifications',
      where: whereClauses.join(' AND '),
      whereArgs: whereArgs,
    );
  }
}
