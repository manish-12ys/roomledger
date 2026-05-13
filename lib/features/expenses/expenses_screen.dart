import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../dashboard/dashboard_providers.dart';
import '../debts/debt_detail_screen.dart';
import '../debts/domain/debts_models.dart';
import 'domain/expense_models.dart';
import 'expenses_providers.dart';

enum _SplitMode {
  single,
  equal,
  custom,
  percentage,
  quantity,
}

class ExpensesScreen extends ConsumerWidget {
  const ExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expensesAsync = ref.watch(expensesListProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Expenses')),
      body: expensesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _ErrorState(
          message: 'Could not load expenses.',
          details: error.toString(),
          onRetry: () => ref.invalidate(expensesListProvider),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(expensesListProvider);
            await ref.read(expensesListProvider.future);
          },
          child: items.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: items.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return _ExpenseCard(item: item);
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddExpenseSheet(context, ref),
        tooltip: 'Add expense',
        icon: const Icon(Icons.add),
        label: const Text('Add Expense'),
      ),
    );
  }

  Future<void> _openAddExpenseSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _AddExpenseSheet(
          onCreated: () {
            ref.invalidate(expensesListProvider);
            ref.invalidate(dashboardOverviewProvider);
          },
        );
      },
    );
  }
}

class _ExpenseCard extends ConsumerWidget {
  const _ExpenseCard({required this.item});

  final ExpenseListItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;

