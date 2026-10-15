import 'package:flutter/material.dart';
import '../core.dart';
import '../widgets/interactive_effects.dart';

class VendorsTab extends StatefulWidget {
  const VendorsTab({super.key});

  @override
  State<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends State<VendorsTab> {
  final _vendorName = TextEditingController();
  final _vendorPhone = TextEditingController();
  bool _isAddingVendor = false;

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
    final res = await supabase.from('vendors').select('*, food_items(*)').order('name');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _addVendor() async {
    final name = _vendorName.text.trim();
    if (name.isEmpty) return;

    setState(() => _isAddingVendor = true);
    try {
      await supabase.from('vendors').insert({
        'name': name,
        'phone': _vendorPhone.text.trim().isEmpty ? null : _vendorPhone.text.trim(),
      });
      _vendorName.clear();
      _vendorPhone.clear();
      refresh();
      setState(() {
        _future = _load();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error adding vendor: $e')));
    } finally {
      if (mounted) setState(() => _isAddingVendor = false);
    }
  }

  Future<void> _deleteVendor(String id, String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Delete $name?'),
        content: const Text('This will also delete all food items associated with this vendor.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await supabase.from('vendors').delete().eq('id', id);
      refresh();
      setState(() {
        _future = _load();
      });
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }

  Future<void> _addItemDialog(String vendorId, String vendorName) async {
    final nameCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    String meal = 'lunch';

    await showDialog(
      context: context,
      builder: (c) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text('Add Item to $vendorName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Item Name (e.g. Masala Dosa, Thali)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(labelText: 'Price (₹)'),
              ),
              const SizedBox(height: 16),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'breakfast', label: Text('Breakfast')),
                  ButtonSegment(value: 'lunch', label: Text('Lunch')),
                ],
                selected: {meal},
                onSelectionChanged: (s) => setDialogState(() => meal = s.first),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(c), child: const Text('Cancel')),
            FilledButton(
              onPressed: () async {
                final name = nameCtrl.text.trim();
                final price = double.tryParse(priceCtrl.text.trim()) ?? 0.0;
                if (name.isEmpty) return;

                final messenger = ScaffoldMessenger.of(context);
                Navigator.pop(c);
                try {
                  await supabase.from('food_items').insert({
                    'vendor_id': vendorId,
                    'name': name,
                    'price': price,
                    'meal': meal,
                  });
                  refresh();
                  setState(() {
                    _future = _load();
                  });
                } catch (e) {
                  if (mounted) messenger.showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              },
              child: const Text('Add Item'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteItem(String itemId) async {
    try {
      await supabase.from('food_items').delete().eq('id', itemId);
      refresh();
      setState(() {
        _future = _load();
      });
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
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 40),
            children: [
              // Add New Vendor Card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFFCEEE3),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFFE84E26),
                          size: 22,
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Add New Vendor',
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF221711),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Inputs Row
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _vendorName,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Vendor Name (e.g....',
                              hintStyle: const TextStyle(color: Color(0xFF9E8D8A), fontSize: 13),
                              prefixIcon: const Icon(Icons.storefront_outlined, size: 18, color: Color(0xFF8A827A)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE8DDD2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE8DDD2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE84E26), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _vendorPhone,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Phone (op...',
                              hintStyle: const TextStyle(color: Color(0xFF9E8D8A), fontSize: 13),
                              prefixIcon: const Icon(Icons.phone_outlined, size: 18, color: Color(0xFF8A827A)),
                              filled: true,
                              fillColor: Colors.white,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                              isDense: true,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE8DDD2)),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE8DDD2)),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: const BorderSide(color: Color(0xFFE84E26), width: 1.5),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Add Vendor Full-Width Button
                    BouncingButton(
                      onPressed: _isAddingVendor ? null : _addVendor,
                      child: Container(
                        width: double.infinity,
                        height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE84E26),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        alignment: Alignment.center,
                        child: _isAddingVendor
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.add, size: 18, color: Colors.white),
                                  SizedBox(width: 6),
                                  Text(
                                    'Add Vendor',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Section Title
              const Text(
                'Vendors & Food Catalog',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF221711),
                ),
              ),
              const SizedBox(height: 10),

              FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snap) {
                  if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                  if (snap.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFFE84E26)));
                  }

                  final vendors = snap.data ?? [];
                  if (vendors.isEmpty) {
                    return Container(
                      margin: const EdgeInsets.only(top: 24),
                      padding: const EdgeInsets.all(32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: const Color(0xFFEFE8DE)),
                      ),
                      child: const Center(
                        child: Text(
                          'No vendors yet. Add your first vendor above.',
                          style: TextStyle(color: Color(0xFF70655E)),
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: [
                      for (final v in vendors) ...[
                        _buildVendorCard(v),
                      ],
                    ],
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final vendorId = vendor['id'] as String;
    final vendorName = vendor['name'] as String;
    final phone = vendor['phone'] as String?;
    final items = List<Map<String, dynamic>>.from(vendor['food_items'] ?? []);

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.all(16),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vendor Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: Color(0xFFFDE6D9),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.storefront_rounded,
                  color: Color(0xFFE84E26),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vendorName,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF221711),
                      ),
                    ),
                    if (phone != null && phone.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.phone, size: 12, color: Color(0xFF70655E)),
                          const SizedBox(width: 4),
                          Text(
                            phone,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFF70655E),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              // Add Item Pill Button
              BouncingButton(
                onPressed: () => _addItemDialog(vendorId, vendorName),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFCEEE3),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.add, size: 14, color: Color(0xFF8A3B18)),
                      SizedBox(width: 4),
                      Text(
                        'Add Item',
                        style: TextStyle(
                          color: Color(0xFF8A3B18),
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 6),
              IconButton(
                icon: const Icon(Icons.delete_outline_rounded, color: Color(0xFFD34A26), size: 22),
                tooltip: 'Delete vendor',
                onPressed: () => _deleteVendor(vendorId, vendorName),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1, color: Color(0xFFF4EEE6)),
          const SizedBox(height: 6),

          if (items.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'No items yet. Tap "+ Add Item" to add food options.',
                style: TextStyle(color: Color(0xFF9E8D8A), fontSize: 13),
              ),
            )
          else
            for (int i = 0; i < items.length; i++) ...[
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Row(
                  children: [
                    // Indian Veg Symbol
                    Container(
                      width: 18,
                      height: 18,
                      decoration: BoxDecoration(
                        border: Border.all(color: const Color(0xFF2E7D32), width: 1.5),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.circle, size: 8, color: Color(0xFF2E7D32)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            items[i]['name'] ?? '',
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF221711),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${(items[i]['meal'] ?? 'Breakfast').toString().toUpperCase()} • ₹${((items[i]['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF8A827A),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 20, color: Color(0xFF554A43)),
                      tooltip: 'Delete item',
                      onPressed: () => _deleteItem(items[i]['id']),
                    ),
                  ],
                ),
              ),
              if (i < items.length - 1)
                const Divider(height: 1, thickness: 1, color: Color(0xFFF7F1EA)),
            ],
        ],
      ),
    );
  }
}
