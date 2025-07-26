import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/tax_residency_service.dart';

/// Provider for current tax residency status for all countries
final allTaxResidencyStatusProvider = FutureProvider<Map<String, TaxResidencyStatus>>((ref) async {
  final service = ref.read(taxResidencyServiceProvider);
  return service.calculateAllTaxResidencyStatus();
});

/// Provider for tax residency status of a specific country
final taxResidencyStatusProvider = FutureProvider.family<TaxResidencyStatus, String>((ref, countryCode) async {
  final service = ref.read(taxResidencyServiceProvider);
  return service.calculateTaxResidencyStatus(countryCode);
});

/// Provider for countries at risk of tax residency issues
final countriesAtRiskProvider = FutureProvider<List<TaxResidencyStatus>>((ref) async {
  final service = ref.read(taxResidencyServiceProvider);
  return service.getCountriesAtRisk();
});

/// Provider for countries that have exceeded tax residency limits
final countriesOverLimitProvider = FutureProvider<List<TaxResidencyStatus>>((ref) async {
  final service = ref.read(taxResidencyServiceProvider);
  return service.getCountriesOverLimit();
});

/// Provider for tax residency summary for the current year
final taxResidencySummaryProvider = FutureProvider<TaxResidencySummary>((ref) async {
  final service = ref.read(taxResidencyServiceProvider);
  return service.generateYearSummary();
});

/// Provider for tax residency summary for a specific year
final taxResidencySummaryForYearProvider = FutureProvider.family<TaxResidencySummary, int>((ref, year) async {
  final service = ref.read(taxResidencyServiceProvider);
  return service.generateYearSummary(year);
});

/// Provider for tax rule of a specific country
final taxRuleProvider = Provider.family<TaxResidencyRule, String>((ref, countryCode) {
  final service = ref.read(taxResidencyServiceProvider);
  return service.getTaxRule(countryCode);
});

/// Provider for checking planned trip warnings
final plannedTripWarningsProvider = FutureProvider.family<List<TaxResidencyWarning>, PlannedTripParams>((ref, params) async {
  final service = ref.read(taxResidencyServiceProvider);
  return service.checkPlannedTrip(
    countryCode: params.countryCode,
    startDate: params.startDate,
    endDate: params.endDate,
  );
});

/// Provider for countries with highest usage percentage
final highestUsageCountriesProvider = FutureProvider<List<TaxResidencyStatus>>((ref) async {
  final allStatus = await ref.watch(allTaxResidencyStatusProvider.future);
  final statusList = allStatus.values.toList();
  
  statusList.sort((a, b) => b.usagePercentage.compareTo(a.usagePercentage));
  return statusList.take(5).toList(); // Top 5 countries by usage
});

/// Provider for total days traveled this year
final totalDaysTraveledProvider = FutureProvider<int>((ref) async {
  final allStatus = await ref.watch(allTaxResidencyStatusProvider.future);
  return allStatus.values.fold<int>(0, (sum, status) => sum + status.actualDaysSpent);
});

/// Provider for countries where user can safely add more days
final safeCountriesProvider = FutureProvider<List<TaxResidencyStatus>>((ref) async {
  final allStatus = await ref.watch(allTaxResidencyStatusProvider.future);
  return allStatus.values
      .where((status) => status.riskLevel == RiskLevel.low && status.safeDaysRemaining > 30)
      .toList()
    ..sort((a, b) => b.safeDaysRemaining.compareTo(a.safeDaysRemaining));
});

/// Provider for overall risk assessment
final overallRiskAssessmentProvider = FutureProvider<String>((ref) async {
  final summary = await ref.watch(taxResidencySummaryProvider.future);
  return summary.overallRiskAssessment;
});

/// Provider for monitoring status
final monitoringStatusProvider = StateProvider<bool>((ref) => false);

/// Provider for notification settings
final notificationSettingsProvider = StateProvider<NotificationSettings>((ref) {
  return const NotificationSettings();
});

/// Auto-refresh provider for tax residency data
final taxResidencyAutoRefreshProvider = StreamProvider<void>((ref) async* {
  while (true) {
    await Future.delayed(const Duration(hours: 1));
    
    // Invalidate all tax residency providers to refresh data
    ref.invalidate(allTaxResidencyStatusProvider);
    ref.invalidate(countriesAtRiskProvider);
    ref.invalidate(countriesOverLimitProvider);
    ref.invalidate(taxResidencySummaryProvider);
    ref.invalidate(highestUsageCountriesProvider);
    ref.invalidate(totalDaysTraveledProvider);
    ref.invalidate(safeCountriesProvider);
    ref.invalidate(overallRiskAssessmentProvider);
    
    yield null;
  }
});

