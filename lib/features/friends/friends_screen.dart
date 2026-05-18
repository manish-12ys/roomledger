import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';
import '../../core/widgets/app_states.dart';
import 'domain/friends_models.dart';
import 'friends_providers.dart';
import '../reminders/reminders_providers.dart';
import '../reminders/domain/reminder_models.dart';
import '../reminders/widgets/auto_reminder_settings_card.dart';
import 'package:url_launcher/url_launcher.dart';

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
                  padding: const EdgeInsets.fromLTRB(20, 60, 20, 16),
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
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: _AutoReminderSettingsSection(),
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
                const SizedBox(height: 10),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    _QuickActionButton(
                      icon: Icons.bolt_outlined,
                      label: 'Direct',
                      color: AppTheme.warning,
                      onTap: () {
                        if (friend.phoneNumber == null || friend.phoneNumber!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('No phone number — tap ⋮ › Edit to add one'),
                              backgroundColor: AppTheme.surfaceElevated,
                              action: SnackBarAction(
                                label: 'Edit',
                                textColor: AppTheme.secondary,
                                onPressed: () => _openEditFriendSheet(context, ref),
                              ),
                            ),
                          );
                        } else {
                          _sendDirectSms(context, friend);
                        }
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.sms_outlined,
                      label: 'SMS App',
                      color: AppTheme.info,
                      onTap: () {
                        if (friend.phoneNumber == null || friend.phoneNumber!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('No phone number — tap ⋮ › Edit to add one'),
                              backgroundColor: AppTheme.surfaceElevated,
                              action: SnackBarAction(
                                label: 'Edit',
                                textColor: AppTheme.secondary,
                                onPressed: () => _openEditFriendSheet(context, ref),
                              ),
                            ),
                          );
                        } else {
                          _launchSms(friend);
                        }
                      },
                    ),
                    _QuickActionButton(
                      icon: Icons.chat_outlined,
                      label: 'WhatsApp',
                      color: const Color(0xFF25D366),
                      onTap: () {
                        if (friend.phoneNumber == null || friend.phoneNumber!.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('No phone number — tap ⋮ › Edit to add one'),
                              backgroundColor: AppTheme.surfaceElevated,
                              action: SnackBarAction(
                                label: 'Edit',
                                textColor: AppTheme.secondary,
                                onPressed: () => _openEditFriendSheet(context, ref),
                              ),
                            ),
                          );
                        } else {
                          _launchWhatsApp(friend);
                        }
                      },
                    ),
                    if (friend.phoneNumber == null || friend.phoneNumber!.isEmpty) ...[
                      const Tooltip(
                        message: 'Add phone number via Edit',
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            Icons.phone_missed_outlined,
                            size: 14,
                            color: AppTheme.muted,
                          ),
                        ),
                      ),
                    ],
                  ],
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
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }

    setState(() => _submitting = true);

    try {
      final repository = ref.read(friendsRepositoryProvider);
      await repository.addFriend(name: name, phoneNumber: phone.isEmpty ? null : phone);

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
            controller: _nameController,
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
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Enter phone number (optional)...',
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
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.friend.name);
    _phoneController = TextEditingController(text: widget.friend.phoneNumber ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Enter a name')));
      return;
    }

    if (name == widget.friend.name && phone == (widget.friend.phoneNumber ?? '')) {
      Navigator.pop(context);
      return;
    }

    setState(() => _submitting = true);

    try {
      final repository = ref.read(friendsRepositoryProvider);
      await repository.updateFriend(
        id: widget.friend.id, 
        name: name,
        phoneNumber: phone.isEmpty ? null : phone,
      );

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
            controller: _nameController,
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
          const SizedBox(height: 16),
          TextField(
            controller: _phoneController,
            enabled: !_submitting,
            keyboardType: TextInputType.phone,
            style: const TextStyle(
              color: AppTheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            decoration: InputDecoration(
              hintText: 'Enter phone number (optional)...',
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

class _AutoReminderSettingsSection extends ConsumerWidget {
  const _AutoReminderSettingsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(reminderSettingsProvider);

    return settingsAsync.when(
      data: (settings) {
        return AutoReminderSettingsCard(
          isEnabled: settings.autoSendEnabled == 1,
          intervalDays: settings.dispatchIntervalDays,
          senderName: settings.senderName,
          onToggle: (val) {
            final updated = ReminderSettings(
              id: settings.id,
              autoSendEnabled: val ? 1 : 0,
              dispatchIntervalDays: settings.dispatchIntervalDays,
              senderName: settings.senderName,
            );
            ref.read(remindersControllerProvider.notifier).updateReminderSettings(updated);
          },
          onIntervalChanged: (val) {
            final updated = ReminderSettings(
              id: settings.id,
              autoSendEnabled: settings.autoSendEnabled,
              dispatchIntervalDays: val,
              senderName: settings.senderName,
            );
            ref.read(remindersControllerProvider.notifier).updateReminderSettings(updated);
          },
          onSenderNameChanged: (val) {
            final updated = ReminderSettings(
              id: settings.id,
              autoSendEnabled: settings.autoSendEnabled,
              dispatchIntervalDays: settings.dispatchIntervalDays,
              senderName: val,
            );
            ref.read(remindersControllerProvider.notifier).updateReminderSettings(updated);
          },
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (e, st) => const SizedBox.shrink(),
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatPhoneNumber(String raw) {
  String clean = raw.replaceAll(RegExp(r'[^\d]'), '');
  if (clean.startsWith('0') && clean.length == 11) {
    clean = clean.substring(1);
  }
  if (clean.length == 10) {
    clean = '91$clean'; // Automatically prepend India's +91 country code
  }
  return clean;
}

Future<void> _sendDirectSms(BuildContext context, FriendSummary friend) async {
  if (friend.phoneNumber == null) return;
  final formattedPhone = _formatPhoneNumber(friend.phoneNumber!);
  final message = 'Hey ${friend.name}! You have a pending split balance of ₹${friend.remainingDebt} outstanding. Please pay when possible! Thank you! 😊';
  try {
    const smsChannel = MethodChannel('roomledger/sms');
    await smsChannel.invokeMethod('sendSms', {
      'recipient': formattedPhone,
      'message': message,
    });
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Direct SMS sent successfully to ${friend.name}! ⚡'),
          backgroundColor: AppTheme.success,
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send Direct SMS: $e'),
          backgroundColor: AppTheme.error,
        ),
      );
    }
  }
}

Future<void> _launchSms(FriendSummary friend) async {
  if (friend.phoneNumber == null) return;
  final formattedPhone = _formatPhoneNumber(friend.phoneNumber!);
  final message = Uri.encodeComponent('Hey ${friend.name}! You have a pending split balance of ₹${friend.remainingDebt} outstanding. Please pay when possible! Thank you! 😊');
  final url = Uri.parse('sms:$formattedPhone?body=$message');
  try {
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    await launchUrl(url, mode: LaunchMode.platformDefault);
  }
}

Future<void> _launchWhatsApp(FriendSummary friend) async {
  if (friend.phoneNumber == null) return;
  
  final formattedPhone = _formatPhoneNumber(friend.phoneNumber!);
  final message = Uri.encodeComponent('Hey ${friend.name}! You have a pending split balance of ₹${friend.remainingDebt} outstanding. Please pay when possible! Thank you! 😊');
  
  final whatsappUrl = Uri.parse('whatsapp://send?phone=$formattedPhone&text=$message');
  final webUrl = Uri.parse('https://wa.me/$formattedPhone?text=$message');
  
  try {
    if (await canLaunchUrl(whatsappUrl)) {
      await launchUrl(whatsappUrl);
    } else if (await canLaunchUrl(webUrl)) {
      await launchUrl(webUrl, mode: LaunchMode.externalNonBrowserApplication);
    } else {
      await launchUrl(webUrl, mode: LaunchMode.externalApplication);
    }
  } catch (e) {
    await launchUrl(webUrl, mode: LaunchMode.platformDefault);
  }
}
