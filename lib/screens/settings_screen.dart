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

  // Async Button Loading States
  bool _isReconnectingListener = false;
  bool _isImporting = false;
  bool _isExporting = false;
  bool _isDeletingDuplicates = false;
  bool _isCleaningUp = false;
  bool _isClearingAll = false;

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

  void _removeExcludedKeyword(NotificationProvider provider, String kw) {
    final current = List<String>.from(provider.settings.excludedKeywordsFromRetention);
    current.remove(kw);
    provider.updateSettings(provider.settings.copyWith(excludedKeywordsFromRetention: current));
  }

  Future<void> _handleListenerAccessButton(BuildContext context, NotificationProvider provider) async {
    if (_isReconnectingListener) return;

    final messenger = ScaffoldMessenger.of(context);

    if (!provider.isPermissionGranted) {
      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
        const SnackBar(
          content: Text('Opening Android notification access settings...'),
          duration: Duration(seconds: 2),
        ),
      );
      await provider.requestPermission();
      return;
    }

    if (!provider.isListenerConnected) {
      setState(() => _isReconnectingListener = true);

      final success = await provider.rebindListener();
      if (!mounted) return;
      setState(() => _isReconnectingListener = false);

      messenger.hideCurrentSnackBar();
      if (success) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('✅ Successfully reconnected to notification listener!'),
            backgroundColor: Color(0xFF10B981),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(
            content: const Text(
              'Listener not responding. Please toggle permission off and on in Android Settings.',
            ),
            action: SnackBarAction(
              label: 'Settings',
              textColor: const Color(0xFFFBBF24),
              onPressed: () => provider.requestPermission(),
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
          ),
        );
        await provider.requestPermission();
      }
      return;
    }

    await provider.requestPermission();
  }

  void _showAppSelectorDialog(
    BuildContext context,
    NotificationProvider provider,
    TextEditingController targetController,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (context) {
        String filterQuery = '';
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final apps = provider.availableApps.where((app) {
              final name = (app['app_name'] ?? '').toLowerCase();
              final pkg = (app['package_name'] ?? '').toLowerCase();
              final query = filterQuery.toLowerCase();
              return name.contains(query) || pkg.contains(query);
            }).toList();

            return AlertDialog(
              backgroundColor: isDark ? const Color(0xFF151D2C) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
              title: const Row(
                children: [
                  Icon(Icons.apps_rounded, size: 22),
                  SizedBox(width: 10),
                  Text('Select App from History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Search app name or package...',
                        prefixIcon: const Icon(Icons.search_rounded, size: 18),
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                      ),
                      onChanged: (val) => setDialogState(() => filterQuery = val),
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: Container(
                        constraints: const BoxConstraints(maxHeight: 250),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0)),
                        ),
                        child: apps.isEmpty
                            ? Padding(
                                padding: const EdgeInsets.all(24),
                                child: Center(
                                  child: Text(
                                    filterQuery.isEmpty
                                        ? 'No recorded applications in history yet.'
                                        : 'No matching applications found.',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(color: Colors.grey, fontSize: 13),
                                  ),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: apps.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (ctx, index) {
                                  final app = apps[index];
                                  final name = app['app_name'] ?? 'Unknown App';
                                  final pkg = app['package_name'] ?? '';
                                  return ListTile(
                                    dense: true,
                                    title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                                    subtitle: Text(pkg, style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    onTap: () {
                                      targetController.text = pkg;
                                      Navigator.pop(context);
                                    },
                                  );
                                },
                              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Rules'),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          // Section 1: System & Keep-Alive
          _buildSectionHeader('SERVICE & SYSTEM KEEP-ALIVE', Icons.bolt_rounded, const Color(0xFF6366F1)),
          
          // Permission & Connection Status Card
          _buildCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: !provider.isPermissionGranted
                            ? Colors.amber.withValues(alpha: 0.15)
                            : (!provider.isListenerConnected
                                ? Colors.orange.withValues(alpha: 0.15)
                                : const Color(0xFF10B981).withValues(alpha: 0.15)),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        !provider.isPermissionGranted
                            ? Icons.warning_amber_rounded
                            : (!provider.isListenerConnected
                                ? Icons.sync_problem_rounded
                                : Icons.check_circle_rounded),
                        color: !provider.isPermissionGranted
                            ? Colors.amber.shade800
                            : (!provider.isListenerConnected
                                ? Colors.orange.shade800
                                : const Color(0xFF10B981)),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            !provider.isPermissionGranted
                                ? 'Permission Required'
                                : (!provider.isListenerConnected
                                    ? 'Listener Disconnected'
                                    : 'Listener Connected & Active'),
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            !provider.isPermissionGranted
                                ? 'Grant notification listener permission in Android Settings.'
                                : (!provider.isListenerConnected
                                    ? 'Service was disconnected by Android. Tap Reconnect.'
                                    : 'Recording incoming notifications in background.'),
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(96, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: _isReconnectingListener ? null : () => _handleListenerAccessButton(context, provider),
                      child: _isReconnectingListener
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : Text(
                              !provider.isPermissionGranted
                                  ? 'Grant'
                                  : (!provider.isListenerConnected
                                      ? 'Reconnect'
                                      : 'Settings'),
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                            ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Battery Optimization
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: provider.isIgnoringBatteryOptimizations
                            ? const Color(0xFF10B981).withValues(alpha: 0.15)
                            : Colors.amber.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        provider.isIgnoringBatteryOptimizations ? Icons.battery_charging_full_rounded : Icons.battery_alert_rounded,
                        color: provider.isIgnoringBatteryOptimizations ? const Color(0xFF10B981) : Colors.amber.shade800,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            provider.isIgnoringBatteryOptimizations
                                ? 'Battery Saver Exempted'
                                : 'Battery Exemption Needed',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            provider.isIgnoringBatteryOptimizations
                                ? 'App is protected from background battery sleep.'
                                : 'Allow unrestricted battery to avoid sleep kills.',
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size(96, 40),
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                      ),
                      onPressed: () => provider.requestIgnoreBatteryOptimizations(),
                      child: Text(
                        provider.isIgnoringBatteryOptimizations ? 'Configured' : 'Exempt',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Keep-Alive Service
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shield_outlined, color: Color(0xFF06B6D4), size: 24),
                  ),
                  title: const Text(
                    'Foreground Keep-Alive Service',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5),
                  ),
                  subtitle: Text(
                    settings.keepAliveNotificationEnabled
                        ? 'Active — Ongoing silent notification prevents Android RAM kills.'
                        : 'Disabled — Background service may be paused when app is closed.',
                    style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                  ),
                  value: settings.keepAliveNotificationEnabled,
                  onChanged: (val) {
                    provider.updateSettings(settings.copyWith(keepAliveNotificationEnabled: val));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 2: Auto-Cleanup & Retention Policy
          _buildSectionHeader('RETENTION & DUPLICATES CLEANER', Icons.auto_delete_rounded, const Color(0xFF3B82F6)),
          _buildCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Auto-Delete Retention Threshold', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                const SizedBox(height: 4),
                Text(
                  'Older notifications will be pruned automatically, unless protected by Whitelist.',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<int>(
                  initialValue: settings.retentionHours,
                  decoration: const InputDecoration(
                    contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  ),
                  items: const [
                    DropdownMenuItem(value: 0, child: Text('Never (Unlimited History)')),
                    DropdownMenuItem(value: 1, child: Text('Older than 1 Hour')),
                    DropdownMenuItem(value: 24, child: Text('Older than 1 Day (24 Hours)')),
                    DropdownMenuItem(value: 72, child: Text('Older than 3 Days')),
                    DropdownMenuItem(value: 168, child: Text('Older than 7 Days (1 Week)')),
                    DropdownMenuItem(value: 336, child: Text('Older than 14 Days (2 Weeks)')),
                    DropdownMenuItem(value: 720, child: Text('Older than 30 Days (1 Month)')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      provider.updateSettings(settings.copyWith(retentionHours: val));
                    }
                  },
                ),
                const Divider(height: 24),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.do_not_disturb_on_outlined, color: Color(0xFFF59E0B)),
                  title: const Text('Skip Duplicate Entries', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Ignore identical notification if already saved recently.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: settings.ignoreDuplicates,
                  onChanged: (val) => provider.updateSettings(settings.copyWith(ignoreDuplicates: val)),
                ),
                const Divider(height: 16),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  secondary: const Icon(Icons.cleaning_services_outlined, color: Color(0xFF3B82F6)),
                  title: const Text('Auto-Prune Duplicates on Cleanup', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: const Text('Keep only the latest instance during periodic cleanup.', style: TextStyle(fontSize: 12, color: Colors.grey)),
                  value: settings.autoDeleteDuplicates,
                  onChanged: (val) => provider.updateSettings(settings.copyWith(autoDeleteDuplicates: val)),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFF59E0B),
                          side: const BorderSide(color: Color(0xFFF59E0B)),
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: _isDeletingDuplicates
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _isDeletingDuplicates = true);
                                final count = await provider.deleteDuplicatesNow();
                                if (!mounted) return;
                                setState(() => _isDeletingDuplicates = false);

                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(count > 0 ? 'Removed $count duplicate notification(s)' : 'No duplicates found'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: _isDeletingDuplicates
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFF59E0B)))
                            : const Icon(Icons.delete_sweep_rounded, size: 18),
                        label: Text(_isDeletingDuplicates ? 'Deleting...' : 'Prune Duplicates'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF3B82F6),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(44),
                        ),
                        onPressed: _isCleaningUp
                            ? null
                            : () async {
                                final messenger = ScaffoldMessenger.of(context);
                                setState(() => _isCleaningUp = true);
                                await provider.runCleanupNow();
                                if (!mounted) return;
                                setState(() => _isCleaningUp = false);

                                messenger.showSnackBar(
                                  const SnackBar(
                                    content: Text('Auto-cleanup executed successfully'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                        icon: _isCleaningUp
                            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.cleaning_services_rounded, size: 18),
                        label: Text(_isCleaningUp ? 'Cleaning...' : 'Run Cleanup Now'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 3: Whitelist Rules (Protected from Retention)
          _buildSectionHeader('RETENTION WHITELIST (NEVER DELETE)', Icons.shield_rounded, const Color(0xFF10B981)),
          _buildCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications matching these applications or keywords will NEVER be purged by retention limits.',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                const Text('Excluded Apps (Package Name):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _excludeAppController,
                        decoration: InputDecoration(
                          hintText: 'e.g. com.whatsapp',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search_rounded, size: 20),
                            tooltip: 'Select from history',
                            onPressed: () => _showAppSelectorDialog(context, provider, _excludeAppController),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      onPressed: () => _addExcludedApp(provider),
                    ),
                  ],
                ),
                if (settings.excludedAppsFromRetention.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: settings.excludedAppsFromRetention.map((app) {
                      return Chip(
                        avatar: const Icon(Icons.shield_rounded, size: 14, color: Color(0xFF10B981)),
                        label: Text(app),
                        onDeleted: () => _removeExcludedApp(provider, app),
                      );
                    }).toList(),
                  ),
                ],
                const Divider(height: 24),
                const Text('Excluded Keywords:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _excludeKeywordController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. Bank, OTP, Important, Alert',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      onPressed: () => _addExcludedKeyword(provider),
                    ),
                  ],
                ),
                if (settings.excludedKeywordsFromRetention.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: settings.excludedKeywordsFromRetention.map((kw) {
                      return Chip(
                        avatar: const Icon(Icons.star_rounded, size: 14, color: Color(0xFFF59E0B)),
                        label: Text(kw),
                        onDeleted: () => _removeExcludedKeyword(provider, kw),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 4: Auto-Remove Blacklist Rules
          _buildSectionHeader('AUTO-REMOVE BLACKLIST (PURGE LIST)', Icons.block_rounded, const Color(0xFFEF4444)),
          _buildCard(
            context,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications matching these apps or keywords are automatically purged.',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                const Text('Auto-Remove Apps (Package Name):', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _blockedAppController,
                        decoration: InputDecoration(
                          hintText: 'e.g. com.junk.app',
                          isDense: true,
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.search_rounded, size: 20),
                            tooltip: 'Select from history',
                            onPressed: () => _showAppSelectorDialog(context, provider, _blockedAppController),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      onPressed: () => _addBlockedApp(provider),
                    ),
                  ],
                ),
                if (settings.blockedApps.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: settings.blockedApps.map((app) {
                      return Chip(
                        avatar: const Icon(Icons.block_rounded, size: 14, color: Color(0xFFEF4444)),
                        label: Text(app),
                        onDeleted: () => _removeBlockedApp(provider, app),
                      );
                    }).toList(),
                  ),
                ],
                const Divider(height: 24),
                const Text('Auto-Remove Keywords:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _blockedKeywordController,
                        decoration: const InputDecoration(
                          hintText: 'e.g. promo, spam, discount, survey',
                          isDense: true,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton.filled(
                      style: IconButton.styleFrom(backgroundColor: const Color(0xFFEF4444)),
                      icon: const Icon(Icons.add_rounded, color: Colors.white),
                      onPressed: () => _addBlockedKeyword(provider),
                    ),
                  ],
                ),
                if (settings.blockedKeywords.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: settings.blockedKeywords.map((kw) {
                      return Chip(
                        avatar: const Icon(Icons.tag_rounded, size: 14, color: Color(0xFFEF4444)),
                        label: Text(kw),
                        onDeleted: () => _removeBlockedKeyword(provider, kw),
                      );
                    }).toList(),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section 5: Data Tools & Appearance
          _buildSectionHeader('DATA TOOLS & APPEARANCE', Icons.settings_suggest_rounded, const Color(0xFF8B5CF6)),
          _buildCard(
            context,
            child: Column(
              children: [
                // Theme Mode Selector
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.palette_outlined, color: Color(0xFF8B5CF6), size: 22),
                    ),
                    const SizedBox(width: 14),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Theme Appearance', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5)),
                          Text('Choose between System, Light, or Dark mode', style: TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                    ),
                    DropdownButton<ThemeMode>(
                      value: provider.themeMode,
                      underline: const SizedBox(),
                      borderRadius: BorderRadius.circular(14),
                      items: const [
                        DropdownMenuItem(value: ThemeMode.system, child: Text('System')),
                        DropdownMenuItem(value: ThemeMode.light, child: Text('Light')),
                        DropdownMenuItem(value: ThemeMode.dark, child: Text('Dark')),
                      ],
                      onChanged: (mode) {
                        if (mode != null) provider.setThemeMode(mode);
                      },
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Import Active Notifications Button
                OutlinedButton.icon(
                  onPressed: _isImporting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isImporting = true);
                          final success = await provider.fetchActiveNotifications();
                          if (!mounted) return;
                          setState(() => _isImporting = false);

                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(success
                                  ? '✅ Imported active status bar notifications!'
                                  : 'Service inactive. Grant permission and retry.'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                  icon: _isImporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.sync_rounded, size: 18),
                  label: Text(_isImporting ? 'Importing Notifications...' : 'Import Status Bar Notifications'),
                ),
                const SizedBox(height: 10),
                // Export to Excel Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isExporting
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          setState(() => _isExporting = true);
                          final path = await provider.exportToExcel();
                          if (!mounted) return;
                          setState(() => _isExporting = false);

                          if (path != null) {
                            await Share.shareXFiles([XFile(path)], text: 'Exported Notifications');
                          } else {
                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('No notifications found to export'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: _isExporting
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.table_view_rounded, size: 18),
                  label: Text(_isExporting ? 'Generating Excel Spreadsheet...' : 'Export to Excel (.xlsx) & Share'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Danger Zone
          _buildCard(
            context,
            borderColor: Colors.red.withValues(alpha: 0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('DANGER ZONE', style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12, letterSpacing: 0.8)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Permanently delete all saved notification records from the local SQLite database.',
                  style: TextStyle(fontSize: 12, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B)),
                ),
                const SizedBox(height: 14),
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade700,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isClearingAll
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: isDark ? const Color(0xFF151D2C) : Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                              title: const Text('Delete All Saved Notifications?'),
                              content: const Text(
                                'This will permanently remove all notification history from your device database. This action cannot be undone.',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(ctx, false),
                                  child: const Text('Cancel'),
                                ),
                                ElevatedButton(
                                  style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                                  onPressed: () => Navigator.pop(ctx, true),
                                  child: const Text('Clear Everything'),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            setState(() => _isClearingAll = true);
                            await provider.clearAll();
                            if (!mounted) return;
                            setState(() => _isClearingAll = false);

                            messenger.showSnackBar(
                              const SnackBar(
                                content: Text('All notification records cleared'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                  icon: _isClearingAll
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Icon(Icons.delete_forever_rounded, size: 18),
                  label: Text(_isClearingAll ? 'Clearing Database...' : 'Clear All Saved Notifications'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 36),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.fromLTRB(6, 12, 6, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCard(BuildContext context, {required Widget child, Color? borderColor}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2C) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: borderColor ?? (isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0)),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }
}
