

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications =
      FlutterLocalNotificationsPlugin();

  static const String _reminderKey = 'mydiary_reminder_settings';

  // Reminder settings configuration
  Map<String, dynamic> _reminderSettings = {
    'enabled': false,
    'time': {'hour': 20, 'minute': 0},
    'days': [false, false, false, false, false, false, false], // Mon-Sun
    'motivationalQuotes': true,
    'streakReminders': true,
    'weeklyReview': false,
  };

  final List<String> _motivationalMessages = [
    "💭 Time to reflect on your day",
    "✨ A perfect moment to write",
    "📝 Capture today's thoughts",
    "🌟 Document this special moment",
    "💡 What did you learn today?",
    "🌙 End the day with a reflection",
    "🎯 Keep your writing streak going",
    "📖 Your diary is waiting for you",
    "🌅 Share your experiences from today",
    "💖 A small moment just for you",
  ];

  Future<void> initialize() async {
    // Initialize time zones
    tz.initializeTimeZones();

    // Android configuration
    const AndroidInitializationSettings androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    // iOS configuration
    const DarwinInitializationSettings iosSettings =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    // Linux configuration
    const LinuxInitializationSettings linuxSettings =
        LinuxInitializationSettings(defaultActionName: 'Open MyDiary');

    const InitializationSettings settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
      linux: linuxSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Create notification channels
    await _createNotificationChannels();

    // Request permissions explicitly
    await requestPermissions();

    // Load saved settings
    await _loadReminderSettings();
  }

  Future<void> _createNotificationChannels() async {
    const AndroidNotificationChannel mainChannel = AndroidNotificationChannel(
      'main_channel',
      'Main Reminders',
      description: 'Notifications for diary writing reminders',
      importance: Importance.high,
      enableVibration: true,
      enableLights: true,
      ledColor: Color(0xFF7B2D8E),
    );

    const AndroidNotificationChannel motivationalChannel =
        AndroidNotificationChannel(
      'motivational_channel',
      'Motivational Messages',
      description: 'Motivational messages for diary writing',
      importance: Importance.defaultImportance,
      enableVibration: true,
    );

    const AndroidNotificationChannel weeklyChannel = AndroidNotificationChannel(
      'weekly_channel',
      'Weekly Summaries',
      description: 'Reminders to review your week',
      importance: Importance.high,
      enableVibration: true,
    );

    final androidImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    if (androidImplementation != null) {
      await androidImplementation.createNotificationChannel(mainChannel);
      await androidImplementation
          .createNotificationChannel(motivationalChannel);
      await androidImplementation.createNotificationChannel(weeklyChannel);
    }
  }

  Future<void> _onNotificationTapped(NotificationResponse response) async {
    // Handle when user taps on notification
    print('Notification tapped: ${response.payload}');
  }

  Future<bool> requestPermissions() async {
    // For Android 13+
    if (await _notifications
            .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin>()
            ?.requestNotificationsPermission() ??
        false) {
      return true;
    }

    // For iOS
    final iosImplementation =
        _notifications.resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin>();

    if (iosImplementation != null) {
      final result = await iosImplementation.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return result ?? false;
    }

    return true; // For desktop, assume it's allowed
  }

  Future<void> _loadReminderSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsJson = prefs.getString(_reminderKey);

      if (settingsJson != null) {
        _reminderSettings = json.decode(settingsJson);
      }
    } catch (e) {
      print('Error loading reminder settings: $e');
    }
  }

  Future<void> saveReminderSettings(Map<String, dynamic> settings) async {
    try {
      _reminderSettings = settings;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_reminderKey, json.encode(settings));

      // Reschedule reminders
      await _scheduleReminders();
    } catch (e) {
      print('Error saving reminder settings: $e');
    }
  }

  Map<String, dynamic> getReminderSettings() {
    return Map<String, dynamic>.from(_reminderSettings);
  }

  Future<void> _scheduleReminders() async {
    // Cancel all existing notifications
    await _notifications.cancelAll();

    if (!_reminderSettings['enabled']) {
      return;
    }

    final time = _reminderSettings['time'];
    final days = List<bool>.from(_reminderSettings['days']);

    // Schedule notifications for each selected day
    for (int i = 0; i < days.length; i++) {
      if (days[i]) {
        await _scheduleDailyNotification(
          i + 1, // 1=Monday, 7=Sunday
          time['hour'],
          time['minute'],
        );
      }
    }

    // Schedule weekly review if enabled
    if (_reminderSettings['weeklyReview']) {
      await _scheduleWeeklyReview();
    }
  }

  Future<void> _scheduleDailyNotification(
      int weekday, int hour, int minute) async {
    try {
      final scheduledDate = _nextInstanceOfWeekday(weekday, hour, minute);

      print(
          'Scheduling notification for: $scheduledDate (day $weekday, time $hour:$minute)');

      String message = _getRandomMotivationalMessage();

      if (_reminderSettings['streakReminders']) {
        // You could add logic here to get the current streak
        // message += "\n🔥 Keep your writing streak";
      }

      await _notifications.zonedSchedule(
        weekday, // Unique ID for each day
        'MyDiary',
        message,
        tz.TZDateTime.from(scheduledDate, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'main_channel',
            'Main Reminders',
            channelDescription: 'Notifications for diary writing reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            enableLights: true,
            autoCancel: false,
            fullScreenIntent: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'daily_reminder',
      );

      print(
          'Notification successfully scheduled for day $weekday at $hour:$minute');
    } catch (e) {
      print('Error scheduling daily notification: $e');
    }
  }

  Future<void> _scheduleWeeklyReview() async {
    try {
      // Schedule for Sunday at 7:00 PM
      final nextSunday = _nextInstanceOfWeekday(7, 19, 0);

      await _notifications.zonedSchedule(
        100, // Unique ID for weekly summary
        'Weekly Summary - MyDiary',
        '📊 Review your writing week and reflect on your experiences',
        tz.TZDateTime.from(nextSunday, tz.local),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_channel',
            'Weekly Summaries',
            channelDescription: 'Weekly notification to review your progress',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
        payload: 'weekly_review',
      );
    } catch (e) {
      print('Error scheduling weekly review: $e');
    }
  }

  DateTime _nextInstanceOfWeekday(int weekday, int hour, int minute) {
    final now = DateTime.now();
    final currentWeekday = now.weekday;

    int daysToAdd = weekday - currentWeekday;
    if (daysToAdd <= 0) {
      daysToAdd += 7; // Next week
    }

    final scheduledDate = DateTime(
      now.year,
      now.month,
      now.day + daysToAdd,
      hour,
      minute,
    );

    // If it's the same day but the time has already passed, schedule for next week
    if (weekday == currentWeekday && scheduledDate.isBefore(now)) {
      return scheduledDate.add(const Duration(days: 7));
    }

    return scheduledDate;
  }

  // Method to test notifications immediately
  Future<void> testNotification() async {
    try {
      await _notifications.show(
        999, // Unique test ID
        'Test Notification',
        'This is a test notification to verify everything is working correctly 📱',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'main_channel',
            'Main Reminders',
            channelDescription: 'Notifications for diary writing reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
            enableVibration: true,
            enableLights: true,
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'test_notification',
      );
      print('Test notification sent');
    } catch (e) {
      print('Error sending test notification: $e');
    }
  }

  String _getRandomMotivationalMessage() {
    if (!_reminderSettings['motivationalQuotes']) {
      return "Time to write in your diary";
    }

    final random =
        DateTime.now().millisecondsSinceEpoch % _motivationalMessages.length;
    return _motivationalMessages[random];
  }

  Future<void> showTestNotification() async {
    try {
      await _notifications.show(
        999, // Temporary test ID
        'MyDiary - Test',
        _getRandomMotivationalMessage(),
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'main_channel',
            'Main Reminders',
            channelDescription: 'Notifications for diary writing reminders',
            importance: Importance.high,
            priority: Priority.high,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: 'test_notification',
      );
    } catch (e) {
      print('Error showing test notification: $e');
    }
  }

  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    return await _notifications.pendingNotificationRequests();
  }

  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  Future<void> cancelNotification(int id) async {
    await _notifications.cancel(id);
  }
}