import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import 'domain/personal_expense_models.dart';
import 'personal_expenses_providers.dart';

class PersonalExpensesScreen extends ConsumerWidget {
  const PersonalExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(personalExpensesSummaryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Personal Tracker'),
        elevation: 0,
        centerTitle: false,
      ),
      body: summaryAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 5),
        error: (error, stackTrace) => AppStatusView(
          icon: Icons.personal_video_outlined,
          title: 'Tracker Unavailable',
          message: 'Unable to render your personal spending log.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(personalExpensesSummaryProvider),
        ),
        data: (summary) => RefreshIndicator(
          color: AppTheme.secondary,
          backgroundColor: AppTheme.surfaceElevated,
          onRefresh: () async {
            ref.invalidate(personalExpensesSummaryProvider);
            ref.invalidate(personalExpensesListProvider);
            await ref.read(personalExpensesSummaryProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              // Hero Section
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                  child: _HeroSection(summary: summary),
                ),
              ),

              // Category Breakdown
              if (summary.totalSpending > 0) ...[
                SliverToBoxAdapter(
                  child: _SectionHeader(title: 'CATEGORY BREAKDOWN'),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  sliver: SliverToBoxAdapter(
                    child: _CategoryBreakdownCard(summary: summary),
                  ),
                ),
              ],

              // Activity List
              SliverToBoxAdapter(
                child: _SectionHeader(title: 'RECENT TRACKED ITEMS'),
              ),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: summary.expenses.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: AppStatusView(
                            icon: Icons.receipt_long_outlined,
                            title: 'No items saved',
                            message: 'Personal tracking inputs will reflect directly below.',
                            scrollable: false,
                          ),
                        ),
                      )
                    : SliverList(
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final expense = summary.expenses[index];
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: _ExpenseItemCard(
                                expense: expense,
                                onDelete: () => _showDeleteConfirmation(context, ref, expense),
                              ),
                            );
                          },
                          childCount: summary.expenses.length,
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: () => _openAddExpenseSheet(context, ref),
            icon: Icons.add_circle_outline,
            label: 'Track Personal Item',
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  Future<void> _openAddExpenseSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
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

  Future<void> _showDeleteConfirmation(BuildContext context, WidgetRef ref, PersonalExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Delete tracked item?', style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text('Remove "${expense.description}" from your personal log?',
            style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository = await ref.read(personalExpensesRepositoryProvider.future);
      await repository.deleteExpense(id: expense.id);
      ref.invalidate(personalExpensesSummaryProvider);
      ref.invalidate(personalExpensesListProvider);
    }
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection({required this.summary});

  final PersonalExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    // Dummy progress - maybe vs a budget if we had one?
    // For now, let's use a constant or a calculation of recent vs total.
    const progress = 0.85;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      accentColor: AppTheme.accent,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TOTAL PERSONAL SPENDING',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppTheme.onSurfaceVariant,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.2,
                      ),
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${summary.totalSpending}',
                  style: const TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w900,
                    color: AppTheme.accent,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppTheme.accent.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.receipt_long_outlined, size: 12, color: AppTheme.accent),
                          const SizedBox(width: 6),
                          Text(
                            '${summary.expenses.length} items',
                            style: const TextStyle(color: AppTheme.accent, fontSize: 10, fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Text('• Shared Vault Private', style: TextStyle(color: AppTheme.muted, fontSize: 10)),
                  ],
                ),
              ],
            ),
          ),
          ProgressRing(
            progress: progress,
            size: 80,
            strokeWidth: 6,
            activeColor: AppTheme.accent,
            child: Text(
              '85%',
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppTheme.accent),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.5),
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
    );
  }
}

class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.summary});

  final PersonalExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    final sortedCategories = summary.categoryBreakdown.entries
        .where((e) => e.value > 0)
        .toList()
        ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: sortedCategories.map((entry) {
          final category = entry.key;
          final amount = entry.value;
          final percentage = summary.getCategoryPercentage(category);

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(color: AppTheme.surfaceElevated, shape: BoxShape.circle),
                          child: Text(category.emoji, style: const TextStyle(fontSize: 14)),
                        ),
                        const SizedBox(width: 12),
                        Text(category.label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                      ],
                    ),
                    Text(
                      '₹$amount',
                      style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: AppTheme.accent),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (percentage / 100).clamp(0.0, 1.0),
                    minHeight: 6,
                    backgroundColor: AppTheme.surfaceElevated,
                    valueColor: const AlwaysStoppedAnimation(AppTheme.accent),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ExpenseItemCard extends StatelessWidget {
  const _ExpenseItemCard({required this.expense, required this.onDelete});

  final PersonalExpense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      accentColor: AppTheme.accent,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.accent.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Text(expense.category.emoji, style: const TextStyle(fontSize: 18)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(expense.description, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                const SizedBox(height: 4),
                Text(
                  '${expense.category.label} • ${_formatDate(expense.createdAt)}',
                  style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11),
                ),
              ],
            ),
          ),
          Text(
            '₹${expense.amount}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppTheme.accent),
          ),
          const SizedBox(width: 8),
          IconButton(
            onPressed: onDelete,
            icon: const Icon(Icons.delete_outline, size: 18, color: AppTheme.muted),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
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

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusLarge)),
        border: Border.all(color: Colors.white10),
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
                child: Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(2))),
              ),
              const SizedBox(height: 20),
              const Text('Track Personal Item', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 20),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: 'Description', filled: true),
                validator: (v) => v!.isEmpty ? 'Provide description' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(labelText: 'Amount (₹)', filled: true),
                keyboardType: TextInputType.number,
                validator: (v) => int.tryParse(v!) == null ? 'Enter amount' : null,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                child: NeumorphicButton(
                  onPressed: _submit,
                  label: _submitting ? 'Saving...' : 'Save Record',
                ),
              ),
            ],
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
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }
}

String _formatDate(DateTime date) {
  final now = DateTime.now();
  final difference = now.difference(date);
  if (difference.inDays == 0) return 'Today';
  if (difference.inDays == 1) return 'Yesterday';
  return '${date.day}/${date.month}/${date.year}';
}
