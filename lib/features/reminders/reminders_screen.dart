import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_theme.dart';
import '../../core/widgets/app_components.dart';

import '../../core/widgets/app_states.dart';
import 'domain/reminder_models.dart';
import 'reminders_providers.dart';

class RemindersScreen extends ConsumerWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final remindersAsync = ref.watch(remindersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reminders'),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.background,
              AppTheme.surface.withValues(alpha: 0.5),
            ],
          ),
        ),
        child: remindersAsync.when(
        loading: () => const AppListLoadingSkeleton(itemCount: 4),
        error: (err, stack) => AppStatusView(
          icon: Icons.error_outline,
          title: 'Could not load reminders',
          message: err.toString(),
          actionLabel: 'Retry',
          onAction: () => ref.invalidate(remindersProvider),
        ),
        data: (reminders) {
          if (reminders.isEmpty) {
            return const AppStatusView(
              icon: Icons.notifications_none,
              title: 'No reminders yet',
              message: 'Create reminders for rent, bills, and repayments.',
            );
          }

          final upcoming = reminders.where((r) => !r.completed).toList();
          final completed = reminders.where((r) => r.completed).toList();
          final entries = <_ReminderListEntry>[];

          if (upcoming.isNotEmpty) {
            entries.add(const _ReminderListEntry.header('Upcoming'));
            for (final reminder in upcoming) {
              entries.add(_ReminderListEntry.reminder(reminder));
            }
            entries.add(const _ReminderListEntry.spacer(24));
          }

          if (completed.isNotEmpty) {
            entries.add(const _ReminderListEntry.header('Completed'));
            for (final reminder in completed) {
              entries.add(_ReminderListEntry.reminder(reminder));
            }
          }

            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: entries.length,
              itemBuilder: (context, index) {
                final entry = entries[index];
                switch (entry.type) {
                  case _ReminderEntryType.header:
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12, top: 4),
                      child: Text(
                        entry.label!,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: AppTheme.secondary,
                              letterSpacing: 0.5,
                            ),
                      ),
                    );
                  case _ReminderEntryType.spacer:
                    return SizedBox(height: entry.spacerHeight);
                  case _ReminderEntryType.reminder:
                    return _ReminderTile(reminder: entry.reminder!);
                }
              },
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          showModalBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (context) => const AddReminderSheet(),
          );
        },
        tooltip: 'Add reminder',
        child: const Icon(Icons.add),
      ),
    );
  }
}

enum _ReminderEntryType {
  header,
  reminder,
  spacer,
}

class _ReminderListEntry {
  const _ReminderListEntry._({
    required this.type,
    this.label,
    this.reminder,
    this.spacerHeight = 0,
  });

  const _ReminderListEntry.header(String label)
      : this._(
          type: _ReminderEntryType.header,
          label: label,
        );

  const _ReminderListEntry.reminder(Reminder reminder)
      : this._(
          type: _ReminderEntryType.reminder,
          reminder: reminder,
        );

  const _ReminderListEntry.spacer(double height)
      : this._(
          type: _ReminderEntryType.spacer,
          spacerHeight: height,
        );

  final _ReminderEntryType type;
  final String? label;
  final Reminder? reminder;
  final double spacerHeight;
}

class _ReminderTile extends ConsumerStatefulWidget {
  const _ReminderTile({required this.reminder});

  final Reminder reminder;

  @override
  ConsumerState<_ReminderTile> createState() => _ReminderTileState();
}

class _ReminderTileState extends ConsumerState<_ReminderTile> {
  bool? _optimisticCompleted;
  bool _updating = false;

