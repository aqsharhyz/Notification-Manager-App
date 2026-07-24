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

  void _openFilterBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const FilterBottomSheet(),
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
        title: const Row(
          children: [
            Icon(Icons.notifications_active, color: Colors.indigo),
            SizedBox(width: 8),
            Text(
              'Manage Notif',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        actions: [
          // Permission status badge
          IconButton(
            tooltip: provider.isPermissionGranted ? 'Listener Active' : 'Permission Required',
            icon: Icon(
              provider.isPermissionGranted ? Icons.circle : Icons.warning,
              color: provider.isPermissionGranted ? Colors.green : Colors.amber.shade800,
              size: 16,
            ),
            onPressed: () {
              if (!provider.isPermissionGranted) {
                provider.requestPermission();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search notification title or content...',
                      prefixIcon: const Icon(Icons.search),
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
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    onChanged: (val) => provider.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Badge(
                    isLabelVisible: provider.selectedAppsFilter.isNotEmpty || provider.selectedDateRange != null,
                    label: Text('${provider.selectedAppsFilter.length + (provider.selectedDateRange != null ? 1 : 0)}'),
                    child: const Icon(Icons.filter_list),
                  ),
                  onPressed: () => _openFilterBottomSheet(context),
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
