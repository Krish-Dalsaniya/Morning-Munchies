import 'package:flutter/material.dart';
import '../core.dart';
import '../widgets/interactive_effects.dart';

class PickMenuTab extends StatefulWidget {
  const PickMenuTab({super.key});

  @override
  State<PickMenuTab> createState() => _PickMenuTabState();
}

class _PickMenuTabState extends State<PickMenuTab> {
  DateTime _date = DateTime.now();
  late Future<List<dynamic>> _future = _load();

  String get _dateStr => _date.toIso8601String().substring(0, 10);

  @override
  void initState() {
    super.initState();
    refreshTick.addListener(_onRefresh);
  }

  @override
  void dispose() {
    refreshTick.removeListener(_onRefresh);
    super.dispose();
  }

  void _onRefresh() {
    if (mounted) {
      setState(() {
        _future = _load();
      });
    }
  }

  Future<List<dynamic>> _load() {
    return Future.wait([
      supabase.from('vendors').select('id, name, food_items(id, name, price, meal)').order('name'),
      supabase.from('daily_menu').select('id, item_id').eq('menu_date', _dateStr),
    ]);
  }

  void _changeDate(int days) {
    setState(() {
      _date = _date.add(Duration(days: days));
      _future = _load();
    });
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now().subtract(const Duration(days: 90)),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    if (picked != null && picked != _date) {
      setState(() {
        _date = picked;
        _future = _load();
      });
    }
  }

  Future<void> _toggleItem(String itemId, bool isCurrentlyOnMenu, String? menuRowId) async {
    try {
      if (isCurrentlyOnMenu) {
        await supabase.from('daily_menu').delete().match({'menu_date': _dateStr, 'item_id': itemId});
      } else {
        await supabase.from('daily_menu').insert({'menu_date': _dateStr, 'item_id': itemId});
      }
      refresh();
      setState(() {
        _future = _load();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error updating menu: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: refreshTick,
      builder: (context, _, child) => Column(
        children: [
          // Date Selector Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  tooltip: 'Previous day',
                  onPressed: () => _changeDate(-1),
                ),
                Expanded(
                  child: InkWell(
                    onTap: _pickDate,
                    borderRadius: BorderRadius.circular(8),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.calendar_today, size: 18),
                          const SizedBox(width: 8),
                          Text(
                            _dateStr == todayStr() ? 'Today ($_dateStr)' : _dateStr,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  tooltip: 'Next day',
                  onPressed: () => _changeDate(1),
                ),
              ],
            ),
          ),

          // Vendors & Checkbox selection list
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _future = _load();
                });
                await _future;
              },
              child: FutureBuilder<List<dynamic>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final vendors = List<Map<String, dynamic>>.from(snap.data?[0] ?? []);
                  final dailyMenuList = List<Map<String, dynamic>>.from(snap.data?[1] ?? []);
                  final onMenuMap = {for (final m in dailyMenuList) m['item_id'] as String: m['id'] as String};

                  if (vendors.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.all(32),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.store_outlined, size: 54, color: Colors.grey),
                          SizedBox(height: 16),
                          Text(
                            'No vendors added yet.\nGo to "Vendors & Food" tab to add vendors and items.',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey, fontSize: 15),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'Tick the food items to make them available for voting on $_dateStr:',
                          style: TextStyle(color: Colors.grey[700], fontSize: 13),
                        ),
                      ),
                      const SizedBox(height: 8),

                      for (int i = 0; i < vendors.length; i++) ...[
                        FadeSlideEntry(
                          index: i,
                          child: HoverLiftCard(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            borderRadius: BorderRadius.circular(16),
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                            hoverBorder: Border.all(color: Colors.deepOrange.withValues(alpha: 0.5), width: 1.5),
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.storefront, color: Colors.deepOrange, size: 20),
                                    const SizedBox(width: 8),
                                    Text(
                                      vendors[i]['name'] ?? '',
                                      style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                                    ),
                                  ],
                                ),
                                const Divider(height: 20),
                                if ((vendors[i]['food_items'] as List).isEmpty)
                                  Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 8),
                                    child: Text('No food items under this vendor.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
                                  )
                                else
                                  for (final item in (vendors[i]['food_items'] as List)) ...[
                                    _buildCheckItem(item, onMenuMap),
                                  ],
                              ],
                            ),
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                    ],
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(dynamic item, Map<String, String> onMenuMap) {
    final itemId = item['id'] as String;
    final isOnMenu = onMenuMap.containsKey(itemId);
    final menuRowId = onMenuMap[itemId];
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final meal = item['meal'] ?? '';

    return CheckboxListTile(
      value: isOnMenu,
      dense: true,
      contentPadding: EdgeInsets.zero,
      activeColor: Colors.deepOrange,
      title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
      subtitle: Text(
        '${meal.toString().toUpperCase()} • ₹${price.toStringAsFixed(2)}',
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
      ),
      onChanged: (_) => _toggleItem(itemId, isOnMenu, menuRowId),
    );
  }
}
