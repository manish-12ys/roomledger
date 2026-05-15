import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import 'domain/friends_models.dart';
import 'friends_providers.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsSummaryProvider);

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: friendsAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 4),
        error: (error, stackTrace) => AppStatusView(
          icon: Icons.people_outline,
          title: 'Mapping Error',
          message: error.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(friendsSummaryProvider),
        ),
        data: (friends) => RefreshIndicator(
          color: AppTheme.secondary,
          backgroundColor: AppTheme.surfaceElevated,
          onRefresh: () async {
            ref.invalidate(friendsSummaryProvider);
            await ref.read(friendsSummaryProvider.future);
          },
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 24),
                  child: const Text(
                    'Roommates',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: -0.5,
                    ),
                  ),
                ),
              ),
              if (friends.isEmpty)
                const SliverFillRemaining(child: _EmptyState())
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _FriendCard(friend: friends[index]),
                      ),
                      childCount: friends.length,
                    ),
                  ),
                ),
              const SliverPadding(padding: EdgeInsets.only(bottom: 120)),
            ],
          ),
        ),
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          child: NeumorphicButton(
            onPressed: () => _openAddFriendSheet(context, ref),
            icon: Icons.person_add_rounded,
            label: 'Add New Roommate',
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }

  void _openAddFriendSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddFriendSheet(onCreated: () => ref.invalidate(friendsSummaryProvider)),
    );
  }
}

class _FriendCard extends StatelessWidget {
  const _FriendCard({required this.friend});
  final FriendSummary friend;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppTheme.secondary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.secondary.withValues(alpha: 0.2)),
            ),
            child: Center(
              child: Text(
                friend.name.isNotEmpty ? friend.name.substring(0, 1).toUpperCase() : '?',
                style: const TextStyle(color: AppTheme.secondary, fontSize: 22, fontWeight: FontWeight.w900),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friend.name, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 4),
                Text(
                  friend.remainingDebt > 0 ? 'Pending: ₹${friend.remainingDebt}' : 'Fully Settled',
                  style: TextStyle(
                    color: friend.remainingDebt > 0 ? const Color(0xFFFF5252) : AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppTheme.muted),
        ],
      ),
    );
  }
}

class _AddFriendSheet extends StatefulWidget {
  const _AddFriendSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  State<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends State<_AddFriendSheet> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.white10, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 24),
          const Text('New Roommate', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.white)),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            autofocus: true,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
            decoration: InputDecoration(
              hintText: 'Enter name...',
              hintStyle: const TextStyle(color: AppTheme.muted),
              filled: true,
              fillColor: Colors.white.withValues(alpha: 0.05),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: NeumorphicButton(
              onPressed: () {
                // This would typically call a repository, but keeping it for UI purposes here
                Navigator.pop(context);
                widget.onCreated();
              },
              icon: Icons.check_circle_rounded,
              label: 'Add Roommate',
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text('No roommates added yet.', style: TextStyle(color: AppTheme.muted)),
    );
  }
}
