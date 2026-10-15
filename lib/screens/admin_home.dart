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
      backgroundColor: const Color(0xFFFBF8F3),
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
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // User Profile Header
                Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: const Color(0xFFE84E26),
                      foregroundColor: Colors.white,
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'A',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                userName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 20,
                                  color: Color(0xFF221711),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE84E26),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: const Text(
                                  'ADMIN',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            userEmail,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF70655E),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Divider(height: 1, thickness: 1, color: Color(0xFFF4EEE6)),
                const SizedBox(height: 12),

                // Management Sections Header
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 8),
                  child: Text(
                    'MANAGEMENT & SETUP',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF8A827A),
                      letterSpacing: 0.8,
                    ),
                  ),
                ),

                _buildMoreTile(
                  icon: Icons.restaurant_menu_rounded,
                  iconColor: const Color(0xFFE84E26),
                  iconBgColor: const Color(0xFFFDE6D9),
                  title: 'Vendors & Food Catalog',
                  subtitle: 'Manage vendors, menu items & prices',
                  onTap: () {
                    Navigator.pop(c);
                    _openVendors();
                  },
                ),
                const SizedBox(height: 8),

                _buildMoreTile(
                  icon: Icons.group_rounded,
                  iconColor: const Color(0xFFE84E26),
                  iconBgColor: const Color(0xFFFDE6D9),
                  title: 'People & Roles',
                  subtitle: 'Manage team members & permissions',
                  onTap: () {
                    Navigator.pop(c);
                    _openPeople();
                  },
                ),
                const SizedBox(height: 8),

                _buildMoreTile(
                  icon: Icons.refresh_rounded,
                  iconColor: const Color(0xFF221711),
                  iconBgColor: const Color(0xFFF0E8DC),
                  title: 'Refresh Data',
                  onTap: () {
                    Navigator.pop(c);
                    refresh();
                  },
                ),
                const SizedBox(height: 8),

                _buildMoreTile(
                  icon: Icons.logout_rounded,
                  iconColor: const Color(0xFFD32F2F),
                  iconBgColor: const Color(0xFFFDECE8),
                  title: 'Sign Out',
                  titleColor: const Color(0xFFD32F2F),
                  chevronColor: const Color(0xFFD32F2F),
                  onTap: () {
                    Navigator.pop(c);
                    supabase.auth.signOut();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMoreTile({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required String title,
    String? subtitle,
    Color titleColor = const Color(0xFF221711),
    Color chevronColor = const Color(0xFF70655E),
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFFCEEE3),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: iconBgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: titleColor,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: Color(0xFF70655E),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: chevronColor, size: 20),
          ],
        ),
      ),
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
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Vote',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Results',
          ),
          NavigationDestination(
            icon: Icon(Icons.checklist_rounded),
            selectedIcon: Icon(Icons.checklist_rounded),
            label: 'Pick Menu',
          ),
          NavigationDestination(
            icon: Icon(Icons.article_outlined),
            selectedIcon: Icon(Icons.article_rounded),
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
