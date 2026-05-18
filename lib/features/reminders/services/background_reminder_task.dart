import 'package:flutter/services.dart';
import 'package:roomledger/core/database/roomledger_database.dart';
import 'package:roomledger/features/reminders/data/reminders_repository.dart';

/// MethodChannel that bridges to Android SmsManager.
const _smsChannel = MethodChannel('roomledger/sms');

class BackgroundReminderTask {
  /// Executed by WorkManager
  static Future<void> execute() async {
    final dbInstance = RoomLedgerDatabase();
    final remindersRepo = RemindersRepository(dbInstance);

    // 1. Read User Reminder Settings
    final settings = await remindersRepo.getReminderSettings();
    if (settings.autoSendEnabled == 0) {
      return; // Automated messages are completely disabled
    }

    // 2. Fetch outstanding debts
    final pendingDebts = await remindersRepo.getPendingDebtsGroupedByFriend();

    for (final record in pendingDebts) {
      // Send reminder if roommate has unpaid debts and a valid phone number
      if (record.remainingAmount > 0 &&
          record.phoneNumber != null &&
          record.phoneNumber!.isNotEmpty) {
        // Dynamic template utilizing custom Sender Name
        final message =
            'Hey ${record.friendName}! This is a friendly automated reminder from '
            '${settings.senderName} via RoomLedger. You have a pending split balance of '
            '₹${record.remainingAmount} outstanding. You can pay me via UPI or Cash. Thank you! 😊';

        try {
          String cleanPhone = record.phoneNumber!.replaceAll(RegExp(r'[^\d]'), '');
          if (cleanPhone.startsWith('0') && cleanPhone.length == 11) {
            cleanPhone = cleanPhone.substring(1);
          }
          if (cleanPhone.length == 10) {
            cleanPhone = '91$cleanPhone'; // Prepend India country code (+91)
          }

          await _smsChannel.invokeMethod('sendSms', {
            'recipient': cleanPhone,
            'message': message,
          });
        } catch (e) {
          // Fail silently — SMS permission may not be granted
        }
      }
    }
  }
}
