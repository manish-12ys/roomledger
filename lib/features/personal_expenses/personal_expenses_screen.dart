import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_states.dart';
import 'domain/personal_expense_models.dart';
import 'personal_expenses_providers.dart';

class PersonalExpensesScreen extends ConsumerWidget {
  const PersonalExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(personalExpensesSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Personal Expenses')),
      body: summaryAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 5),
        error: (error, stackTrace) => _ErrorState(
          message: 'Could not load expenses.',
          details: error.toString(),
          onRetry: () => ref.invalidate(personalExpensesSummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(personalExpensesSummaryProvider);
            ref.invalidate(personalExpensesListProvider);
          },
          child: ListView(
            children: [
              _SummaryCard(summary: summary),
              const SizedBox(height: 12),
              _CategoryBreakdownCard(summary: summary),
              const SizedBox(height: 12),
              _ExpensesList(summary: summary, ref: ref),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddExpenseSheet(context, ref),
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
            ref.invalidate(personalExpensesSummaryProvider);
            ref.invalidate(personalExpensesListProvider);
          },
        );
      },
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({required this.summary});

  final PersonalExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Total Personal Spending',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Text(
                '₹${summary.totalSpending}',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: colorScheme.primary,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                '${summary.expenses.length} expense${summary.expenses.length != 1 ? 's' : ''}',
                style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.summary});

  final PersonalExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (summary.totalSpending == 0) {
      return const SizedBox.shrink();
    }

    final sortedCategories = summary.categoryBreakdown.entries
        .where((e) => e.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Category Breakdown',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),
              ...sortedCategories.map((entry) {
                final category = entry.key;
                final amount = entry.value;
                final percentage = summary.getCategoryPercentage(category);

                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${category.emoji} ${category.label}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            '₹$amount (${percentage.toStringAsFixed(1)}%)',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: percentage / 100,
                          minHeight: 6,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExpensesList extends ConsumerWidget {
  const _ExpensesList({
    required this.summary,
    required this.ref,
  });

  final PersonalExpenseSummary summary;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (summary.expenses.isEmpty) {
      return const AppStatusView(
        icon: Icons.receipt_long_outlined,
        title: 'No personal expenses yet',
        message: 'Add your first personal expense to start tracking spending.',
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Recent Expenses',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: summary.expenses.length,
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final expense = summary.expenses[index];
              return _ExpenseItem(
                expense: expense,
                onDelete: () => _showDeleteConfirmation(context, ref, expense),
              );
            },
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    PersonalExpense expense,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Expense?'),
        content: Text('Remove ${expense.description}?'),
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
        final repository = await ref.read(personalExpensesRepositoryProvider.future);
        await repository.deleteExpense(id: expense.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Expense deleted'),
              duration: Duration(seconds: 2),
            ),
          );

          ref.invalidate(personalExpensesSummaryProvider);
          ref.invalidate(personalExpensesListProvider);
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

class _ExpenseItem extends StatelessWidget {
  const _ExpenseItem({
    required this.expense,
    required this.onDelete,
  });

  final PersonalExpense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      expense.category.emoji,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        expense.description,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.category.label} · ${_formatDate(expense.createdAt)}',
                  style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                ),
              ],
            ),
          ),
          PopupMenuButton(
            itemBuilder: (context) => [
              PopupMenuItem(
                onTap: onDelete,
                child: Text(
                  'Delete',
                  style: TextStyle(color: colorScheme.error),
                ),
              ),
            ],
            child: Text(
              '₹${expense.amount}',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: colorScheme.primary,
              ),
            ),
          ),
        ],
      ),
    );
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
  final _descriptionController = TextEditingController();
  final _amountController = TextEditingController();

  late ExpenseCategory _selectedCategory;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _selectedCategory = ExpenseCategory.other;
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                'Add Personal Expense',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              Text(
                'Category',
                style: Theme.of(context).textTheme.labelMedium,
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values
                    .map(
                      (category) => FilterChip(
                        label: Text('${category.emoji} ${category.label}'),
                        selected: _selectedCategory == category,
                        onSelected: _submitting
                            ? null
                            : (selected) {
                                setState(() {
                                  _selectedCategory = category;
                                });
                              },
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  hintText: 'e.g., Lunch at cafe',
                ),
                textInputAction: TextInputAction.next,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Enter a description';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _amountController,
                enabled: !_submitting,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  prefixText: '₹ ',
                ),
                keyboardType: TextInputType.number,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
                validator: (value) {
                  final amount = int.tryParse(value?.trim() ?? '');
                  if (amount == null || amount <= 0) {
                    return 'Enter a valid amount';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _submitting ? null : _submit,
                  child: _submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Save Expense'),
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
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final repository = await ref.read(personalExpensesRepositoryProvider.future);
      await repository.addExpense(
        description: _descriptionController.text.trim(),
        amount: int.parse(_amountController.text.trim()),
        category: _selectedCategory,
      );

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense added'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
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
    return AppStatusView(
      icon: Icons.error_outline,
      title: message,
      message: details,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);

  if (difference.inDays == 0) {
    return 'today';
  } else if (difference.inDays == 1) {
    return 'yesterday';
  } else if (difference.inDays < 7) {
    return '${difference.inDays} days ago';
  } else {
    return '${date.day}/${date.month}/${date.year}';
  }
}
