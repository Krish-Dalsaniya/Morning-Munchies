import 'package:flutter/material.dart';
import '../core.dart';

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
    return ValueListenableBuilder<int>(
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
            if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

            final rows = snap.data ?? [];
            final pending = rows.where((r) => (r['balance'] as num) < -0.01).toList();
            final settled = rows.where((r) => (r['balance'] as num) >= -0.01).toList();
            final totalOwed = pending.fold<double>(0, (sum, r) => sum - (r['balance'] as num).toDouble());

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Office Summary Card
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  color: totalOwed > 0 ? Colors.red.withValues(alpha: 0.08) : Colors.green.withValues(alpha: 0.08),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Total Outstanding Owed',
                              style: TextStyle(fontSize: 13, color: Colors.grey[700], fontWeight: FontWeight.w500),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '₹${totalOwed.toStringAsFixed(2)}',
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: totalOwed > 0 ? Colors.red[800] : Colors.green[800],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${pending.length} people have pending dues',
                              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                            ),
                          ],
                        ),
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: (totalOwed > 0 ? Colors.red : Colors.green).withValues(alpha: 0.2),
                          child: Icon(
                            totalOwed > 0 ? Icons.money_off : Icons.check_circle,
                            color: totalOwed > 0 ? Colors.red : Colors.green,
                            size: 28,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Pending Dues Section
                Row(
                  children: [
                    const Text('Pending Payments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(color: Colors.red.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(99)),
                      child: Text('${pending.length}', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.red[900])),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                if (pending.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: Text('🎉 Everyone is settled up! No pending payments.', style: TextStyle(color: Colors.grey[600])),
                  )
                else
                  for (final r in pending) ...[
                    Card(
                      elevation: 0,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: Colors.red.withValues(alpha: 0.2)),
                      ),
                      child: ListTile(
                        leading: const CircleAvatar(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          child: Icon(Icons.person, size: 20),
                        ),
                        title: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          'Owes ₹${(-(r['balance'] as num)).toStringAsFixed(2)}',
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
                        ),
                        trailing: FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.deepOrange),
                          onPressed: () => _recordPayment(r, false),
                          child: const Text('Mark Paid'),
                        ),
                      ),
                    ),
                  ],

                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 8),

                // Settled / Advance Section
                const Text('Settled / Advance Credit', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                for (final r in settled) ...[
                  Card(
                    elevation: 0,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                      side: BorderSide(color: Colors.grey.withValues(alpha: 0.2)),
                    ),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: Colors.green.withValues(alpha: 0.15),
                        foregroundColor: Colors.green[800],
                        child: const Icon(Icons.person, size: 20),
                      ),
                      title: Text(r['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        (r['balance'] as num) > 0.01
                            ? 'Credit: +₹${(r['balance'] as num).toStringAsFixed(2)}'
                            : 'Settled (₹0.00)',
                        style: TextStyle(
                          color: (r['balance'] as num) > 0.01 ? Colors.green[800] : Colors.grey[600],
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      trailing: TextButton(
                        onPressed: () => _recordPayment(r, true),
                        child: const Text('Add Advance'),
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
    );
  }
}
