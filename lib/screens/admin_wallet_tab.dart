import 'dart:convert';
import 'package:flutter/material.dart';
import '../core.dart';
import '../widgets/interactive_effects.dart';

class AdminWalletTab extends StatefulWidget {
  const AdminWalletTab({super.key});

  @override
  State<AdminWalletTab> createState() => _AdminWalletTabState();
}

class _AdminWalletTabState extends State<AdminWalletTab> {
  late Future<Map<String, dynamic>> _future = _load();

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
    List<Map<String, dynamic>> balances = [];
    List<Map<String, dynamic>> topups = [];
    final Map<String, String> userNames = {};
    final Map<String, String> settings = {
      'admin_upi_id': 'kotechashalini-1@okicici',
      'admin_payee_name': 'shalini Kotecha',
    };

    // 1. Balances
    try {
      final res = await supabase.from('wallet_balances').select().order('balance');
      balances = List<Map<String, dynamic>>.from(res);
      for (final b in balances) {
        if (b['user_id'] != null && b['name'] != null) {
          userNames[b['user_id'].toString()] = b['name'].toString();
        }
      }
    } catch (e) {
      debugPrint('Error loading balances: $e');
    }

    // 2. Profiles (to resolve any user names)
    try {
      final pRes = await supabase.from('profiles').select('id, name');
      for (final p in pRes) {
        if (p['id'] != null && p['name'] != null) {
          userNames[p['id'].toString()] = p['name'].toString();
        }
      }
    } catch (e) {
      debugPrint('Error loading profiles: $e');
    }

    // 3. Top-up requests (plain select without ambiguous embedding)
    try {
      final tRes = await supabase.from('topup_requests').select().order('created_at', ascending: false);
      final rawTopups = List<Map<String, dynamic>>.from(tRes);
      topups = rawTopups.map((t) {
        final uid = t['user_id']?.toString() ?? '';
        final resolvedName = userNames[uid] ?? 'Staff';
        return {
          ...t,
          'user_name': resolvedName,
        };
      }).toList();
    } catch (e) {
      debugPrint('Error loading topup_requests: $e');
    }

    // 4. Admin Settings
    try {
      final sRes = await supabase.from('admin_settings').select();
      for (final s in sRes) {
        if (s['key'] != null && s['value'] != null) {
          settings[s['key'].toString()] = s['value'].toString();
        }
      }
    } catch (e) {
      debugPrint('Note: admin_settings error: $e');
    }

