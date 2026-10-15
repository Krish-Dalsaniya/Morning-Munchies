import 'package:flutter/material.dart';
import '../core.dart';
import '../widgets/interactive_effects.dart';

class AdminWalletTab extends StatefulWidget {
  const AdminWalletTab({super.key});

  @override
  State<AdminWalletTab> createState() => _AdminWalletTabState();
}

class _AdminWalletTabState extends State<AdminWalletTab> {
  late Future<List<Map<String, dynamic>>> _future = _load();

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
    final res = await supabase.from('wallet_balances').select().order('balance');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _recordPayment(Map<String, dynamic> row, bool isAdvance) async {
    final balance = (row['balance'] as num).toDouble();
    final owed = -balance;
    final amountCtrl = TextEditingController(text: owed > 0 ? owed.toStringAsFixed(2) : '');
    final noteCtrl = TextEditingController(text: isAdvance ? 'UPI Advance' : 'Cash');

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(isAdvance ? 'Add Advance for ${row['name']}' : 'Payment from ${row['name']}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Amount (₹)', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              decoration: const InputDecoration(labelText: 'Payment Note (Cash / UPI / GPay)', border: OutlineInputBorder()),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: Text(isAdvance ? 'Add Credit' : 'Mark Paid'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    final amount = double.tryParse(amountCtrl.text.trim());
    if (amount == null || amount <= 0) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a valid amount')));
      return;
    }

    try {
      await supabase.from('wallet_transactions').insert({
        'user_id': row['user_id'],
        'type': 'payment',
        'amount': amount,
        'note': noteCtrl.text.trim().isEmpty ? 'Payment' : noteCtrl.text.trim(),
      });
      refresh();
      setState(() {
        _future = _load();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Payment of ₹$amount recorded for ${row['name']}!')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFFFBF8F3),
      child: ValueListenableBuilder<int>(
        valueListenable: refreshTick,
        builder: (context, _, child) => RefreshIndicator(
          onRefresh: () async {
            setState(() {
              _future = _load();
            });
            await _future;
          },
          child: FutureBuilder<List<Map<String, dynamic>>>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE84E26)));
              }

              final rows = snap.data ?? [];
              final pending = rows.where((r) => (r['balance'] as num) < -0.01).toList();
              final settled = rows.where((r) => (r['balance'] as num) >= -0.01).toList();
              final totalOwed = pending.fold<double>(0, (sum, r) => sum - (r['balance'] as num).toDouble());

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Total Outstanding Owed Summary Card
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEEE3),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Total Outstanding Owed',
                              style: TextStyle(
                                fontSize: 14,
                                color: Color(0xFF70655E),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '₹${totalOwed.toStringAsFixed(2)}',
                              style: const TextStyle(
                                fontSize: 36,
                                fontWeight: FontWeight.w900,
                                color: Color(0xFFE84E26),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              pending.length == 1
                                  ? '1 person has pending dues'
                                  : '${pending.length} people have pending dues',
                              style: const TextStyle(
                                fontSize: 13,
                                color: Color(0xFF8A827A),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          width: 64,
                          height: 64,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5DCD3),
                            shape: BoxShape.circle,
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              const Icon(
                                Icons.receipt_long_rounded,
                                color: Color(0xFFD34A26),
                                size: 34,
                              ),
                              Positioned(
                                right: 12,
                                bottom: 12,
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFD34A26),
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Text(
                                    '₹',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Section 1: Pending Payments
                  Row(
                    children: [
                      const Icon(
                        Icons.access_time_filled_rounded,
                        color: Color(0xFFD34A26),
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Pending Payments',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF221711),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDE6E2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          '${pending.length}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFD34A26),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (pending.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Center(
                        child: Text(
                          '🎉 Everyone is settled up! No pending payments.',
                          style: TextStyle(color: Color(0xFF70655E)),
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < pending.length; i++) ...[
                      FadeSlideEntry(
                        index: i,
                        child: Container(
                          margin: const EdgeInsets.symmetric(vertical: 5),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                          child: Row(
                            children: [
                              const CircleAvatar(
                                radius: 24,
                                backgroundColor: Color(0xFFFDECE8),
                                child: Icon(Icons.person, color: Color(0xFFD34A26), size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      pending[i]['name'] ?? '',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFF221711),
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      'Owes ₹${(-(pending[i]['balance'] as num)).toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: Color(0xFFD34A26),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              BouncingButton(
                                onPressed: () => _recordPayment(pending[i], false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE84E26),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const Text(
                                    'Mark Paid',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],

                  const SizedBox(height: 24),

                  // Section 2: Settled / Advance Credit
                  const Row(
                    children: [
                      Icon(
                        Icons.check_circle_rounded,
                        color: Color(0xFF2E7D32),
                        size: 20,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Settled / Advance Credit',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF221711),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  for (int i = 0; i < settled.length; i++) ...[
                    FadeSlideEntry(
                      index: i,
                      child: Container(
                        margin: const EdgeInsets.symmetric(vertical: 5),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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
                        child: Row(
                          children: [
                            const CircleAvatar(
                              radius: 24,
                              backgroundColor: Color(0xFFE8F5E9),
                              child: Icon(Icons.person, color: Color(0xFF2E7D32), size: 24),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    settled[i]['name'] ?? '',
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF221711),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    (settled[i]['balance'] as num) > 0.01
                                        ? 'Credit: +₹${(settled[i]['balance'] as num).toStringAsFixed(2)}'
                                        : 'Settled (₹0.00)',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: (settled[i]['balance'] as num) > 0.01
                                          ? FontWeight.bold
                                          : FontWeight.w600,
                                      color: (settled[i]['balance'] as num) > 0.01
                                          ? const Color(0xFF2E7D32)
                                          : const Color(0xFF8A827A),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            BouncingButton(
                              onPressed: () => _recordPayment(settled[i], true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCEEE3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.add_circle_outline_rounded,
                                      size: 15,
                                      color: Color(0xFF8A3B18),
                                    ),
                                    SizedBox(width: 6),
                                    Text(
                                      'Add Advance',
                                      style: TextStyle(
                                        color: Color(0xFF8A3B18),
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
    );
  }
}
