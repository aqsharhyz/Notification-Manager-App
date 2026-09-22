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
  bool _isReconnecting = false;

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

  Future<void> _handleAccessButton(BuildContext context, NotificationProvider provider) async {
    if (_isReconnecting) return;

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
      setState(() => _isReconnecting = true);

      messenger.hideCurrentSnackBar();
      messenger.showSnackBar(
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
                child: Text('Reconnecting to Android notification listener...'),
              ),
            ],
          ),
          duration: Duration(seconds: 2),
        ),
      );

      final success = await provider.rebindListener();
      if (!mounted) return;
      setState(() => _isReconnecting = false);

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

    if (mounted) {
      _showConnectionInfoSheet(context, provider);
    }
  }

  void _showConnectionInfoSheet(BuildContext context, NotificationProvider provider) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF151D2C) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.check_circle_rounded, color: Color(0xFF10B981), size: 24),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Listener Active & Connected',
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, letterSpacing: -0.3),
                            ),
                            Text(
                              'Service is capturing background notifications.',
                              style: TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
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
                                  content: Text('Service connection refreshed'),
                                  duration: Duration(seconds: 1),
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          },
                          icon: const Icon(Icons.refresh_rounded, size: 18),
                          label: const Text('Rebind Service'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(ctx);
                            provider.requestPermission();
                          },
                          icon: const Icon(Icons.settings_outlined, size: 18),
                          label: const Text('Android Settings'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasActiveFilter = provider.selectedAppsFilter.isNotEmpty ||
        provider.selectedDateRange != null ||
        provider.searchQuery.isNotEmpty;

    // Calculate today's notification count
    final now = DateTime.now();
    final todayCount = notifications.where((n) => n.timestamp.year == now.year && n.timestamp.month == now.month && n.timestamp.day == now.day).length;

    return Scaffold(
      appBar: AppBar(
        titleSpacing: 16,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6366F1).withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Icon(
                Icons.notifications_active_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Manage Notif',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, letterSpacing: -0.4),
                ),
                Text(
                  'History & Auto-Cleaner',
                  style: TextStyle(fontSize: 11, color: Colors.grey, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
        ),
        actions: [
          // Connection Pill
          Container(
            margin: const EdgeInsets.only(right: 6),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => _handleAccessButton(context, provider),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: !provider.isPermissionGranted
                      ? Colors.amber.withValues(alpha: isDark ? 0.2 : 0.15)
                      : (!provider.isListenerConnected
                          ? Colors.orange.withValues(alpha: isDark ? 0.2 : 0.15)
                          : const Color(0xFF10B981).withValues(alpha: isDark ? 0.2 : 0.15)),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: !provider.isPermissionGranted
                        ? Colors.amber.withValues(alpha: 0.4)
                        : (!provider.isListenerConnected
                            ? Colors.orange.withValues(alpha: 0.4)
                            : const Color(0xFF10B981).withValues(alpha: 0.4)),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_isReconnecting) ...[
                      const SizedBox(
                        width: 10,
                        height: 10,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      const SizedBox(width: 6),
                    ] else ...[
                      Container(
                        width: 7,
                        height: 7,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: !provider.isPermissionGranted
                              ? Colors.amber.shade700
                              : (!provider.isListenerConnected
                                  ? Colors.orange.shade700
                                  : const Color(0xFF10B981)),
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      _isReconnecting
                          ? 'Syncing'
                          : (!provider.isPermissionGranted
                              ? 'Fix Access'
                              : (!provider.isListenerConnected
                                  ? 'Reconnect'
                                  : 'Live')),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: !provider.isPermissionGranted
                            ? Colors.amber.shade800
                            : (!provider.isListenerConnected
                                ? Colors.orange.shade800
                                : const Color(0xFF10B981)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined, size: 22),
            tooltip: 'Settings & Rules',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (ctx) => const SettingsScreen()),
              );
            },
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: Column(
        children: [
          // Stats Overview Banner
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: "Today's",
                    value: '$todayCount',
                    icon: Icons.today_rounded,
                    color: const Color(0xFF6366F1),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Total Saved',
                    value: '${notifications.length}',
                    icon: Icons.inventory_2_outlined,
                    color: const Color(0xFF06B6D4),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildStatCard(
                    context,
                    title: 'Apps',
                    value: '${provider.availableApps.length}',
                    icon: Icons.apps_rounded,
                    color: const Color(0xFF8B5CF6),
                  ),
                ),
              ],
            ),
          ),

          // Search Bar & Filter Button
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 6),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search title or message...',
                      prefixIcon: Icon(Icons.search_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear_rounded, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    ),
                    onChanged: (val) => provider.setSearchQuery(val),
                  ),
                ),
                const SizedBox(width: 10),
                IconButton.filledTonal(
                  style: IconButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF151D2C) : Colors.white,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0),
                    ),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.all(12),
                  ),
                  icon: Badge(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    isLabelVisible: provider.selectedAppsFilter.isNotEmpty || provider.selectedDateRange != null,
                    label: Text(
                      '${provider.selectedAppsFilter.length + (provider.selectedDateRange != null ? 1 : 0)}',
                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                    ),
                    child: Icon(Icons.tune_rounded, color: Theme.of(context).colorScheme.primary, size: 20),
                  ),
                  tooltip: 'Filter Notifications',
                  onPressed: () => _openFilterBottomSheet(context),
                ),
              ],
            ),
          ),

          // Active Filter Chips Row
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
                        avatar: const Icon(Icons.apps_rounded, size: 14),
                        label: Text('${provider.selectedAppsFilter.length} Apps'),
                        onDeleted: () => provider.setSelectedAppsFilter([]),
                      ),
                    ),
                  if (provider.selectedDateRange != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        avatar: const Icon(Icons.date_range_rounded, size: 14),
                        label: const Text('Date Filter Active'),
                        onDeleted: () => provider.setSelectedDateRange(null),
                      ),
                    ),
                  if (provider.searchQuery.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(right: 6),
                      child: Chip(
                        avatar: const Icon(Icons.search_rounded, size: 14),
                        label: Text('"${provider.searchQuery}"'),
                        onDeleted: () {
                          _searchController.clear();
                          provider.setSearchQuery('');
                        },
                      ),
                    ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      minimumSize: Size.zero,
                    ),
                    onPressed: () {
                      _searchController.clear();
                      provider.clearFilters();
                    },
                    icon: const Icon(Icons.close_rounded, size: 14),
                    label: const Text('Clear All', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),

          // Section Subheader / Loading Bar
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  hasActiveFilter ? 'FILTERED RESULTS (${notifications.length})' : 'RECENT NOTIFICATIONS (${notifications.length})',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                    color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8),
                  ),
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

          // Notification Feed List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () => provider.loadNotifications(),
              child: notifications.isEmpty
                  ? SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      child: Container(
                        height: MediaQuery.of(context).size.height * 0.5,
                        alignment: Alignment.center,
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.08),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                hasActiveFilter ? Icons.search_off_rounded : Icons.notifications_none_rounded,
                                size: 54,
                                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.6),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              hasActiveFilter ? 'No Notifications Found' : 'No Notifications Recorded Yet',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              hasActiveFilter
                                  ? 'Try adjusting or resetting your search and filters.'
                                  : 'Incoming notifications from your apps will appear here automatically.',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                            const SizedBox(height: 16),
                            if (hasActiveFilter)
                              OutlinedButton.icon(
                                onPressed: () {
                                  _searchController.clear();
                                  provider.clearFilters();
                                },
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('Reset All Filters'),
                              )
                            else if (!provider.isPermissionGranted)
                              ElevatedButton.icon(
                                onPressed: () => provider.requestPermission(),
                                icon: const Icon(Icons.security_rounded, size: 16),
                                label: const Text('Grant Notification Permission'),
                              ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.only(top: 2, bottom: 20),
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

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2C) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 16, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
