import 'package:flutter/material.dart';

import '../analytics/analytics_screen.dart';
import '../debts/debts_screen.dart';
import '../expenses/expenses_screen.dart';
import '../friends/friends_screen.dart';
import '../personal_expenses/personal_expenses_screen.dart';
import 'dashboard_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    DashboardScreen(),
    ExpensesScreen(),
    DebtsScreen(),
    PersonalExpensesScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: Drawer(
        backgroundColor: Theme.of(context).colorScheme.surface,
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Icon(Icons.account_balance_wallet, size: 48, color: Theme.of(context).colorScheme.secondary),
                  const SizedBox(height: 12),
                  const Text(
                    'RoomLedger',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.bar_chart_outlined, color: Colors.white70),
              title: const Text('Analytics', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
              },
            ),
            ListTile(
              leading: const Icon(Icons.people_outlined, color: Colors.white70),
              title: const Text('Roommates', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
              },
            ),
          ],
        ),
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (value) {
          setState(() {
            _selectedIndex = value;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'Expenses'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'Debts'),
          NavigationDestination(icon: Icon(Icons.person_outline), label: 'Profile'),
        ],
      ),
    );
  }
}
