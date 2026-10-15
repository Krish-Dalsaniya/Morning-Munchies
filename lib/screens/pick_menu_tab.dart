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
    return Container(
      color: const Color(0xFFFBF8F3),
      child: ValueListenableBuilder<int>(
        valueListenable: refreshTick,
        builder: (context, _, child) => Column(
          children: [
            // Pill Date Selector Header
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 6),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Color(0xFF2E221B), size: 22),
                    tooltip: 'Previous day',
                    onPressed: () => _changeDate(-1),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(16),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF2E221B)),
                            const SizedBox(width: 8),
                            Text(
                              _dateStr == todayStr() ? 'Today ($_dateStr)' : _dateStr,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                                color: Color(0xFF2E221B),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Color(0xFF2E221B), size: 22),
                    tooltip: 'Next day',
                    onPressed: () => _changeDate(1),
                  ),
                ],
              ),
            ),

            // Content
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
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE84E26)));
                    }

                    final vendors = List<Map<String, dynamic>>.from(snap.data?[0] ?? []);
                    final dailyMenuList = List<Map<String, dynamic>>.from(snap.data?[1] ?? []);
                    final onMenuMap = {for (final m in dailyMenuList) m['item_id'] as String: m['id'] as String};

                    int totalItemsCount = 0;
                    for (final v in vendors) {
                      totalItemsCount += (v['food_items'] as List? ?? []).length;
                    }
                    final selectedCount = onMenuMap.length;

                    if (vendors.isEmpty) {
                      return Container(
                        margin: const EdgeInsets.all(32),
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEFE8DE)),
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.store_outlined, size: 54, color: Color(0xFFB5A99B)),
                            SizedBox(height: 16),
                            Text(
                              'No vendors added yet.\nGo to More > "Vendors & Food Catalog" to add items.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Color(0xFF70655E), fontSize: 14),
                            ),
                          ],
                        ),
                      );
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      children: [
                        // Instruction note
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12, top: 4),
                          child: Text(
                            'Tick the food items to make them available for voting on $_dateStr:',
                            style: const TextStyle(
                              color: Color(0xFF4A3E38),
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),

                        // Selected Items Counter Banner
                        Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFCEEE3),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 24,
                                height: 24,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFE84E26),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.check, size: 16, color: Colors.white),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                '$selectedCount items selected',
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: Color(0xFF221711),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'out of $totalItemsCount items',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color(0xFF70655E),
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Vendor Cards
                        for (int i = 0; i < vendors.length; i++) ...[
                          FadeSlideEntry(
                            index: i,
                            child: Container(
                              margin: const EdgeInsets.symmetric(vertical: 8),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Vendor Header
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.storefront_rounded,
                                        color: Color(0xFFE84E26),
                                        size: 22,
                                      ),
                                      const SizedBox(width: 10),
                                      Text(
                                        vendors[i]['name'] ?? '',
                                        style: const TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.bold,
                                          color: Color(0xFF221711),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(height: 1, thickness: 1, color: Color(0xFFF4EEE6)),
                                  const SizedBox(height: 6),

                                  // Food Items
                                  if ((vendors[i]['food_items'] as List).isEmpty)
                                    const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 12),
                                      child: Text(
                                        'No food items under this vendor.',
                                        style: TextStyle(color: Color(0xFF9E8D8A), fontSize: 13),
                                      ),
                                    )
                                  else
                                    for (int j = 0; j < (vendors[i]['food_items'] as List).length; j++) ...[
                                      _buildCheckItem(
                                        (vendors[i]['food_items'] as List)[j],
                                        onMenuMap,
                                        isLast: j == (vendors[i]['food_items'] as List).length - 1,
                                      ),
                                    ],
                                ],
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckItem(dynamic item, Map<String, String> onMenuMap, {bool isLast = false}) {
    final itemId = item['id'] as String;
    final isOnMenu = onMenuMap.containsKey(itemId);
    final menuRowId = onMenuMap[itemId];
    final price = (item['price'] as num?)?.toDouble() ?? 0;
    final meal = item['meal'] ?? 'Breakfast';

    return Column(
      children: [
        InkWell(
          onTap: () => _toggleItem(itemId, isOnMenu, menuRowId),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
            child: Row(
              children: [
                // Indian Vegetarian Symbol Box
                Container(
                  width: 18,
                  height: 18,
                  decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  alignment: Alignment.center,
                  child: const Icon(Icons.circle, size: 8, color: Color(0xFF2E7D32)),
                ),
                const SizedBox(width: 14),

                // Name, Meal & Price
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'] ?? '',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF221711),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        '${meal.toString().toUpperCase()} • ₹${price.toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF8A827A),
                        ),
                      ),
                    ],
                  ),
                ),

                // Custom Styled Rounded Checkbox
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: isOnMenu ? const Color(0xFFE84E26) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(
                      color: isOnMenu ? const Color(0xFFE84E26) : const Color(0xFF8A827A),
                      width: 1.8,
                    ),
                  ),
                  child: isOnMenu
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
              ],
            ),
          ),
        ),
        if (!isLast)
          const Divider(height: 1, thickness: 1, color: Color(0xFFF7F1EA)),
      ],
    );
  }
}
