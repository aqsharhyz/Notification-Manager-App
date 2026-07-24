import 'dart:convert';

class AutoRemoveSettings {
  final int retentionDays; // 0 = unlimited / disabled
  final List<String> blockedApps; // Package names to auto-remove
  final List<String> blockedKeywords; // Keywords in title/body to auto-remove
  final List<String> excludedAppsFromRetention; // Whitelist app packages kept forever
  final List<String> excludedKeywordsFromRetention; // Whitelist keywords kept forever

  AutoRemoveSettings({
    this.retentionDays = 7,
    this.blockedApps = const [],
    this.blockedKeywords = const [],
    this.excludedAppsFromRetention = const [],
    this.excludedKeywordsFromRetention = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'retentionDays': retentionDays,
      'blockedApps': blockedApps,
      'blockedKeywords': blockedKeywords,
      'excludedAppsFromRetention': excludedAppsFromRetention,
      'excludedKeywordsFromRetention': excludedKeywordsFromRetention,
    };
  }

  factory AutoRemoveSettings.fromMap(Map<String, dynamic> map) {
    return AutoRemoveSettings(
      retentionDays: map['retentionDays'] as int? ?? 7,
      blockedApps: List<String>.from(map['blockedApps'] ?? []),
      blockedKeywords: List<String>.from(map['blockedKeywords'] ?? []),
      excludedAppsFromRetention: List<String>.from(map['excludedAppsFromRetention'] ?? []),
      excludedKeywordsFromRetention: List<String>.from(map['excludedKeywordsFromRetention'] ?? []),
    );
  }

  String toJson() => jsonEncode(toMap());

  factory AutoRemoveSettings.fromJson(String source) =>
      AutoRemoveSettings.fromMap(jsonDecode(source) as Map<String, dynamic>);

  AutoRemoveSettings copyWith({
    int? retentionDays,
    List<String>? blockedApps,
    List<String>? blockedKeywords,
    List<String>? excludedAppsFromRetention,
    List<String>? excludedKeywordsFromRetention,
  }) {
    return AutoRemoveSettings(
      retentionDays: retentionDays ?? this.retentionDays,
      blockedApps: blockedApps ?? this.blockedApps,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      excludedAppsFromRetention: excludedAppsFromRetention ?? this.excludedAppsFromRetention,
      excludedKeywordsFromRetention: excludedKeywordsFromRetention ?? this.excludedKeywordsFromRetention,
    );
  }
}