    return {
      'balances': balances,
      'topups': topups,
      'settings': settings,
    };
  }

  Widget _buildScreenshotWidget(String url, {double? width, double? height, BoxFit fit = BoxFit.cover}) {
    if (url.startsWith('data:image')) {
      try {
        final base64Str = url.contains(',') ? url.split(',').last : url;
        final bytes = base64Decode(base64Str);
        return Image.memory(bytes, width: width, height: height, fit: fit);
      } catch (e) {
        return const Icon(Icons.broken_image, color: Colors.grey);
      }
    }
    return Image.network(
      url,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image, color: Colors.grey),
    );
  }

  void _showScreenshotDialog(Map<String, dynamic> req) {
    final url = req['screenshot_url']?.toString();
    if (url == null || url.isEmpty) return;
    final staffName = req['user_name'] ?? 'Staff';
    final amount = (req['amount'] as num).toDouble();

    showDialog(
      context: context,
      builder: (c) => Dialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440, maxHeight: 650),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('$staffName\'s Payment Proof', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF221711))),
                        const SizedBox(height: 2),
                        Text(
                          'Amount: ₹${amount.toStringAsFixed(2)}',
                          style: const TextStyle(color: Color(0xFF2E7D32), fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(c),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      color: const Color(0xFFF5F3EF),
                      alignment: Alignment.center,
                      child: InteractiveViewer(
                        minScale: 1.0,
                        maxScale: 4.0,
                        child: _buildScreenshotWidget(url, fit: BoxFit.contain),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(onPressed: () => Navigator.pop(c), child: const Text('Close')),
                    const SizedBox(width: 8),
                    FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
                      onPressed: () {
                        Navigator.pop(c);
                        _approveTopup(req);
                      },
                      icon: const Icon(Icons.check_rounded, size: 16),
                      label: const Text('Approve & Credit'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _approveTopup(Map<String, dynamic> req) async {
    final staffName = req['user_name'] ?? 'Staff';
    final amount = (req['amount'] as num).toDouble();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Approve Top-up?'),
        content: Text(
          'Have you verified the payment screenshot for ₹${amount.toStringAsFixed(2)} from $staffName in your UPI app?\n\nThis will instantly credit ₹${amount.toStringAsFixed(2)} to their wallet.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF2E7D32)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Confirm & Credit'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.rpc('approve_topup_request', params: {'p_request_id': req['id']});
      refresh();
      setState(() {
        _future = _load();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 Approved! ₹${amount.toStringAsFixed(2)} credited to $staffName'),
            backgroundColor: const Color(0xFF2E7D32),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error approving request: $e')),
        );
      }
    }
  }

  Future<void> _rejectTopup(Map<String, dynamic> req) async {
    final reasonCtrl = TextEditingController(text: 'Payment not received in account');
    final staffName = req['user_name'] ?? 'Staff';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Reject Top-up for $staffName'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Enter reason for declining this request:'),
            const SizedBox(height: 12),
            TextField(
              controller: reasonCtrl,
              decoration: const InputDecoration(
                labelText: 'Reason',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFD34A26)),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Decline Request'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.rpc('reject_topup_request', params: {
        'p_request_id': req['id'],
        'p_reason': reasonCtrl.text.trim(),
      });
      refresh();
      setState(() {
        _future = _load();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Top-up request for $staffName was declined.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _showUpiSettingsDialog(Map<String, String> settings) {
    final upiCtrl = TextEditingController(text: settings['admin_upi_id'] ?? 'kotechashalini-1@okicici');
    final nameCtrl = TextEditingController(text: settings['admin_payee_name'] ?? 'shalini Kotecha');

    showDialog(
      context: context,
      builder: (c) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        title: const Row(
          children: [
            Icon(Icons.qr_code_rounded, color: Color(0xFFE84E26)),
            SizedBox(width: 8),
            Text('Admin UPI Settings'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure the UPI ID and Payee Name that staff will see when adding money to their wallet.',
              style: TextStyle(fontSize: 13, color: Color(0xFF70655E)),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: upiCtrl,
              decoration: const InputDecoration(
                labelText: 'Admin UPI ID*',
                hintText: 'e.g. kotechashalini-1@okicici',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Payee / Display Name',
                hintText: 'e.g. shalini Kotecha',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE84E26)),
            onPressed: () async {
              final newUpi = upiCtrl.text.trim();
              final newName = nameCtrl.text.trim();
              if (newUpi.isEmpty) return;

              try {
                await Future.wait([
                  supabase.from('admin_settings').upsert({
                    'key': 'admin_upi_id',
                    'value': newUpi,
                  }),
                  supabase.from('admin_settings').upsert({
                    'key': 'admin_payee_name',
                    'value': newName.isEmpty ? 'shalini Kotecha' : newName,
                  }),
                ]);
                if (c.mounted) Navigator.pop(c);
                refresh();
                setState(() {
                  _future = _load();
                });
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('UPI settings updated successfully!'),
                      backgroundColor: Color(0xFF2E7D32),
                    ),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to save settings: $e')));
                }
              }
            },
            child: const Text('Save Settings'),
          ),
        ],
      ),
    );
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
          child: FutureBuilder<Map<String, dynamic>>(
            future: _future,
            builder: (context, snap) {
              if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator(color: Color(0xFFE84E26)));
              }

              final data = snap.data ?? {};
              final rows = List<Map<String, dynamic>>.from(data['balances'] ?? []);
              final topups = List<Map<String, dynamic>>.from(data['topups'] ?? []);
              final settings = Map<String, String>.from(data['settings'] ?? {});

              final pendingTopups = topups.where((t) => t['status'] == 'pending').toList();
              final pending = rows.where((r) => (r['balance'] as num) < -0.01).toList();
              final settled = rows.where((r) => (r['balance'] as num) >= -0.01).toList();
              final totalOwed = pending.fold<double>(0, (sum, r) => sum - (r['balance'] as num).toDouble());

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Top Row with UPI Settings button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Wallet Overview',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF221711),
                        ),
                      ),
                      InkWell(
                        onTap: () => _showUpiSettingsDialog(settings),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEFE8DE)),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 4, offset: const Offset(0, 2)),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.qr_code_2_rounded, size: 16, color: Color(0xFFE84E26)),
                              const SizedBox(width: 6),
                              Text(
                                settings['admin_upi_id'] ?? 'Setup UPI',
                                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF4A3E38)),
                              ),
                              const SizedBox(width: 4),
                              const Icon(Icons.edit_rounded, size: 13, color: Color(0xFF8A827A)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Total Outstanding Owed Summary Card
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEEE3),
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Total Outstanding Owed',
                                style: TextStyle(
                                  fontSize: 13.5,
                                  color: Color(0xFF70655E),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '₹${totalOwed.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 34,
                                    fontWeight: FontWeight.w900,
                                    color: Color(0xFFE84E26),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                pending.length == 1
                                    ? '1 person has pending dues'
                                    : '${pending.length} people have pending dues',
                                style: const TextStyle(
                                  fontSize: 12.5,
                                  color: Color(0xFF8A827A),
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 58,
                          height: 58,
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
                                size: 30,
                              ),
                              Positioned(
                                right: 10,
                                bottom: 10,
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
                                      fontSize: 9.5,
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
                  const SizedBox(height: 20),

                  // Section 0: Pending Top-up Requests
                  if (pendingTopups.isNotEmpty) ...[
                    Row(
                      children: [
                        const Icon(Icons.notifications_active_rounded, color: Color(0xFFE84E26), size: 20),
                        const SizedBox(width: 8),
                        const Text(
                          'Top-up Requests',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF221711)),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFE84E26),
                            borderRadius: BorderRadius.circular(99),
                          ),
                          child: Text(
                            '${pendingTopups.length} New',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    for (final req in pendingTopups)
                      Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFFFCCBC), width: 1.5),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFFE84E26).withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: const Color(0xFFFDECE8),
                                  child: Text(
                                    ((req['user_name'] ?? 'S').toString())[0].toUpperCase(),
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Color(0xFFE84E26)),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        req['user_name'] ?? 'Staff Member',
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Color(0xFF221711)),
                                      ),
                                      Text(
                                        req['created_at'] != null ? req['created_at'].toString().substring(0, 16).replaceAll('T', ' ') : '',
                                        style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A827A)),
                                      ),
                                    ],
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE8F5E9),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Text(
                                    '+₹${(req['amount'] as num).toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      fontSize: 17,
                                      fontWeight: FontWeight.w900,
                                      color: Color(0xFF2E7D32),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Payment Proof Section (Screenshot & Info)
                            if (req['screenshot_url'] != null && req['screenshot_url'].toString().isNotEmpty) ...[
                              InkWell(
                                onTap: () => _showScreenshotDialog(req),
                                borderRadius: BorderRadius.circular(12),
                                child: Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF9F6F0),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(color: const Color(0xFFEFE8DE)),
                                  ),
                                  child: Row(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: SizedBox(
                                          width: 48,
                                          height: 48,
                                          child: _buildScreenshotWidget(req['screenshot_url'], fit: BoxFit.cover),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      const Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Payment Screenshot Attached',
                                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF221711)),
                                            ),
                                            SizedBox(height: 2),
                                            Text(
                                              'Tap to view & zoom screenshot',
                                              style: TextStyle(fontSize: 11.5, color: Color(0xFFE84E26), fontWeight: FontWeight.w600),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Icon(Icons.fullscreen_rounded, color: Color(0xFFE84E26), size: 24),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],

                            if (req['upi_ref'] != null && req['upi_ref'].toString() != 'Screenshot Uploaded') ...[
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFBF8F3),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  children: [
                                    const Text('Ref / Note: ', style: TextStyle(fontSize: 12, color: Color(0xFF70655E))),
                                    Expanded(
                                      child: SelectableText(
                                        req['upi_ref'] ?? '',
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF221711)),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],

                            if (req['note'] != null && req['note'].toString().isNotEmpty) ...[
                              const SizedBox(height: 6),
                              Text(
                                'Note: "${req['note']}"',
                                style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: Color(0xFF70655E)),
                              ),
                            ],
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _rejectTopup(req),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: const Color(0xFFD34A26),
                                      side: const BorderSide(color: Color(0xFFF5C6BA)),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                    child: const Text('Decline'),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  flex: 2,
                                  child: FilledButton.icon(
                                    onPressed: () => _approveTopup(req),
                                    icon: const Icon(Icons.check_rounded, size: 16),
                                    label: const Text('Approve & Credit', overflow: TextOverflow.ellipsis),
                                    style: FilledButton.styleFrom(
                                      backgroundColor: const Color(0xFF2E7D32),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                      padding: const EdgeInsets.symmetric(vertical: 10),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    const SizedBox(height: 16),
                  ],

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
                                      overflow: TextOverflow.ellipsis,
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
                              const SizedBox(width: 8),
                              BouncingButton(
                                onPressed: () => _recordPayment(pending[i], false),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFE84E26),
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  child: const FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      'Mark Paid',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
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
                                    overflow: TextOverflow.ellipsis,
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
                            const SizedBox(width: 8),
                            BouncingButton(
                              onPressed: () => _recordPayment(settled[i], true),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFCEEE3),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.add_circle_outline_rounded,
                                        size: 15,
                                        color: Color(0xFF8A3B18),
                                      ),
                                      SizedBox(width: 5),
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
