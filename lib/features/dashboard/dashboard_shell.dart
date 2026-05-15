import 'package:flutter/material.dart';

import '../../core/theme/app_theme.dart';
import '../analytics/analytics_screen.dart';
import '../debts/debts_screen.dart';
import '../expenses/expenses_screen.dart';
import '../friends/friends_screen.dart';
import 'dashboard_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell> {
  int _selectedIndex = 3; // Start on Debts as per image

  void _onItemTapped(int index) {
    if (index == 2) {
      _showAddSheet();
      return;
    }
    setState(() {
      _selectedIndex = index;
    });
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return Container(
          decoration: const BoxDecoration(
            color: AppTheme.surfaceElevated,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).padding.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'Create New',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _QuickAddIcon(
                    icon: Icons.receipt_long_outlined,
                    label: 'Expense',
                    color: AppTheme.secondary,
                    onTap: () {
                      Navigator.pop(context);
                      // Logic to open add expense
                    },
                  ),
                  _QuickAddIcon(
                    icon: Icons.person_add_outlined,
                    label: 'Friend',
                    color: AppTheme.accent,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const FriendsScreen()));
                    },
                  ),
                  _QuickAddIcon(
                    icon: Icons.insights_outlined,
                    label: 'Analytics',
                    color: Colors.orange,
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Definining pages inside build to ensure they are always synchronized with the current index
    // and to handle hot-reload scenarios correctly.
    final List<Widget> pages = [
      const DashboardScreen(),
      const ExpensesScreen(),
      const SizedBox.shrink(), // Index 2: Placeholder for Add button
      const DebtsScreen(),
      const FriendsScreen(), // Index 4: Profile/Roommates
    ];

    // Safety check for index
    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        height: 90,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: AppTheme.surfaceElevated,
          border: Border(top: BorderSide(color: AppTheme.onSurface.withValues(alpha: 0.08), width: 1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _NavBarItem(
              icon: Icons.home_filled,
              label: 'Home',
              isSelected: safeIndex == 0,
              onTap: () => _onItemTapped(0),
            ),
            _NavBarItem(
              icon: Icons.group_rounded,
              label: 'Shared',
              isSelected: safeIndex == 1,
              onTap: () => _onItemTapped(1),
            ),
            _AddButton(onTap: () => _onItemTapped(2)),
            _NavBarItem(
              icon: Icons.account_balance_wallet_rounded,
              label: 'Debts',
              isSelected: safeIndex == 3,
              onTap: () => _onItemTapped(3),
            ),
            _NavBarItem(
              icon: Icons.person_rounded,
              label: 'Profile',
              isSelected: safeIndex == 4,
              onTap: () => _onItemTapped(4),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavBarItem extends StatelessWidget {
  const _NavBarItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppTheme.secondary.withValues(alpha: 0.1) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                color: isSelected ? AppTheme.secondary : AppTheme.muted,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? AppTheme.secondary : AppTheme.muted,
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: const BoxDecoration(
          color: AppTheme.secondary,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Color(0x4000FFA3),
              blurRadius: 12,
              offset: Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.add, color: Colors.black, size: 28),
      ),
    );
  }
}

class _QuickAddIcon extends StatelessWidget {
  const _QuickAddIcon({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }
}
