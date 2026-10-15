import 'package:flutter/material.dart';
import '../core.dart';
import '../widgets/interactive_effects.dart';

class ResultsTab extends StatefulWidget {
  const ResultsTab({super.key});

  @override
  State<ResultsTab> createState() => _ResultsTabState();
}

class _ResultsTabState extends State<ResultsTab> {
  DateTime _date = DateTime.now();
  late Future<Map<String, dynamic>> _future = _load();

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

  Future<Map<String, dynamic>> _load() async {
    final results = await Future.wait([
      // Menu items with votes & voter names
      supabase
          .from('daily_menu')
          .select('''
            id,
            menu_date,
            status,
            food_items (
              id,
              name,
              price,
              meal,
              vendors (
                name
              )
            ),
            votes (
              response,
              profiles (
                name
              )
            )
          ''')
          .eq('menu_date', _dateStr),
      // Total registered people count
      supabase.from('profiles').select('id'),
    ]);

    return {
      'menu': List<Map<String, dynamic>>.from(results[0]),
      'totalPeople': (results[1] as List).length,
    };
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

  Future<void> _closeMenuAndCharge() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Close Voting & Charge?'),
        content: Text(
          'This will close voting for $_dateStr and automatically create wallet charges for everyone who voted "Interested" (Yes).',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Confirm & Charge')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await supabase.rpc('close_menu_and_charge', params: {'p_date': _dateStr});
      refresh();
      setState(() {
        _future = _load();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Voting closed and wallet charges recorded!')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
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
            // Pill Date Selector
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
                child: FutureBuilder<Map<String, dynamic>>(
                  future: _future,
                  builder: (context, snap) {
                    if (snap.hasError) {
                      return Center(child: Text('Error: ${snap.error}'));
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFFE86034)));
                    }

                    final menuList = List<Map<String, dynamic>>.from(snap.data?['menu'] ?? []);
                    final totalPeople = snap.data?['totalPeople'] as int? ?? 0;
                    final hasOpenItems = menuList.any((m) => m['status'] == 'open');

                    return ListView(
                      padding: const EdgeInsets.only(bottom: 40),
                      children: [
                        // Subheader Row: Registered People count + Menu Status Pill
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.group_outlined, size: 20, color: Color(0xFF33261F)),
                                  const SizedBox(width: 8),
                                  Text(
                                    '$totalPeople registered people',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: Color(0xFF33261F),
                                    ),
                                  ),
                                ],
                              ),
                              if (hasOpenItems)
                                BouncingButton(
                                  onPressed: _closeMenuAndCharge,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFE86034),
                                      borderRadius: BorderRadius.circular(20),
                                      boxShadow: [
                                        BoxShadow(
                                          color: const Color(0xFFE86034).withValues(alpha: 0.3),
                                          blurRadius: 6,
                                          offset: const Offset(0, 2),
                                        ),
                                      ],
                                    ),
                                    child: const Row(
                                      children: [
                                        Icon(Icons.check_circle_outline, size: 15, color: Colors.white),
                                        SizedBox(width: 6),
                                        Text(
                                          'Close & Charge',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              else if (menuList.isNotEmpty)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFFCEEE3),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.credit_card_outlined, size: 15, color: Color(0xFF9E4B28)),
                                      SizedBox(width: 6),
                                      Text(
                                        'Menu Closed & Charged',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: Color(0xFF9E4B28),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),

                        if (menuList.isEmpty)
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                            padding: const EdgeInsets.all(32),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: const Color(0xFFEFE8DE)),
                            ),
                            child: const Center(
                              child: Text('No menu items for this date.', style: TextStyle(color: Colors.grey)),
                            ),
                          )
                        else
                          for (int i = 0; i < menuList.length; i++)
                            FadeSlideEntry(
                              index: i,
                              child: _buildResultCard(menuList[i]),
                            ),
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

  Widget _buildResultCard(Map<String, dynamic> menu) {
    final food = menu['food_items'] as Map<String, dynamic>?;
    if (food == null) return const SizedBox.shrink();

    final vendor = food['vendors'] as Map<String, dynamic>?;
    final vendorName = vendor?['name'] ?? 'Vendor';
    final itemName = food['name'] ?? '';
    final price = (food['price'] as num?)?.toDouble() ?? 0;
    final meal = food['meal'] ?? 'Breakfast';

    final votes = List<Map<String, dynamic>>.from(menu['votes'] ?? []);
    final yesVoters = votes
        .where((v) => v['response'] == 'yes')
        .map((v) => v['profiles']?['name'] as String? ?? 'Someone')
        .toList();
    final noVoters = votes
        .where((v) => v['response'] == 'no')
        .map((v) => v['profiles']?['name'] as String? ?? 'Someone')
        .toList();

    final imagePath = getDishImagePath(itemName);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Dish Image + Item Title / Vendor / Meal + Price
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Dish Image
              ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: Image.asset(
                  imagePath,
                  width: 78,
                  height: 78,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 78,
                    height: 78,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF3ECE2),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(Icons.restaurant, color: Color(0xFFB5A99B)),
                  ),
                ),
              ),
              const SizedBox(width: 14),

              // Title, Meal and Vendor
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      itemName,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF221711),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${meal.toString().toUpperCase()} • ${vendorName.toString().toUpperCase()}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF8A827A),
                        letterSpacing: 0.4,
                      ),
                    ),
                  ],
                ),
              ),

              // Price in terracotta
              Text(
                '₹${price.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 18,
                  color: Color(0xFFC8532F),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4EEE6)),
          const SizedBox(height: 12),

          // Interested (Yes) Row with Soft Green Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFF0F8F1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_up, color: Color(0xFF2E7D32), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${yesVoters.length} Yes',
                        style: const TextStyle(
                          color: Color(0xFF1B5E20),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: yesVoters.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Nobody',
                            style: TextStyle(
                              color: Color(0xFF8C9B8E),
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final name in yesVoters)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFDFECE1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF2D3B2F),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),

          // Not Interested (No) Row with Soft Coral/Pink Banner
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFFFDF2F0),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                SizedBox(
                  width: 80,
                  child: Row(
                    children: [
                      const Icon(Icons.thumb_down, color: Color(0xFFD32F2F), size: 16),
                      const SizedBox(width: 8),
                      Text(
                        '${noVoters.length} No',
                        style: const TextStyle(
                          color: Color(0xFFB71C1C),
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: noVoters.isEmpty
                      ? const Padding(
                          padding: EdgeInsets.symmetric(vertical: 4),
                          child: Text(
                            'Nobody',
                            style: TextStyle(
                              color: Color(0xFF9E8D8A),
                              fontStyle: FontStyle.italic,
                              fontSize: 13,
                            ),
                          ),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final name in noVoters)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8E7E5),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF4A2C29),
                                  ),
                                ),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
