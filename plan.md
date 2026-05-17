# 🤖 RoomLedger Automated SMS Reminders Plan (Android-Only)

This document outlines a complete, production-ready, offline-first plan to implement automated carrier-SMS reminders for **Android**. Because RoomLedger is an Android-only, 100% offline application, we can implement this feature **completely free** using your phone's native carrier network.

---

## 🏛️ Background Automated Architecture

Since this is an Android-first project, the architecture centers around a native **WorkManager Periodic Background Task** that runs on a recurring schedule to query debts and programmatically dispatch SMS reminders, personalized with the sender's custom name.

```
                      ┌─────────────────────────────────┐
                      │    WorkManager Background Task  │
                      │       (Fires every N days)      │
                      └────────────────┬────────────────┘
                                       │
                                       ▼
                      ┌─────────────────────────────────┐
                      │    Read `reminder_settings`     │
                      │   - auto_send_enabled (Toggle)  │
                      │   - dispatch_interval_days      │
                      │   - sender_name (Custom Sign)   │
                      └────────────────┬────────────────┘
                                       │
                ┌──────────────────────┴──────────────────────┐
                ▼ (If Enabled & Interval Met)                 ▼ (If Disabled)
      ┌─────────────────────────────────┐               ┌─────────────────────────┐
      │  Queries active pending debts   │               │      Sleep Task         │
      │    that have phone numbers      │               └─────────────────────────┘
      └────────────────┬────────────────┘
                       │
                       ▼
      ┌─────────────────────────────────┐
      │     Personalized Carrier SMS    │
      │     Signed with `sender_name`    │
      └─────────────────────────────────┘
```

---

## 💾 1. Database & Profile Settings Integration

We will introduce a new schema table `reminder_settings` to keep track of the toggle configuration, selected dispatch frequency, and custom sender name.

### SQLite Schema Migration:
In `lib/core/database/roomledger_database.dart`, we will execute a database schema migration inside `onUpgrade` and `_createSchema`:

```sql
CREATE TABLE IF NOT EXISTS reminder_settings (
  id INTEGER PRIMARY KEY,
  auto_send_enabled INTEGER DEFAULT 1,       -- 0 = Disabled, 1 = Enabled
  dispatch_interval_days INTEGER DEFAULT 5,  -- Range: 5 to 10 days
  sender_name TEXT DEFAULT 'User'            -- Personalized name in SMS
);

-- Seed with initial default settings on table creation
INSERT OR IGNORE INTO reminder_settings (id, auto_send_enabled, dispatch_interval_days, sender_name) 
VALUES (1, 1, 5, 'User');
```

### Roommate Contact Update:
Roommate details in `friends` table are extended to store a nullable `phone_number TEXT` column to direct programmatic SMS.

---

## 🛠️ 2. WorkManager & Background Dispatcher Service

We use the standard Android WorkManager background thread to run the periodic task. It checks if auto-send is allowed, reads the sender's customized name, and triggers SMS reminders.

### Dynamic SMS Message Template:
The service compiles a custom message template appending the user's name:

```dart
final message = 
    'Hey ${record.friendName}! This is a friendly automated reminder from '
    '${settings.senderName} via RoomLedger. You have a pending split balance of '
    '₹${record.remainingAmount} outstanding. You can pay me via UPI or Cash. Thank you! 😊';
```

### Programmatic Carrier SMS Service:
We use a platform channel wrapper to dispatch carrier SMS silently in the background:

