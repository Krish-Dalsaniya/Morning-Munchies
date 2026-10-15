import 'package:flutter/material.dart';
import '../core.dart';

class PeopleTab extends StatefulWidget {
  const PeopleTab({super.key});

  @override
  State<PeopleTab> createState() => _PeopleTabState();
}

class _PeopleTabState extends State<PeopleTab> {
  final _currentUid = supabase.auth.currentUser?.id ?? '';
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
    final res = await supabase.from('profiles').select().order('created_at');
    return List<Map<String, dynamic>>.from(res);
  }

  Future<void> _toggleRole(String userId, String currentRole, String userName) async {
    if (userId == _currentUid) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("You cannot change your own role.")));
      return;
    }

    final newRole = currentRole == 'admin' ? 'staff' : 'admin';
    final ok = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('Change role for $userName?'),
        content: Text('Set role from $currentRole to $newRole?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(c, true), child: const Text('Change')),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await supabase.from('profiles').update({'role': newRole}).eq('id', userId);
      refresh();
      setState(() {
        _future = _load();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$userName is now $newRole!')));
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

            final people = snap.data ?? [];

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Registered People', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Chip(
                      label: Text('${people.length} members', style: const TextStyle(fontSize: 12)),
                      visualDensity: VisualDensity.compact,
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                for (final p in people) ...[
                  Card(
                    elevation: 1,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: p['role'] == 'admin' ? Colors.deepOrange : Colors.grey[400],
                        foregroundColor: Colors.white,
                        child: Icon(p['role'] == 'admin' ? Icons.admin_panel_settings : Icons.person),
                      ),
                      title: Row(
                        children: [
                          Expanded(child: Text(p['name'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold))),
                          if (p['id'] == _currentUid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(color: Colors.blue[100], borderRadius: BorderRadius.circular(6)),
                              child: Text('You', style: TextStyle(fontSize: 11, color: Colors.blue[900], fontWeight: FontWeight.bold)),
                            ),
                        ],
                      ),
                      subtitle: Text(
                        'Role: ${(p['role'] ?? 'staff').toString().toUpperCase()}',
                        style: TextStyle(
                          color: p['role'] == 'admin' ? Colors.deepOrange : Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      trailing: p['id'] == _currentUid
                          ? null
                          : OutlinedButton(
                              style: OutlinedButton.styleFrom(visualDensity: VisualDensity.compact),
                              onPressed: () => _toggleRole(p['id'], p['role'] ?? 'staff', p['name'] ?? 'User'),
                              child: Text(p['role'] == 'admin' ? 'Make Staff' : 'Make Admin'),
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
