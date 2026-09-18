import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/notification_card.dart';
import '../widgets/filter_bottom_sheet.dart';
import 'settings_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  bool _isReconnecting = false;

  void _openFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FilterBottomSheet(),
    );
  }

  Future<void> _handleAccessButton(BuildContext context, NotificationProvider provider) async {
    if (_isReconnecting) return;

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
        _isReconnecting = true;
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
        _isReconnecting = false;
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

    // When already active & connected
    _showConnectionInfoSheet(context, provider);
  }

  void _showConnectionInfoSheet(BuildContext context, NotificationProvider provider) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.check_circle, color: Colors.green, size: 24),
                    ),
                    const SizedBox(width: 12),
                    const Expanded(
                      child: Text(
                        'Status Akses Notifikasi',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const Text(
                  'Aplikasi terhubung normal dengan sistem Android dan aktif merekam notifikasi yang masuk.',
                  style: TextStyle(fontSize: 13, height: 1.4),
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await provider.rebindListener();
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Status koneksi diperbarui'),
                                duration: Duration(seconds: 1),
                              ),
                            );
                          }
                        },
                        icon: const Icon(Icons.refresh, size: 16),
                        label: const Text('Refresh'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          provider.requestPermission();
                        },
                        icon: const Icon(Icons.settings, size: 16),
                        label: const Text('Buka Pengaturan'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final notifications = provider.notifications;
    final hasActiveFilter = provider.selectedAppsFilter.isNotEmpty ||
        provider.selectedDateRange != null ||
        provider.searchQuery.isNotEmpty;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                Icons.notifications_active, 
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
            ),
            const SizedBox(width: 10),
            const Text(
              'Manage Notif',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, letterSpacing: -0.5),
            ),
          ],
        ),
        actions: [
          // Permission & Connection status badge
          Container(
            margin: const EdgeInsets.only(right: 8),
            child: TextButton.icon(
              style: TextButton.styleFrom(
                backgroundColor: !provider.isPermissionGranted
                    ? Colors.amber.withOpacity(0.12)
                    : (!provider.isListenerConnected
                        ? Colors.orange.withOpacity(0.15)
                        : Colors.green.withOpacity(0.1)),
                foregroundColor: !provider.isPermissionGranted
                    ? Colors.amber.shade800
                    : (!provider.isListenerConnected
                        ? Colors.orange.shade900
                        : Colors.green),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                minimumSize: Size.zero,
              ),
              onPressed: () => _handleAccessButton(context, provider),
              icon: _isReconnecting
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : Icon(
                      !provider.isPermissionGranted
                          ? Icons.warning_amber_rounded
                          : (!provider.isListenerConnected
                              ? Icons.sync_problem
                              : Icons.check_circle),
                      size: 14,
                    ),
              label: Text(
                _isReconnecting
                    ? 'Connecting...'
                    : (!provider.isPermissionGranted
                        ? 'Fix access'
                        : (!provider.isListenerConnected
                            ? 'Reconnect'
                            : 'Active')),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.02),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search title or content...',
                        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                        prefixIcon: Icon(Icons.search, color: Theme.of(context).colorScheme.primary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear),
                                onPressed: () {
                                  _searchController.clear();
                                  provider.setSearchQuery('');
                                },
                              )
                            : null,
                        isDense: true,
                        filled: true,
                        fillColor: Theme.of(context).cardTheme.color,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(
                            color: Theme.of(context).brightness == Brightness.light 
                                ? const Color(0xFFE2E8F0) 
                                : const Color(0xFF334155), 
                            width: 1,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                        ),
                      ),
                      onChanged: (val) => provider.setSearchQuery(val),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  decoration: BoxDecoration(
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: IconButton.filledTonal(
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).cardTheme.color,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                        side: BorderSide(
                          color: Theme.of(context).brightness == Brightness.light 
                              ? const Color(0xFFE2E8F0) 
                              : const Color(0xFF334155), 
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(12),
                    ),
                    icon: Badge(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      isLabelVisible: provider.selectedAppsFilter.isNotEmpty || provider.selectedDateRange != null,
                      label: Text(
                        '${provider.selectedAppsFilter.length + (provider.selectedDateRange != null ? 1 : 0)}',
                        style: const TextStyle(color: Colors.white, fontSize: 10),
                      ),
                      child: Icon(Icons.tune, color: Theme.of(context).colorScheme.primary),
                    ),
                    onPressed: () => _openFilterBottomSheet(context),
                  ),
                ),
              ],
            ),
          ),

          // Active Filter Badges Row
          if (hasActiveFilter)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  if (provider.selectedAppsFilter.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        label: Text('${provider.selectedAppsFilter.length} Apps'),
                        onDeleted: () => provider.setSelectedAppsFilter([]),
                      ),
                    ),
                  if (provider.selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        avatar: const Icon(Icons.date_range, size: 14),
                        label: const Text('Date Range'),
                        onDeleted: () => provider.setSelectedDateRange(null),
                      ),
                    ),
                  TextButton.icon(
                    onPressed: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Reset All'),
                  ),
                ],
              ),
            ),

          // Item Count & Status Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Saved Notifications (${notifications.length})',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
                ),
                if (provider.isLoading)
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),

          // Notifications List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadNotifications(),
              child: notifications.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        // Center vertically within available space
                        height: MediaQuery.of(context).size.height * 0.6,
                        alignment: Alignment.center,
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.notifications_none, size: 64, color: Colors.grey.shade400),
                            const SizedBox(height: 12),
                            Text(
                              hasActiveFilter ? 'No notifications match your filters.' : 'No notifications saved yet.',
                              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                            ),
                            const SizedBox(height: 8),
                            if (!provider.isPermissionGranted)
                              ElevatedButton.icon(
                                onPressed: () => provider.requestPermission(),
                                icon: const Icon(Icons.security),
                                label: const Text('Enable Notification Listener'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: notifications.length,
                      itemBuilder: (context, index) {
                        final item = notifications[index];
                        return NotificationCard(
                          item: item,
                          onDelete: () => provider.deleteNotification(item.id!),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
