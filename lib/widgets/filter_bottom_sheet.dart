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

  void _setDatePreset(Duration duration) {
    final now = DateTime.now();
    final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
    final start = DateTime(now.year, now.month, now.day).subtract(duration);
    setState(() {
      _tempDateRange = DateTimeRange(start: start, end: end);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<NotificationProvider>();
    final availableApps = provider.availableApps;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle/indicator
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: -0.4),
              ),
              TextButton(
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.primary,
                ),
                onPressed: () {
                  setState(() {
                    _tempSelectedApps.clear();
                    _tempDateRange = null;
                  });
                },
                child: const Text('Reset All', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Date Range Presets
          const Text(
            'Date Range',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Today'),
                selected: _tempDateRange != null &&
                    _tempDateRange!.start.day == DateTime.now().day &&
                    _tempDateRange!.end.difference(_tempDateRange!.start).inDays == 0,
                onSelected: (selected) {
                  if (selected) _setDatePreset(const Duration(days: 0));
                },
              ),
              ChoiceChip(
                label: const Text('Last 7 Days'),
                selected: _tempDateRange != null &&
                    _tempDateRange!.end.difference(_tempDateRange!.start).inDays == 7,
                onSelected: (selected) {
                  if (selected) _setDatePreset(const Duration(days: 7));
                },
              ),
              ChoiceChip(
                label: const Text('Last 30 Days'),
                selected: _tempDateRange != null &&
                    _tempDateRange!.end.difference(_tempDateRange!.start).inDays == 30,
                onSelected: (selected) {
                  if (selected) _setDatePreset(const Duration(days: 30));
                },
              ),
              ActionChip(
                avatar: const Icon(Icons.date_range_outlined, size: 14),
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

          const SizedBox(height: 20),

          // Apps Multiselect Filter
          const Text(
            'Filter by Apps',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 8),
          if (availableApps.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text('No apps registered in database yet.', style: TextStyle(color: Colors.grey)),
            )
          else ...[
            TextField(
              decoration: InputDecoration(
                hintText: 'Search app name or package...',
                hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 18),
                isDense: true,
                filled: true,
                fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0), 
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Theme.of(context).colorScheme.primary, width: 1.5),
                ),
              ),
              onChanged: (val) {
                setState(() {
                  _searchAppQuery = val;
                });
              },
            ),
            const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: Builder(
                builder: (context) {
                  final filteredApps = availableApps.where((app) {
                    final name = (app['app_name'] ?? '').toLowerCase();
                    final pkg = (app['package_name'] ?? '').toLowerCase();
                    final query = _searchAppQuery.toLowerCase();
                    return name.contains(query) || pkg.contains(query);
                  }).toList();

                  if (filteredApps.isEmpty) {
                    return const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Text('No matching apps found.', style: TextStyle(color: Colors.grey, fontSize: 12)),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    itemCount: filteredApps.length,
                    itemBuilder: (context, index) {
                      final app = filteredApps[index];
                      final pkg = app['package_name'] ?? '';
                      final name = app['app_name'] ?? pkg;
                      final isSelected = _tempSelectedApps.contains(pkg);

                      return Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: isSelected 
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.08)
                              : Colors.transparent,
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                          dense: true,
                          visualDensity: VisualDensity.compact,
                          title: Text(
                            name, 
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          subtitle: Text(
                            pkg, 
                            style: TextStyle(color: Colors.grey.shade500, fontSize: 10),
                          ),
                          trailing: isSelected 
                              ? Icon(Icons.check_circle, color: Theme.of(context).colorScheme.primary, size: 20)
                              : Icon(Icons.radio_button_off_outlined, color: Colors.grey.shade400, size: 20),
                          onTap: () {
                            setState(() {
                              if (isSelected) {
                                _tempSelectedApps.remove(pkg);
                              } else {
                                _tempSelectedApps.add(pkg);
                              }
                            });
                          },
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],

          const SizedBox(height: 24),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                elevation: 0,
              ),
              onPressed: () {
                provider.setSelectedAppsFilter(_tempSelectedApps);
                provider.setSelectedDateRange(_tempDateRange);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
