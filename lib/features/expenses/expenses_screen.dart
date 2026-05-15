import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import '../debts/debt_detail_screen.dart';
import '../debts/domain/debts_models.dart';
import '../dashboard/dashboard_shell.dart';
import 'domain/expense_models.dart';
import 'expenses_providers.dart';

String _formatRelativeDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays == 0) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  return '${date.day}/${date.month}/${date.year}';
}

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesListProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      appBar: AppBar(
        title: const Text('Shared Ledger'),
        elevation: 0,
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () => _openAddFriendSheet(context, ref),
            icon: const Icon(Icons.person_add_outlined, size: 22, color: AppTheme.onSurfaceVariant),
            tooltip: 'Add Roommate',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: expensesAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 5),
        error: (error, stackTrace) => AppStatusView(
          icon: Icons.history_edu_outlined,
          title: 'Ledger Unavailable',
          message: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(expensesListProvider),
        ),
        data: (items) => RefreshIndicator(
          color: AppTheme.secondary,
          backgroundColor: AppTheme.surfaceElevated,
          onRefresh: () async {
            ref.invalidate(expensesListProvider);
            await ref.read(expensesListProvider.future);
          },
          child: items.isEmpty ? const _EmptyState() : _TimelineExpenseList(items: items),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: () => _openAddExpenseSheet(context, ref),
            icon: Icons.add_circle_outline,
            label: 'Add Shared Expense',
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _openAddFriendSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => AddFriendSheet(
        onCreated: () {
          ref.invalidate(friendOptionsProvider);
        },
      ),
    );
  }

  Future<void> _openAddExpenseSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        return AddSharedExpenseSheet(
          onCreated: () {
            ref.invalidate(expensesListProvider);
          },
        );
      },
    );
  }
}

class _TimelineExpenseList extends StatelessWidget {
  const _TimelineExpenseList({required this.items});
  final List<ExpenseListItem> items;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final todayItems = <ExpenseListItem>[];
    final yesterdayItems = <ExpenseListItem>[];
    final earlierItems = <ExpenseListItem>[];

    for (final item in items) {
      final itemDate = DateTime(item.createdAt.year, item.createdAt.month, item.createdAt.day);
      if (itemDate == today) {
        todayItems.add(item);
      } else if (itemDate == yesterday) {
        yesterdayItems.add(item);
      } else {
        earlierItems.add(item);
      }
    }

    final totalPending = items.fold<int>(0, (s, e) => s + e.remainingAmount);
    final totalAmount = items.fold<int>(0, (s, e) => s + e.totalAmount);

    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            child: _ExpensesSummaryHero(totalPending: totalPending, count: items.length, totalAmount: totalAmount),
          ),
        ),
        if (todayItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'TODAY'),
          _buildExpenseSliver(todayItems),
        ],
        if (yesterdayItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'YESTERDAY'),
          _buildExpenseSliver(yesterdayItems),
        ],
        if (earlierItems.isNotEmpty) ...[
          _buildSectionHeader(context, 'PREVIOUS ENTRIES'),
          _buildExpenseSliver(earlierItems),
        ],
        const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
      ],
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.secondary.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              title,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: AppTheme.onSurfaceVariant,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                  ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpenseSliver(List<ExpenseListItem> sectionItems) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverList(
        delegate: SliverChildBuilderDelegate(
          (context, index) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _ExpenseCard(item: sectionItems[index]),
          ),
          childCount: sectionItems.length,
        ),
      ),
    );
  }
}

class _ExpensesSummaryHero extends StatelessWidget {
  const _ExpensesSummaryHero({required this.totalPending, required this.count, required this.totalAmount});
  final int totalPending;
  final int count;
  final int totalAmount;

