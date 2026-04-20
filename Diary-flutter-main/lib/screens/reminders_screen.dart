import 'package:diary/main.dart';
import 'package:flutter/material.dart';
import '../services/notification_service.dart';

class RemindersScreen extends StatefulWidget {
  const RemindersScreen({super.key});

  @override
  State<RemindersScreen> createState() => _RemindersScreenState();
}

class _RemindersScreenState extends State<RemindersScreen> {
  final NotificationService _notificationService = NotificationService();

  bool _dailyReminder = false;
  TimeOfDay _reminderTime = const TimeOfDay(hour: 20, minute: 0);
  List<bool> _selectedDays = List.filled(7, false);
  bool _motivationalQuotes = true;
  bool _streakReminders = true;
  bool _weeklyReview = false;

  final List<String> _dayNames = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday'
  ];

  final List<String> _motivationalMessages = [
    "💭 Time to reflect on your day",
    "✨ A perfect moment to write",
    "📝 Capture today's thoughts",
    "🌟 Document this special moment",
    "💡 What did you learn today?",
    "🌙 End the day with a reflection",
  ];

  @override
  void initState() {
    super.initState();
    _loadCurrentSettings();
  }

  void _loadCurrentSettings() {
    final settings = _notificationService.getReminderSettings();
    setState(() {
      _dailyReminder = settings['enabled'] ?? false;
      final time = settings['time'] ?? {'hour': 20, 'minute': 0};
      _reminderTime = TimeOfDay(hour: time['hour'], minute: time['minute']);
      _selectedDays =
          List<bool>.from(settings['days'] ?? List.filled(7, false));
      _motivationalQuotes = settings['motivationalQuotes'] ?? true;
      _streakReminders = settings['streakReminders'] ?? true;
      _weeklyReview = settings['weeklyReview'] ?? false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reminders',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
              icon: Icon(
                MyDiaryApp.appKey.currentState?.isDarkMode == true
                    ? Icons.wb_sunny
                    : Icons.nightlight_round,
                size: 28,
              ),
              onPressed: () {
                MyDiaryApp.appKey.currentState?.toggleTheme();
              }),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Main Reminder Card
            _buildReminderCard(
              'Daily Reminder',
              'Receive a notification to write in your diary',
              Icons.notifications_active,
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Enable daily reminder'),
                    subtitle: Text(_dailyReminder
                        ? 'Reminder active at ${_reminderTime.format(context)}'
                        : 'Tap to enable'),
                    value: _dailyReminder,
                    onChanged: (value) {
                      setState(() {
                        _dailyReminder = value;
                      });
                      if (value) {
                        _showTimePickerDialog();
                      }
                    },
                    activeThumbColor: const Color(0xFF7B2D8E),
                  ),
                  if (_dailyReminder) ...[
                    const Divider(),
                    ListTile(
                      leading: const Icon(Icons.access_time,
                          color: Color(0xFF7B2D8E)),
                      title: const Text('Reminder time'),
                      subtitle: Text(_reminderTime.format(context)),
                      trailing: const Icon(Icons.edit),
                      onTap: _showTimePickerDialog,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Days of Week
            if (_dailyReminder) ...[
              _buildReminderCard(
                'Days of the Week',
                'Select which days you want to receive reminders',
                Icons.calendar_today,
                Column(
                  children: [
                    for (int i = 0; i < _dayNames.length; i++)
                      CheckboxListTile(
                        title: Text(_dayNames[i]),
                        value: _selectedDays[i],
                        onChanged: (value) {
                          setState(() {
                            _selectedDays[i] = value ?? false;
                          });
                        },
                        activeColor: const Color(0xFF7B2D8E),
                        dense: true,
                      ),
                    if (!_selectedDays.contains(true))
                      Container(
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border:
                              Border.all(color: Colors.orange.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.warning,
                                color: Colors.orange[700], size: 20),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Select at least one day to receive reminders',
                                style: TextStyle(fontSize: 12),
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Reminder Types
            _buildReminderCard(
              'Reminder Types',
              'Customize the types of notifications you receive',
              Icons.tune,
              Column(
                children: [
                  SwitchListTile(
                    title: const Text('Motivational quotes'),
                    subtitle: const Text('Include inspirational messages'),
                    value: _motivationalQuotes,
                    onChanged: (value) {
                      setState(() {
                        _motivationalQuotes = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF7B2D8E),
                  ),
                  SwitchListTile(
                    title: const Text('Streak reminders'),
                    subtitle:
                        const Text('Notifications about your current streak'),
                    value: _streakReminders,
                    onChanged: (value) {
                      setState(() {
                        _streakReminders = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF7B2D8E),
                  ),
                  SwitchListTile(
                    title: const Text('Weekly review'),
                    subtitle: const Text('Reminder to review your week'),
                    value: _weeklyReview,
                    onChanged: (value) {
                      setState(() {
                        _weeklyReview = value;
                      });
                    },
                    activeThumbColor: const Color(0xFF7B2D8E),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Preview
            if (_dailyReminder && _motivationalQuotes) ...[
              _buildReminderCard(
                'Preview',
                'See how your notifications will look',
                Icons.preview,
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF7B2D8E).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: const Color(0xFF7B2D8E).withOpacity(0.3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFF7B2D8E),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.edit,
                                color: Colors.white, size: 16),
                          ),
                          const SizedBox(width: 12),
                          const Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'My Diary',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                                Text(
                                  'Just now',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        _motivationalMessages[DateTime.now().second %
                            _motivationalMessages.length],
                        style: const TextStyle(fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _showTestNotification();
                    },
                    icon: const Icon(Icons.send),
                    label: const Text('Test Notification'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      side: const BorderSide(color: Color(0xFF7B2D8E)),
                      foregroundColor: const Color(0xFF7B2D8E),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: _saveSettings,
                    icon: const Icon(Icons.save),
                    label: const Text('Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7B2D8E),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Additional Information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.info_outline,
                          color: Colors.blue[700], size: 20),
                      const SizedBox(width: 8),
                      const Text(
                        'About Reminders',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Reminders help you maintain the habit of writing\n'
                    '• You can disable them at any time\n'
                    '• Notifications will only appear when the app is installed\n'
                    '• Weekly reviews are sent on Sunday evenings',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildReminderCard(
      String title, String subtitle, IconData icon, Widget content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: const Color(0xFF7B2D8E), size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            content,
          ],
        ),
      ),
    );
  }

  void _showTimePickerDialog() async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: const Color(0xFF7B2D8E),
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _reminderTime) {
      setState(() {
        _reminderTime = picked;
      });
    }
  }

  void _showTestNotification() async {
    try {
      await _notificationService.showTestNotification();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 8),
                Text('Test notification sent!'),
              ],
            ),
            backgroundColor: Color(0xFF7B2D8E),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sending notification: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _saveSettings() async {
    // Validate settings
    if (_dailyReminder && !_selectedDays.contains(true)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one day for reminders'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    try {
      // Create settings
      final settings = {
        'enabled': _dailyReminder,
        'time': {'hour': _reminderTime.hour, 'minute': _reminderTime.minute},
        'days': _selectedDays,
        'motivationalQuotes': _motivationalQuotes,
        'streakReminders': _streakReminders,
        'weeklyReview': _weeklyReview,
      };

      // Save settings and schedule notifications
      await _notificationService.saveReminderSettings(settings);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 8),
                Text(_dailyReminder
                    ? 'Reminders configured successfully'
                    : 'Reminders disabled'),
              ],
            ),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );

        // Show additional info if enabled
        if (_dailyReminder) {
          final activeDays = _selectedDays.where((day) => day).length;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  'Reminders scheduled for $activeDays ${activeDays == 1 ? 'day' : 'days'} at ${_reminderTime.format(context)}'),
              backgroundColor: const Color(0xFF7B2D8E),
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}