```dart
import 'package:flutter_sms_plus/flutter_sms_plus.dart';

class BackgroundReminderTask {
  /// Executed by WorkManager
  static Future<void> execute() async {
    final db = RoomLedgerDatabase();
    
    // 1. Read User Reminder Settings
    final settings = await db.getReminderSettings();
    if (settings.autoSendEnabled == 0) {
      return; // Automated messages are completely disabled
    }

    // 2. Fetch outstanding debts
    final pendingDebts = await db.getPendingDebtsGroupedByFriend();

    for (final record in pendingDebts) {
      // Send reminder if roommate has unpaid debts and a valid phone number
      if (record.remainingAmount > 0 && record.phoneNumber != null) {
        
        // Dynamic template utilizing custom Sender Name
        final message = 
            'Hey ${record.friendName}! This is a friendly automated reminder from '
            '${settings.senderName} via RoomLedger. You have a pending split balance of '
            '₹${record.remainingAmount} outstanding. You can pay me via UPI or Cash. Thank you! 😊';

        try {
          // Silent carrier SMS dispatch
          await FlutterSmsPlus.sendSms(
            recipient: record.phoneNumber!,
            message: message,
            runInBackground: true, // Native background dispatcher
          );
        } catch (e) {
          // Catch and handle fails silently
        }
      }
    }
  }
}
```

---

## 📱 3. Premium Settings UI (AMOLED Switch, Interval & Sender Name)

We will introduce a beautiful settings card in the **Profile/Settings Screen** to toggle this automation, choose the interval, and sign the SMS with a custom sender name.

### Settings UI Widget:
```dart
class AutoReminderSettingsCard extends StatelessWidget {
  const AutoReminderSettingsCard({
    required this.isEnabled,
    required this.intervalDays,
    required this.senderName,
    required this.onToggle,
    required this.onIntervalChanged,
    required this.onSenderNameChanged,
  });

  final bool isEnabled;
  final int intervalDays;
  final String senderName;
  final ValueChanged<bool> onToggle;
  final ValueChanged<int> onIntervalChanged;
  final ValueChanged<String> onSenderNameChanged;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Automated SMS Reminders',
                    style: TextStyle(
                      fontSize: 16, 
                      fontWeight: FontWeight.bold, 
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Sends automated split bills to roommates via carrier SMS.',
                    style: TextStyle(color: AppTheme.muted, fontSize: 11),
                  ),
                ],
              ),
              Switch(
                value: isEnabled,
                activeColor: AppTheme.secondary,
                onChanged: onToggle,
              ),
            ],
          ),
          if (isEnabled) ...[
            const Divider(height: 24, color: AppTheme.surfaceElevated),
            // Sender Name input field
            TextFormField(
              initialValue: senderName,
              onChanged: onSenderNameChanged,
              decoration: const InputDecoration(
                labelText: 'Your Name (Appended to SMS)',
                hintText: 'Enter your name...',
                prefixIcon: Icon(Icons.person_rounded),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Send Frequency Interval',
                  style: TextStyle(
                    fontSize: 14, 
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                DropdownButton<int>(
                  value: intervalDays,
                  dropdownColor: AppTheme.surfaceContainer,
                  items: List.generate(6, (index) => index + 5).map((days) {
                    return DropdownMenuItem(
                      value: days,
                      child: Text('$days Days'),
                    );
                  }).toList(),
                  onChanged: (days) {
                    if (days != null) onIntervalChanged(days);
                  },
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
```

---

## 📈 4. Step-by-Step Implementation Plan

| Step | Scope | Description |
|---|---|---|
| **Step 1** | **Database updates** | Add `reminder_settings` table (including `sender_name TEXT`) to DB schema and add a `phone_number` TEXT column to the `friends` table. Seeding initial settings. |
| **Step 2** | **Settings UI Screen** | Implement the toggle switch, the custom Sender Name input, and the 5-10 days interval frequency dropdown selector inside the Settings UI. |
| **Step 3** | **Manual UI Actions** | Add manual **"Send SMS"** / **"WhatsApp Share"** buttons on individual friend cards for on-demand actions. |
| **Step 4** | **WorkManager Hook** | Configure `workmanager` in your project to periodic schedule `BackgroundReminderTask` based on the frequency selected by the user. |
| **Step 5** | **SMS Carrier Hook** | Integrate programmatic `flutter_sms_plus` carrier dispatching inside the background task, incorporating `senderName` dynamically. |