  @override
  Widget build(BuildContext context) {
    final totalRepaid = totalAmount - totalPending;
    final progress = totalAmount > 0 ? totalRepaid / totalAmount : 0.0;
    final pct = (progress * 100).toInt();

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('SHARED OUTSTANDING', style: TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2)),
                const SizedBox(height: 12),
                Text('₹$totalPending', style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.secondary)),
                const SizedBox(height: 16),
                Text('$count active ledger entries in shared vault.', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressRing(
                progress: progress,
                size: 80,
                strokeWidth: 6,
                child: Text(
                  '$pct%',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w900, color: AppTheme.secondary),
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'repaid',
                style: TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  const _ExpenseCard({required this.item});
  final ExpenseListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progress = item.totalAmount > 0 ? item.repaidAmount / item.totalAmount : 0.0;
    final isSettled = item.remainingAmount == 0;

    return GlassCard(
      onTap: () {
        final debtRecord = PendingDebtRecord(
          debtId: item.id,
          friendId: item.friendId,
          friendName: item.friendName,
          note: item.note,
          totalAmount: item.totalAmount,
          repaidAmount: item.repaidAmount,
          createdAt: item.createdAt,
        );
        Navigator.push(context, MaterialPageRoute(builder: (context) => DebtDetailScreen(debt: debtRecord)));
      },
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
                ),
                child: Center(
                  child: Text(
                    item.friendName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800, fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.note, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 4),
                    Text('${item.friendName} • ${_formatRelativeDate(item.createdAt)}', style: const TextStyle(color: AppTheme.muted, fontSize: 11)),
                  ],
                ),
              ),
              ProgressRing(
                progress: progress,
                size: 40,
                strokeWidth: 3.5,
                child: Text('${(progress * 100).toInt()}%', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.secondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _MetricItem(label: 'TOTAL', value: '₹${item.totalAmount}'),
              _MetricItem(label: 'PAID', value: '₹${item.repaidAmount}', color: AppTheme.secondary),
              _MetricItem(label: 'REMAINING', value: '₹${item.remainingAmount}', color: isSettled ? AppTheme.secondary : AppTheme.onSurfaceVariant),
            ],
          ),
        ],
      ),
    );
  }
}

class _MetricItem extends StatelessWidget {
  const _MetricItem({required this.label, required this.value, this.color});
  final String label;
  final String value;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        Text(value, style: TextStyle(color: color ?? AppTheme.onSurface, fontSize: 14, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _EmptyState extends ConsumerWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AppStatusView(
      icon: Icons.receipt_long_outlined,
      title: 'Shared ledger empty',
      message: 'Add shared expenses to track splits with roommates.',
      actionLabel: 'Add Roommate',
      onAction: () {
        // Find the ExpensesScreen state and call _openAddFriendSheet
        // Or just implement it here
        showModalBottomSheet<void>(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (ctx) => AddFriendSheet(
            onCreated: () {
              ref.invalidate(friendOptionsProvider);
            },
          ),
        );
      },
    );
  }
}

// ─── Add Shared Expense Sheet ────────────────────────────────────────────────

class AddSharedExpenseSheet extends ConsumerStatefulWidget {
  const AddSharedExpenseSheet({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<AddSharedExpenseSheet> createState() => _AddSharedExpenseSheetState();
}

class _AddSharedExpenseSheetState extends ConsumerState<AddSharedExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  bool _submitting = false;

  // Split mode: 'equal', 'custom', 'percentage'
  String _splitMode = 'equal';

  // Selected friend IDs for equal split
  final Set<int> _selectedFriendIds = {};

  // Custom split: friendId -> amount controller
  final Map<int, TextEditingController> _customAmountControllers = {};

  // Percentage split: friendId -> percentage controller
  final Map<int, TextEditingController> _percentageControllers = {};

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    for (final c in _customAmountControllers.values) {
      c.dispose();
    }
    for (final c in _percentageControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleFriend(int friendId) {
    setState(() {
      if (_selectedFriendIds.contains(friendId)) {
        _selectedFriendIds.remove(friendId);
        _customAmountControllers.remove(friendId)?.dispose();
        _percentageControllers.remove(friendId)?.dispose();
      } else {
        _selectedFriendIds.add(friendId);
        _customAmountControllers[friendId] = TextEditingController();
        _percentageControllers[friendId] = TextEditingController();
      }
    });
  }

  Future<void> _submit(List<FriendOption> friends) async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedFriendIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select at least one friend to split with')),
      );
      return;
    }

    final totalAmount = int.tryParse(_amountController.text.trim()) ?? 0;
    if (totalAmount <= 0) return;

    setState(() => _submitting = true);
    try {
      final repository = ref.read(expensesRepositoryProvider);
      final participantIds = _selectedFriendIds.toList();

      if (_splitMode == 'equal') {
        await repository.addSplitExpense(
          AddSplitExpenseInput(
            note: _noteController.text.trim(),
            totalAmount: totalAmount,
            participantIds: participantIds,
            splitWithSelf: true,
          ),
        );
      } else if (_splitMode == 'custom') {
        final allocations = participantIds.map((id) {
          final amount = int.tryParse(_customAmountControllers[id]?.text.trim() ?? '') ?? 0;
          return SplitAllocation(friendId: id, amount: amount);
        }).toList();

        final allocated = allocations.fold<int>(0, (s, a) => s + a.amount);
        if (allocated != totalAmount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Amounts must add up to ₹$totalAmount (currently ₹$allocated)')),
          );
          setState(() => _submitting = false);
          return;
        }

        await repository.addCustomSplitExpense(
          AddCustomSplitExpenseInput(
            note: _noteController.text.trim(),
            totalAmount: totalAmount,
            allocations: allocations,
          ),
        );
      } else if (_splitMode == 'percentage') {
        final allocations = participantIds.map((id) {
          final pct = int.tryParse(_percentageControllers[id]?.text.trim() ?? '') ?? 0;
          return PercentageAllocation(friendId: id, percentage: pct);
        }).toList();

        final totalPct = allocations.fold<int>(0, (s, a) => s + a.percentage);
        if (totalPct != 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Percentages must add up to 100% (currently $totalPct%)')),
          );
          setState(() => _submitting = false);
          return;
        }

