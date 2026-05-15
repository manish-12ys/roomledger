import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import 'domain/personal_expense_models.dart';
import 'personal_expenses_providers.dart';

// ─── Category color palette ───────────────────────────────────────────────────
Color _categoryColor(ExpenseCategory cat) {
  return switch (cat) {
    ExpenseCategory.food => const Color(0xFFFF6B6B),
    ExpenseCategory.travel => AppTheme.secondary,
    ExpenseCategory.bills => AppTheme.warning,
    ExpenseCategory.entertainment => const Color(0xFFA78BFA),
    ExpenseCategory.shopping => const Color(0xFFF97316),
    ExpenseCategory.utilities => AppTheme.info,
    ExpenseCategory.other => AppTheme.muted,
  };
}

// ─── Main Screen ─────────────────────────────────────────────────────────────
class PersonalExpensesScreen extends ConsumerWidget {
  const PersonalExpensesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(personalExpensesSummaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: summaryAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 5),
        error: (error, _) => AppStatusView(
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
              // ── App Bar (matches Debts / Dashboard style) ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(0, 52, 20, 24),
                  child: Row(
                    children: [
                      if (Navigator.of(context).canPop())
                        IconButton(
                          onPressed: () => Navigator.of(context).pop(),
                          icon: const Icon(Icons.arrow_back_ios_new_rounded,
                              size: 20, color: AppTheme.onSurface),
                          tooltip: 'Back',
                        )
                      else
                        const SizedBox(width: 20),
                      const Text(
                        'Personal Tracker',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppTheme.onSurface,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Hero summary card ──
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 28),
                  child: _HeroCard(summary: summary),
                ),
              ),

              // ── Category breakdown ──
              if (summary.totalSpending > 0) ...[
                _SectionHeader(title: 'CATEGORY BREAKDOWN'),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                  sliver: SliverToBoxAdapter(
                    child: _CategoryBreakdownCard(summary: summary),
                  ),
                ),
              ],

              // ── Expense list ──
              _SectionHeader(title: 'RECENT TRACKED ITEMS'),
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
                sliver: summary.expenses.isEmpty
                    ? const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.only(top: 40),
                          child: AppStatusView(
                            icon: Icons.receipt_long_outlined,
                            title: 'No items saved',
                            message:
                                'Tap the button below to track your first expense.',
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
                                onDelete: () => _showDeleteConfirmation(
                                    context, ref, expense),
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
      builder: (context) => _AddExpenseSheet(
        onCreated: () {
          ref.invalidate(personalExpensesSummaryProvider);
          ref.invalidate(personalExpensesListProvider);
        },
      ),
    );
  }

  Future<void> _showDeleteConfirmation(
      BuildContext context, WidgetRef ref, PersonalExpense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceContainer,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium)),
        title: const Text('Delete tracked item?',
            style: TextStyle(fontWeight: FontWeight.w800)),
        content: Text(
            'Remove "${expense.description}" from your personal log?',
            style: const TextStyle(
                color: AppTheme.onSurfaceVariant, fontSize: 14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel',
                style: TextStyle(color: AppTheme.onSurfaceVariant)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppTheme.error),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete',
                style: TextStyle(
                    color: AppTheme.onSurface, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      final repository =
          await ref.read(personalExpensesRepositoryProvider.future);
      await repository.deleteExpense(id: expense.id);
      ref.invalidate(personalExpensesSummaryProvider);
      ref.invalidate(personalExpensesListProvider);
    }
  }
}

// ─── Section Header (matches dashboard_screen style) ─────────────────────────
class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
        child: Text(
          title,
          style: const TextStyle(
              color: AppTheme.muted,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2),
        ),
      ),
    );
  }
}

