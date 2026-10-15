import 'package:flutter/material.dart';
import '../core.dart';

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
    return ValueListenableBuilder<int>(
      valueListenable: refreshTick,
      builder: (context, _, child) => RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _future = _load();
          });
          await _future;
        },
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Add Vendor Card
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Add New Vendor', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          flex: 3,
                          child: TextField(
                            controller: _vendorName,
                            decoration: const InputDecoration(
                              labelText: 'Vendor Name (e.g. Sharma Canteen)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: _vendorPhone,
                            decoration: const InputDecoration(
                              labelText: 'Phone (optional)',
                              border: OutlineInputBorder(),
                              isDense: true,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerRight,
                      child: FilledButton.icon(
                        onPressed: _isAddingVendor ? null : _addVendor,
                        icon: const Icon(Icons.add, size: 18),
                        label: const Text('Add Vendor'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text('Vendors & Food Catalog', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),

            FutureBuilder<List<Map<String, dynamic>>>(
              future: _future,
              builder: (context, snap) {
                if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
                if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());

                final vendors = snap.data ?? [];
                if (vendors.isEmpty) {
                  return Container(
                    margin: const EdgeInsets.only(top: 24),
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Center(
                      child: Text('No vendors yet. Add your first vendor above.', style: TextStyle(color: Colors.grey)),
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
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorCard(Map<String, dynamic> vendor) {
    final vendorId = vendor['id'] as String;
    final vendorName = vendor['name'] as String;
    final phone = vendor['phone'] as String?;
    final items = List<Map<String, dynamic>>.from(vendor['food_items'] ?? []);

    return Card(
      elevation: 1,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Vendor header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(vendorName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      if (phone != null && phone.isNotEmpty)
                        Text('📞 $phone', style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => _addItemDialog(vendorId, vendorName),
                  icon: const Icon(Icons.add, size: 16),
                  label: const Text('Add Item'),
                  style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  tooltip: 'Delete vendor',
                  onPressed: () => _deleteVendor(vendorId, vendorName),
                ),
              ],
            ),
            const Divider(height: 20),

            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text('No items yet. Tap "Add Item" to add food options.', style: TextStyle(color: Colors.grey[500], fontSize: 13)),
              )
            else
              for (final item in items) ...[
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item['name'] ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Text(
                    '${(item['meal'] ?? '').toString().toUpperCase()} • ₹${((item['price'] as num?)?.toDouble() ?? 0).toStringAsFixed(2)}',
                    style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.close, size: 18, color: Colors.grey),
                    tooltip: 'Delete item',
                    onPressed: () => _deleteItem(item['id']),
                  ),
                ),
              ],
          ],
        ),
      ),
    );
  }
}
