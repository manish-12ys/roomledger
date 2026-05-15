import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../analytics/analytics_screen.dart';
import '../debts/debts_screen.dart';
import '../expenses/expenses_providers.dart';
import '../expenses/expenses_screen.dart';
import '../friends/friends_providers.dart';
import '../friends/friends_screen.dart';
import '../personal_expenses/personal_expenses_screen.dart';
import 'dashboard_screen.dart';

class DashboardShell extends StatefulWidget {
  const DashboardShell({super.key});

  @override
  State<DashboardShell> createState() => _DashboardShellState();
}

class _DashboardShellState extends State<DashboardShell>
    with TickerProviderStateMixin {
  int _selectedIndex = 0;

  List<AnimationController> _tabControllers = [];
  List<Animation<double>> _tabScales = [];

  @override
  void initState() {
    super.initState();
    _tabControllers = List.generate(
      5,
      (_) => AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 200),
      ),
    );
    _tabScales = _tabControllers
        .map((c) => Tween<double>(begin: 1.0, end: 0.88)
            .animate(CurvedAnimation(parent: c, curve: Curves.easeInOut)))
        .toList();
    // Animate the initial selected tab
    _tabControllers[_selectedIndex].forward();
  }

  @override
  void dispose() {
    for (final c in _tabControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onItemTapped(int index) {
    if (index == 2) {
      HapticFeedback.mediumImpact();
      _showAddSheet();
      return;
    }
    if (index == _selectedIndex) return;
    HapticFeedback.selectionClick();
    _tabControllers[_selectedIndex].reverse();
    setState(() => _selectedIndex = index);
    _tabControllers[index].forward();
  }

  Future<void> _showAddSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.6),
      builder: (ctx) => _CreateNewSheet(
        onSharedExpense: () {
          Navigator.pop(ctx);
          _openAddSharedExpenseSheet();
        },
        onPersonalExpense: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const PersonalExpensesScreen()),
          );
        },
        onAddFriend: () {
          Navigator.pop(ctx);
          Future.delayed(const Duration(milliseconds: 200), _openAddFriendSheet);
        },
        onAnalytics: () {
          Navigator.pop(ctx);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
          );
        },
      ),
    );
  }

  Future<void> _openAddSharedExpenseSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Consumer(
        builder: (context, ref, _) => AddSharedExpenseSheet(
          onCreated: () {
            ref.invalidate(expensesListProvider);
            // Optionally switch to shared ledger tab
            setState(() => _selectedIndex = 1);
          },
        ),
      ),
    );
  }

  Future<void> _openAddFriendSheet() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddFriendSheet(
        onCreated: () {
          // Navigate to friends tab so user sees the new friend
          setState(() => _selectedIndex = 4);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Guard: if initState hasn't run yet, show nothing
    if (_tabScales.isEmpty) return const SizedBox.shrink();

    final pages = [
      const DashboardScreen(),
      const ExpensesScreen(),
      const SizedBox.shrink(),
      const DebtsScreen(),
      const FriendsScreen(),
    ];

    final safeIndex = _selectedIndex.clamp(0, pages.length - 1);
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return Scaffold(
      backgroundColor: AppTheme.background,
      extendBody: true,
      body: IndexedStack(
        index: safeIndex,
        children: pages,
      ),
      bottomNavigationBar: _NavBar(
        selectedIndex: safeIndex,
        tabScales: _tabScales,
        onTap: _onItemTapped,
        bottomPadding: bottomPadding,
      ),
    );
  }
}

// ─── Nav Bar ──────────────────────────────────────────────────────────────────
class _NavBar extends StatelessWidget {
  const _NavBar({
    required this.selectedIndex,
    required this.tabScales,
    required this.onTap,
    required this.bottomPadding,
  });

  final int selectedIndex;
  final List<Animation<double>> tabScales;
  final ValueChanged<int> onTap;
  final double bottomPadding;

  static const _items = [
    (Icons.home_rounded, Icons.home_outlined, 'Home'),
    (Icons.receipt_long_rounded, Icons.receipt_long_outlined, 'Shared'),
    (null, null, ''),
    (Icons.account_balance_wallet_rounded, Icons.account_balance_wallet_outlined, 'Debts'),
    (Icons.person_rounded, Icons.person_outline_rounded, 'Profile'),
  ];

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          height: 64 + bottomPadding,
          padding: EdgeInsets.only(
              left: 8, right: 8, bottom: bottomPadding, top: 0),
          decoration: BoxDecoration(
            color: AppTheme.surfaceElevated.withValues(alpha: 0.92),
            border: Border(
              top: BorderSide(
                color: AppTheme.onSurface.withValues(alpha: 0.07),
                width: 0.5,
              ),
            ),
          ),
          child: Row(
            children: List.generate(_items.length, (i) {
              if (i == 2) {
                return Expanded(
                  child: Center(child: _AddFab(onTap: () => onTap(2))),
                );
              }
              final item = _items[i];
              final isSelected = selectedIndex == i;
              return Expanded(
                child: ScaleTransition(
                  scale: tabScales[i],
                  child: _NavItem(
                    activeIcon: item.$1!,
                    inactiveIcon: item.$2!,
                    label: item.$3,
                    isSelected: isSelected,
                    onTap: () => onTap(i),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.activeIcon,
    required this.inactiveIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData activeIcon;
  final IconData inactiveIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 64,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppTheme.secondary.withValues(alpha: 0.14)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                isSelected ? activeIcon : inactiveIcon,
                size: 22,
                color: isSelected ? AppTheme.secondary : AppTheme.muted,
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 220),
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.secondary : AppTheme.muted,
              ),
              child: Text(label),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── FAB in navbar ────────────────────────────────────────────────────────────
class _AddFab extends StatefulWidget {
  const _AddFab({required this.onTap});
  final VoidCallback onTap;

  @override
  State<_AddFab> createState() => _AddFabState();
}

class _AddFabState extends State<_AddFab>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _scale = Tween<double>(begin: 1.0, end: 0.90)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.forward(),
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 52,
          height: 52,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF2DD4BF), Color(0xFF14B8A6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.secondary.withValues(alpha: 0.45),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: const Icon(Icons.add_rounded,
              color: AppTheme.background, size: 28),
        ),
      ),
    );
  }
}