/// Function to invalidate all tax residency providers
void invalidateTaxResidencyProviders(WidgetRef ref) {
  ref.invalidate(allTaxResidencyStatusProvider);
  ref.invalidate(countriesAtRiskProvider);
  ref.invalidate(countriesOverLimitProvider);
  ref.invalidate(taxResidencySummaryProvider);
  ref.invalidate(highestUsageCountriesProvider);
  ref.invalidate(totalDaysTraveledProvider);
  ref.invalidate(safeCountriesProvider);
  ref.invalidate(overallRiskAssessmentProvider);
}

/// Parameters for planned trip warnings
class PlannedTripParams {
  final String countryCode;
  final DateTime startDate;
  final DateTime endDate;

  const PlannedTripParams({
    required this.countryCode,
    required this.startDate,
    required this.endDate,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PlannedTripParams &&
        other.countryCode == countryCode &&
        other.startDate == startDate &&
        other.endDate == endDate;
  }

  @override
  int get hashCode => Object.hash(countryCode, startDate, endDate);
}

/// Notification settings model
class NotificationSettings {
  final bool enableDailyChecks;
  final bool enableWeeklySummary;
  final bool enablePlannedTripWarnings;
  final bool enableCriticalAlerts;
  final int warningThresholdDays;
  final TimeOfDay dailyCheckTime;

  const NotificationSettings({
    this.enableDailyChecks = true,
    this.enableWeeklySummary = true,
    this.enablePlannedTripWarnings = true,
    this.enableCriticalAlerts = true,
    this.warningThresholdDays = 30,
    this.dailyCheckTime = const TimeOfDay(hour: 9, minute: 0),
  });

  NotificationSettings copyWith({
    bool? enableDailyChecks,
    bool? enableWeeklySummary,
    bool? enablePlannedTripWarnings,
    bool? enableCriticalAlerts,
    int? warningThresholdDays,
    TimeOfDay? dailyCheckTime,
  }) {
    return NotificationSettings(
      enableDailyChecks: enableDailyChecks ?? this.enableDailyChecks,
      enableWeeklySummary: enableWeeklySummary ?? this.enableWeeklySummary,
      enablePlannedTripWarnings: enablePlannedTripWarnings ?? this.enablePlannedTripWarnings,
      enableCriticalAlerts: enableCriticalAlerts ?? this.enableCriticalAlerts,
      warningThresholdDays: warningThresholdDays ?? this.warningThresholdDays,
      dailyCheckTime: dailyCheckTime ?? this.dailyCheckTime,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableDailyChecks': enableDailyChecks,
      'enableWeeklySummary': enableWeeklySummary,
      'enablePlannedTripWarnings': enablePlannedTripWarnings,
      'enableCriticalAlerts': enableCriticalAlerts,
      'warningThresholdDays': warningThresholdDays,
      'dailyCheckTimeHour': dailyCheckTime.hour,
      'dailyCheckTimeMinute': dailyCheckTime.minute,
    };
  }

  factory NotificationSettings.fromJson(Map<String, dynamic> json) {
    return NotificationSettings(
      enableDailyChecks: json['enableDailyChecks'] ?? true,
      enableWeeklySummary: json['enableWeeklySummary'] ?? true,
      enablePlannedTripWarnings: json['enablePlannedTripWarnings'] ?? true,
      enableCriticalAlerts: json['enableCriticalAlerts'] ?? true,
      warningThresholdDays: json['warningThresholdDays'] ?? 30,
      dailyCheckTime: TimeOfDay(
        hour: json['dailyCheckTimeHour'] ?? 9,
        minute: json['dailyCheckTimeMinute'] ?? 0,
      ),
    );
  }
}

/// Simple TimeOfDay class since Flutter's might not be available
class TimeOfDay {
  final int hour;
  final int minute;

  const TimeOfDay({required this.hour, required this.minute});

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TimeOfDay && other.hour == hour && other.minute == minute;
  }

  @override
  int get hashCode => Object.hash(hour, minute);

  @override
  String toString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}