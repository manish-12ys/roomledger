class Reminder {
  const Reminder({
    required this.id,
    required this.title,
    required this.reminderDate,
    required this.type,
    required this.completed,
  });

  final int id;
  final String title;
  final DateTime reminderDate;
  final String type; // e.g. 'BILL', 'RENT', 'DEBT'
  final bool completed;

  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as int,
      title: map['title'] as String,
      reminderDate: DateTime.parse(map['reminder_date'] as String),
      type: map['type'] as String,
      completed: (map['completed'] as int) == 1,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id > 0) 'id': id,
      'title': title,
      'reminder_date': reminderDate.toIso8601String(),
      'type': type,
      'completed': completed ? 1 : 0,
    };
  }

  Reminder copyWith({
    int? id,
    String? title,
    DateTime? reminderDate,
    String? type,
    bool? completed,
  }) {
    return Reminder(
      id: id ?? this.id,
      title: title ?? this.title,
      reminderDate: reminderDate ?? this.reminderDate,
      type: type ?? this.type,
      completed: completed ?? this.completed,
    );
  }
}

class ReminderSettings {
  const ReminderSettings({
    required this.id,
    required this.autoSendEnabled,
    required this.dispatchIntervalDays,
    required this.senderName,
  });

  final int id;
  final int autoSendEnabled;
  final int dispatchIntervalDays;
  final String senderName;

  factory ReminderSettings.fromMap(Map<String, dynamic> map) {
    return ReminderSettings(
      id: map['id'] as int,
      autoSendEnabled: map['auto_send_enabled'] as int,
      dispatchIntervalDays: map['dispatch_interval_days'] as int,
      senderName: map['sender_name'] as String,
    );
  }
}

class PendingDebtRecord {
  const PendingDebtRecord({
    required this.friendName,
    required this.remainingAmount,
    this.phoneNumber,
  });

  final String friendName;
  final int remainingAmount;
  final String? phoneNumber;
}
