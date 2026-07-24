import 'dart:typed_data';

class NotificationItem {
  final int? id;
  final String packageName;
  final String appName;
  final String title;
  final String body;
  final DateTime timestamp;
  final bool isRead;
  final String? channelId;
  final bool isAutoRemoved;
  final Uint8List? appIcon;

  NotificationItem({
    this.id,
    required this.packageName,
    required this.appName,
    required this.title,
    required this.body,
    required this.timestamp,
    this.isRead = false,
    this.channelId,
    this.isAutoRemoved = false,
    this.appIcon,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'package_name': packageName,
      'app_name': appName,
      'title': title,
      'body': body,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'is_read': isRead ? 1 : 0,
      'channel_id': channelId,
      'is_auto_removed': isAutoRemoved ? 1 : 0,
      'app_icon': appIcon,
    };
  }

  factory NotificationItem.fromMap(Map<String, dynamic> map) {
    return NotificationItem(
      id: map['id'] as int?,
      packageName: map['package_name'] as String? ?? '',
      appName: map['app_name'] as String? ?? '',
      title: map['title'] as String? ?? '',
      body: map['body'] as String? ?? '',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      isRead: (map['is_read'] as int? ?? 0) == 1,
      channelId: map['channel_id'] as String?,
      isAutoRemoved: (map['is_auto_removed'] as int? ?? 0) == 1,
      appIcon: map['app_icon'] as Uint8List?,
    );
  }

  NotificationItem copyWith({
    int? id,
    String? packageName,
    String? appName,
    String? title,
    String? body,
    DateTime? timestamp,
    bool? isRead,
    String? channelId,
    bool? isAutoRemoved,
    Uint8List? appIcon,
  }) {
    return NotificationItem(
      id: id ?? this.id,
      packageName: packageName ?? this.packageName,
      appName: appName ?? this.appName,
      title: title ?? this.title,
      body: body ?? this.body,
      timestamp: timestamp ?? this.timestamp,
      isRead: isRead ?? this.isRead,
      channelId: channelId ?? this.channelId,
      isAutoRemoved: isAutoRemoved ?? this.isAutoRemoved,
      appIcon: appIcon ?? this.appIcon,
    );
  }
}
