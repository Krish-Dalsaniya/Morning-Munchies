import 'package:flutter/material.dart';
import '../core.dart';
import '../widgets/interactive_effects.dart';

class WalletTab extends StatefulWidget {
  const WalletTab({super.key});

  @override
  State<WalletTab> createState() => _WalletTabState();
}

class _WalletTabState extends State<WalletTab> {
  String get _uid => supabase.auth.currentUser?.id ?? '';
  late Future<List<dynamic>> _future = _load();

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
      supabase.from('wallet_balances').select().eq('user_id', _uid).maybeSingle(),
      supabase.from('wallet_transactions').select().eq('user_id', _uid).order('created_at', ascending: false),
    ]);
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
        child: FutureBuilder<List<dynamic>>(
          future: _future,
          builder: (context, snap) {
            if (snap.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('Error loading wallet: ${snap.error}', textAlign: TextAlign.center),
                ),
              );
            }
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final balanceData = snap.data?[0] as Map<String, dynamic>?;
            final double balance = (balanceData?['balance'] as num?)?.toDouble() ?? 0.0;
            final txns = List<Map<String, dynamic>>.from(snap.data?[1] ?? []);

            final owes = balance < -0.01;
            final advance = balance > 0.01;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Modern Wallet Balance Card with hover lift
                HoverLiftCard(
                  borderRadius: BorderRadius.circular(20),
                  color: owes
                      ? Colors.red.withValues(alpha: 0.08)
                      : advance
                          ? Colors.green.withValues(alpha: 0.08)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  border: Border.all(
                    color: owes
                        ? Colors.red.withValues(alpha: 0.2)
                        : advance
                            ? Colors.green.withValues(alpha: 0.2)
                            : Colors.transparent,
                  ),
                  hoverBorder: Border.all(
                    color: owes
                        ? Colors.red.withValues(alpha: 0.6)
                        : advance
                            ? Colors.green.withValues(alpha: 0.6)
                            : Colors.deepOrange.withValues(alpha: 0.5),
                    width: 1.5,
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.account_balance_wallet,
                        size: 36,
                        color: owes ? Colors.red : advance ? Colors.green : Colors.deepOrange,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        owes ? 'Amount You Owe' : advance ? 'Advance Credit Balance' : 'Account Balance',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.grey[700]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '₹${balance.abs().toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 34,
                          fontWeight: FontWeight.bold,
                          color: owes ? Colors.red[800] : advance ? Colors.green[800] : Colors.grey[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                        decoration: BoxDecoration(
                          color: owes
                              ? Colors.red.withValues(alpha: 0.15)
                              : advance
                                  ? Colors.green.withValues(alpha: 0.15)
                                  : Colors.grey.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(99),
                        ),
                        child: Text(
                          owes
                              ? 'Payment Pending'
                              : advance
                                  ? 'Prepaid Credit Active'
                                  : 'All Settled',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: owes ? Colors.red[900] : advance ? Colors.green[900] : Colors.grey[800],
                          ),
                        ),
                      ),
                      if (owes) ...[
                        const SizedBox(height: 12),
                        Text(
                          'Please pay the office food coordinator via Cash / UPI to settle.',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Transactions Title
                const Text('Transaction History', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),

                if (txns.isEmpty)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No transactions yet.', style: TextStyle(color: Colors.grey)),
                    ),
                  )
                else
                  for (int i = 0; i < txns.length; i++) ...[
                    Builder(
                      builder: (context) {
                        final t = txns[i];
                        return FadeSlideEntry(
                          index: i,
                          child: HoverLiftCard(
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            borderRadius: BorderRadius.circular(12),
                            color: Colors.white,
                            border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                            hoverBorder: Border.all(color: Colors.deepOrange.withValues(alpha: 0.4), width: 1.2),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: t['type'] == 'charge'
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.green.withValues(alpha: 0.1),
                                child: Icon(
                            t['type'] == 'charge' ? Icons.restaurant : Icons.payments,
                            color: t['type'] == 'charge' ? Colors.red : Colors.green,
                            size: 20,
                          ),
                        ),
                        title: Text(t['note'] ?? (t['type'] == 'charge' ? 'Food Order' : 'Payment'), style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(
                          t['created_at'] != null ? t['created_at'].toString().substring(0, 10) : '',
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                        ),
                        trailing: Text(
                          '${t['type'] == 'charge' ? '-' : '+'}₹${(t['amount'] as num).toDouble().toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: t['type'] == 'charge' ? Colors.red : Colors.green[700],
                          ),
                        ),
                      ),
                    ),
                  );
                },
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
