import 'package:flutter/material.dart';
import '../core.dart';
import 'vote_tab.dart';
import 'results_tab.dart';
import 'pick_menu_tab.dart';
import 'vendors_tab.dart';
import 'admin_wallet_tab.dart';
import 'people_tab.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    final user = supabase.auth.currentUser;
    final userName = user?.userMetadata?['name'] ?? user?.email?.split('@').first ?? 'Admin';

    return DefaultTabController(
      length: 6,
      child: Scaffold(
        appBar: AppBar(
          title: Row(
            children: [
              const Text('Morning Munchies', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.deepOrange,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text('ADMIN', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
          actions: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text('Hi, $userName', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              tooltip: 'Refresh all',
              onPressed: refresh,
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sign out',
              onPressed: () => supabase.auth.signOut(),
            ),
          ],
          bottom: const TabBar(
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            labelColor: Colors.deepOrange,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Colors.deepOrange,
            tabs: [
              Tab(icon: Icon(Icons.how_to_vote, size: 20), text: 'Vote'),
              Tab(icon: Icon(Icons.poll_outlined, size: 20), text: 'Results'),
              Tab(icon: Icon(Icons.checklist, size: 20), text: 'Pick Menu'),
              Tab(icon: Icon(Icons.restaurant_menu, size: 20), text: 'Vendors & Food'),
              Tab(icon: Icon(Icons.account_balance_wallet, size: 20), text: 'Ledger / Wallet'),
              Tab(icon: Icon(Icons.people_outline, size: 20), text: 'People'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            VoteTab(),
            ResultsTab(),
            PickMenuTab(),
            VendorsTab(),
            AdminWalletTab(),
            PeopleTab(),
          ],
        ),
      ),
    );
  }
}
