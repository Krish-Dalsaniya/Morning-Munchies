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
                    return const Center(child: CircularProgressIndicator());
                  }

                  final menuList = List<Map<String, dynamic>>.from(snap.data?['menu'] ?? []);
                  final totalPeople = snap.data?['totalPeople'] as int? ?? 0;
                  final hasOpenItems = menuList.any((m) => m['status'] == 'open');

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      // Summary Row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '$totalPeople registered people',
                            style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey[700]),
                          ),
                          if (hasOpenItems)
                            FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                              onPressed: _closeMenuAndCharge,
                              icon: const Icon(Icons.check_circle_outline, size: 18),
                              label: const Text('Close & Charge'),
                            )
                          else if (menuList.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.grey[200], borderRadius: BorderRadius.circular(99)),
                              child: const Text('Menu Closed & Charged', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      if (menuList.isEmpty)
                        Container(
                          margin: const EdgeInsets.only(top: 24),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(16),
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

  Widget _buildResultCard(Map<String, dynamic> menu) {
    final food = menu['food_items'] as Map<String, dynamic>?;
    if (food == null) return const SizedBox.shrink();

    final vendor = food['vendors'] as Map<String, dynamic>?;
    final vendorName = vendor?['name'] ?? 'Vendor';
    final itemName = food['name'] ?? '';
    final price = (food['price'] as num?)?.toDouble() ?? 0;
    final meal = food['meal'] ?? '';

    final votes = List<Map<String, dynamic>>.from(menu['votes'] ?? []);
    final yesVoters = votes
        .where((v) => v['response'] == 'yes')
        .map((v) => v['profiles']?['name'] as String? ?? 'Someone')
        .toList();
    final noVoters = votes
        .where((v) => v['response'] == 'no')
        .map((v) => v['profiles']?['name'] as String? ?? 'Someone')
        .toList();

    return HoverLiftCard(
      margin: const EdgeInsets.symmetric(vertical: 8),
      borderRadius: BorderRadius.circular(16),
      color: Colors.white,
      border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
      hoverBorder: Border.all(color: Colors.deepOrange.withValues(alpha: 0.5), width: 1.5),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            // Title & Vendor
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    itemName,
                    style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.deepOrange),
                ),
              ],
            ),
            Text(
              '${meal.toString().toUpperCase()} • ${vendorName.toUpperCase()}',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.grey[600]),
            ),
            const Divider(height: 24),

            // Interested (Yes) section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '👍 ${yesVoters.length} Yes',
                    style: TextStyle(color: Colors.green[900], fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: yesVoters.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('Nobody', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final name in yesVoters)
                              Chip(
                                label: Text(name, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Colors.green.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                          ],
                        ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Not Interested (No) section
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                  child: Text(
                    '👎 ${noVoters.length} No',
                    style: TextStyle(color: Colors.red[900], fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: noVoters.isEmpty
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('Nobody', style: TextStyle(color: Colors.grey[500], fontStyle: FontStyle.italic)),
                        )
                      : Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            for (final name in noVoters)
                              Chip(
                                label: Text(name, style: const TextStyle(fontSize: 12)),
                                backgroundColor: Colors.red.withValues(alpha: 0.1),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                                side: BorderSide.none,
                                visualDensity: VisualDensity.compact,
                                padding: const EdgeInsets.symmetric(horizontal: 4),
                              ),
                          ],
                        ),
                ),
              ],
            ),
          ],
        ),
    );
  }
}
