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
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE84E26)));
              }

              final balanceData = snap.data?[0] as Map<String, dynamic>?;
              final double balance = (balanceData?['balance'] as num?)?.toDouble() ?? 0.0;
              final txns = List<Map<String, dynamic>>.from(snap.data?[1] ?? []);

              final owes = balance < -0.01;
              final advance = balance > 0.01;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Modern Account Balance Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 26),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEEE3),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Wallet Circle Icon
                        Container(
                          width: 58,
                          height: 58,
                          decoration: const BoxDecoration(
                            color: Color(0xFFF7D9CE),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_rounded,
                            size: 30,
                            color: Color(0xFFE84E26),
                          ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'Account Balance',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF70655E),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          owes
                              ? '-₹${balance.abs().toStringAsFixed(2)}'
                              : '₹${balance.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 38,
                            fontWeight: FontWeight.w900,
                            color: owes ? const Color(0xFFD34A26) : const Color(0xFF221711),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                          decoration: BoxDecoration(
                            color: owes
                                ? const Color(0xFFFDE6E2)
                                : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            owes
                                ? 'Payment Pending'
                                : advance
                                    ? 'Advance Credit'
                                    : 'All Settled',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: owes
                                  ? const Color(0xFFD34A26)
                                  : const Color(0xFF2E7D32),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Transaction History Title
                  const Text(
                    'Transaction History',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF221711),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (txns.isEmpty)
                    Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEFE8DE)),
                      ),
                      child: const Center(
                        child: Text(
                          'No transactions yet.',
                          style: TextStyle(color: Color(0xFF70655E)),
                        ),
                      ),
                    )
                  else
                    for (int i = 0; i < txns.length; i++) ...[
                      Builder(
                        builder: (context) {
                          final t = txns[i];
                          final isCharge = t['type'] == 'charge';
                          final note = t['note'] ?? (isCharge ? 'Food Order' : 'Payment');
                          final amount = (t['amount'] as num).toDouble();
                          final dateStr = t['created_at'] != null
                              ? t['created_at'].toString().substring(0, 10)
                              : '';

                          return FadeSlideEntry(
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
                                  Container(
                                    width: 44,
                                    height: 44,
                                    decoration: BoxDecoration(
                                      color: isCharge
                                          ? const Color(0xFFFDECE8)
                                          : const Color(0xFFE8F5E9),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      isCharge
                                          ? Icons.restaurant_rounded
                                          : Icons.payments_rounded,
                                      color: isCharge
                                          ? const Color(0xFFD34A26)
                                          : const Color(0xFF2E7D32),
                                      size: 22,
                                    ),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          note,
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: Color(0xFF221711),
                                          ),
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8A827A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Text(
                                    '${isCharge ? '-' : '+'}₹${amount.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w800,
                                      color: isCharge
                                          ? const Color(0xFFD34A26)
                                          : const Color(0xFF2E7D32),
                                    ),
                                  ),
                                ],
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
      ),
    );
  }
}