        await repository.addPercentageSplitExpense(
          AddPercentageSplitExpenseInput(
            note: _noteController.text.trim(),
            totalAmount: totalAmount,
            allocations: allocations,
          ),
        );
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final friendsAsync = ref.watch(friendOptionsProvider);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
        border: Border.all(color: AppTheme.onSurface.withValues(alpha: 0.08)),
      ),
      padding: EdgeInsets.fromLTRB(24, 20, 24, 24 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Add Shared Expense',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),

              // Note field
              TextFormField(
                controller: _noteController,
                decoration: const InputDecoration(labelText: 'Description / Note', filled: true),
                validator: (v) => (v == null || v.isEmpty) ? 'Provide a description' : null,
              ),
              const SizedBox(height: 14),

              // Amount field
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Total Amount (₹)', filled: true),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 20),

              // Split mode selector
              const Text(
                'Split Method',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _SplitModeChip(
                    label: 'Equal',
                    icon: Icons.balance_outlined,
                    selected: _splitMode == 'equal',
                    onTap: () => setState(() => _splitMode = 'equal'),
                  ),
                  const SizedBox(width: 8),
                  _SplitModeChip(
                    label: 'Custom',
                    icon: Icons.tune_outlined,
                    selected: _splitMode == 'custom',
                    onTap: () => setState(() => _splitMode = 'custom'),
                  ),
                  const SizedBox(width: 8),
                  _SplitModeChip(
                    label: 'Percent',
                    icon: Icons.percent_outlined,
                    selected: _splitMode == 'percentage',
                    onTap: () => setState(() => _splitMode = 'percentage'),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Friends list
              const Text(
                'Split With',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.onSurfaceVariant),
              ),
              const SizedBox(height: 10),
              friendsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text('Could not load friends: $e',
                    style: const TextStyle(color: AppTheme.error)),
                data: (friends) {
                  if (friends.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                      ),
                      child: const Row(
                        children: [
                          Icon(Icons.person_add_outlined, color: AppTheme.muted, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'No friends yet — add friends first',
                            style: TextStyle(color: AppTheme.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    );
                  }
                  return Column(
                    children: friends.map((friend) {
                      final isSelected = _selectedFriendIds.contains(friend.id);
                      return Column(
                        children: [
                          GestureDetector(
                            onTap: () => _toggleFriend(friend.id),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.secondary.withValues(alpha: 0.1)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.secondary
                                      : AppTheme.onSurface.withValues(alpha: 0.08),
                                  width: isSelected ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 36,
                                    height: 36,
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? AppTheme.secondary.withValues(alpha: 0.2)
                                          : AppTheme.surfaceContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        friend.name.substring(0, 1).toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected ? AppTheme.secondary : AppTheme.onSurfaceVariant,
                                          fontWeight: FontWeight.w800,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      friend.name,
                                      style: TextStyle(
                                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                                        color: isSelected ? AppTheme.onSurface : AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(Icons.check_circle_rounded,
                                        color: AppTheme.secondary, size: 20),
                                ],
                              ),
                            ),
                          ),
                          // Custom/Percentage input per friend
                          if (isSelected && _splitMode == 'custom') ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextFormField(
                                controller: _customAmountControllers[friend.id],
                                decoration: InputDecoration(
                                  labelText: '${friend.name}\'s share (₹)',
                                  filled: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                          if (isSelected && _splitMode == 'percentage') ...[
                            const SizedBox(height: 8),
                            Padding(
                              padding: const EdgeInsets.only(left: 8),
                              child: TextFormField(
                                controller: _percentageControllers[friend.id],
                                decoration: InputDecoration(
                                  labelText: '${friend.name}\'s share (%)',
                                  filled: true,
                                ),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                          ],
                          const SizedBox(height: 8),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: () {
                    final friends = ref.read(friendOptionsProvider).valueOrNull ?? [];
                    _submit(friends);
                  },
                  icon: Icons.add_circle_outline,
                  label: _submitting ? 'Saving...' : 'Add Shared Expense',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SplitModeChip extends StatelessWidget {
  const _SplitModeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? AppTheme.secondary.withValues(alpha: 0.15) : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? AppTheme.secondary : AppTheme.onSurface.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: selected ? AppTheme.secondary : AppTheme.onSurfaceVariant),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                color: selected ? AppTheme.secondary : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
