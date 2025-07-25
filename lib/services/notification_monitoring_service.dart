import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/notification_service.dart';
import 'package:trottstr/services/country_tracking_service.dart';

/// Service for monitoring country stay thresholds and triggering notifications
class NotificationMonitoringService {
  final Ref _ref;
  final NotificationService _notificationService;
  Timer? _monitoringTimer;
  final Set<String> _notifiedCountries = {};

  NotificationMonitoringService(this._ref) 
    : _notificationService = NotificationService();

  /// Initialize the monitoring service
  Future<void> initialize() async {
    await _notificationService.initialize();
    await startMonitoring();
    debugPrint('NotificationMonitoringService initialized');
  }

  /// Start monitoring country stays for threshold warnings
  Future<void> startMonitoring() async {
    // Stop any existing timer
    stopMonitoring();

    // Check immediately on start
    await _checkThresholds();

    // Schedule periodic checks every hour
    _monitoringTimer = Timer.periodic(
      const Duration(hours: 1),
      (_) => _checkThresholds(),
    );

    debugPrint('Started monitoring country stay thresholds');
  }

  /// Stop monitoring
  void stopMonitoring() {
    _monitoringTimer?.cancel();
    _monitoringTimer = null;
    debugPrint('Stopped monitoring country stay thresholds');
  }

  /// Check all countries for threshold warnings
  Future<void> _checkThresholds() async {
    try {
      final trackingService = _ref.read(countryTrackingServiceProvider);
      final risks = await trackingService.calculateTaxResidencyRisks();

      for (final risk in risks.values) {
        await _checkCountryThreshold(risk);
      }
    } catch (e) {
      debugPrint('Error checking thresholds: $e');
    }
  }

  /// Check threshold for a specific country
  Future<void> _checkCountryThreshold(TaxResidencyRisk risk) async {
    // Check if 80% threshold is reached
    if (risk.percentageUsed >= 80.0) {
      final countryKey = '${risk.countryCode}_80';
      
      // Only notify once per threshold crossing
      if (!_notifiedCountries.contains(countryKey)) {
        await _notificationService.showThresholdWarningNotification(
          countryCode: risk.countryCode,
          countryName: risk.countryName,
          currentDays: risk.currentDays,
          maxDays: risk.threshold,
          percentage: risk.percentageUsed,
        );

        _notifiedCountries.add(countryKey);
        
        // Schedule exit reminder if approaching limit
        if (risk.daysRemaining > 0 && risk.daysRemaining <= 30) {
          final suggestedExitDate = DateTime.now().add(
            Duration(days: risk.daysRemaining - 5), // Exit 5 days before limit
          );
          
          await _notificationService.scheduleExitReminderNotification(
            countryCode: risk.countryCode,
            countryName: risk.countryName,
            suggestedExitDate: suggestedExitDate,
            daysRemaining: risk.daysRemaining,
          );
        }

        debugPrint('80% threshold notification sent for ${risk.countryName}');
      }
    }

    // Check if 95% threshold is reached (critical warning)
    if (risk.percentageUsed >= 95.0) {
      final countryKey = '${risk.countryCode}_95';
      
      if (!_notifiedCountries.contains(countryKey)) {
        await _showCriticalWarningNotification(risk);
        _notifiedCountries.add(countryKey);
        debugPrint('95% critical warning sent for ${risk.countryName}');
      }
    }

    // Check if limit is exceeded
    if (risk.isExceeded) {
      final countryKey = '${risk.countryCode}_exceeded';
      
      if (!_notifiedCountries.contains(countryKey)) {
        await _showLimitExceededNotification(risk);
        _notifiedCountries.add(countryKey);
        debugPrint('Limit exceeded notification sent for ${risk.countryName}');
      }
    }
  }

  /// Show critical warning notification (95% threshold)
  Future<void> _showCriticalWarningNotification(TaxResidencyRisk risk) async {
    await _notificationService.showThresholdWarningNotification(
      countryCode: risk.countryCode,
      countryName: risk.countryName,
      currentDays: risk.currentDays,
      maxDays: risk.threshold,
      percentage: risk.percentageUsed,
    );
  }

  /// Show limit exceeded notification
  Future<void> _showLimitExceededNotification(TaxResidencyRisk risk) async {
    await _notificationService.showThresholdWarningNotification(
      countryCode: risk.countryCode,
      countryName: risk.countryName,
      currentDays: risk.currentDays,
      maxDays: risk.threshold,
      percentage: risk.percentageUsed,
    );
  }

  /// Reset notification tracking for a country (when user exits)
  void resetCountryNotifications(String countryCode) {
    _notifiedCountries.removeWhere((key) => key.startsWith(countryCode));
    _notificationService.cancelCountryNotification(countryCode);
    debugPrint('Reset notifications for country: $countryCode');
  }

  /// Check and schedule notifications for current location
  Future<void> checkCurrentLocationThreshold() async {
    try {
      final trackingService = _ref.read(countryTrackingServiceProvider);
      final currentLocation = await trackingService.getCurrentLocation();
      
      if (currentLocation != null) {
        final risks = await trackingService.calculateTaxResidencyRisks();
        final currentRisk = risks[currentLocation];
        
        if (currentRisk != null) {
          await _checkCountryThreshold(currentRisk);
        }
      }
    } catch (e) {
      debugPrint('Error checking current location threshold: $e');
    }
  }

  /// Schedule daily monitoring notification
  Future<void> scheduleDailyMonitoring() async {
    await _notificationService.scheduleDailyStayCheck();
  }

  /// Get countries that have received threshold notifications
  Set<String> getNotifiedCountries() {
    return Set.from(_notifiedCountries);
  }

  /// Check if a country has been notified for a specific threshold
  bool hasBeenNotified(String countryCode, int thresholdPercentage) {
    return _notifiedCountries.contains('${countryCode}_$thresholdPercentage');
  }

  /// Clear all notification history
  void clearNotificationHistory() {
    _notifiedCountries.clear();
    debugPrint('Cleared notification history');
  }

  /// Force check thresholds (for manual testing)
  Future<void> forceCheckThresholds() async {
    await _checkThresholds();
  }

  /// Handle country entry - reset notifications and check thresholds
  Future<void> onCountryEntry(String countryCode) async {
    // Reset notifications for the new country
    resetCountryNotifications(countryCode);
    
    // Check thresholds immediately
    await checkCurrentLocationThreshold();
    
    debugPrint('Handled country entry for: $countryCode');
  }

  /// Handle country exit - cancel scheduled notifications
  Future<void> onCountryExit(String countryCode) async {
    await _notificationService.cancelCountryNotification(countryCode);
    debugPrint('Handled country exit for: $countryCode');
  }

  /// Dispose of resources
  void dispose() {
    stopMonitoring();
    debugPrint('NotificationMonitoringService disposed');
  }
}

/// Provider for the notification monitoring service
final notificationMonitoringServiceProvider = Provider<NotificationMonitoringService>((ref) {
  final service = NotificationMonitoringService(ref);
  
  // Initialize the service when first accessed
  service.initialize();
  
  // Dispose when the provider is disposed
  ref.onDispose(() {
    service.dispose();
  });
  
  return service;
});

/// Provider to automatically start monitoring when app starts
final autoStartMonitoringProvider = Provider<void>((ref) {
  // This provider automatically starts monitoring when accessed
  final service = ref.read(notificationMonitoringServiceProvider);
  return;
});