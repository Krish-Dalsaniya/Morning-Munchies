import 'package:flutter/material.dart';
import '../core.dart';
import 'vote_tab.dart';
import 'results_tab.dart';
import 'pick_menu_tab.dart';
import 'admin_wallet_tab.dart';
import 'vendors_tab.dart';
import 'people_tab.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  int _currentIndex = 0;

  final List<Widget> _mainPages = const [
    VoteTab(),
    ResultsTab(),
    PickMenuTab(),
    AdminWalletTab(),
  ];

  void _openVendors() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Vendors & Food Catalog', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: refresh),
            ],
          ),
          body: const VendorsTab(),
        ),
      ),
    );
  }

  void _openPeople() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('People & Roles', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            actions: [
              IconButton(icon: const Icon(Icons.refresh), tooltip: 'Refresh', onPressed: refresh),
            ],
          ),
          body: const PeopleTab(),
        ),
      ),
    );
  }

  void _showMoreBottomSheet() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (c) {
        final user = supabase.auth.currentUser;
        final userName = user?.userMetadata?['name'] ?? user?.email?.split('@').first ?? 'Admin';
        final userEmail = user?.email ?? '';

        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Header
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    radius: 24,
                    backgroundColor: Colors.deepOrange,
                    foregroundColor: Colors.white,
                    child: Text(
                      userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20),
                    ),
                  ),
                  title: Row(
                    children: [
                      Text(userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: Colors.deepOrange, borderRadius: BorderRadius.circular(4)),
                        child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ),
                  subtitle: Text(userEmail, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
                ),
                const Divider(height: 24),

                // Management Sections
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Text('MANAGEMENT & SETUP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.1)),
                ),
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.restaurant_menu, color: Colors.deepOrange),
                        title: const Text('Vendors & Food Catalog', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Manage vendors, menu items & prices', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(c);
                          _openVendors();
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.people_outline, color: Colors.deepOrange),
                        title: const Text('People & Roles', style: TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: const Text('Manage team members & permissions', style: TextStyle(fontSize: 12)),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () {
                          Navigator.pop(c);
                          _openPeople();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Account Actions
                Card(
                  elevation: 0,
                  color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    children: [
                      ListTile(
                        leading: const Icon(Icons.refresh),
                        title: const Text('Refresh Data'),
                        onTap: () {
                          Navigator.pop(c);
                          refresh();
                        },
                      ),
                      const Divider(height: 1, indent: 56),
                      ListTile(
                        leading: const Icon(Icons.logout, color: Colors.red),
                        title: const Text('Sign Out', style: TextStyle(color: Colors.red, fontWeight: FontWeight.w600)),
                        onTap: () {
                          Navigator.pop(c);
                          supabase.auth.signOut();
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFFBF8F3),
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                width: 34,
                height: 34,
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.wb_sunny, color: Colors.orange),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'Morning Munchies',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C2420)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: const Color(0xFFFA5A1E),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.workspace_premium_rounded, color: Colors.white, size: 12),
                  SizedBox(width: 3),
                  Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF0E8DC),
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 6),
            child: IconButton(
              icon: const Icon(Icons.refresh_rounded, size: 20, color: Color(0xFF4A3E38)),
              tooltip: 'Refresh',
              onPressed: refresh,
            ),
          ),
          Container(
            decoration: const BoxDecoration(
              color: Color(0xFFF0E8DC),
              shape: BoxShape.circle,
            ),
            margin: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.more_vert_rounded, size: 20, color: Color(0xFF4A3E38)),
              tooltip: 'More Options',
              onPressed: _showMoreBottomSheet,
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _mainPages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          if (index == 4) {
            _showMoreBottomSheet();
          } else {
            setState(() => _currentIndex = index);
          }
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.how_to_vote_outlined),
            selectedIcon: Icon(Icons.how_to_vote),
            label: 'Vote',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.dinner_dining_outlined),
            selectedIcon: Icon(Icons.dinner_dining),
            label: 'Pick Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),
            selectedIcon: Icon(Icons.receipt_long),
            label: 'Ledger',
          ),
          NavigationDestination(
            icon: Icon(Icons.more_horiz_rounded),
            selectedIcon: Icon(Icons.more_horiz_rounded),
            label: 'More',
          ),
        ],
      ),
    );
  }
}
