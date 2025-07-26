import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/tax_residency_service.dart';
import 'package:timezone/timezone.dart' as tz;

/// Provider for tax residency notification service
final taxResidencyNotificationServiceProvider = Provider<TaxResidencyNotificationService>((ref) {
  return TaxResidencyNotificationService(ref);
});

/// Service for managing tax residency notifications
class TaxResidencyNotificationService {
  final Ref _ref;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  Timer? _monitoringTimer;

  TaxResidencyNotificationService(this._ref);

  /// Initialize the notification service
  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: _onNotificationTapped,
    );

    // Request permissions
    await _requestPermissions();
  }

  /// Request notification permissions
  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
        
    await _notifications
        .resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>()
        ?.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
  }

  /// Handle notification tap
  void _onNotificationTapped(NotificationResponse response) {
    // Handle navigation to relevant screen
    // This could navigate to a tax residency details screen
    debugPrint('Tax residency notification tapped: ${response.payload}');
  }

  /// Start monitoring for tax residency issues
  Future<void> startMonitoring({Duration interval = const Duration(hours: 6)}) async {
    _monitoringTimer?.cancel();
    
    // Run initial check
    await _checkAndNotify();
    
    // Schedule periodic checks
    _monitoringTimer = Timer.periodic(interval, (_) async {
      await _checkAndNotify();
    });
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
  }

  /// Check current status and send notifications if needed
  Future<void> _checkAndNotify() async {
    try {
      final taxService = _ref.read(taxResidencyServiceProvider);
      final countriesAtRisk = await taxService.getCountriesAtRisk();
      
      for (final status in countriesAtRisk) {
        await _sendTaxResidencyNotification(status);
      }
      
      // Check for countries over limit
      final countriesOverLimit = await taxService.getCountriesOverLimit();
      for (final status in countriesOverLimit) {
        await _sendOverLimitNotification(status);
      }
      
    } catch (e) {
      debugPrint('Error checking tax residency status: $e');
    }
  }

  /// Send notification for countries at risk
  Future<void> _sendTaxResidencyNotification(TaxResidencyStatus status) async {
    final notificationId = status.countryCode.hashCode;
    
    // Don't spam notifications - check if we already sent one recently
    if (await _wasRecentlySent(notificationId)) {
      return;
    }
    
    final title = '⚠️ Tax Residency Warning';
    final body = status.isOverLimit
        ? 'You have exceeded the ${status.rule.maxDays}-day limit for ${status.rule.countryName} '
          'by ${-status.daysRemaining} days'
        : 'You have ${status.daysRemaining} days remaining before reaching the tax residency '
          'threshold for ${status.rule.countryName}';

    await _notifications.show(
      notificationId,
      title,
      body,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'tax_residency_warnings',
          'Tax Residency Warnings',
          channelDescription: 'Notifications about approaching tax residency limits',
          importance: status.isOverLimit ? Importance.max : Importance.high,
          priority: status.isOverLimit ? Priority.max : Priority.high,
          icon: '@mipmap/ic_launcher',
          color: _getColorForRisk(status.riskLevel) != null ? Color(_getColorForRisk(status.riskLevel)!) : null,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: status.isOverLimit 
              ? InterruptionLevel.critical 
              : InterruptionLevel.active,
        ),
      ),
      payload: 'tax_residency:${status.countryCode}',
    );

    await _markAsSent(notificationId);
  }

  /// Send notification for countries over limit
  Future<void> _sendOverLimitNotification(TaxResidencyStatus status) async {
    final notificationId = '${status.countryCode}_overlimit'.hashCode;
    
    if (await _wasRecentlySent(notificationId)) {
      return;
    }
    
    const title = '🚨 Tax Residency Limit Exceeded';
    final body = 'You have spent ${status.totalDaysIncludingPlanned} days in ${status.rule.countryName} '
        'this year, exceeding the ${status.rule.maxDays}-day limit by ${-status.daysRemaining} days. '
        'You may be considered a tax resident.';

    await _notifications.show(
      notificationId,
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'tax_residency_critical',
          'Critical Tax Residency Alerts',
          channelDescription: 'Critical notifications about exceeded tax residency limits',
          importance: Importance.max,
          priority: Priority.max,
          icon: '@mipmap/ic_launcher',
          color: Color(0xFFD32F2F), // Red
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: InterruptionLevel.critical,
        ),
      ),
      payload: 'tax_residency_critical:${status.countryCode}',
    );

    await _markAsSent(notificationId);
  }

  /// Schedule notification for planned trip warnings
  Future<void> scheduleWarnignForPlannedTrip({
    required String countryCode,
    required DateTime tripStartDate,
    required List<TaxResidencyWarning> warnings,
  }) async {
    for (int i = 0; i < warnings.length; i++) {
      final warning = warnings[i];
      final notificationId = '${countryCode}_planned_${tripStartDate.millisecondsSinceEpoch}_$i'.hashCode;
      
      // Schedule notification 1 day before trip
      final scheduledDate = tripStartDate.subtract(const Duration(days: 1));
      
      if (scheduledDate.isBefore(DateTime.now())) {
        // If trip is today or past, send immediately
        await _sendPlannedTripNotification(warning, notificationId);
      } else {
        // Schedule for future
        await _notifications.zonedSchedule(
          notificationId,
          '📅 Upcoming Trip Warning',
          warning.message,
          tz.TZDateTime.from(scheduledDate, tz.local),
          NotificationDetails(
            android: AndroidNotificationDetails(
              'planned_trip_warnings',
              'Planned Trip Warnings',
              channelDescription: 'Warnings about planned trips affecting tax residency',
              importance: _getImportanceForSeverity(warning.severity),
              priority: _getPriorityForSeverity(warning.severity),
              icon: '@mipmap/ic_launcher',
            ),
            iOS: DarwinNotificationDetails(
              presentAlert: true,
              presentBadge: true,
              presentSound: true,
              interruptionLevel: _getInterruptionLevelForSeverity(warning.severity),
            ),
          ),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: 'planned_trip:$countryCode',
          uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        );
      }
    }
  }

  /// Send notification for planned trip warning
  Future<void> _sendPlannedTripNotification(TaxResidencyWarning warning, int notificationId) async {
    await _notifications.show(
      notificationId,
      '📅 Planned Trip Warning',
      warning.message,
      NotificationDetails(
        android: AndroidNotificationDetails(
          'planned_trip_warnings',
          'Planned Trip Warnings',
          channelDescription: 'Warnings about planned trips affecting tax residency',
          importance: _getImportanceForSeverity(warning.severity),
          priority: _getPriorityForSeverity(warning.severity),
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
          interruptionLevel: _getInterruptionLevelForSeverity(warning.severity),
        ),
      ),
      payload: 'planned_trip:${warning.countryCode}',
    );
  }

  /// Send weekly summary notification
  Future<void> sendWeeklySummary() async {
    try {
      final taxService = _ref.read(taxResidencyServiceProvider);
      final summary = await taxService.generateYearSummary();
      
      const title = '📊 Weekly Tax Residency Summary';
      final body = 'Countries visited: ${summary.totalCountries}\n'
          'Days traveled: ${summary.totalDaysTraveled}\n'
          'Countries at risk: ${summary.countriesAtRisk}\n'
          '${summary.overallRiskAssessment}';

      await _notifications.show(
        'weekly_summary'.hashCode,
        title,
        body,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'weekly_summaries',
            'Weekly Summaries',
            channelDescription: 'Weekly summaries of tax residency status',
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
            icon: '@mipmap/ic_launcher',
          ),
          iOS: DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: false,
          ),
        ),
        payload: 'weekly_summary',
      );
    } catch (e) {
      debugPrint('Error sending weekly summary: $e');
    }
  }

  /// Cancel all pending notifications
  Future<void> cancelAllNotifications() async {
    await _notifications.cancelAll();
  }

  /// Cancel notifications for a specific country
  Future<void> cancelNotificationsForCountry(String countryCode) async {
    // Cancel monitoring notification
    await _notifications.cancel(countryCode.hashCode);
    
    // Cancel over limit notification  
    await _notifications.cancel('${countryCode}_overlimit'.hashCode);
  }

  /// Get color for risk level
  int? _getColorForRisk(RiskLevel risk) {
    switch (risk) {
      case RiskLevel.low:
        return 0xFF4CAF50; // Green
      case RiskLevel.medium:
        return 0xFFFF9800; // Orange
      case RiskLevel.high:
        return 0xFFF44336; // Red
      case RiskLevel.critical:
        return 0xFFD32F2F; // Dark Red
    }
  }

  /// Get importance level for warning severity
  Importance _getImportanceForSeverity(WarningSeventeenity severity) {
    switch (severity) {
      case WarningSeventeenity.low:
        return Importance.low;
      case WarningSeventeenity.medium:
        return Importance.defaultImportance;
      case WarningSeventeenity.high:
        return Importance.high;
      case WarningSeventeenity.critical:
        return Importance.max;
    }
  }

  /// Get priority level for warning severity
  Priority _getPriorityForSeverity(WarningSeventeenity severity) {
    switch (severity) {
      case WarningSeventeenity.low:
        return Priority.low;
      case WarningSeventeenity.medium:
        return Priority.defaultPriority;
      case WarningSeventeenity.high:
        return Priority.high;
      case WarningSeventeenity.critical:
        return Priority.max;
    }
  }

  /// Get interruption level for warning severity (iOS)
  InterruptionLevel _getInterruptionLevelForSeverity(WarningSeventeenity severity) {
    switch (severity) {
      case WarningSeventeenity.low:
        return InterruptionLevel.passive;
      case WarningSeventeenity.medium:
        return InterruptionLevel.active;
      case WarningSeventeenity.high:
        return InterruptionLevel.timeSensitive;
      case WarningSeventeenity.critical:
        return InterruptionLevel.critical;
    }
  }

  /// Simple storage for tracking sent notifications (in production, use proper storage)
  final Map<int, DateTime> _sentNotifications = {};

  /// Check if notification was recently sent (within 24 hours)
  Future<bool> _wasRecentlySent(int notificationId) async {
    final lastSent = _sentNotifications[notificationId];
    if (lastSent == null) return false;
    
    return DateTime.now().difference(lastSent).inHours < 24;
  }

  /// Mark notification as sent
  Future<void> _markAsSent(int notificationId) async {
    _sentNotifications[notificationId] = DateTime.now();
    
    // Clean up old entries (older than 48 hours)
    final cutoff = DateTime.now().subtract(const Duration(hours: 48));
    _sentNotifications.removeWhere((key, value) => value.isBefore(cutoff));
  }

  /// Schedule daily monitoring check
  Future<void> scheduleDailyMonitoring() async {
    // Cancel existing scheduled notifications
    await _notifications.cancel('daily_check'.hashCode);
    
    // Schedule daily check at 9 AM
    final now = DateTime.now();
    var scheduledDate = DateTime(now.year, now.month, now.day, 9, 0);
    
    // If 9 AM today has passed, schedule for tomorrow
    if (scheduledDate.isBefore(now)) {
      scheduledDate = scheduledDate.add(const Duration(days: 1));
    }

    await _notifications.zonedSchedule(
      'daily_check'.hashCode,
      'Daily Tax Residency Check',
      'Checking your tax residency status...',
      tz.TZDateTime.from(scheduledDate, tz.local),
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'daily_monitoring',
          'Daily Monitoring',
          channelDescription: 'Daily tax residency monitoring checks',
          importance: Importance.low,
          priority: Priority.low,
          icon: '@mipmap/ic_launcher',
          ongoing: false,
          autoCancel: true,
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: false,
          presentBadge: false,
          presentSound: false,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: 'daily_check',
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time, // Repeat daily
    );
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
  }
}