import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core.dart';
import '../widgets/image_picker_helper.dart';
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

  Future<List<dynamic>> _load() async {
    Map<String, dynamic>? balanceData;
    List<Map<String, dynamic>> txns = [];
    List<Map<String, dynamic>> topups = [];
    final Map<String, String> settings = {
      'admin_upi_id': 'kotechashalini-1@okicici',
      'admin_payee_name': 'shalini Kotecha',
    };

    try {
      balanceData = await supabase.from('wallet_balances').select().eq('user_id', _uid).maybeSingle();
    } catch (e) {
      debugPrint('Error loading balance: $e');
    }

    try {
      final res = await supabase.from('wallet_transactions').select().eq('user_id', _uid).order('created_at', ascending: false);
      txns = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Error loading txns: $e');
    }

    try {
      final res = await supabase.from('topup_requests').select().eq('user_id', _uid).order('created_at', ascending: false);
      topups = List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Note: topup_requests query error: $e');
    }

    try {
      final res = await supabase.from('admin_settings').select();
      for (final s in res) {
        if (s['key'] != null && s['value'] != null) {
          settings[s['key'].toString()] = s['value'].toString();
        }
      }
    } catch (e) {
      debugPrint('Note: admin_settings error: $e');
    }

    return [balanceData, txns, topups, settings];
  }

  void _showAddMoneySheet(Map<String, String> settings) {
    final upiId = settings['admin_upi_id'] ?? 'kotechashalini-1@okicici';
    final payeeName = settings['admin_payee_name'] ?? 'shalini Kotecha';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddMoneyModal(
        adminUpiId: upiId,
        adminPayeeName: payeeName,
        onSuccess: () {
          refresh();
          setState(() {
            _future = _load();
          });
        },
      ),
    );
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
              final topups = List<Map<String, dynamic>>.from(snap.data?[2] ?? []);
              final settings = Map<String, String>.from(snap.data?[3] ?? {});

              final pendingTopups = topups.where((t) => t['status'] == 'pending').toList();
              final owes = balance < -0.01;
              final advance = balance > 0.01;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                children: [
                  // Modern Account Balance Card
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFCEEE3),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFE84E26).withValues(alpha: 0.08),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ],
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
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            owes
                                ? '-₹${balance.abs().toStringAsFixed(2)}'
                                : '₹${balance.toStringAsFixed(2)}',
                            style: TextStyle(
                              fontSize: 38,
                              fontWeight: FontWeight.w900,
                              color: owes ? const Color(0xFFD34A26) : const Color(0xFF221711),
                            ),
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
                        const SizedBox(height: 20),
                        // Add Money Button
                        BouncingButton(
                          onPressed: () => _showAddMoneySheet(settings),
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFFE84E26), Color(0xFFFF6D3B)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFFE84E26).withValues(alpha: 0.35),
                                  blurRadius: 12,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.add_circle_outline_rounded, color: Colors.white, size: 20),
                                SizedBox(width: 8),
                                Text(
                                  '+ Add Money to Wallet',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Pending Top-up Alerts
                  if (pendingTopups.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    for (final pt in pendingTopups)
                      Container(
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E7),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFFFE082), width: 1.2),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: const BoxDecoration(
                                color: Color(0xFFFFECC0),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.hourglass_top_rounded, color: Color(0xFFC77700), size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        'Top-up: +₹${(pt['amount'] as num).toStringAsFixed(2)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 15,
                                          color: Color(0xFF5E3900),
                                        ),
                                      ),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFFFECC0),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Text(
                                          'Pending Approval',
                                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFFC77700)),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    pt['screenshot_url'] != null
                                        ? '📸 Screenshot attached'
                                        : 'Ref: ${pt['upi_ref'] ?? 'Payment submitted'}',
                                    style: const TextStyle(fontSize: 12, color: Color(0xFF8A6830)),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],

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
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 3),
                                        Text(
                                          dateStr,
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color: Color(0xFF8A827A),
                                            fontWeight: FontWeight.w500,
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  FittedBox(
                                    fit: BoxFit.scaleDown,
                                    child: Text(
                                      '${isCharge ? '-' : '+'}₹${amount.toStringAsFixed(2)}',
                                      style: TextStyle(
                                        fontSize: 17,
                                        fontWeight: FontWeight.w800,
                                        color: isCharge
                                            ? const Color(0xFFD34A26)
                                            : const Color(0xFF2E7D32),
                                      ),
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

/// Bottom sheet dialog to add money via UPI & submit Screenshot for Admin approval
class _AddMoneyModal extends StatefulWidget {
  final String adminUpiId;
  final String adminPayeeName;
  final VoidCallback onSuccess;

  const _AddMoneyModal({
    required this.adminUpiId,
    required this.adminPayeeName,
    required this.onSuccess,
  });

  @override
  State<_AddMoneyModal> createState() => _AddMoneyModalState();
}

class _AddMoneyModalState extends State<_AddMoneyModal> {
  final _amountCtrl = TextEditingController(text: '200');
  final _utrCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();
  bool _submitting = false;

  Uint8List? _screenshotBytes;
  String? _screenshotName;

  final List<int> _quickAmounts = [100, 200, 500, 1000];

  void _copyUpi() {
    Clipboard.setData(ClipboardData(text: widget.adminUpiId));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('UPI ID copied: ${widget.adminUpiId}'),
        backgroundColor: const Color(0xFF2E7D32),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<void> _pickScreenshot() async {
    try {
      final picked = await pickImageFile();
      if (picked != null) {
        setState(() {
          _screenshotBytes = picked.bytes;
          _screenshotName = picked.name;
        });
      }
    } catch (e) {
      debugPrint('Error picking screenshot: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not pick screenshot: $e'),
            backgroundColor: const Color(0xFFD34A26),
          ),
        );
      }
    }
  }

  Future<String?> _uploadOrEncodeScreenshot(String uid) async {
    if (_screenshotBytes == null) return null;
    final fileName = '${uid}_${DateTime.now().millisecondsSinceEpoch}.jpg';
    final filePath = 'proofs/$fileName';

    try {
      await supabase.storage.from('payment_proofs').uploadBinary(
        filePath,
        _screenshotBytes!,
        fileOptions: const FileOptions(contentType: 'image/jpeg', upsert: true),
      );
      return supabase.storage.from('payment_proofs').getPublicUrl(filePath);
    } catch (e) {
      debugPrint('Note: Storage bucket upload skipped or failed ($e), saving as base64 data.');
      return 'data:image/jpeg;base64,${base64Encode(_screenshotBytes!)}';
    }
  }

  Future<void> _submit() async {
    final amount = double.tryParse(_amountCtrl.text.trim());
    final utr = _utrCtrl.text.trim();

    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid amount')),
      );
      return;
    }

    if (_screenshotBytes == null && utr.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a payment screenshot (or enter UPI reference)')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final uid = supabase.auth.currentUser?.id;
      if (uid == null) throw Exception('User not authenticated');

      final screenshotUrl = await _uploadOrEncodeScreenshot(uid);

      try {
        await supabase.from('topup_requests').insert({
          'user_id': uid,
          'amount': amount,
          'upi_ref': utr.isEmpty ? 'Screenshot Uploaded' : utr,
          'screenshot_url': screenshotUrl,
          'note': _noteCtrl.text.trim().isEmpty ? null : _noteCtrl.text.trim(),
          'status': 'pending',
        });
      } catch (insertErr) {
        debugPrint('Insert with screenshot_url failed ($insertErr), retrying without screenshot_url column...');
        // Fallback in case screenshot_url column is not yet added in Supabase
        await supabase.from('topup_requests').insert({
          'user_id': uid,
          'amount': amount,
          'upi_ref': utr.isEmpty ? 'Screenshot Uploaded' : utr,
          'note': _noteCtrl.text.trim().isEmpty ? 'Screenshot submitted' : _noteCtrl.text.trim(),
          'status': 'pending',
        });
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onSuccess();
        showDialog(
          context: context,
          builder: (c) => AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
            title: const Row(
              children: [
                Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 28),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Screenshot Submitted!',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            content: Text(
              'Your payment screenshot of ₹${amount.toStringAsFixed(2)} has been sent to Shalini Kotecha for verification.\n\nYour wallet balance will update as soon as the Admin approves it.',
              style: const TextStyle(fontSize: 14, color: Color(0xFF4A3E38), height: 1.4),
            ),
            actions: [
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE84E26)),
                onPressed: () => Navigator.pop(c),
                child: const Text('Got it'),
              ),
            ],
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _submitting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit: $e'),
            backgroundColor: const Color(0xFFD34A26),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag indicator handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE0D8D0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Add Money to Wallet',
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF221711)),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Scan, pay & upload payment screenshot',
                      style: TextStyle(fontSize: 13, color: Color(0xFF8A827A)),
                    ),
                  ],
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, color: Color(0xFF8A827A)),
                ),
              ],
            ),
            const SizedBox(height: 18),

            // Quick Amount Selector
            const Text(
              'Select Amount',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: Color(0xFF70655E)),
            ),
            const SizedBox(height: 8),
            Row(
              children: _quickAmounts.map((amt) {
                final isSelected = _amountCtrl.text.trim() == amt.toString();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: InkWell(
                      onTap: () {
                        setState(() {
                          _amountCtrl.text = amt.toString();
                        });
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFFFDECE8) : const Color(0xFFFBF8F3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? const Color(0xFFE84E26) : const Color(0xFFEFE8DE),
                            width: isSelected ? 1.8 : 1,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '₹$amt',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isSelected ? const Color(0xFFE84E26) : const Color(0xFF4A3E38),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 14),

            // Amount Input
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.currency_rupee_rounded, color: Color(0xFFE84E26)),
                labelText: 'Top-up Amount',
                filled: true,
                fillColor: const Color(0xFFFBF8F3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 20),

            // UPI Payment Card (QR + UPI ID)
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFCEEE3),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFF5DCD3)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFFE84E26),
                          shape: BoxShape.circle,
                        ),
                        child: const Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Scan QR or Pay to Admin UPI ID',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF221711)),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // Official QR Code Image
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.asset(
                        'assets/images/admin_qr.jpg',
                        width: 190,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 190,
                          height: 190,
                          alignment: Alignment.center,
                          child: const Icon(Icons.qr_code_2_rounded, size: 54, color: Color(0xFFE84E26)),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // UPI ID Copy Row
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.account_balance_rounded, size: 20, color: Color(0xFF70655E)),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.adminPayeeName,
                                style: const TextStyle(fontSize: 11.5, color: Color(0xFF8A827A)),
                              ),
                              SelectableText(
                                widget.adminUpiId,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13.5, color: Color(0xFF221711)),
                              ),
                            ],
                          ),
                        ),
                        InkWell(
                          onTap: _copyUpi,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDECE8),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Row(
                              children: [
                                Icon(Icons.copy_rounded, size: 14, color: Color(0xFFE84E26)),
                                SizedBox(width: 4),
                                Text(
                                  'Copy',
                                  style: TextStyle(color: Color(0xFFE84E26), fontWeight: FontWeight.bold, fontSize: 12),
                                ),
                              ],
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

            // Step 2: Upload Payment Screenshot
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: const BoxDecoration(
                    color: Color(0xFFE84E26),
                    shape: BoxShape.circle,
                  ),
                  child: const Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                ),
                const SizedBox(width: 10),
                const Text(
                  'Upload Payment Screenshot',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF221711)),
                ),
              ],
            ),
            const SizedBox(height: 10),

            // Screenshot Upload Picker Box
            InkWell(
              onTap: _pickScreenshot,
              borderRadius: BorderRadius.circular(16),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _screenshotBytes != null ? const Color(0xFFE8F5E9) : const Color(0xFFFBF8F3),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _screenshotBytes != null ? const Color(0xFF4CAF50) : const Color(0xFFE0D8D0),
                    width: 1.5,
                  ),
                ),
                child: _screenshotBytes != null
                    ? Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(10),
                            child: Image.memory(
                              _screenshotBytes!,
                              width: 60,
                              height: 60,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(Icons.check_circle_rounded, color: Color(0xFF2E7D32), size: 18),
                                    SizedBox(width: 6),
                                    Text(
                                      'Screenshot Attached!',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF2E7D32), fontSize: 13.5),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  _screenshotName ?? 'payment_proof.jpg',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(fontSize: 12, color: Color(0xFF555555)),
                                ),
                                const SizedBox(height: 4),
                                const Text(
                                  'Tap to change screenshot',
                                  style: TextStyle(fontSize: 11, color: Color(0xFFE84E26), fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close_rounded, color: Colors.red),
                            onPressed: () => setState(() {
                              _screenshotBytes = null;
                              _screenshotName = null;
                            }),
                          ),
                        ],
                      )
                    : const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.add_photo_alternate_outlined, size: 38, color: Color(0xFFE84E26)),
                          SizedBox(height: 8),
                          Text(
                            'Tap to Select Payment Screenshot',
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Color(0xFF221711)),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'GPay / PhonePe / Paytm receipt (JPG, PNG)',
                            style: TextStyle(fontSize: 12, color: Color(0xFF8A827A)),
                          ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),

            // Optional Note / Reference
            TextField(
              controller: _noteCtrl,
              decoration: InputDecoration(
                labelText: 'Note or UPI Reference (Optional)',
                hintText: 'e.g. Paid via GPay',
                prefixIcon: const Icon(Icons.edit_note_rounded, color: Color(0xFF70655E)),
                filled: true,
                fillColor: const Color(0xFFFBF8F3),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
            const SizedBox(height: 22),

            // Submit Button
            FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE84E26),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _submitting
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                    )
                  : const Text(
                      'Submit Top-up Request',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