// ─── Hero Card (matches DebtsScreen GlassCard hero) ──────────────────────────
class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.summary});
  final PersonalExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    final topCategory = summary.categoryBreakdown.entries
        .where((e) => e.value > 0)
        .fold<MapEntry<ExpenseCategory, int>?>(
          null,
          (prev, e) => prev == null || e.value > prev.value ? e : prev,
        );

    final progress = summary.expenses.isEmpty
        ? 0.0
        : (summary.expenses.length / (summary.expenses.length + 5))
            .clamp(0.0, 1.0);

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Total Personal Spending',
                  style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 12),
                Text(
                  '₹${summary.totalSpending}',
                  style: const TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w900,
                      color: AppTheme.onSurface),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Badge(
                      label: 'Items',
                      value: '${summary.expenses.length}',
                      color: AppTheme.secondary,
                    ),
                    const SizedBox(width: 12),
                    if (topCategory != null)
                      _Badge(
                        label: topCategory.key.label,
                        value: topCategory.key.emoji,
                        color: _categoryColor(topCategory.key),
                      ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ProgressRing(
                progress: progress,
                size: 84,
                strokeWidth: 7,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${summary.expenses.length}',
                      style: const TextStyle(
                          color: AppTheme.secondary,
                          fontWeight: FontWeight.w900,
                          fontSize: 18),
                    ),
                    const Text(
                      'items',
                      style: TextStyle(
                          color: AppTheme.muted,
                          fontWeight: FontWeight.w600,
                          fontSize: 9),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'tracked',
                style: TextStyle(
                    color: AppTheme.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Text('$value $label',
          style: TextStyle(
              color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}

// ─── Category Breakdown Card (matches GlassCard pattern) ─────────────────────
class _CategoryBreakdownCard extends StatelessWidget {
  const _CategoryBreakdownCard({required this.summary});
  final PersonalExpenseSummary summary;

  @override
  Widget build(BuildContext context) {
    final sorted = summary.categoryBreakdown.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return GlassCard(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Column(
        children: sorted.map((entry) {
          final color = _categoryColor(entry.key);
          final pct = summary.getCategoryPercentage(entry.key);
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color, shape: BoxShape.circle),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        '${entry.key.emoji}  ${entry.key.label}',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                    ),
                    Text(
                      '₹${entry.value}',
                      style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          color: color),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (pct / 100).clamp(0.0, 1.0),
                    minHeight: 5,
                    backgroundColor: AppTheme.surfaceElevated,
                    valueColor: AlwaysStoppedAnimation(color),
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

// ─── Expense Item Card (matches _ActivityItem / _RoommateDebtCard style) ──────
class _ExpenseItemCard extends StatelessWidget {
  const _ExpenseItemCard({required this.expense, required this.onDelete});
  final PersonalExpense expense;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(expense.category);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(expense.category.emoji,
                  style: const TextStyle(fontSize: 20)),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  expense.description,
                  style: const TextStyle(
                      color: AppTheme.onSurface,
                      fontWeight: FontWeight.w800,
                      fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${expense.category.label} • ${_formatDate(expense.createdAt)}',
                  style: const TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '₹${expense.amount}',
            style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
                fontSize: 16),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onDelete,
            child: const Icon(Icons.delete_outline,
                size: 18, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }
}

// ─── Add Expense Sheet ────────────────────────────────────────────────────────
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
        borderRadius: const BorderRadius.vertical(
            top: Radius.circular(AppTheme.radiusLarge)),
        border:
            Border.all(color: AppTheme.onSurface.withValues(alpha: 0.08)),
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
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.onSurface.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Track Personal Item',
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 6),
              const Text('Add an expense to your personal log',
                  style: TextStyle(
                      fontSize: 13, color: AppTheme.muted)),
              const SizedBox(height: 24),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description',
                  filled: true,
                  prefixIcon: Icon(Icons.edit_outlined, size: 18),
                ),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Provide description' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Amount (₹)',
                  filled: true,
                  prefixIcon: Icon(Icons.currency_rupee, size: 18),
                ),
                keyboardType: TextInputType.number,
                validator: (v) =>
                    int.tryParse(v ?? '') == null ? 'Enter valid amount' : null,
              ),
              const SizedBox(height: 22),
              const Text('Category',
                  style: TextStyle(
                      color: AppTheme.muted,
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ExpenseCategory.values.map((cat) {
                  final isSelected = _selectedCategory == cat;
                  final color = _categoryColor(cat);
                  return GestureDetector(
                    onTap: () => setState(() => _selectedCategory = cat),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? color.withValues(alpha: 0.15)
                            : AppTheme.surfaceElevated,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isSelected
                              ? color
                              : AppTheme.onSurface.withValues(alpha: 0.08),
                          width: isSelected ? 1.5 : 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(cat.emoji,
                              style: const TextStyle(fontSize: 14)),
                          const SizedBox(width: 6),
                          Text(
                            cat.label,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: isSelected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isSelected
                                  ? color
                                  : AppTheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
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
      final repository =
          await ref.read(personalExpensesRepositoryProvider.future);
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

// ─── Helpers ──────────────────────────────────────────────────────────────────
String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);
  if (diff.inDays == 0) return 'Today';
  if (diff.inDays == 1) return 'Yesterday';
  return '${date.day}/${date.month}/${date.year}';
}
