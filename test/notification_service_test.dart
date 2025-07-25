import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:trottstr/services/notification_service.dart';

void main() {
  group('NotificationService Tests', () {
    late NotificationService notificationService;

    setUp(() {
      notificationService = NotificationService();
      
      // Mock the platform channel to avoid errors in tests
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        (MethodCall methodCall) async {
          switch (methodCall.method) {
            case 'initialize':
              return true;
            case 'requestPermissions':
              return true;
            case 'areNotificationsEnabled':
              return true;
            case 'show':
              return null;
            case 'zonedSchedule':
              return null;
            case 'cancel':
              return null;
            case 'cancelAll':
              return null;
            case 'pendingNotificationRequests':
              return <Map<String, dynamic>>[];
            default:
              return null;
          }
        },
      );
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('dexterous.com/flutter/local_notifications'),
        null,
      );
    });

    test('should initialize without errors', () async {
      expect(() => notificationService.initialize(), returnsNormally);
    });

    test('should show threshold warning notification', () async {
      await notificationService.initialize();
      
      expect(
        () => notificationService.showThresholdWarningNotification(
          countryCode: 'US',
          countryName: 'United States',
          currentDays: 160,
          maxDays: 183,
          percentage: 87.4,
        ),
        returnsNormally,
      );
    });

    test('should schedule daily check notification', () async {
      await notificationService.initialize();
      
      expect(
        () => notificationService.scheduleDailyStayCheck(),
        returnsNormally,
      );
    });

    test('should schedule exit reminder notification', () async {
      await notificationService.initialize();
      
      final futureDate = DateTime.now().add(const Duration(days: 10));
      
      expect(
        () => notificationService.scheduleExitReminderNotification(
          countryCode: 'DE',
          countryName: 'Germany',
          suggestedExitDate: futureDate,
          daysRemaining: 20,
        ),
        returnsNormally,
      );
    });

    test('should cancel notifications', () async {
      await notificationService.initialize();
      
      expect(
        () => notificationService.cancelAllNotifications(),
        returnsNormally,
      );
      
      expect(
        () => notificationService.cancelCountryNotification('US'),
        returnsNormally,
      );
    });

    test('should check if notifications are enabled', () async {
      await notificationService.initialize();
      
      final result = await notificationService.areNotificationsEnabled();
      expect(result, isA<bool>());
    });

    test('should get pending notifications', () async {
      await notificationService.initialize();
      
      final result = await notificationService.getPendingNotifications();
      expect(result, isA<List>());
    });
  });
}