import 'dart:convert';

class AutoRemoveSettings {
  final int retentionHours; // 0 = unlimited / disabled
  final List<String> blockedApps; // Package names to auto-remove
  final List<String> blockedKeywords; // Keywords in title/body to auto-remove
  final List<String> excludedAppsFromRetention; // Whitelist app packages kept forever
  final List<String> excludedKeywordsFromRetention; // Whitelist keywords kept forever

  AutoRemoveSettings({
    this.retentionHours = 168, // Default to 7 days (168 hours)
    this.blockedApps = const [],
    this.blockedKeywords = const [],
    this.excludedAppsFromRetention = const [],
    this.excludedKeywordsFromRetention = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'retentionHours': retentionHours,
      'blockedApps': blockedApps,
      'blockedKeywords': blockedKeywords,
      'excludedAppsFromRetention': excludedAppsFromRetention,
      'excludedKeywordsFromRetention': excludedKeywordsFromRetention,
    };
  }

  factory AutoRemoveSettings.fromMap(Map<String, dynamic> map) {
    // Map legacy retentionDays to retentionHours if present
    int hours = map['retentionHours'] as int? ?? 0;
    if (hours == 0 && map['retentionDays'] != null) {
      hours = (map['retentionDays'] as int) * 24;
    }
    
    return AutoRemoveSettings(
      retentionHours: hours == 0 ? 168 : hours,
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
    int? retentionHours,
    List<String>? blockedApps,
    List<String>? blockedKeywords,
    List<String>? excludedAppsFromRetention,
    List<String>? excludedKeywordsFromRetention,
  }) {
    return AutoRemoveSettings(
      retentionHours: retentionHours ?? this.retentionHours,
      blockedApps: blockedApps ?? this.blockedApps,
      blockedKeywords: blockedKeywords ?? this.blockedKeywords,
      excludedAppsFromRetention: excludedAppsFromRetention ?? this.excludedAppsFromRetention,
      excludedKeywordsFromRetention: excludedKeywordsFromRetention ?? this.excludedKeywordsFromRetention,
    );
  }
}
