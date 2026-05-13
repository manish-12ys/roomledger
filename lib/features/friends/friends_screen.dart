import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/widgets/app_states.dart';
import 'domain/friends_models.dart';
import 'friends_providers.dart';

class FriendsScreen extends ConsumerWidget {
  const FriendsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final friendsAsync = ref.watch(friendsSummaryProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Roommates')),
      body: friendsAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 4),
        error: (error, stackTrace) => _ErrorState(
          message: 'Could not load roommates.',
          details: error.toString(),
          onRetry: () => ref.invalidate(friendsSummaryProvider),
        ),
        data: (friends) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(friendsSummaryProvider);
            await ref.read(friendsSummaryProvider.future);
          },
          child: friends.isEmpty
              ? const _EmptyState()
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                  itemCount: friends.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final friend = friends[index];
                    return _FriendCard(
                      friend: friend,
                      onDelete: () => _showDeleteConfirmation(context, ref, friend),
                      onEdit: () => _openEditFriendSheet(context, ref, friend),
                    );
                  },
                ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openAddFriendSheet(context, ref),
        tooltip: 'Add roommate',
        icon: const Icon(Icons.person_add),
        label: const Text('Add Roommate'),
      ),
    );
  }

  Future<void> _openAddFriendSheet(BuildContext context, WidgetRef ref) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _AddFriendSheet(
          onCreated: () {
            ref.invalidate(friendsSummaryProvider);
            ref.invalidate(friendsListProvider);
          },
        );
      },
    );
  }

  Future<void> _openEditFriendSheet(
    BuildContext context,
    WidgetRef ref,
    FriendSummary friend,
  ) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) {
        return _AddFriendSheet(
          friendId: friend.id,
          initialName: friend.name,
          onCreated: () {
            ref.invalidate(friendsSummaryProvider);
            ref.invalidate(friendsListProvider);
          },
        );
      },
    );
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    FriendSummary friend,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Roommate?'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Remove ${friend.name} from your roommates list?'),
            if (friend.hasActiveDebt) ...[
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
                        '${friend.name} still has ₹${friend.remainingDebt} pending.',
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
        final repository = ref.read(friendsRepositoryProvider);
        final canDelete = await repository.canDeleteFriend(friendId: friend.id);

        if (!context.mounted) return;

        if (!canDelete) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Cannot delete ${friend.name}: still has pending debts'),
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
          );
          return;
        }

        await repository.deleteFriend(friendId: friend.id);

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${friend.name} removed'),
              duration: const Duration(seconds: 2),
            ),
          );

          ref.invalidate(friendsSummaryProvider);
          ref.invalidate(friendsListProvider);
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

class _FriendCard extends StatelessWidget {
  const _FriendCard({
    required this.friend,
    required this.onDelete,
    required this.onEdit,
  });

  final FriendSummary friend;
  final VoidCallback onDelete;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: colorScheme.primary.withValues(alpha: 0.10),
                  child: Text(
                    friend.name.substring(0, 1),
                    style: TextStyle(
                      color: colorScheme.primary,
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        friend.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                      Text(
                        'Added ${_formatDate(friend.createdAt)}',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      onTap: onEdit,
                      child: const Text('Edit'),
                    ),
                    PopupMenuItem(
                      onTap: onDelete,
                      child: const Text('Delete'),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Total Owed',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      Text(
                        _formatCurrency(friend.totalDebt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Repaid',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      Text(
                        _formatCurrency(friend.repaidAmount),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Pending',
                        style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 12),
                      ),
                      Text(
                        _formatCurrency(friend.remainingDebt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          color: friend.hasActiveDebt ? colorScheme.error : colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _AddFriendSheet extends ConsumerStatefulWidget {
  const _AddFriendSheet({
    required this.onCreated,
    this.friendId,
    this.initialName,
  });

  final VoidCallback onCreated;
  final int? friendId;
  final String? initialName;

  @override
  ConsumerState<_AddFriendSheet> createState() => _AddFriendSheetState();
}

class _AddFriendSheetState extends ConsumerState<_AddFriendSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialName ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final isEditing = widget.friendId != null;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 20, 16, 16 + bottomInset),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Roommate' : 'Add Roommate',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 6),
              Text(
                isEditing
                    ? 'Update roommate details.'
                    : 'New roommates can be assigned expenses and debts.',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 20),
              TextFormField(
                controller: _nameController,
                enabled: !_submitting,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submitForm(),
                decoration: const InputDecoration(
                  labelText: 'Roommate Name',
                  hintText: 'e.g., Ravi',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Please enter a name';
                  }
                  if (value.length < 2) {
                    return 'Name must be at least 2 characters';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: Semantics(
                  button: true,
                  label: isEditing ? 'Update roommate' : 'Add roommate',
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submitForm,
                    child: _submitting
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(isEditing ? 'Update Roommate' : 'Add Roommate'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);

    try {
      final repository = ref.read(friendsRepositoryProvider);
      final isEditing = widget.friendId != null;

      if (isEditing) {
        await repository.updateFriend(id: widget.friendId!, name: _nameController.text);
      } else {
        await repository.addFriend(name: _nameController.text);
      }

      if (mounted) {
        Navigator.pop(context);
        widget.onCreated();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              isEditing
                  ? '${_nameController.text} updated'
                  : '${_nameController.text} added as roommate',
            ),
            duration: const Duration(seconds: 2),
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

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const AppStatusView(
      icon: Icons.people_outline,
      title: 'No roommates yet',
      message: 'Add your first roommate to get started',
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
    return AppStatusView(
      icon: Icons.error_outline,
      title: message,
      message: details,
      actionLabel: 'Retry',
      onAction: onRetry,
    );
  }
}

String _formatCurrency(int amount) {
  return '₹${amount.toStringAsFixed(0)}';
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
  } else if (difference.inDays < 30) {
    final weeks = (difference.inDays / 7).floor();
    return '$weeks ${weeks == 1 ? 'week' : 'weeks'} ago';
  } else {
    final months = (difference.inDays / 30).floor();
    return '$months ${months == 1 ? 'month' : 'months'} ago';
  }
}
