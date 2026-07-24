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

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Filter Notifications',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _tempSelectedApps.clear();
                    _tempDateRange = null;
                  });
                },
                child: const Text('Reset All'),
              ),
            ],
          ),
          const Divider(),
          const SizedBox(height: 10),

          // Date Range Presets
          const Text(
            'Date Range',
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Today'),
                selected: _tempDateRange != null &&
                    _tempDateRange!.start.day == DateTime.now().day,
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
                avatar: const Icon(Icons.date_range, size: 16),
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
            style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
          ),
          const SizedBox(height: 8),
          availableApps.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('No apps registered in database yet.'),
                )
              : Container(
                  constraints: const BoxConstraints(maxHeight: 180),
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: availableApps.length,
                    itemBuilder: (context, index) {
                      final app = availableApps[index];
                      final pkg = app['package_name'] ?? '';
                      final name = app['app_name'] ?? pkg;
                      final isSelected = _tempSelectedApps.contains(pkg);

                      return CheckboxListTile(
                        title: Text(name),
                        subtitle: Text(pkg, style: const TextStyle(fontSize: 11)),
                        value: isSelected,
                        dense: true,
                        onChanged: (checked) {
                          setState(() {
                            if (checked == true) {
                              _tempSelectedApps.add(pkg);
                            } else {
                              _tempSelectedApps.remove(pkg);
                            }
                          });
                        },
                      );
                    },
                  ),
                ),

          const SizedBox(height: 20),

          // Apply Button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                backgroundColor: Theme.of(context).primaryColor,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                provider.setSelectedAppsFilter(_tempSelectedApps);
                provider.setSelectedDateRange(_tempDateRange);
                Navigator.pop(context);
              },
              child: const Text('Apply Filters', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
