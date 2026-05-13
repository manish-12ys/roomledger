import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

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
      body: remindersAsync.when(
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
            padding: const EdgeInsets.all(16),
            itemCount: entries.length,
            itemBuilder: (context, index) {
              final entry = entries[index];
              switch (entry.type) {
                case _ReminderEntryType.header:
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      entry.label!,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
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

    return Card(
      child: ListTile(
        leading: Checkbox(
          value: effectiveCompleted,
          onChanged: _updating ? null : (val) => _toggleReminder(),
        ),
        title: Text(
          widget.reminder.title,
          style: TextStyle(
            decoration: effectiveCompleted ? TextDecoration.lineThrough : null,
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Text(
          formatter.format(widget.reminder.reminderDate),
          style: TextStyle(
            color: isOverdue ? Theme.of(context).colorScheme.error : null,
            fontWeight: isOverdue ? FontWeight.bold : null,
          ),
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          onPressed: _updating
              ? null
              : () {
                  ref.read(remindersControllerProvider.notifier).deleteReminder(widget.reminder);
                },
          tooltip: 'Delete reminder',
        ),
        enabled: !_updating,
        horizontalTitleGap: 8,
        minLeadingWidth: 16,
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
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
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
              const SizedBox(height: 24),
              Semantics(
                button: true,
                label: 'Save reminder',
                child: FilledButton(
                  onPressed: _submit,
                  child: const Text('Save Reminder'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
