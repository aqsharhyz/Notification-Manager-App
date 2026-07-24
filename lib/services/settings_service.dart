import 'package:shared_preferences/shared_preferences.dart';
import '../models/auto_remove_settings.dart';

class SettingsService {
  static const String _keySettings = 'auto_remove_settings_v1';

  Future<AutoRemoveSettings> loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? jsonStr = prefs.getString(_keySettings);
    if (jsonStr == null || jsonStr.isEmpty) {
      return AutoRemoveSettings();
    }
    try {
      return AutoRemoveSettings.fromJson(jsonStr);
    } catch (_) {
      return AutoRemoveSettings();
    }
  }

  Future<bool> saveSettings(AutoRemoveSettings settings) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setString(_keySettings, settings.toJson());
  }
}