// ─── Create New Sheet ─────────────────────────────────────────────────────────
class _CreateNewSheet extends StatelessWidget {
  const _CreateNewSheet({
    required this.onSharedExpense,
    required this.onPersonalExpense,
    required this.onAddFriend,
    required this.onAnalytics,
  });

  final VoidCallback onSharedExpense;
  final VoidCallback onPersonalExpense;
  final VoidCallback onAddFriend;
  final VoidCallback onAnalytics;

  @override
  Widget build(BuildContext context) {
    final bottomPadding = MediaQuery.of(context).padding.bottom;

    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            color: AppTheme.surfaceContainer.withValues(alpha: 0.97),
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(28)),
            border: Border.all(
                color: AppTheme.onSurface.withValues(alpha: 0.07),
                width: 0.5),
          ),
          padding: EdgeInsets.fromLTRB(24, 14, 24, bottomPadding + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetHandle(),
              const SizedBox(height: 22),

              // Title row
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.add_rounded,
                        color: AppTheme.secondary, size: 20),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Create New',
                          style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.onSurface,
                              letterSpacing: -0.3)),
                      Text('What would you like to add?',
                          style: TextStyle(
                              fontSize: 12,
                              color: AppTheme.muted,
                              fontWeight: FontWeight.w500)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Top row — Shared + Personal
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.receipt_long_rounded,
                      label: 'Shared\nLedger',
                      sublabel: 'Split with roommates',
                      color: AppTheme.secondary,
                      onTap: onSharedExpense,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.receipt_rounded,
                      label: 'Personal\nExpense',
                      sublabel: 'Track for self',
                      color: AppTheme.warning,
                      onTap: onPersonalExpense,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Bottom row — Add Friend + Analytics
              Row(
                children: [
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.person_add_rounded,
                      label: 'Add\nFriend',
                      sublabel: 'Invite a roommate',
                      color: AppTheme.info,
                      onTap: onAddFriend,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _ActionTile(
                      icon: Icons.insights_rounded,
                      label: 'Analytics',
                      sublabel: 'View insights',
                      color: const Color(0xFFA78BFA),
                      onTap: onAnalytics,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatefulWidget {
  const _ActionTile({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onTap;

  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 100));
    _scale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        HapticFeedback.selectionClick();
        _ctrl.forward();
      },
      onTapUp: (_) {
        _ctrl.reverse();
        widget.onTap();
      },
      onTapCancel: () => _ctrl.reverse(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: widget.color.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
                color: widget.color.withValues(alpha: 0.18), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: widget.color.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(widget.icon, color: widget.color, size: 22),
              ),
              const SizedBox(height: 14),
              Text(
                widget.label,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.onSurface,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                widget.sublabel,
                style: const TextStyle(
                  fontSize: 11,
                  color: AppTheme.muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Shared helpers ───────────────────────────────────────────────────────────
class _SheetHandle extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 36,
        height: 4,
        decoration: BoxDecoration(
          color: AppTheme.onSurface.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(2),
        ),
      ),
    );
  }
}

// ─── Inline Add Friend Sheet (used from Create New) ───────────────────────────
class AddFriendSheet extends ConsumerStatefulWidget {
  const AddFriendSheet({super.key, required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<AddFriendSheet> {
  final _controller = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }
    setState(() => _submitting = true);
    try {
      final repository = ref.read(friendsRepositoryProvider);
      await repository.addFriend(name: name);
      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('Roommate added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error));
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 14, 24, bottomInset + 28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetHandle(),
          const SizedBox(height: 22),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.info.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.person_add_rounded,
                    color: AppTheme.info, size: 20),
              ),
              const SizedBox(width: 14),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add Roommate',
                      style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.onSurface)),
                  Text('They\'ll appear in your shared ledger',
                      style: TextStyle(
                          fontSize: 12,
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            enabled: !_submitting,
            autofocus: true,
            style: const TextStyle(
                color: AppTheme.onSurface, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Enter name...',
              hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
              filled: true,
              fillColor: AppTheme.onSurface.withValues(alpha: 0.05),
              prefixIcon: const Icon(Icons.person_outline_rounded,
                  color: AppTheme.muted, size: 20),
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none),
            ),
            onSubmitted: (_) => _submit(),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.info,
                foregroundColor: AppTheme.background,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppTheme.background))
                  : const Text('Add Roommate',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 15)),
            ),
          ),
        ],
      ),
    );
  }
}
