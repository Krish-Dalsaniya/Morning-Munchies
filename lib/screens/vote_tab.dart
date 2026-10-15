import 'package:flutter/material.dart';
import '../core.dart';
import '../widgets/interactive_effects.dart';

class VoteTab extends StatefulWidget {
  const VoteTab({super.key});

  @override
  State<VoteTab> createState() => _VoteTabState();
}

class _VoteTabState extends State<VoteTab> {
  DateTime _date = DateTime.now();
  late Future<List<Map<String, dynamic>>> _future = _load();

  String get _dateStr => _date.toIso8601String().substring(0, 10);
  String get _currentUid => supabase.auth.currentUser?.id ?? '';

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

  Future<List<Map<String, dynamic>>> _load() async {
    final res = await supabase
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
              id,
              name
            )
          ),
          votes (
            id,
            user_id,
            response,
            profiles (
              name
            )
          )
        ''')
        .eq('menu_date', _dateStr);

    return List<Map<String, dynamic>>.from(res);
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

  Future<void> _vote(String menuId, String response, String? currentVote) async {
    try {
      if (currentVote == response) {
        // Unvote (toggle off)
        await supabase.from('votes').delete().match({
          'menu_id': menuId,
          'user_id': _currentUid,
        });
      } else {
        // Cast or switch vote
        await supabase.from('votes').upsert(
          {
            'menu_id': menuId,
            'user_id': _currentUid,
            'response': response,
            'updated_at': DateTime.now().toIso8601String(),
          },
          onConflict: 'menu_id,user_id',
        );
      }
      refresh();
      setState(() {
        _future = _load();
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error voting: $e')));
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

          // Menu List
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _future = _load();
                });
                await _future;
              },
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Text('Error loading menu: ${snap.error}', textAlign: TextAlign.center),
                      ),
                    );
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final items = snap.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      children: [
                        Container(
                          margin: const EdgeInsets.all(32),
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.restaurant_outlined, size: 54, color: Colors.grey),
                              SizedBox(height: 16),
                              Text(
                                'No food has been picked for this date yet.',
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey, fontSize: 16),
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  }

                  final breakfastItems = items.where((m) => m['food_items']?['meal'] == 'breakfast').toList();
                  final lunchItems = items.where((m) => m['food_items']?['meal'] == 'lunch').toList();

                  return ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (breakfastItems.isNotEmpty) ...[
                        _buildMealHeader('🍳 Breakfast', breakfastItems.length),
                        for (int i = 0; i < breakfastItems.length; i++)
                          FadeSlideEntry(
                            index: i,
                            child: _buildItemCard(breakfastItems[i]),
                          ),
                        const SizedBox(height: 16),
                      ],
                      if (lunchItems.isNotEmpty) ...[
                        _buildMealHeader('🍱 Lunch', lunchItems.length),
                        for (int i = 0; i < lunchItems.length; i++)
                          FadeSlideEntry(
                            index: i + breakfastItems.length,
                            child: _buildItemCard(lunchItems[i]),
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

  Widget _buildMealHeader(String title, int count) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Row(
        children: [
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Chip(
            label: Text('$count', style: const TextStyle(fontSize: 12)),
            visualDensity: VisualDensity.compact,
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCard(Map<String, dynamic> menu) {
    final food = menu['food_items'] as Map<String, dynamic>?;
    if (food == null) return const SizedBox.shrink();

    final vendor = food['vendors'] as Map<String, dynamic>?;
    final vendorName = vendor?['name'] ?? 'Vendor';
    final itemName = food['name'] ?? '';
    final price = (food['price'] as num?)?.toDouble() ?? 0;
    final open = menu['status'] == 'open';

    final votes = List<Map<String, dynamic>>.from(menu['votes'] ?? []);
    final yesCount = votes.where((v) => v['response'] == 'yes').length;
    final noCount = votes.where((v) => v['response'] == 'no').length;
    final totalVotes = yesCount + noCount;

    final myVoteObj = votes.firstWhere(
      (v) => v['user_id'] == _currentUid,
      orElse: () => {},
    );
    final String? myVote = myVoteObj['response'];

    final yesPercent = totalVotes > 0 ? (yesCount / totalVotes) : 0.0;
    final noPercent = totalVotes > 0 ? (noCount / totalVotes) : 0.0;

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
          // Vendor & Closed status
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                vendorName.toUpperCase(),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey[600], letterSpacing: 0.8),
              ),
              if (!open)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(99)),
                  child: const Text('Voting Closed', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 4),

          // Item Name & Price
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(itemName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
              ),
              if (price > 0)
                Text(
                  '₹${price.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.deepOrange),
                ),
            ],
          ),
          const SizedBox(height: 12),

          // Vote Buttons with bouncy micro-animations
          Row(
            children: [
              Expanded(
                child: BouncingButton(
                  onPressed: open ? () => _vote(menu['id'], 'yes', myVote) : null,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: myVote == 'yes' ? Colors.green.withValues(alpha: 0.15) : null,
                      side: BorderSide(
                        color: myVote == 'yes' ? Colors.green : Colors.grey.withValues(alpha: 0.3),
                        width: myVote == 'yes' ? 2 : 1,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: open ? () => _vote(menu['id'], 'yes', myVote) : null,
                    icon: Icon(Icons.thumb_up, size: 18, color: myVote == 'yes' ? Colors.green : Colors.grey[700]),
                    label: Text(
                      'Interested',
                      style: TextStyle(
                        fontWeight: myVote == 'yes' ? FontWeight.bold : FontWeight.normal,
                        color: myVote == 'yes' ? Colors.green[800] : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: BouncingButton(
                  onPressed: open ? () => _vote(menu['id'], 'no', myVote) : null,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      backgroundColor: myVote == 'no' ? Colors.red.withValues(alpha: 0.15) : null,
                      side: BorderSide(
                        color: myVote == 'no' ? Colors.red : Colors.grey.withValues(alpha: 0.3),
                        width: myVote == 'no' ? 2 : 1,
                      ),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    onPressed: open ? () => _vote(menu['id'], 'no', myVote) : null,
                    icon: Icon(Icons.thumb_down, size: 18, color: myVote == 'no' ? Colors.red : Colors.grey[700]),
                    label: Text(
                      'Not interested',
                      style: TextStyle(
                        fontWeight: myVote == 'no' ? FontWeight.bold : FontWeight.normal,
                        color: myVote == 'no' ? Colors.red[800] : Colors.grey[800],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Animated Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 6,
              child: totalVotes == 0
                  ? Container(color: Colors.grey.withValues(alpha: 0.2))
                  : Row(
                      children: [
                        if (yesPercent > 0)
                          Expanded(
                            flex: (yesPercent * 1000).toInt(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: Colors.green,
                            ),
                          ),
                        if (noPercent > 0)
                          Expanded(
                            flex: (noPercent * 1000).toInt(),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              color: Colors.red,
                            ),
                          ),
                      ],
                    ),
            ),
          ),
          const SizedBox(height: 6),

          // Counts text
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '$yesCount interested • $noCount not interested',
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              ),
              if (myVote != null)
                Text(
                  myVote == 'yes' ? 'You: Interested' : 'You: Not interested',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: myVote == 'yes' ? Colors.green : Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
