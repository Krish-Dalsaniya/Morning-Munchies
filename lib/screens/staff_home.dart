import 'package:flutter/material.dart';
import '../core.dart';
import 'vote_tab.dart';
import 'wallet_tab.dart';

class StaffHome extends StatefulWidget {
  const StaffHome({super.key});

  @override
  State<StaffHome> createState() => _StaffHomeState();
}

class _StaffHomeState extends State<StaffHome> {
  int _currentIndex = 0;

  final _tabs = const [
    VoteTab(),
    WalletTab(),
  ];

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email?.split('@').first ?? 'Staff';

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
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Morning Munchies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Color(0xFF2C2420))),
                Text(
                  'Hi, $userName',
                  style: const TextStyle(fontSize: 12, color: Color(0xFF8C827A)),
                ),
              ],
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
              icon: const Icon(Icons.logout_rounded, size: 20, color: Color(0xFF4A3E38)),
              tooltip: 'Sign out',
              onPressed: () => supabase.auth.signOut(),
            ),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentIndex,
        children: _tabs,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (i) => setState(() => _currentIndex = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.how_to_vote_outlined),
            selectedIcon: Icon(Icons.how_to_vote),
            label: 'Vote',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet),
            label: 'My Wallet',
          ),
        ],
      ),
    );
  }
}
