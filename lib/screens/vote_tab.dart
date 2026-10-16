import 'package:flutter/material.dart';
import '../core.dart';
import '../widgets/interactive_effects.dart';
import '../widgets/voters_list_modal.dart';

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

  String _getDishImagePath(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('vaghareli')) return 'assets/images/dishes/vaghareli_idli.png';
    if (name.contains('mendu') || name.contains('medu')) return 'assets/images/dishes/mendu_vada.png';
    if (name.contains('idli')) return 'assets/images/dishes/idli.png';
    if (name.contains('thepla')) return 'assets/images/dishes/thepla.png';
    if (name.contains('handvo') || name.contains('handva')) return 'assets/images/dishes/handvo.png';
    if (name.contains('poha')) return 'assets/images/dishes/poha.png';
    if (name.contains('dhokla') || name.contains('khaman')) return 'assets/images/dishes/dhokla.png';
    if (name.contains('dal vada') || name.contains('dalvada') || name.contains('vada')) return 'assets/images/dishes/dal_vada.png';
    if (name.contains('paratha')) return 'assets/images/dishes/paratha.png';
    return 'assets/images/dishes/thepla.png';
  }

  String _getDishDescription(String itemName) {
    final name = itemName.toLowerCase();
    if (name.contains('vaghareli')) {
      return 'Tempered idli cubes sauteed with mustard seeds, curry leaves and fresh coriander.';
    }
    if (name.contains('mendu') || name.contains('medu')) {
      return 'Crispy golden medu vada served with warm sambhar and fresh coconut chutney.';
    }
    if (name.contains('idli')) {
      return 'Soft and healthy idli served with spicy sambar and chutney.';
    }
    if (name.contains('thepla')) {
      return 'Tasty methi thepla served with green chutney.';
    }
    if (name.contains('handvo') || name.contains('handva')) {
      return 'Savory tava handvo baked with mixed lentils and vegetables, served with green chutney.';
    }
    if (name.contains('poha')) {
      return 'Steamed flattened rice bowl garnished with crunchy peanuts, onions and lemon.';
    }
    if (name.contains('dhokla') || name.contains('khaman')) {
      return 'Soft, fluffy steamed dhokla tempered with mustard seeds and green chilies.';
    }
    if (name.contains('dal vada') || name.contains('dalvada')) {
      return 'Hot crispy fried dal vada served with spicy green chutney and fried chilies.';
    }
    if (name.contains('paratha')) {
      return 'Hot and flaky stuffed paratha served with fresh curd and spicy pickle.';
    }
    return 'Fresh and delicious meal prepared with authentic spices and love.';
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: refreshTick,
      builder: (context, _, child) => Container(
        color: const Color(0xFFFBF8F3), // Warm soft cream background
        child: Column(
          children: [
            // Pill Date Selector
            Container(
              margin: const EdgeInsets.fromLTRB(16, 12, 16, 8),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFF3ECE2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded, size: 22, color: Color(0xFF4A3E38)),
                    tooltip: 'Previous day',
                    onPressed: () => _changeDate(-1),
                  ),
                  Expanded(
                    child: InkWell(
                      onTap: _pickDate,
                      borderRadius: BorderRadius.circular(20),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.calendar_today_outlined, size: 17, color: Color(0xFF4A3E38)),
                            const SizedBox(width: 8),
                            Text(
                              _dateStr == todayStr() ? 'Today ($_dateStr)' : _dateStr,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Color(0xFF2C2420)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded, size: 22, color: Color(0xFF4A3E38)),
                    tooltip: 'Next day',
                    onPressed: () => _changeDate(1),
                  ),
                ],
              ),
            ),

            // Menu List
            Expanded(
              child: RefreshIndicator(
                color: const Color(0xFFE94B0C),
                backgroundColor: Colors.white,
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
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          CheerfulEmptyState(
                            icon: Icons.error_outline_rounded,
                            title: 'Could Not Load Menu',
                            message: '${snap.error}\nPull down to retry.',
                            actionLabel: 'Try Again',
                            onAction: () => setState(() => _future = _load()),
                          ),
                        ],
                      );
                    }
                    if (snap.connectionState == ConnectionState.waiting) {
                      return const ShimmerDishList(count: 3);
                    }

                    final items = snap.data ?? [];
                    if (items.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          CheerfulEmptyState(
                            icon: Icons.soup_kitchen_rounded,
                            title: 'The Kitchen is Preparing!',
                            message: 'No dishes have been picked for ${_dateStr == todayStr() ? "today" : _dateStr} yet.\nCheck back soon or pull down to refresh!',
                            actionLabel: 'Refresh Menu',
                            onAction: () {
                              setState(() {
                                _future = _load();
                              });
                            },
                          ),
                        ],
                      );
                    }

                    final breakfastItems = items.where((m) => m['food_items']?['meal'] == 'breakfast').toList();
                    final lunchItems = items.where((m) => m['food_items']?['meal'] == 'lunch').toList();

                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                      children: [
                        if (breakfastItems.isNotEmpty) ...[
                          _buildMealHeader(
                            title: 'Breakfast',
                            count: breakfastItems.length,
                            subtitle: 'Vote for your favourite breakfast',
                            icon: Icons.breakfast_dining_rounded,
                          ),
                          const SizedBox(height: 6),
                          for (int i = 0; i < breakfastItems.length; i++)
                            FadeSlideEntry(
                              index: i,
                              child: _buildItemCard(breakfastItems[i]),
                            ),
                          const SizedBox(height: 20),
                        ],
                        if (lunchItems.isNotEmpty) ...[
                          _buildMealHeader(
                            title: 'Lunch',
                            count: lunchItems.length,
                            subtitle: 'Vote for today\'s lunch meal',
                            icon: Icons.lunch_dining_rounded,
                          ),
                          const SizedBox(height: 6),
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
      ),
    );
  }

  Widget _buildMealHeader({
    required String title,
    required int count,
    required String subtitle,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 6),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: const Color(0xFFFFE8D6),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFFC8532F).withValues(alpha: 0.12),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Icon(icon, color: const Color(0xFFC8532F), size: 24),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF2C2420)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3EAE0),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$count',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF8C7E72)),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(fontSize: 12.5, color: Color(0xFF8C827A)),
                ),
              ],
            ),
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
    final yesVoters = votes
        .where((v) => v['response'] == 'yes')
        .map((v) => v['profiles']?['name'] as String? ?? 'Someone')
        .toList();
    final noVoters = votes
        .where((v) => v['response'] == 'no')
        .map((v) => v['profiles']?['name'] as String? ?? 'Someone')
        .toList();
    final yesCount = yesVoters.length;
    final noCount = noVoters.length;
    final totalVotes = yesCount + noCount;

    final myVoteObj = votes.firstWhere(
      (v) => v['user_id'] == _currentUid,
      orElse: () => {},
    );
    final String? myVote = myVoteObj['response'];

    final yesPercent = totalVotes > 0 ? (yesCount / totalVotes) : 0.0;
    final noPercent = totalVotes > 0 ? (noCount / totalVotes) : 0.0;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 340;
        final imgWidth = isCompact ? 92.0 : 110.0;
        final imgHeight = isCompact ? 64.0 : 72.0;

        return HoverLiftCard(
          margin: const EdgeInsets.symmetric(vertical: 8),
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          border: Border.all(color: const Color(0xFFEDE5DA), width: 1.2),
          hoverBorder: Border.all(color: const Color(0xFFC8532F).withValues(alpha: 0.5), width: 1.5),
          padding: EdgeInsets.all(isCompact ? 12 : 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Vendor & Status pill
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: Text(
                      vendorName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF8C827A),
                        letterSpacing: 0.8,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                      color: open ? const Color(0xFFE8F5E9) : const Color(0xFFEFEBE6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      open ? 'Voting Open' : 'Voting Closed',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: open ? const Color(0xFF2E7D32) : const Color(0xFF756C65),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Main Content: Dish Info on Left, Price & Image on Right
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Column: Name & Description
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          itemName,
                          style: TextStyle(
                            fontSize: isCompact ? 18 : 20,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF2C2420),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          _getDishDescription(itemName),
                          style: TextStyle(
                            fontSize: isCompact ? 11.5 : 12.5,
                            color: const Color(0xFF756C65),
                            height: 1.35,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Right Column: Price at top, Dish Image below
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      if (price > 0)
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            '₹${price.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: isCompact ? 16 : 18,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFC8532F),
                            ),
                          ),
                        ),
                      const SizedBox(height: 6),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.asset(
                          _getDishImagePath(itemName),
                          width: imgWidth,
                          height: imgHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (ctx, err, stack) => Container(
                            width: imgWidth,
                            height: imgHeight,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5EBE1),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.restaurant_rounded, color: Color(0xFFC8532F), size: 28),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Vote Buttons with bouncy micro-animations & FittedBox for responsive text
              Row(
                children: [
                  // Interested Button
                  Expanded(
                    child: BouncingButton(
                      onPressed: open ? () => _vote(menu['id'], 'yes', myVote) : null,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: myVote == 'yes' ? const Color(0xFFE8F5E9) : Colors.white,
                          border: Border.all(
                            color: myVote == 'yes' ? const Color(0xFF2E7D32) : const Color(0xFF2E7D32).withValues(alpha: 0.7),
                            width: myVote == 'yes' ? 1.8 : 1.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.thumb_up_rounded, size: 16, color: Color(0xFF2E7D32)),
                              SizedBox(width: 6),
                              Text(
                                'Interested',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF2E7D32),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Not Interested Button
                  Expanded(
                    child: BouncingButton(
                      onPressed: open ? () => _vote(menu['id'], 'no', myVote) : null,
                      child: Container(
                        height: 42,
                        padding: const EdgeInsets.symmetric(horizontal: 6),
                        decoration: BoxDecoration(
                          color: myVote == 'no' ? const Color(0xFFFFEBEE) : Colors.white,
                          border: Border.all(
                            color: myVote == 'no' ? const Color(0xFFC62828) : const Color(0xFFD1C7BD),
                            width: myVote == 'no' ? 1.8 : 1.2,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.thumb_down_rounded,
                                size: 16,
                                color: myVote == 'no' ? const Color(0xFFC62828) : const Color(0xFF6B635C),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                'Not interested',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  fontWeight: FontWeight.bold,
                                  color: myVote == 'no' ? const Color(0xFFC62828) : const Color(0xFF6B635C),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Dual-color Animated Progress Bar
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: SizedBox(
                  height: 6,
                  child: totalVotes == 0
                      ? Container(color: const Color(0xFFE8E0D5))
                      : Row(
                          children: [
                            if (yesPercent > 0)
                              Expanded(
                                flex: (yesPercent * 1000).toInt(),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  color: const Color(0xFF2E7D32),
                                ),
                              ),
                            if (noPercent > 0)
                              Expanded(
                                flex: (noPercent * 1000).toInt(),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  color: const Color(0xFFE53935),
                                ),
                              ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 8),

              // Counts & My Vote Status
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Flexible(
                    child: InkWell(
                      onTap: totalVotes > 0
                          ? () => showVotersModal(
                                context: context,
                                itemName: itemName,
                                meal: food['meal'] ?? 'Breakfast',
                                vendorName: vendorName,
                                yesVoters: yesVoters,
                                noVoters: noVoters,
                                initialTab: 'yes',
                              )
                          : null,
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              '$yesCount interested  •  $noCount not interested',
                              style: TextStyle(
                                fontSize: 12,
                                color: const Color(0xFF756C65),
                                decoration: totalVotes > 0 ? TextDecoration.underline : TextDecoration.none,
                                decorationColor: const Color(0xFFC7BEB5),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (totalVotes > 0) ...[
                              const SizedBox(width: 4),
                              const Icon(Icons.people_alt_outlined, size: 13, color: Color(0xFF756C65)),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (myVote != null) ...[
                    const SizedBox(width: 8),
                    Text(
                      myVote == 'yes' ? 'You: Interested' : 'You: Not interested',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: myVote == 'yes' ? const Color(0xFF2E7D32) : const Color(0xFFC62828),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
