import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  late List<String> _tempSelectedApps;
  DateTimeRange? _tempDateRange;
  String _searchAppQuery = '';

  @override
  void initState() {
    super.initState();
    final provider = context.read<NotificationProvider>();
    _tempSelectedApps = List.from(provider.selectedAppsFilter);
    _tempDateRange = provider.selectedDateRange;
  }

  void _setDatePreset(int days) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
    setState(() {
      _tempDateRange = DateTimeRange(start: start, end: end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final availableApps = provider.availableApps;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final filteredApps = availableApps.where((app) {
      final name = (app['app_name'] ?? '').toLowerCase();
      final pkg = (app['package_name'] ?? '').toLowerCase();
      final query = _searchAppQuery.toLowerCase();
      return name.contains(query) || pkg.contains(query);
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF151D2C) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.tune_rounded, size: 22),
                      SizedBox(width: 8),
                      Text(
                        'Filter Notifications',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.4),
                      ),
                    ],
                  ),
                  TextButton.icon(
                    style: TextButton.styleFrom(
                      foregroundColor: Theme.of(context).colorScheme.primary,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () {
                      setState(() {
                        _tempSelectedApps.clear();
                        _tempDateRange = null;
                        _searchAppQuery = '';
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Filters
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Section 1: Date Range
                    Row(
                      children: [
                        Icon(Icons.calendar_today_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                        const SizedBox(width: 8),
                        Text(
                          'TIMEFRAME',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.8,
                            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildDateChip('Today', 0),
                        _buildDateChip('Last 7 Days', 7),
                        _buildDateChip('Last 30 Days', 30),
                        ActionChip(
                          avatar: Icon(Icons.date_range_rounded, size: 15, color: _tempDateRange != null ? Theme.of(context).colorScheme.primary : null),
                          label: Text(_tempDateRange == null
                              ? 'Custom Range'
                              : '${_tempDateRange!.start.day}/${_tempDateRange!.start.month} - ${_tempDateRange!.end.day}/${_tempDateRange!.end.month}'),
                          onPressed: () async {
                            final picked = await showDateRangePicker(
                              context: context,
                              firstDate: DateTime(2020),
                              lastDate: DateTime.now(),
                              initialDateRange: _tempDateRange,
                            );
                            if (picked != null) {
                              setState(() {
                                _tempDateRange = picked;
                              });
                            }
                          },
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Section 2: Apps Filter
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.apps_rounded, size: 16, color: Theme.of(context).colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              'APPLICATIONS (${availableApps.length})',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.8,
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                        if (availableApps.isNotEmpty)
                          InkWell(
                            onTap: () {
                              setState(() {
                                if (_tempSelectedApps.length == availableApps.length) {
                                  _tempSelectedApps.clear();
                                } else {
                                  _tempSelectedApps = availableApps.map((a) => a['package_name'] ?? '').where((pkg) => pkg.isNotEmpty).toList();
                                }
                              });
                            },
                            child: Text(
                              _tempSelectedApps.length == availableApps.length ? 'Deselect All' : 'Select All',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 10),

                    if (availableApps.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Center(
                          child: Text(
                            'No recorded applications found in history.',
                            style: TextStyle(fontSize: 13, color: Colors.grey),
                          ),
                        ),
                      )
                    else ...[
                      // Search inside apps
                      TextField(
                        decoration: InputDecoration(
                          hintText: 'Search application...',
                          prefixIcon: const Icon(Icons.search_rounded, size: 18),
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          fillColor: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                        ),
                        onChanged: (val) => setState(() => _searchAppQuery = val),
                      ),
                      const SizedBox(height: 10),

                      Container(
                        constraints: const BoxConstraints(maxHeight: 220),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0)),
                        ),
                        child: filteredApps.isEmpty
                            ? const Center(
                                child: Padding(
                                  padding: EdgeInsets.symmetric(vertical: 24),
                                  child: Text('No matching applications found.', style: TextStyle(color: Colors.grey, fontSize: 13)),
                                ),
                              )
                            : ListView.separated(
                                shrinkWrap: true,
                                itemCount: filteredApps.length,
                                separatorBuilder: (_, _) => Divider(
                                  height: 1,
                                  color: isDark ? const Color(0xFF243044) : const Color(0xFFE2E8F0),
                                ),
                                itemBuilder: (context, index) {
                                  final app = filteredApps[index];
                                  final pkg = app['package_name'] ?? '';
                                  final name = app['app_name'] ?? pkg;
                                  final isSelected = _tempSelectedApps.contains(pkg);

                                  return InkWell(
                                    onTap: () {
                                      setState(() {
                                        if (isSelected) {
                                          _tempSelectedApps.remove(pkg);
                                        } else {
                                          _tempSelectedApps.add(pkg);
                                        }
                                      });
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                      child: Row(
                                        children: [
                                          Icon(
                                            isSelected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
                                            color: isSelected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400,
                                            size: 20,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  name,
                                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                Text(
                                                  pkg,
                                                  style: TextStyle(
                                                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                                                    fontSize: 11,
                                                  ),
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Footer Apply Button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 16),
              child: ElevatedButton(
                onPressed: () {
                  provider.setSelectedAppsFilter(_tempSelectedApps);
                  provider.setSelectedDateRange(_tempDateRange);
                  Navigator.pop(context);
                },
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check_rounded, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      _tempSelectedApps.isNotEmpty || _tempDateRange != null
                          ? 'Apply Filters (${_tempSelectedApps.length + (_tempDateRange != null ? 1 : 0)})'
                          : 'Show All Results',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateChip(String label, int days) {
    final now = DateTime.now();
    final isSelected = _tempDateRange != null &&
        _tempDateRange!.start.day == now.subtract(Duration(days: days)).day &&
        _tempDateRange!.end.difference(_tempDateRange!.start).inDays == days;

    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) _setDatePreset(days);
      },
    );
  }
}
