import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/app_components.dart';
import '../domain/expense_models.dart';
import '../expenses_providers.dart';

class AddSharedExpenseSheet extends ConsumerStatefulWidget {
  const AddSharedExpenseSheet({super.key, required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<AddSharedExpenseSheet> createState() =>
      _AddSharedExpenseSheetState();
}

class _AddSharedExpenseSheetState extends ConsumerState<AddSharedExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();
  bool _submitting = false;

  // Categories
  final List<Map<String, dynamic>> _categories = [
    {'name': 'Groceries', 'icon': '🛒'},
    {'name': 'Vegetables', 'icon': '🥦'},
    {'name': 'Auto / Fuel', 'icon': '🚗'},
    {'name': 'Shopping', 'icon': '🛍️'},
    {'name': 'Bills', 'icon': '💡'},
    {'name': 'Food', 'icon': '🍔'},
    {'name': 'Entertainment', 'icon': '🎬'},
    {'name': 'Medical', 'icon': '💊'},
    {'name': 'Transport', 'icon': '🚕'},
    {'name': 'Education', 'icon': '📚'},
    {'name': 'Rent', 'icon': '🏠'},
    {'name': 'Recharge', 'icon': '📱'},
    {'name': 'Travel', 'icon': '✈️'},
    {'name': 'Others', 'icon': '🏷️'},
  ];

  String _selectedCategory = 'Groceries';

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
        const SnackBar(
          content: Text('Select at least one friend to split with'),
        ),
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
            category: _selectedCategory,
            totalAmount: totalAmount,
            participantIds: participantIds,
            splitWithSelf: true,
          ),
        );
      } else if (_splitMode == 'custom') {
        final allocations = participantIds.map((id) {
          final amount =
              int.tryParse(_customAmountControllers[id]?.text.trim() ?? '') ??
              0;
          return SplitAllocation(friendId: id, amount: amount);
        }).toList();

        final allocated = allocations.fold<int>(0, (s, a) => s + a.amount);
        if (allocated != totalAmount) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Amounts must add up to ₹$totalAmount (currently ₹$allocated)',
              ),
            ),
          );
          setState(() => _submitting = false);
          return;
        }

        await repository.addCustomSplitExpense(
          AddCustomSplitExpenseInput(
            note: _noteController.text.trim(),
            category: _selectedCategory,
            totalAmount: totalAmount,
            allocations: allocations,
          ),
        );
      } else if (_splitMode == 'percentage') {
        final allocations = participantIds.map((id) {
          final pct =
              int.tryParse(_percentageControllers[id]?.text.trim() ?? '') ?? 0;
          return PercentageAllocation(friendId: id, percentage: pct);
        }).toList();

        final totalPct = allocations.fold<int>(0, (s, a) => s + a.percentage);
        if (totalPct != 100) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Percentages must add up to 100% (currently $totalPct%)',
              ),
            ),
          );
          setState(() => _submitting = false);
          return;
        }

        await repository.addPercentageSplitExpense(
          AddPercentageSplitExpenseInput(
            note: _noteController.text.trim(),
            category: _selectedCategory,
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
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
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.radiusLarge),
        ),
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
              const SizedBox(height: 24),

              // 1. Category Section
              const Text(
                'Expense Category *',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _categories.map((cat) {
                  final isSelected = _selectedCategory == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppTheme.secondary.withValues(alpha: 0.15)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? AppTheme.secondary
                              : AppTheme.onSurface.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: AppTheme.secondary.withValues(alpha: 0.2),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                )
                              ]
                            : null,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            cat['icon'],
                            style: const TextStyle(fontSize: 16),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'],
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight:
                                  isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? AppTheme.secondary
                                  : AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // 2. Amount Section
              TextFormField(
                controller: _amountController,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.secondary,
                ),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  hintText: '0',
                  filled: true,
                  prefixIcon: Icon(Icons.currency_rupee, color: AppTheme.secondary),
                ),
                keyboardType: TextInputType.number,
                validator: (v) {
                  final n = int.tryParse(v ?? '');
                  if (n == null || n <= 0) return 'Enter a valid amount';
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // 3. Split Method Section
              const Text(
                'Split Method',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
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
              const SizedBox(height: 24),

              // 4. Members Section
              const Text(
                'Split With',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 12),
              friendsAsync.when(
                loading: () => const Center(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: CircularProgressIndicator(),
                  ),
                ),
                error: (e, _) => Text(
                  'Could not load friends: $e',
                  style: const TextStyle(color: AppTheme.error),
                ),
                data: (friends) {
                  if (friends.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(
                          AppTheme.radiusMedium,
                        ),
                      ),
                      child: const Row(
                        children: [
                          Icon(
                            Icons.person_add_outlined,
                            color: AppTheme.muted,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'No friends yet — add friends first',
                            style: TextStyle(
                              color: AppTheme.muted,
                              fontSize: 13,
                            ),
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
                              padding: const EdgeInsets.symmetric(
                                horizontal: 14,
                                vertical: 12,
                              ),
                              decoration: BoxDecoration(
                                color: isSelected
                                    ? AppTheme.secondary.withValues(alpha: 0.1)
                                    : AppTheme.surfaceElevated,
                                borderRadius: BorderRadius.circular(
                                  AppTheme.radiusMedium,
                                ),
                                border: Border.all(
                                  color: isSelected
                                      ? AppTheme.secondary
                                      : AppTheme.onSurface.withValues(
                                          alpha: 0.08,
                                        ),
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
                                          ? AppTheme.secondary.withValues(
                                              alpha: 0.2,
                                            )
                                          : AppTheme.surfaceContainer,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        friend.name
                                            .substring(0, 1)
                                            .toUpperCase(),
                                        style: TextStyle(
                                          color: isSelected
                                              ? AppTheme.secondary
                                              : AppTheme.onSurfaceVariant,
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
                                        fontWeight: isSelected
                                            ? FontWeight.w700
                                            : FontWeight.w500,
                                        color: isSelected
                                            ? AppTheme.onSurface
                                            : AppTheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  if (isSelected)
                                    const Icon(
                                      Icons.check_circle_rounded,
                                      color: AppTheme.secondary,
                                      size: 20,
                                    ),
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
              const SizedBox(height: 24),

              // 5. Optional Note Section
              const Text(
                'Add Note (Optional)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _noteController,
                decoration: InputDecoration(
                  hintText: 'Example: Bought vegetables for dinner',
                  hintStyle: TextStyle(
                    color: AppTheme.onSurface.withValues(alpha: 0.3),
                    fontSize: 13,
                  ),
                  filled: true,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 32),

              // CTA Button
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: () {
                    final friends =
                        ref.read(friendOptionsProvider).valueOrNull ?? [];
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected
              ? AppTheme.secondary.withValues(alpha: 0.15)
              : AppTheme.surfaceElevated,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? AppTheme.secondary
                : AppTheme.onSurface.withValues(alpha: 0.08),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 16,
              color: selected ? AppTheme.secondary : AppTheme.onSurfaceVariant,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected
                    ? AppTheme.secondary
                    : AppTheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
