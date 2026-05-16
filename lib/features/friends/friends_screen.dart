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
                      color: AppTheme.onSurface,
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
      builder: (_) => _AddFriendSheet(
        onCreated: () => ref.invalidate(friendsSummaryProvider),
      ),
    );
  }
}

class _FriendCard extends ConsumerWidget {
  const _FriendCard({required this.friend});
  final FriendSummary friend;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              border: Border.all(
                color: AppTheme.secondary.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Text(
                friend.name.isNotEmpty
                    ? friend.name.substring(0, 1).toUpperCase()
                    : '?',
                style: const TextStyle(
                  color: AppTheme.secondary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  friend.name,
                  style: const TextStyle(
                    color: AppTheme.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  friend.remainingDebt > 0
                      ? 'Pending: ₹${friend.remainingDebt}'
                      : 'Fully Settled',
                  style: TextStyle(
                    color: friend.remainingDebt > 0
                        ? AppTheme.error
                        : AppTheme.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              if (value == 'edit') {
                _openEditFriendSheet(context, ref);
              } else if (value == 'delete') {
                _showDeleteConfirmation(context, ref);
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'edit',
                child: Row(
                  children: [
                    Icon(Icons.edit_outlined, size: 18),
                    SizedBox(width: 8),
                    Text('Edit'),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'delete',
                child: Row(
                  children: [
                    Icon(Icons.delete_outline, size: 18, color: AppTheme.error),
                    const SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: AppTheme.error)),
                  ],
                ),
              ),
            ],
            child: const Icon(Icons.more_vert_rounded, color: AppTheme.muted),
          ),
        ],
      ),
    );
  }

  void _openEditFriendSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _EditFriendSheet(
        friend: friend,
        onUpdated: () => ref.invalidate(friendsSummaryProvider),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Roommate?'),
        content: Text('Remove ${friend.name} from your roommates?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteFriend(context, ref);
            },
            child: Text('Delete', style: TextStyle(color: AppTheme.error)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFriend(BuildContext context, WidgetRef ref) async {
    try {
      final repository = ref.read(friendsRepositoryProvider);
      final canDelete = await repository.canDeleteFriend(friendId: friend.id);

      if (!context.mounted) return;

      if (!canDelete) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Cannot delete: active debts exist'),
            backgroundColor: AppTheme.error,
          ),
        );
        return;
      }

      await repository.deleteFriend(friendId: friend.id);

      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Roommate deleted')));
        ref.invalidate(friendsSummaryProvider);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    }
  }
}

class _AddFriendSheet extends ConsumerStatefulWidget {
  const _AddFriendSheet({required this.onCreated});
  final VoidCallback onCreated;

  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet> {
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
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }

    setState(() => _submitting = true);

    try {
      final repository = ref.read(friendsRepositoryProvider);
      await repository.addFriend(name: name);

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Roommate added')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'New Roommate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            enabled: !_submitting,
            autofocus: true,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Enter name...',
              hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
              filled: true,
              fillColor: AppTheme.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.tonal(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Add Roommate'),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditFriendSheet extends ConsumerStatefulWidget {
  const _EditFriendSheet({required this.friend, required this.onUpdated});
  final FriendSummary friend;
  final VoidCallback onUpdated;

  @override
  ConsumerState<_EditFriendSheet> createState() => _EditFriendSheetState();
}

class _EditFriendSheetState extends ConsumerState<_EditFriendSheet> {
  late final TextEditingController _controller;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.friend.name);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _controller.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }

    if (name == widget.friend.name) {
      Navigator.pop(context);
      return;
    }

    setState(() => _submitting = true);

    try {
      final repository = ref.read(friendsRepositoryProvider);
      await repository.updateFriend(id: widget.friend.id, name: name);

      if (mounted) {
        Navigator.pop(context);
        widget.onUpdated();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Roommate updated')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppTheme.error),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppTheme.surfaceElevated,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        12,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppTheme.onSurface.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Edit Roommate',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppTheme.onSurface,
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _controller,
            enabled: !_submitting,
            autofocus: true,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Enter name...',
              hintStyle: const TextStyle(color: AppTheme.onSurfaceVariant),
              filled: true,
              fillColor: AppTheme.onSurface.withValues(alpha: 0.05),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.tonal(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      height: 18,
                      width: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Update Roommate'),
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
      child: Text(
        'No roommates added yet.',
        style: TextStyle(color: AppTheme.muted),
      ),
    );
  }
}