  Future<void> _toggleReminder() async {
    if (_updating) {
      return;
    }

    final nextValue = !(widget.reminder.completed);
    setState(() {
      _optimisticCompleted = nextValue;
      _updating = true;
    });

    await ref.read(remindersControllerProvider.notifier).toggleReminder(widget.reminder);

    if (mounted) {
      setState(() {
        _optimisticCompleted = null;
        _updating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final formatter = DateFormat('MMM d, yyyy · h:mm a');
    final effectiveCompleted = _optimisticCompleted ?? widget.reminder.completed;
    final isOverdue = !effectiveCompleted && widget.reminder.reminderDate.isBefore(DateTime.now());

    return GlassCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      accentColor: isOverdue ? AppTheme.error : (effectiveCompleted ? AppTheme.muted : AppTheme.secondary),
      child: Row(
        children: [
          Checkbox(
            value: effectiveCompleted,
            activeColor: AppTheme.secondary,
            checkColor: AppTheme.background,
            onChanged: _updating ? null : (val) => _toggleReminder(),
          ),
          const AppSpacing.horizontal(8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.reminder.title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        decoration: effectiveCompleted ? TextDecoration.lineThrough : null,
                        color: effectiveCompleted ? AppTheme.muted : AppTheme.onSurface,
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const AppSpacing.vertical(4),
                Row(
                  children: [
                    Icon(
                      Icons.access_time_rounded,
                      size: 14,
                      color: isOverdue ? AppTheme.error : AppTheme.onSurfaceVariant,
                    ),
                    const AppSpacing.horizontal(6),
                    Text(
                      formatter.format(widget.reminder.reminderDate),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: isOverdue ? AppTheme.error : AppTheme.onSurfaceVariant,
                            fontWeight: isOverdue ? FontWeight.bold : null,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: AppTheme.muted, size: 22),
            onPressed: _updating
                ? null
                : () {
                    ref.read(remindersControllerProvider.notifier).deleteReminder(widget.reminder);
                  },
            tooltip: 'Delete reminder',
          ),
        ],
      ),
    );
  }
}

class AddReminderSheet extends ConsumerStatefulWidget {
  const AddReminderSheet({
    super.key,
    this.initialTitle,
    this.initialType,
  });

  final String? initialTitle;
  final String? initialType;

  @override
  ConsumerState<AddReminderSheet> createState() => _AddReminderSheetState();
}

class _AddReminderSheetState extends ConsumerState<AddReminderSheet> {
  late final TextEditingController _titleController;
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  late String _selectedType;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle);
    _selectedType = widget.initialType ?? 'BILL';
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) {
      setState(() => _selectedDate = date);
    }
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );
    if (time != null) {
      setState(() => _selectedTime = time);
    }
  }

  void _submit() {
    final title = _titleController.text.trim();
    if (title.isEmpty || _selectedDate == null || _selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    final reminderDate = DateTime(
      _selectedDate!.year,
      _selectedDate!.month,
      _selectedDate!.day,
      _selectedTime!.hour,
      _selectedTime!.minute,
    );

    if (reminderDate.isBefore(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Time must be in the future')),
      );
      return;
    }

    ref.read(remindersControllerProvider.notifier).addReminder(title, reminderDate, _selectedType);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final dateFormatter = DateFormat('MMM d, yyyy');

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Padding(
        padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'New Reminder',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: AppTheme.secondary,
                    ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _titleController,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                decoration: const InputDecoration(
                  labelText: 'Title (e.g. Pay Rent)',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType,
                decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
                items: const [
                  DropdownMenuItem(value: 'BILL', child: Text('Bill')),
                  DropdownMenuItem(value: 'RENT', child: Text('Rent')),
                  DropdownMenuItem(value: 'DEBT', child: Text('Debt')),
                ],
                onChanged: (val) {
                  if (val != null) setState(() => _selectedType = val);
                },
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickDate,
                      icon: const Icon(Icons.calendar_today),
                      label: Text(_selectedDate == null ? 'Select Date' : dateFormatter.format(_selectedDate!)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _pickTime,
                      icon: const Icon(Icons.access_time),
                      label: Text(_selectedTime == null ? 'Select Time' : _selectedTime!.format(context)),
                    ),
                  ),
                ],
              ),
              const AppSpacing.vertical(AppTheme.space300),
              ActionButton(
                label: 'Save Reminder',
                icon: Icons.check_rounded,
                onPressed: _submit,
                variant: ActionButtonVariant.primary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
