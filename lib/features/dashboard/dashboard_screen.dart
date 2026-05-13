import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import '../analytics/analytics_screen.dart';
import '../backup_restore/backup_restore_screen.dart';
import '../cash_management/cash_management_screen.dart';
import '../reminders/reminders_screen.dart';
import '../debts/debts_screen.dart';
import '../expenses/expenses_screen.dart';
import 'dashboard_providers.dart';
import 'domain/dashboard_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return SafeArea(
      child: overviewAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => _DashboardError(
          message: 'Could not load dashboard data.',
          details: error.toString(),
          onRetry: () => ref.invalidate(dashboardOverviewProvider),
        ),
        data: (overview) => _DashboardContent(
          overview: overview,
          onRefresh: () async {
            ref.invalidate(dashboardOverviewProvider);
            await ref.read(dashboardOverviewProvider.future);
          },
        ),
      ),
    );
  }
}

class _DashboardContent extends ConsumerWidget {
  const _DashboardContent({required this.overview, required this.onRefresh});

  final DashboardOverview overview;
  final Future<void> Function() onRefresh;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeFilter = ref.watch(transactionFilterProvider);

    // Filter activities
    final filteredActivities = overview.recentActivities.where((activity) {
      switch (activeFilter) {
        case TransactionFilter.all:
          return true;
        case TransactionFilter.expenses:
          return !activity.isSettlement && !activity.isPersonal;
        case TransactionFilter.repayments:
          return activity.isSettlement;
        case TransactionFilter.personal:
          return activity.isPersonal;
      }
    }).toList();

    return RefreshIndicator(
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            title: const Text('RoomLedger'),
            leading: IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () => Scaffold.of(context).openDrawer(),
              tooltip: 'Open menu',
            ),
            actions: [
              IconButton(
                onPressed: () {
                   ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Search coming soon!')),
                  );
                },
                tooltip: 'Search activity',
                icon: const Icon(Icons.search),
              ),
              const SizedBox(width: 8),
            ],
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                [
                  _HeroCard(
                    colorScheme: colorScheme,
                    totalPending: overview.totalPending,
                    debtorCount: overview.debtorCount,
                    overdueCount: overview.overdueCount,
                  ),
                  const SizedBox(height: 18),
                  if (overview.cashBalance <= overview.emergencyReserve) ...[
                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: ListTile(
                        leading: Icon(Icons.warning_amber_rounded, color: Theme.of(context).colorScheme.error),
                        title: Text('Low Cash Warning', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer, fontWeight: FontWeight.bold)),
                        subtitle: Text('Wallet balance (₹${overview.cashBalance}) is at or below the emergency reserve (₹${overview.emergencyReserve}).', style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer)),
                      ),
                    ),
                    const SizedBox(height: 18),
                  ],
                  Text(
                    'Spending snapshot',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _MetricCard(
                          label: 'Monthly spending',
                          value: _formatCurrency(overview.monthlySpending),
                          icon: Icons.calendar_month_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _MetricCard(
                          label: 'Shared spending',
                          value: _formatCurrency(overview.sharedSpending),
                          icon: Icons.groups_outlined,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _MetricCard(
                    label: 'Personal spending',
                    value: _formatCurrency(overview.personalSpending),
                    icon: Icons.person_outline,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Quick actions',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: 'Add expense',
                          icon: Icons.add_circle_outline,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => Scaffold(body: ExpensesScreen())),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          label: 'Record repayment',
                          icon: Icons.payments_outlined,
                          variant: ActionButtonVariant.secondary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const DebtsScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: 'Manage cash',
                          icon: Icons.account_balance_wallet_outlined,
                          variant: ActionButtonVariant.secondary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const CashManagementScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          label: 'Analytics',
                          icon: Icons.bar_chart_outlined,
                          variant: ActionButtonVariant.ghost,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const AnalyticsScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ActionButton(
                          label: 'Reminders',
                          icon: Icons.notifications_active_outlined,
                          variant: ActionButtonVariant.ghost,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const RemindersScreen()),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ActionButton(
                          label: 'Backup',
                          icon: Icons.backup_outlined,
                          variant: ActionButtonVariant.ghost,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const BackupRestoreScreen()),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Pending repayments',
                    actionLabel: 'See all',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const DebtsScreen()),
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _PendingRepaymentList(items: overview.pendingDebts),
                  const SizedBox(height: 20),
                  _SectionHeader(
                    title: 'Recent transactions',
                    actionLabel: '', // Removed 'Filter' label since chips are always visible
                    onTap: () {},
                  ),
                  const SizedBox(height: 8),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _FilterChip(
                          label: 'All',
                          isSelected: activeFilter == TransactionFilter.all,
                          onSelected: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.all,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Expenses',
                          isSelected: activeFilter == TransactionFilter.expenses,
                          onSelected: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.expenses,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Repayments',
                          isSelected: activeFilter == TransactionFilter.repayments,
                          onSelected: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.repayments,
                        ),
                        const SizedBox(width: 8),
                        _FilterChip(
                          label: 'Personal',
                          isSelected: activeFilter == TransactionFilter.personal,
                          onSelected: () => ref.read(transactionFilterProvider.notifier).state = TransactionFilter.personal,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _RecentTransactionsList(items: filteredActivities),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onSelected,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelected(),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : colorScheme.onSurface,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    );
  }
}

