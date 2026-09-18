import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import '../providers/notification_provider.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final TextEditingController _blockedAppController = TextEditingController();
  final TextEditingController _blockedKeywordController = TextEditingController();
  final TextEditingController _excludeAppController = TextEditingController();
  final TextEditingController _excludeKeywordController = TextEditingController();

  @override
  void dispose() {
    _blockedAppController.dispose();
    _blockedKeywordController.dispose();
    _excludeAppController.dispose();
    _excludeKeywordController.dispose();
    super.dispose();
  }

  void _addBlockedApp(NotificationProvider provider) {
    final text = _blockedAppController.text.trim();
    if (text.isEmpty) return;
    final current = List<String>.from(provider.settings.blockedApps);
    if (!current.contains(text)) {
      current.add(text);
      provider.updateSettings(provider.settings.copyWith(blockedApps: current));
    }
    _blockedAppController.clear();
  }

  void _removeBlockedApp(NotificationProvider provider, String app) {
    final current = List<String>.from(provider.settings.blockedApps);
    current.remove(app);
    provider.updateSettings(provider.settings.copyWith(blockedApps: current));
  }

  void _addBlockedKeyword(NotificationProvider provider) {
    final text = _blockedKeywordController.text.trim();
    if (text.isEmpty) return;
    final current = List<String>.from(provider.settings.blockedKeywords);
    if (!current.contains(text)) {
      current.add(text);
      provider.updateSettings(provider.settings.copyWith(blockedKeywords: current));
    }
    _blockedKeywordController.clear();
  }

  void _removeBlockedKeyword(NotificationProvider provider, String kw) {
    final current = List<String>.from(provider.settings.blockedKeywords);
    current.remove(kw);
    provider.updateSettings(provider.settings.copyWith(blockedKeywords: current));
  }

  void _addExcludedApp(NotificationProvider provider) {
    final text = _excludeAppController.text.trim();
    if (text.isEmpty) return;
    final current = List<String>.from(provider.settings.excludedAppsFromRetention);
    if (!current.contains(text)) {
      current.add(text);
      provider.updateSettings(provider.settings.copyWith(excludedAppsFromRetention: current));
    }
    _excludeAppController.clear();
  }

  void _removeExcludedApp(NotificationProvider provider, String app) {
    final current = List<String>.from(provider.settings.excludedAppsFromRetention);
    current.remove(app);
    provider.updateSettings(provider.settings.copyWith(excludedAppsFromRetention: current));
  }

  void _addExcludedKeyword(NotificationProvider provider) {
    final text = _excludeKeywordController.text.trim();
    if (text.isEmpty) return;
    final current = List<String>.from(provider.settings.excludedKeywordsFromRetention);
    if (!current.contains(text)) {
      current.add(text);
      provider.updateSettings(provider.settings.copyWith(excludedKeywordsFromRetention: current));
    }
    _excludeKeywordController.clear();
  }

  bool _isReconnectingListener = false;

  Future<void> _handleListenerAccessButton(BuildContext context, NotificationProvider provider) async {
    if (_isReconnectingListener) return;

    if (!provider.isPermissionGranted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Membuka pengaturan izin akses notifikasi Android...'),
          duration: Duration(seconds: 2),
        ),
      );
      await provider.requestPermission();
      return;
    }

    if (!provider.isListenerConnected) {
      setState(() {
        _isReconnectingListener = true;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text('Menghubungkan ulang ke listener notifikasi Android...'),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await provider.rebindListener();
      if (!mounted) return;

      setState(() {
        _isReconnectingListener = false;
      });

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Berhasil terhubung kembali ke sistem notifikasi!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Layanan belum merespon. Silakan toggle (matikan & hidupkan lagi) izin di Pengaturan Android.',
            ),
            action: SnackBarAction(
              label: 'Pengaturan',
              textColor: Colors.amber,
              onPressed: () => provider.requestPermission(),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        await provider.requestPermission();
      }
      return;
    }

    // Already connected -> open Android settings
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Membuka pengaturan izin akses notifikasi Android...'),
        duration: Duration(seconds: 2),
      ),
    );
    await provider.requestPermission();
  }

  void _removeExcludedKeyword(NotificationProvider provider, String kw) {
    final current = List<String>.from(provider.settings.excludedKeywordsFromRetention);
    current.remove(kw);
    provider.updateSettings(provider.settings.copyWith(excludedKeywordsFromRetention: current));
  }

  void _showAppSelectorDialog(
    BuildContext context,
    NotificationProvider provider,
    TextEditingController targetController,
  ) {
    showDialog(
      context: context,
      builder: (context) {
        String filterQuery = '';
        return StatefulBuilder(
          builder: (context, setState) {
            // Filter unique apps by query
            final apps = provider.availableApps.where((app) {
              final name = (app['app_name'] ?? '').toLowerCase();
              final pkg = (app['package_name'] ?? '').toLowerCase();
              final query = filterQuery.toLowerCase();
              return name.contains(query) || pkg.contains(query);
            }).toList();

            return AlertDialog(
              title: const Text('Select App from History'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: const InputDecoration(
                        hintText: 'Search app name or package...',
                        prefixIcon: Icon(Icons.search),
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                      onChanged: (val) {
                        setState(() {
                          filterQuery = val;
                        });
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: apps.isEmpty
                          ? Padding(
                              padding: const EdgeInsets.symmetric(vertical: 24),
                              child: Text(
                                filterQuery.isEmpty
                                    ? 'No apps recorded yet.\nImport active notifications first!'
                                    : 'No matching apps found.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: apps.length,
                              itemBuilder: (ctx, index) {
                                final app = apps[index];
                                final name = app['app_name'] ?? 'Unknown App';
                                final pkg = app['package_name'] ?? '';
                                return ListTile(
                                  title: Text(name),
                                  subtitle: Text(pkg, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                  onTap: () {
                                    targetController.text = pkg;
                                    Navigator.pop(context);
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final settings = provider.settings;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Auto-Remove & Rules Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Permission Status Card
          Card(
            color: Theme.of(context).brightness == Brightness.dark
                ? (!provider.isPermissionGranted
                    ? Colors.amber.withOpacity(0.15)
                    : (!provider.isListenerConnected
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.green.withOpacity(0.15)))
                : (!provider.isPermissionGranted
                    ? Colors.amber.shade50
                    : (!provider.isListenerConnected
                        ? Colors.orange.shade50
                        : Colors.green.shade50)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    !provider.isPermissionGranted
                        ? Icons.warning_amber_rounded
                        : (!provider.isListenerConnected
                            ? Icons.sync_problem
                            : Icons.check_circle),
                    color: !provider.isPermissionGranted
                        ? Colors.amber.shade800
                        : (!provider.isListenerConnected
                            ? Colors.orange.shade900
                            : Colors.green),
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          !provider.isPermissionGranted
                              ? 'Notification Access Needed'
                              : (!provider.isListenerConnected
                                  ? 'Listener Disconnected'
                                  : 'Notification Access Connected'),
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          !provider.isPermissionGranted
                              ? 'Grant notification listener permission in Android settings.'
                              : (!provider.isListenerConnected
                                  ? 'Izin aktif, tapi koneksi terputus oleh Android. Tap Reconnect.'
                                  : 'App is actively listening & connected to Android system.'),
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => _handleListenerAccessButton(context, provider),
                    child: _isReconnectingListener
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(
                            !provider.isPermissionGranted
                                ? 'Grant'
                                : (!provider.isListenerConnected
                                    ? 'Reconnect'
                                    : 'Settings'),
                          ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Battery Saver Settings Card
          Card(
            color: Theme.of(context).brightness == Brightness.dark
                ? (provider.isIgnoringBatteryOptimizations
                    ? Colors.green.withOpacity(0.15)
                    : Colors.amber.withOpacity(0.15))
                : (provider.isIgnoringBatteryOptimizations
                    ? Colors.green.shade50
                    : Colors.amber.shade50),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    provider.isIgnoringBatteryOptimizations ? Icons.battery_charging_full : Icons.battery_alert,
                    color: provider.isIgnoringBatteryOptimizations ? Colors.green : Colors.amber.shade800,
                    size: 32,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          provider.isIgnoringBatteryOptimizations
                              ? 'Battery Saver Exempted'
                              : 'Battery Saver Exemption Needed',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          provider.isIgnoringBatteryOptimizations
                              ? 'Background listener is protected from system sleep.'
                              : 'Allow app to run unrestricted to prevent background listener stops.',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () => provider.requestIgnoreBatteryOptimizations(),
                    child: Text(provider.isIgnoringBatteryOptimizations ? 'Configured' : 'Exempt'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Keep-Alive Background Service Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: Colors.teal),
                      const SizedBox(width: 8),
                      const Text(
                        'Keep App Alive in Background',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: provider.isKeepAliveRunning ? Colors.teal.withOpacity(0.15) : Colors.grey.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          provider.isKeepAliveRunning ? 'Running' : 'Off',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: provider.isKeepAliveRunning ? Colors.teal : Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Menjalankan notifikasi ongoing berprioritas rendah agar background listener tidak dibekukan atau dimatikan oleh sistem Android / pembersih RAM saat Anda menutup aplikasi.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Layanan Latar Belakang Kebal Kill',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: Text(
                      settings.keepAliveNotificationEnabled
                          ? 'Aktif — Notifikasi pemantau sedang berjalan.'
                          : 'Nonaktif — Berisiko dimatikan sistem saat keluar aplikasi.',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: settings.keepAliveNotificationEnabled,
                    onChanged: (val) {
                      provider.updateSettings(settings.copyWith(keepAliveNotificationEnabled: val));
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Download Current Notifications Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.download, color: Colors.indigo),
                      SizedBox(width: 8),
                      Text(
                        'Import Active Notifications',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Fetch all notifications currently visible on your status bar and save them to the database.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.sync),
                    label: const Text('Download Status Bar Notifications'),
                    onPressed: () async {
                      final success = await provider.fetchActiveNotifications();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(success 
                              ? 'Imported active notifications successfully!'
                              : 'Service not active. Please grant permission and try again.'),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Export to Excel Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.table_view, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Export Data',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Export all saved notifications to an Excel spreadsheet (.xlsx) and share it.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      side: const BorderSide(color: Colors.green, width: 1),
                      foregroundColor: Colors.green,
                    ),
                    icon: const Icon(Icons.share_outlined),
                    label: const Text('Export to Excel & Share'),
                    onPressed: () async {
                      final path = await provider.exportToExcel();
                      if (path != null) {
                        await Share.shareXFiles([XFile(path)], text: 'Exported Notifications');
                      } else {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('No notifications found to export.')),
                          );
                        }
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Theme Switcher Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.palette, color: Colors.purple),
                      SizedBox(width: 8),
                      Text(
                        'Appearance Settings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Theme Mode', style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14)),
                    subtitle: Text(
                      provider.themeMode == ThemeMode.system
                          ? 'Follow system settings'
                          : (provider.themeMode == ThemeMode.dark ? 'Dark Mode' : 'Light Mode'),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    trailing: DropdownButton<ThemeMode>(
                      value: provider.themeMode,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(
                          value: ThemeMode.system,
                          child: Text('System'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.light,
                          child: Text('Light'),
                        ),
                        DropdownMenuItem(
                          value: ThemeMode.dark,
                          child: Text('Dark'),
                        ),
                      ],
                      onChanged: (mode) {
                        if (mode != null) {
                          provider.setThemeMode(mode);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Retention Period Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.auto_delete, color: Colors.blue),
                      SizedBox(width: 8),
                      Text(
                        'Auto-Delete Retention Policy',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Automatically remove notifications older than the selected threshold:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    value: settings.retentionHours,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    ),
                    items: const [
                      DropdownMenuItem(value: 0, child: Text('Never (Unlimited)')),
                      DropdownMenuItem(value: 1, child: Text('Older than 1 Hour')),
                      DropdownMenuItem(value: 24, child: Text('Older than 1 Day')),
                      DropdownMenuItem(value: 72, child: Text('Older than 3 Days')),
                      DropdownMenuItem(value: 168, child: Text('Older than 7 Days')),
                      DropdownMenuItem(value: 336, child: Text('Older than 14 Days')),
                      DropdownMenuItem(value: 720, child: Text('Older than 30 Days')),
                    ],
                    onChanged: (val) {
                      if (val != null) {
                        provider.updateSettings(settings.copyWith(retentionHours: val));
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Duplicate Prevention & Auto-Delete Card
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.content_copy, color: Colors.orange),
                      SizedBox(width: 8),
                      Text(
                        'Duplicate Handling & Prevention',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Control how duplicate notifications (identical app, title, and body) are handled:',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.do_not_disturb_on_outlined, color: Colors.orange),
                    title: const Text(
                      'Skip Duplicates (Tdk Masukkan Jika Duplikat)',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Do not record to database if identical notification already exists.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: settings.ignoreDuplicates,
                    onChanged: (val) {
                      provider.updateSettings(settings.copyWith(ignoreDuplicates: val));
                    },
                  ),
                  const Divider(height: 16),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: const Icon(Icons.auto_delete_outlined, color: Colors.blue),
                    title: const Text(
                      'Auto-Delete Duplicates on Cleanup',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                    ),
                    subtitle: const Text(
                      'Automatically prune duplicate records during cleanup, keeping only the latest.',
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    value: settings.autoDeleteDuplicates,
                    onChanged: (val) {
                      provider.updateSettings(settings.copyWith(autoDeleteDuplicates: val));
                    },
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(40),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      foregroundColor: Colors.orange,
                      side: const BorderSide(color: Colors.orange),
                    ),
                    icon: const Icon(Icons.delete_sweep, size: 18),
                    label: const Text('Delete Existing Duplicates Now'),
                    onPressed: () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final count = await provider.deleteDuplicatesNow();
                      if (!mounted) return;
                      messenger.showSnackBar(
                        SnackBar(
                          content: Text(
                            count > 0
                                ? 'Successfully removed $count duplicate notification(s)!'
                                : 'No duplicate notifications found.',
                          ),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Exclude Whitelist Section (Protect from retention days)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield, color: Colors.green),
                      SizedBox(width: 8),
                      Text(
                        'Retention Exclude List (Whitelist)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Notifications matching these apps or keywords will NEVER be deleted by retention days policy.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  // Exclude Apps
                  const Text('Excluded Apps (Package Name):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _excludeAppController,
                          decoration: InputDecoration(
                            hintText: 'e.g. com.whatsapp',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'Select from active apps',
                              onPressed: () => _showAppSelectorDialog(context, provider, _excludeAppController),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addExcludedApp(provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: settings.excludedAppsFromRetention.map((app) {
                      return Chip(
                        avatar: const Icon(Icons.shield, size: 14, color: Colors.green),
                        label: Text(app),
                        onDeleted: () => _removeExcludedApp(provider, app),
                      );
                    }).toList(),
                  ),

                  const Divider(height: 24),

                  // Exclude Keywords
                  const Text('Excluded Keywords:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _excludeKeywordController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. Bank, OTP, Important',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addExcludedKeyword(provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: settings.excludedKeywordsFromRetention.map((kw) {
                      return Chip(
                        avatar: const Icon(Icons.star, size: 14, color: Colors.amber),
                        label: Text(kw),
                        onDeleted: () => _removeExcludedKeyword(provider, kw),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Auto-Remove Rules Section (Purge list)
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.block, color: Colors.red),
                      SizedBox(width: 8),
                      Text(
                        'Auto-Remove Rules (Purge List)',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Notifications are saved first, then automatically purged if matching these apps or keywords.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 14),

                  // Blocked Apps
                  const Text('Auto-Remove Apps (Package Name):', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _blockedAppController,
                          decoration: InputDecoration(
                            hintText: 'e.g. com.junk.app',
                            isDense: true,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.search),
                              tooltip: 'Select from active apps',
                              onPressed: () => _showAppSelectorDialog(context, provider, _blockedAppController),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addBlockedApp(provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: settings.blockedApps.map((app) {
                      return Chip(
                        label: Text(app),
                        onDeleted: () => _removeBlockedApp(provider, app),
                      );
                    }).toList(),
                  ),

                  const Divider(height: 24),

                  // Blocked Keywords
                  const Text('Auto-Remove Keywords:', style: TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _blockedKeywordController,
                          decoration: const InputDecoration(
                            hintText: 'e.g. promo, spam, discount',
                            isDense: true,
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton.filled(
                        icon: const Icon(Icons.add),
                        onPressed: () => _addBlockedKeyword(provider),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    children: settings.blockedKeywords.map((kw) {
                      return Chip(
                        label: Text(kw),
                        onDeleted: () => _removeBlockedKeyword(provider, kw),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Action Buttons
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.cleaning_services),
            label: const Text('Run Auto-Cleanup Rules Now'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              await provider.runCleanupNow();
              if (!mounted) return;
              messenger.showSnackBar(
                const SnackBar(content: Text('Auto-cleanup executed successfully.')),
              );
            },
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: Colors.red.shade700,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.delete_forever),
            label: const Text('Clear All Saved Notifications'),
            onPressed: () async {
              final messenger = ScaffoldMessenger.of(context);
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Clear All Notifications?'),
                  content: const Text('This will permanently delete all stored notifications from database.'),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Clear All', style: TextStyle(color: Colors.red))),
                  ],
                ),
              );

              if (confirm == true) {
                await provider.clearAll();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(content: Text('All notifications cleared.')),
                );
              }
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }
}
