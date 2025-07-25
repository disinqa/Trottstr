import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tz;
import 'package:hooks_riverpod/hooks_riverpod.dart';

/// Service for managing local notifications and OS-level alarms
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  bool _isInitialized = false;

  /// Initialize the notification service
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // Initialize timezone
      tz.initializeTimeZones();

      // Android initialization
      const AndroidInitializationSettings initializationSettingsAndroid =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      // iOS initialization
      const DarwinInitializationSettings initializationSettingsIOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      // macOS initialization
      const DarwinInitializationSettings initializationSettingsMacOS =
          DarwinInitializationSettings(
            requestAlertPermission: true,
            requestBadgePermission: true,
            requestSoundPermission: true,
          );

      const InitializationSettings initializationSettings =
          InitializationSettings(
            android: initializationSettingsAndroid,
            iOS: initializationSettingsIOS,
            macOS: initializationSettingsMacOS,
          );

      await _flutterLocalNotificationsPlugin.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: _onDidReceiveNotificationResponse,
      );

      // Request permissions
      await _requestPermissions();

      _isInitialized = true;
      debugPrint('NotificationService initialized successfully');
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Request notification permissions
  Future<bool> _requestPermissions() async {
    if (Platform.isIOS || Platform.isMacOS) {
      final bool? result = await _flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
      return result ?? false;
    } else if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();

      final bool? grantedNotificationPermission = await androidImplementation
          ?.requestNotificationsPermission();
      final bool? grantedScheduleExactAlarmPermission =
          await androidImplementation?.requestExactAlarmsPermission();

      return (grantedNotificationPermission ?? false) &&
          (grantedScheduleExactAlarmPermission ?? false);
    }
    return true;
  }

  /// Handle notification tap/response
  static void _onDidReceiveNotificationResponse(
    NotificationResponse notificationResponse,
  ) async {
    final String? payload = notificationResponse.payload;
    if (payload != null) {
      debugPrint('Notification payload: $payload');
      // Handle notification tap - could navigate to specific screen
    }
  }

  /// Show immediate notification for 80% threshold reached
  Future<void> showThresholdWarningNotification({
    required String countryCode,
    required String countryName,
    required int currentDays,
    required int maxDays,
    required double percentage,
  }) async {
    if (!_isInitialized) await initialize();

    const int notificationId = 1001;

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'threshold_warnings',
          'Country Stay Threshold Warnings',
          channelDescription:
              'Notifications when approaching country stay limits',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFFF6B35), // Orange color for warnings
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
      macOS: iosNotificationDetails,
    );

    final String title = '⚠️ $countryName Stay Limit Warning';
    final String body =
        'You\'ve reached ${percentage.toStringAsFixed(1)}% of your $maxDays-day limit ($currentDays days used). '
        'Consider planning your exit to avoid tax residency issues.';

    await _flutterLocalNotificationsPlugin.show(
      notificationId,
      title,
      body,
      notificationDetails,
      payload: 'threshold_warning:$countryCode:$currentDays:$maxDays',
    );

    debugPrint('Threshold warning notification sent for $countryName');
  }

  /// Schedule a daily check notification
  Future<void> scheduleDailyStayCheck() async {
    if (!_isInitialized) await initialize();

    const int notificationId = 1002;

    // Cancel any existing daily check
    await _flutterLocalNotificationsPlugin.cancel(notificationId);

    // Schedule for 9 AM daily
    final tz.TZDateTime scheduledDate = _nextInstanceOf9AM();

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'daily_checks',
          'Daily Stay Checks',
          channelDescription:
              'Daily reminders to check your country stay status',
          importance: Importance.defaultImportance,
          priority: Priority.defaultPriority,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
      macOS: iosNotificationDetails,
    );

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      '📍 Daily Stay Check',
      'Review your current country stay status and plan ahead.',
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
      payload: 'daily_check',
    );

    debugPrint('Daily stay check scheduled for ${scheduledDate.toString()}');
  }

  /// Schedule notification for when user is approaching exit deadline
  Future<void> scheduleExitReminderNotification({
    required String countryCode,
    required String countryName,
    required DateTime suggestedExitDate,
    required int daysRemaining,
  }) async {
    if (!_isInitialized) await initialize();

    final int notificationId = 2000 + countryCode.hashCode % 1000;

    // Cancel any existing reminder for this country
    await _flutterLocalNotificationsPlugin.cancel(notificationId);

    // Schedule for 2 days before the suggested exit date at 10 AM
    final tz.TZDateTime scheduledDate = tz.TZDateTime.from(
      suggestedExitDate.subtract(const Duration(days: 2)),
      tz.local,
    ).add(const Duration(hours: 10));

    // Only schedule if the date is in the future
    if (scheduledDate.isBefore(tz.TZDateTime.now(tz.local))) {
      debugPrint('Cannot schedule exit reminder for past date');
      return;
    }

    const AndroidNotificationDetails androidNotificationDetails =
        AndroidNotificationDetails(
          'exit_reminders',
          'Country Exit Reminders',
          channelDescription:
              'Reminders to exit countries before reaching limits',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFE74C3C), // Red color for urgent reminders
          enableVibration: true,
          playSound: true,
        );

    const DarwinNotificationDetails iosNotificationDetails =
        DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          sound: 'default',
        );

    const NotificationDetails notificationDetails = NotificationDetails(
      android: androidNotificationDetails,
      iOS: iosNotificationDetails,
      macOS: iosNotificationDetails,
    );

    final String title = '🚨 Exit Reminder: $countryName';
    final String body =
        'You should consider exiting $countryName soon. You have $daysRemaining days '
        'remaining before reaching your stay limit.';

    await _flutterLocalNotificationsPlugin.zonedSchedule(
      notificationId,
      title,
      body,
      scheduledDate,
      notificationDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      uiLocalNotificationDateInterpretation:
          UILocalNotificationDateInterpretation.absoluteTime,
      payload: 'exit_reminder:$countryCode:$daysRemaining',
    );

    debugPrint(
      'Exit reminder scheduled for $countryName on ${scheduledDate.toString()}',
    );
  }

  /// Cancel all scheduled notifications
  Future<void> cancelAllNotifications() async {
    if (!_isInitialized) await initialize();
    await _flutterLocalNotificationsPlugin.cancelAll();
    debugPrint('All notifications cancelled');
  }

  /// Cancel notification for specific country
  Future<void> cancelCountryNotification(String countryCode) async {
    if (!_isInitialized) await initialize();
    final int notificationId = 2000 + countryCode.hashCode % 1000;
    await _flutterLocalNotificationsPlugin.cancel(notificationId);
    debugPrint('Cancelled notification for country: $countryCode');
  }

  /// Get next instance of 9 AM for daily scheduling
  tz.TZDateTime _nextInstanceOf9AM() {
    final tz.TZDateTime now = tz.TZDateTime.now(tz.local);
    tz.TZDateTime scheduledDate = tz.TZDateTime(
      tz.local,
      now.year,
      now.month,
      now.day,
      9,
    );

    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    return scheduledDate;
  }

  /// Check if notifications are enabled
  Future<bool> areNotificationsEnabled() async {
    if (!_isInitialized) await initialize();

    if (Platform.isAndroid) {
      final AndroidFlutterLocalNotificationsPlugin? androidImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                AndroidFlutterLocalNotificationsPlugin
              >();
      return await androidImplementation?.areNotificationsEnabled() ?? false;
    } else if (Platform.isIOS) {
      final IOSFlutterLocalNotificationsPlugin? iosImplementation =
          _flutterLocalNotificationsPlugin
              .resolvePlatformSpecificImplementation<
                IOSFlutterLocalNotificationsPlugin
              >();
      final permissions = await iosImplementation?.checkPermissions();
      return permissions?.isEnabled == true;
    }

    return true; // Default to true for other platforms
  }

  /// Get pending notifications
  Future<List<PendingNotificationRequest>> getPendingNotifications() async {
    if (!_isInitialized) await initialize();
    return await _flutterLocalNotificationsPlugin.pendingNotificationRequests();
  }
}

/// Provider for the notification service
final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService();
});