    return AppCard(
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
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => DebtDetailScreen(debt: debtRecord),
          ),
        );
      },
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          CircleAvatar(
            backgroundColor: AppTheme.secondary.withValues(alpha: 0.10),
            child: Text(
              item.friendName.substring(0, 1),
              style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w800),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.note, style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  '${item.friendName} · Paid ${_formatCurrency(item.repaidAmount)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: () => _openEditExpenseSheet(context, ref),
                child: const Text('Edit'),
              ),
              PopupMenuItem(
                onTap: () => _showDeleteConfirmation(context, ref),
                child: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _formatCurrency(item.totalAmount),
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                Text(
                  'Due ${_formatCurrency(item.remainingAmount)}',
                  style: TextStyle(color: colorScheme.primary, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openEditExpenseSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _EditExpenseSheet(
          item: item,
          onUpdated: () {
            ref.invalidate(expensesListProvider);
            ref.invalidate(dashboardOverviewProvider);
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove "${item.note}" from ${item.friendName}?'),
            if (item.remainingAmount < item.totalAmount) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_outlined,
                      color: Theme.of(context).colorScheme.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '₹${item.repaidAmount} already settled.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ]
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              'Delete',
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      try {
        final repository = ref.read(expensesRepositoryProvider);
        final canDelete = await repository.canDeleteExpense(debtId: item.id);

        if (!context.mounted) return;

        if (!canDelete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Cannot delete: expense has settled amounts'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }

        await repository.deleteExpense(debtId: item.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted'),
              duration: Duration(seconds: 2),
            ),
          );

          ref.invalidate(expensesListProvider);
          ref.invalidate(dashboardOverviewProvider);
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
        }
      }
    }
  }
}

class _AddExpenseSheet extends ConsumerStatefulWidget {
  const _AddExpenseSheet({required this.onCreated});

  final VoidCallback onCreated;

  @override
  ConsumerState<_AddExpenseSheet> createState() => _AddExpenseSheetState();
}

class _AddExpenseSheetState extends ConsumerState<_AddExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  final _noteController = TextEditingController();
  final _amountController = TextEditingController();

  int? _selectedFriendId;
  final Set<int> _selectedParticipantIds = {};
  final Map<int, TextEditingController> _customAmountControllers = {};
  final Map<int, TextEditingController> _percentageControllers = {};
  final Map<int, TextEditingController> _quantityControllers = {};
  _SplitMode _splitMode = _SplitMode.single;
  bool _submitting = false;
  bool _includeSelf = false;
  DateTime _selectedDate = DateTime.now();

  @override
  void dispose() {
    for (final controller in _customAmountControllers.values) {
      controller.dispose();
    }
    for (final controller in _percentageControllers.values) {
      controller.dispose();
    }
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendOptionsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Shared Expense',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: [
                  FilterChip(
                    label: const Text('Single Person'),
                    selected: _splitMode == _SplitMode.single,
                    onSelected: _submitting
                        ? null
                        : (selected) {
                            setState(() {
                              _splitMode = _SplitMode.single;
                              _selectedFriendId = null;
                              _selectedParticipantIds.clear();
                              _clearCustomAllocations();
                              _clearPercentageAllocations();
                              _clearQuantityAllocations();
                            });
                          },
                  ),
                  FilterChip(
                    label: const Text('Equal Split'),
                    selected: _splitMode == _SplitMode.equal,
                    onSelected: _submitting
                        ? null
                        : (selected) {
                            setState(() {
                              _splitMode = _SplitMode.equal;
                              _selectedFriendId = null;
                              _clearCustomAllocations();
                              _clearPercentageAllocations();
                              _clearQuantityAllocations();
                            });
                          },
                  ),
                  FilterChip(
                    label: const Text('Custom Split'),
                    selected: _splitMode == _SplitMode.custom,
                    onSelected: _submitting
                        ? null
                        : (selected) {
                            setState(() {
                              _splitMode = _SplitMode.custom;
                              _selectedFriendId = null;
                              _clearPercentageAllocations();
                              _clearQuantityAllocations();
                              _syncCustomAllocations();
                            });
                          },
                  ),
                  FilterChip(
                    label: const Text('Percentage Split'),
                    selected: _splitMode == _SplitMode.percentage,
                    onSelected: _submitting
                        ? null
                        : (selected) {
                            setState(() {
                              _splitMode = _SplitMode.percentage;
                              _selectedFriendId = null;
                              _clearCustomAllocations();
                              _clearQuantityAllocations();
                              _syncPercentageAllocations();
                            });
                          },
                  ),
                  FilterChip(
                    label: const Text('Quantity Split'),
                    selected: _splitMode == _SplitMode.quantity,
                    onSelected: _submitting
                        ? null
                        : (selected) {
                            setState(() {
                              _splitMode = _SplitMode.quantity;
                              _selectedFriendId = null;
                              _clearCustomAllocations();
                              _clearPercentageAllocations();
                              _syncQuantityAllocations();
                            });
                          },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              friendsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Text('Could not load friends: $error'),
                data: (friends) {
                  if (friends.isEmpty) {
                    return const Text('No roommates found. Add friends first.');
                  }

                  final selectedFriends = friends
                      .where((friend) => _selectedParticipantIds.contains(friend.id))
                      .toList();

                  if (_splitMode == _SplitMode.equal) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Participants (${_selectedParticipantIds.length})',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            FilterChip(
                              label: const Text('Me (You)'),
                              selected: _includeSelf,
                              onSelected: _submitting
                                  ? null
                                  : (selected) {
                                      setState(() {
                                        _includeSelf = selected;
                                      });
                                    },
                            ),
                            ...friends.map(
                              (friend) => FilterChip(
                                label: Text(friend.name),
                                selected: _selectedParticipantIds.contains(friend.id),
                                onSelected: _submitting
                                    ? null
                                    : (selected) {
                                        setState(() {
                                          if (selected) {
                                            _selectedParticipantIds.add(friend.id);
                                          } else {
                                            _selectedParticipantIds.remove(friend.id);
                                          }
                                        });
                                      },
                              ),
                            ),
                          ],
                        ),
                        if (_selectedParticipantIds.isEmpty && !_includeSelf)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Select at least one other person or include yourself',
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                            ),
                          ),
                      ],
                    );
                  }

                  if (_splitMode == _SplitMode.custom) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Participants (${_selectedParticipantIds.length})',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: friends
                              .map(
                                (friend) => FilterChip(
                                  label: Text(friend.name),
                                  selected: _selectedParticipantIds.contains(friend.id),
                                  onSelected: _submitting
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedParticipantIds.add(friend.id);
                                            } else {
                                              _selectedParticipantIds.remove(friend.id);
                                            }
                                            _syncCustomAllocations();
                                          });
                                        },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedParticipantIds.length < 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Select at least 2 people',
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                            ),
                          ),
                        ...selectedFriends.map(
                          (friend) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _customAmountControllers[friend.id],
                              enabled: !_submitting,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '${friend.name} amount (INR)',
                                prefixText: '₹ ',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final amount = int.tryParse((value ?? '').trim());
                                if (amount == null || amount <= 0) {
                                  return 'Enter a valid amount';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (_splitMode == _SplitMode.percentage) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Participants (${_selectedParticipantIds.length})',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: friends
                              .map(
                                (friend) => FilterChip(
                                  label: Text(friend.name),
                                  selected: _selectedParticipantIds.contains(friend.id),
                                  onSelected: _submitting
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedParticipantIds.add(friend.id);
                                            } else {
                                              _selectedParticipantIds.remove(friend.id);
                                            }
                                            _syncPercentageAllocations();
                                          });
                                        },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedParticipantIds.length < 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Select at least 2 people',
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                            ),
                          ),
                        ...selectedFriends.map(
                          (friend) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _percentageControllers[friend.id],
                              enabled: !_submitting,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '${friend.name} percentage (%)',
                                suffixText: '%',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final percentage = int.tryParse((value ?? '').trim());
                                if (percentage == null || percentage <= 0) {
                                  return 'Enter a valid percentage';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  if (_splitMode == _SplitMode.quantity) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Select Participants (${_selectedParticipantIds.length})',
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: friends
                              .map(
                                (friend) => FilterChip(
                                  label: Text(friend.name),
                                  selected: _selectedParticipantIds.contains(friend.id),
                                  onSelected: _submitting
                                      ? null
                                      : (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedParticipantIds.add(friend.id);
                                            } else {
                                              _selectedParticipantIds.remove(friend.id);
                                            }
                                            _syncQuantityAllocations();
                                          });
                                        },
                                ),
                              )
                              .toList(),
                        ),
                        const SizedBox(height: 12),
                        if (_selectedParticipantIds.length < 2)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              'Select at least 2 people',
                              style: TextStyle(color: Theme.of(context).colorScheme.error, fontSize: 12),
                            ),
                          ),
                        ...selectedFriends.map(
                          (friend) => Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: TextFormField(
                              controller: _quantityControllers[friend.id],
                              enabled: !_submitting,
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                labelText: '${friend.name} quantity',
                                suffixText: 'units',
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (value) {
                                final quantity = int.tryParse((value ?? '').trim());
                                if (quantity == null || quantity <= 0) {
                                  return 'Enter a valid quantity';
                                }
                                return null;
                              },
                            ),
                          ),
                        ),
                      ],
                    );
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedFriendId,
                    decoration: const InputDecoration(labelText: 'Friend'),
                    items: friends
                        .map(
                          (friend) => DropdownMenuItem<int>(
                            value: friend.id,
                            child: Text(friend.name),
                          ),
                        )
                        .toList(),
                    onChanged: _submitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedFriendId = value;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Select a friend';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Expense Note',
                  hintText: 'Groceries, rent split, internet bill...',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Enter a note';
                  }
                  if (text.length < 3) {
                    return 'Use at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Amount (INR)',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                onChanged: (_) => setState(() {}),
                validator: (value) {
                  final amount = int.tryParse((value ?? '').trim());
                  if (amount == null) {
                    return 'Enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              if (_splitMode == _SplitMode.equal && _selectedParticipantIds.isNotEmpty && _amountController.text.isNotEmpty)
                _buildEqualSplitPreview(),
              if (_splitMode == _SplitMode.custom && _selectedParticipantIds.isNotEmpty && _amountController.text.isNotEmpty)
                _buildCustomSplitPreview(friendsAsync),
              if (_splitMode == _SplitMode.percentage && _selectedParticipantIds.isNotEmpty && _amountController.text.isNotEmpty)
                _buildPercentageSplitPreview(friendsAsync),
              if (_splitMode == _SplitMode.quantity && _selectedParticipantIds.isNotEmpty && _amountController.text.isNotEmpty)
                _buildQuantitySplitPreview(friendsAsync),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaction Date', style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'Save expense',
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save Expense'),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEqualSplitPreview() {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return const SizedBox.shrink();

    final totalParticipants = _selectedParticipantIds.length + (_includeSelf ? 1 : 0);
    if (totalParticipants == 0) return const SizedBox.shrink();

    final sharePerPerson = amount ~/ totalParticipants;
    final remainder = amount % totalParticipants;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Split Preview',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              '₹$amount ÷ $totalParticipants = ₹$sharePerPerson${remainder > 0 ? ' + ₹$remainder rem' : ''}',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            if (remainder > 0) ...[
              const SizedBox(height: 4),
              Text(
                'First $remainder person(s) pay ₹${sharePerPerson + 1}, rest pay ₹$sharePerPerson',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
              ),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildCustomSplitPreview(AsyncValue<List<FriendOption>> friendsAsync) {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return const SizedBox.shrink();

    final selectedFriends = friendsAsync.valueOrNull
            ?.where((friend) => _selectedParticipantIds.contains(friend.id))
            .toList() ??
        const <FriendOption>[];

    if (selectedFriends.isEmpty) {
      return const SizedBox.shrink();
    }

    final allocations = selectedFriends
        .map(
          (friend) => MapEntry(
            friend,
            int.tryParse(_customAmountControllers[friend.id]?.text.trim() ?? ''),
          ),
        )
        .toList();

    final allocatedTotal = allocations.fold<int>(0, (sum, entry) => sum + (entry.value ?? 0));
    final remainder = amount - allocatedTotal;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Custom Split Preview',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Allocated ₹$allocatedTotal of ₹$amount',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...allocations.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${entry.key.name}: ₹${entry.value ?? 0}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            ),
            if (remainder != 0) ...[
              const SizedBox(height: 4),
              Text(
                remainder > 0
                    ? '₹$remainder still needs to be allocated'
                    : 'Allocated amount exceeds total by ₹${remainder.abs()}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _clearCustomAllocations() {
    for (final controller in _customAmountControllers.values) {
      controller.dispose();
    }
    _customAmountControllers.clear();
  }

  void _clearPercentageAllocations() {
    for (final controller in _percentageControllers.values) {
      controller.dispose();
    }
    _percentageControllers.clear();
  }

  void _clearQuantityAllocations() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _quantityControllers.clear();
  }

  void _syncCustomAllocations() {
    final selectedIds = _selectedParticipantIds.toList();
    final toRemove = _customAmountControllers.keys
        .where((id) => !selectedIds.contains(id))
        .toList();

    for (final id in toRemove) {
      _customAmountControllers.remove(id)?.dispose();
    }

    for (final id in selectedIds) {
      _customAmountControllers.putIfAbsent(id, () => TextEditingController());
    }
  }

  void _syncPercentageAllocations() {
    final selectedIds = _selectedParticipantIds.toList();
    final toRemove = _percentageControllers.keys
        .where((id) => !selectedIds.contains(id))
        .toList();

    for (final id in toRemove) {
      _percentageControllers.remove(id)?.dispose();
    }

    for (final id in selectedIds) {
      _percentageControllers.putIfAbsent(id, () => TextEditingController());
    }
  }

  void _syncQuantityAllocations() {
    final selectedIds = _selectedParticipantIds.toList();
    final toRemove = _quantityControllers.keys.where((id) => !selectedIds.contains(id)).toList();

    for (final id in toRemove) {
      _quantityControllers.remove(id)?.dispose();
    }

    for (final id in selectedIds) {
      _quantityControllers.putIfAbsent(id, () => TextEditingController());
    }
  }

  Widget _buildPercentageSplitPreview(AsyncValue<List<FriendOption>> friendsAsync) {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return const SizedBox.shrink();

    final selectedFriends = friendsAsync.valueOrNull
            ?.where((friend) => _selectedParticipantIds.contains(friend.id))
            .toList() ??
        const <FriendOption>[];

    if (selectedFriends.isEmpty) {
      return const SizedBox.shrink();
    }

    final allocations = selectedFriends
        .map(
          (friend) => MapEntry(
            friend,
            int.tryParse(_percentageControllers[friend.id]?.text.trim() ?? ''),
          ),
        )
        .toList();

    final totalPercentage = allocations.fold<int>(0, (sum, entry) => sum + (entry.value ?? 0));
    final calculatedShares = <int>[];

    for (final entry in allocations) {
      final percentage = entry.value ?? 0;
      calculatedShares.add((amount * percentage / 100).floor());
    }

    final baseTotal = calculatedShares.fold<int>(0, (sum, share) => sum + share);
    final remainder = amount - baseTotal;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Percentage Split Preview',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Total selected: $totalPercentage%',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...allocations.asMap().entries.map(
              (indexedEntry) {
                final index = indexedEntry.key;
                final entry = indexedEntry.value;
                final percentage = entry.value ?? 0;
                final share = calculatedShares[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entry.key.name}: $percentage% = ₹$share',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
            if (totalPercentage != 100 || remainder != 0) ...[
              const SizedBox(height: 4),
              Text(
                totalPercentage != 100
                    ? 'Percentages must total 100%'
                    : 'Rounding adjusted across shares to match ₹$amount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildQuantitySplitPreview(AsyncValue<List<FriendOption>> friendsAsync) {
    final amount = int.tryParse(_amountController.text.trim());
    if (amount == null || amount <= 0) return const SizedBox.shrink();

    final selectedFriends = friendsAsync.valueOrNull
            ?.where((friend) => _selectedParticipantIds.contains(friend.id))
            .toList() ??
        const <FriendOption>[];

    if (selectedFriends.isEmpty) {
      return const SizedBox.shrink();
    }

    final allocations = selectedFriends
        .map(
          (friend) => MapEntry(
            friend,
            int.tryParse(_quantityControllers[friend.id]?.text.trim() ?? ''),
          ),
        )
        .toList();

    final totalQuantity = allocations.fold<int>(0, (sum, entry) => sum + (entry.value ?? 0));
    final calculatedShares = <int>[];

    for (final entry in allocations) {
      final quantity = entry.value ?? 0;
      calculatedShares.add((amount * quantity / (totalQuantity == 0 ? 1 : totalQuantity)).floor());
    }

    final baseTotal = calculatedShares.fold<int>(0, (sum, share) => sum + share);
    final remainder = amount - baseTotal;

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quantity Split Preview',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              'Total quantity: $totalQuantity',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            ...allocations.asMap().entries.map(
              (indexedEntry) {
                final index = indexedEntry.key;
                final entry = indexedEntry.value;
                final quantity = entry.value ?? 0;
                final share = calculatedShares[index];

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Text(
                    '${entry.key.name}: $quantity units = ₹$share',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                );
              },
            ),
            if (totalQuantity <= 0 || remainder != 0) ...[
              const SizedBox(height: 4),
              Text(
                totalQuantity <= 0
                    ? 'Enter quantities for each participant'
                    : 'Rounding adjusted across shares to match ₹$amount',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.error,
                    ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_splitMode == _SplitMode.equal || _splitMode == _SplitMode.custom || _splitMode == _SplitMode.percentage || _splitMode == _SplitMode.quantity) {
      if (_selectedParticipantIds.length < 2) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select at least 2 people for split')),
        );
        return;
      }
    } else {
      if (_selectedFriendId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Select a friend')),
        );
        return;
      }
    }

    setState(() {
      _submitting = true;
    });

    try {
      final repository = ref.read(expensesRepositoryProvider);
      final note = _noteController.text.trim();
      final amount = int.parse(_amountController.text.trim());
      final friends = await ref.read(friendOptionsProvider.future);

      if (_splitMode == _SplitMode.equal) {
        if (_selectedParticipantIds.isEmpty && !_includeSelf) return;

        final input = AddSplitExpenseInput(
          note: _noteController.text.trim(),
          totalAmount: int.parse(_amountController.text.trim()),
          participantIds: _selectedParticipantIds.toList(),
          splitWithSelf: _includeSelf,
          date: _selectedDate,
        );
        await repository.addSplitExpense(input);
      } else if (_splitMode == _SplitMode.custom) {
        final selectedFriends = friends.where((friend) => _selectedParticipantIds.contains(friend.id)).toList();
        final allocations = selectedFriends.map((friend) {
          final controllerValue = _customAmountControllers[friend.id]?.text.trim() ?? '';
          final allocationAmount = int.tryParse(controllerValue);

          if (allocationAmount == null || allocationAmount <= 0) {
            throw ArgumentError('Enter a valid amount for ${friend.name}');
          }

          return SplitAllocation(friendId: friend.id, amount: allocationAmount);
        }).toList();

        final input = AddCustomSplitExpenseInput(
          note: note,
          totalAmount: amount,
          allocations: allocations,
          date: _selectedDate,
        );

        if (!input.isValid()) {
          throw ArgumentError('Custom split amounts must add up to the total amount');
        }

        await repository.addCustomSplitExpense(input);
      } else if (_splitMode == _SplitMode.percentage) {
        final selectedFriends = friends.where((friend) => _selectedParticipantIds.contains(friend.id)).toList();
        final allocations = selectedFriends.map((friend) {
          final controllerValue = _percentageControllers[friend.id]?.text.trim() ?? '';
          final percentage = int.tryParse(controllerValue);

          if (percentage == null || percentage <= 0) {
            throw ArgumentError('Enter a valid percentage for ${friend.name}');
          }

          return PercentageAllocation(friendId: friend.id, percentage: percentage);
        }).toList();

        final input = AddPercentageSplitExpenseInput(
          note: note,
          totalAmount: amount,
          allocations: allocations,
          date: _selectedDate,
        );

        if (!input.isValid()) {
          throw ArgumentError('Percentage split must total 100%');
        }

        await repository.addPercentageSplitExpense(input);
      } else if (_splitMode == _SplitMode.quantity) {
        final selectedFriends = friends.where((friend) => _selectedParticipantIds.contains(friend.id)).toList();
        final allocations = selectedFriends.map((friend) {
          final controllerValue = _quantityControllers[friend.id]?.text.trim() ?? '';
          final quantity = int.tryParse(controllerValue);

          if (quantity == null || quantity <= 0) {
            throw ArgumentError('Enter a valid quantity for ${friend.name}');
          }

          return QuantityAllocation(friendId: friend.id, quantity: quantity);
        }).toList();

        final input = AddQuantitySplitExpenseInput(
          note: note,
          totalAmount: amount,
          allocations: allocations,
          date: _selectedDate,
        );

        if (!input.isValid()) {
          throw ArgumentError('Quantity split requires positive quantities');
        }

        await repository.addQuantitySplitExpense(input);
      } else {
        await repository.addExpense(
          AddExpenseInput(
            friendId: _selectedFriendId!,
            note: note,
            amount: amount,
            date: _selectedDate,
          ),
        );
      }

      widget.onCreated();
      if (mounted) {
        Navigator.of(context).pop();
        final mode = _splitMode == _SplitMode.single
            ? 'single'
            : _splitMode == _SplitMode.equal
                ? 'equal split'
                : _splitMode == _SplitMode.custom
                    ? 'custom split'
                    : 'percentage split';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Expense added ($mode)')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to save expense: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}

class _EditExpenseSheet extends ConsumerStatefulWidget {
  const _EditExpenseSheet({
    required this.item,
    required this.onUpdated,
  });

  final ExpenseListItem item;
  final VoidCallback onUpdated;

  @override
  ConsumerState<_EditExpenseSheet> createState() => _EditExpenseSheetState();
}

class _EditExpenseSheetState extends ConsumerState<_EditExpenseSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _noteController;
  late final TextEditingController _amountController;

  late int _selectedFriendId;
  bool _submitting = false;
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController(text: widget.item.note);
    _amountController = TextEditingController(text: widget.item.totalAmount.toString());
    _selectedFriendId = 0; // Will be set when friends load
    _selectedDate = widget.item.createdAt;
  }

  @override
  void dispose() {
    _noteController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final friendsAsync = ref.watch(friendOptionsProvider);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Expense',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                'Update the expense details.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              friendsAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (error, stackTrace) => Text('Could not load friends: $error'),
                data: (friends) {
                  if (_selectedFriendId == 0 && friends.isNotEmpty) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() {
                          _selectedFriendId = friends.first.id;
                        });
                      }
                    });
                  }

                  if (friends.isEmpty) {
                    return const Text('No roommates found.');
                  }

                  return DropdownButtonFormField<int>(
                    initialValue: _selectedFriendId == 0 ? null : _selectedFriendId,
                    decoration: const InputDecoration(labelText: 'Friend'),
                    items: friends
                        .map(
                          (friend) => DropdownMenuItem<int>(
                            value: friend.id,
                            child: Text(friend.name),
                          ),
                        )
                        .toList(),
                    onChanged: _submitting
                        ? null
                        : (value) {
                            setState(() {
                              _selectedFriendId = value ?? _selectedFriendId;
                            });
                          },
                    validator: (value) {
                      if (value == null) {
                        return 'Select a friend';
                      }
                      return null;
                    },
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _noteController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Expense Note',
                  hintText: 'Groceries, rent split, internet bill...',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  final text = value?.trim() ?? '';
                  if (text.isEmpty) {
                    return 'Enter a note';
                  }
                  if (text.length < 3) {
                    return 'Use at least 3 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Amount (INR)',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  final amount = int.tryParse((value ?? '').trim());
                  if (amount == null) {
                    return 'Enter a valid number';
                  }
                  if (amount <= 0) {
                    return 'Amount must be greater than zero';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Transaction Date', style: Theme.of(context).textTheme.titleSmall),
                  TextButton.icon(
                    onPressed: _submitting
                        ? null
                        : () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: _selectedDate,
                              firstDate: DateTime(2000),
                              lastDate: DateTime.now(),
                            );
                            if (date != null) {
                              setState(() => _selectedDate = date);
                            }
                          },
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text('${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: 'Update expense',
                  child: FilledButton(
                    onPressed: _submitting ? null : _submit,
                    child: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Update Expense'),
                  ),
                ),
              ),
            ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _submitting = true;
    });

    try {
      final repository = ref.read(expensesRepositoryProvider);
      await repository.updateExpense(
        debtId: widget.item.id,
        friendId: _selectedFriendId,
        note: _noteController.text.trim(),
        amount: int.parse(_amountController.text.trim()),
        date: _selectedDate,
      );

      widget.onUpdated();
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Expense updated')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to update expense: $error')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _submitting = false;
        });
      }
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 120),
      children: [
        AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: const [
              Icon(Icons.receipt_long, size: 42, color: AppTheme.onSurfaceVariant),
              SizedBox(height: 12),
              Text(
                'No expenses yet. Add your first one.',
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({
    required this.message,
    required this.details,
    required this.onRetry,
  });

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: AppCard(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 44, color: AppTheme.error),
              const SizedBox(height: 12),
              Text(message, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text(details, textAlign: TextAlign.center),
              const SizedBox(height: 16),
              ActionButton(
                label: 'Retry',
                icon: Icons.refresh,
                onPressed: onRetry,
                variant: ActionButtonVariant.secondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _formatCurrency(int amount) => '₹$amount';