class _DashboardError extends StatelessWidget {
  const _DashboardError({required this.message, required this.details, required this.onRetry});

  final String message;
  final String details;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 44),
            const SizedBox(height: 12),
            Text(message, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(details, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.colorScheme,
    required this.totalPending,
    required this.debtorCount,
    required this.overdueCount,
  });

  final ColorScheme colorScheme;
  final int totalPending;
  final int debtorCount;
  final int overdueCount;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total pending',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: AppTheme.onSurfaceVariant,
                          ),
                    ),
                    const AppSpacing.vertical(8),
                    Text(
                      _formatCurrency(totalPending),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: AppTheme.onSurface,
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.account_balance_wallet_outlined, color: AppTheme.secondary),
              ),
            ],
          ),
          const AppSpacing.vertical(20),
          Row(
            children: [
              Expanded(
                child: _HeroMetric(
                  label: 'Owing friends',
                  value: debtorCount.toString(),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _HeroMetric(
                  label: 'Overdue',
                  value: overdueCount.toString(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white.withValues(alpha: 0.75)),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                ),
          ),
        ],
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Theme.of(context).colorScheme.primary),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: Theme.of(context).textTheme.bodyMedium),
                  const SizedBox(height: 4),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.title,
    required this.actionLabel,
    required this.onTap,
  });

  final String title;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          ),
        ),
        if (actionLabel.isNotEmpty)
          TextButton(onPressed: onTap, child: Text(actionLabel)),
      ],
    );
  }
}

class _PendingRepaymentList extends StatelessWidget {
  const _PendingRepaymentList({required this.items});

  final List<PendingDebtItem> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: AppStatusView(
          scrollable: false,
          icon: Icons.done_all,
          title: 'All clear',
          message: 'No pending repayments right now.',
        ),
      );
    }

    return Column(
      children: items
          .map(
            (debt) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _DebtTile(item: debt),
            ),
          )
          .toList(),
    );
  }
}

class _DebtTile extends StatelessWidget {
  const _DebtTile({required this.item});

  final PendingDebtItem item;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          child: Text(
            item.friendName.substring(0, 1),
            style: TextStyle(color: Theme.of(context).colorScheme.primary, fontWeight: FontWeight.w800),
          ),
        ),
        title: Text(item.friendName, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text('${item.note} · ${_formatCurrency(item.repaidAmount)} paid'),
        trailing: Text(
          _formatCurrency(item.remainingAmount),
          style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

class _RecentTransactionsList extends StatelessWidget {
  const _RecentTransactionsList({required this.items});

  final List<DashboardActivity> items;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Card(
        child: AppStatusView(
          scrollable: false,
          icon: Icons.receipt_long_outlined,
          title: 'No activity',
          message: 'Recent transactions matching this filter will appear here.',
        ),
      );
    }

    return Column(
      children: items
          .map(
            (activity) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _TransactionTile(activity: activity),
            ),
          )
          .toList(),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  const _TransactionTile({required this.activity});

  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.secondary.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(
            activity.isSettlement ? Icons.payments_outlined : Icons.sync_alt,
            color: Theme.of(context).colorScheme.secondary,
          ),
        ),
        title: Text(activity.title, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Text(activity.subtitle),
        trailing: Text(
          _formatCurrency(activity.amount),
          style: const TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

String _formatCurrency(int amount) => '₹$amount';