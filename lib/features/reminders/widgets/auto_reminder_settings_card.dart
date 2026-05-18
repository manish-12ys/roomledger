import 'package:flutter/material.dart';
import 'package:roomledger/core/theme/app_theme.dart';
import 'package:roomledger/core/widgets/app_components.dart';

class AutoReminderSettingsCard extends StatelessWidget {
  const AutoReminderSettingsCard({
    super.key,
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
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
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
                      softWrap: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Switch(
                value: isEnabled,
                activeThumbColor: AppTheme.secondary,
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
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'Your Name (Appended to SMS)',
                labelStyle: TextStyle(color: AppTheme.muted),
                hintText: 'Enter your name...',
                hintStyle: TextStyle(color: AppTheme.muted),
                prefixIcon: Icon(Icons.person_rounded, color: AppTheme.muted),
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
                  style: const TextStyle(color: Colors.white),
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
