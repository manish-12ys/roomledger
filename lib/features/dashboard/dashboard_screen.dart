import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import '../analytics/analytics_screen.dart';
import '../backup_restore/backup_restore_screen.dart';
import '../cash_management/cash_management_screen.dart';
import '../personal_expenses/personal_expenses_screen.dart';
import 'dashboard_providers.dart';
import 'domain/dashboard_models.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final overviewAsync = ref.watch(dashboardOverviewProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: overviewAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 4),
        error: (error, stackTrace) => AppStatusView(
          icon: Icons.dashboard_customize_outlined,
          title: 'Dashboard Error',
          message: 'Unable to load your financial overview.',
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(dashboardOverviewProvider),
        ),
        data: (overview) => RefreshIndicator(
          color: AppTheme.secondary,
          backgroundColor: AppTheme.surfaceElevated,
          onRefresh: () async {
            ref.invalidate(dashboardOverviewProvider);
            await ref.read(dashboardOverviewProvider.future);
          },
          child: _DashboardContent(overview: overview),
        ),
      ),
    );
  }
}

class _DashboardContent extends StatelessWidget {
  const _DashboardContent({required this.overview});

  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        // Premium App Bar
        SliverAppBar(
          backgroundColor: Colors.transparent,
          floating: true,
          title: const Text(
            'RoomLedger',
            style: TextStyle(fontWeight: FontWeight.w900, fontSize: 24, letterSpacing: -0.5),
          ),
          actions: [
            IconButton(
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => BackupRestoreScreen())),
              icon: const Icon(Icons.settings_backup_restore, size: 22, color: AppTheme.onSurfaceVariant),
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Hero Summary
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            child: _PremiumHero(overview: overview),
          ),
        ),

        // Quick Access Row
        SliverToBoxAdapter(
          child: _SectionHeader(title: 'QUICK ACCESS'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                _AccessPill(
                  label: 'Analytics',
                  icon: Icons.insights_rounded,
                  color: AppTheme.warning,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsScreen())),
                ),
                const SizedBox(width: 10),
                _AccessPill(
                  label: 'Personal',
                  icon: Icons.person_rounded,
                  color: AppTheme.accent,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PersonalExpensesScreen())),
                ),
                const SizedBox(width: 10),
                _AccessPill(
                  label: 'Vault',
                  icon: Icons.account_balance_wallet_rounded,
                  color: AppTheme.secondary,
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CashManagementScreen())),
                ),
              ],
            ),
          ),
        ),

        // Monthly Breakdown
        SliverToBoxAdapter(
          child: _SectionHeader(title: 'MONTHLY SNAPSHOT'),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          sliver: SliverToBoxAdapter(
            child: Row(
              children: [
                Expanded(
                  child: _MiniMetric(
                    label: 'Spent',
                    value: '₹${overview.monthlySpending}',
                    icon: Icons.trending_up_rounded,
                    color: AppTheme.onSurface,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _MiniMetric(
                    label: 'Saved',
                    value: '₹${overview.emergencyReserve}',
                    icon: Icons.savings_rounded,
                    color: AppTheme.secondary,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Recent Activity List
        SliverToBoxAdapter(
          child: _SectionHeader(title: 'RECENT ACTIVITY'),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 120),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _ActivityItem(activity: overview.recentActivities[index]),
              ),
              childCount: overview.recentActivities.length,
            ),
          ),
        ),
      ],
    );
  }
}

class _PremiumHero extends StatelessWidget {
  const _PremiumHero({required this.overview});
  final DashboardOverview overview;

  @override
  Widget build(BuildContext context) {
    // Same calculation as Shared Ledger: total repaid / total ever owed across ALL debts
    final progress = overview.totalDebt > 0
        ? (overview.totalRepaid / overview.totalDebt).clamp(0.0, 1.0)
        : 0.0;

    return GlassCard(
      padding: const EdgeInsets.all(24),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Total Shared Debt', style: TextStyle(color: AppTheme.muted, fontSize: 13, fontWeight: FontWeight.w700)),
                const SizedBox(height: 12),
                Text('₹${overview.totalPending}', 
                  style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AppTheme.onSurface)),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _Badge(label: 'Debtors', value: '${overview.debtorCount}', color: AppTheme.secondary),
                    const SizedBox(width: 12),
                    _Badge(label: 'Overdue', value: '${overview.overdueCount}', color: AppTheme.error),
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
                size: 80,
                strokeWidth: 6,
                child: Text('${(progress * 100).toInt()}%',
                  style: const TextStyle(color: AppTheme.secondary, fontWeight: FontWeight.w900, fontSize: 14)),
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

class _AccessPill extends StatelessWidget {
  const _AccessPill({required this.label, required this.icon, required this.color, required this.onTap});
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: AppTheme.onSurfaceVariant, fontSize: 11, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value, required this.icon, required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 12),
          Text(label, style: const TextStyle(color: AppTheme.muted, fontSize: 10, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(value, style: const TextStyle(color: AppTheme.onSurface, fontSize: 18, fontWeight: FontWeight.w900)),
        ],
      ),
    );
  }
}

class _ActivityItem extends StatelessWidget {
  const _ActivityItem({required this.activity});
  final DashboardActivity activity;

  @override
  Widget build(BuildContext context) {
    final color = activity.isSettlement ? AppTheme.secondary : (activity.isPersonal ? AppTheme.accent : AppTheme.onSurfaceVariant);
    
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
            child: Icon(
              activity.isSettlement ? Icons.handshake_rounded : (activity.isPersonal ? Icons.person_rounded : Icons.shopping_bag_rounded),
              color: color,
              size: 20,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(activity.title, style: const TextStyle(color: AppTheme.onSurface, fontWeight: FontWeight.w800, fontSize: 15)),
                const SizedBox(height: 4),
                Text(activity.subtitle, style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Text('₹${activity.amount}', style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 16)),
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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
      child: Text(
        title,
        style: const TextStyle(color: AppTheme.muted, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 1.2),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.value, required this.color});
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
      child: Text('$value $label', style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w800)),
    );
  }
}