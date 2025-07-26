import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/time_limit_models.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/services/time_limit_management_service.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/providers/optimized_tracking_providers.dart';

/// Provider for all time limit configurations
final timeLimitConfigurationsProvider = FutureProvider<List<CountryTimeLimitConfig>>((ref) async {
  final service = ref.read(timeLimitManagementServiceProvider);
  return await service.getAllConfigurations();
});

/// Provider for a specific country's time limit configuration
final countryTimeLimitConfigProvider = FutureProvider.family<CountryTimeLimitConfig?, String>((ref, countryCode) async {
  final service = ref.read(timeLimitManagementServiceProvider);
  return await service.getConfigurationForCountry(countryCode);
});

/// Provider for effective time limit for a country and visa type
final effectiveTimeLimitProvider = FutureProvider.family<TimeDuration, TimeLimitQuery>((ref, query) async {
  final service = ref.read(timeLimitManagementServiceProvider);
  return await service.getEffectiveTimeLimit(
    countryCode: query.countryCode,
    visaType: query.visaType,
  );
});

/// Provider for time limit validation warnings
final timeLimitWarningsProvider = Provider<Map<String, TimeLimitWarning>>((ref) {
  final trackingState = ref.watch(optimizedTrackingProvider);
  final configurations = ref.watch(timeLimitConfigurationsProvider);

  if (trackingState is! TrackingDataLoaded || configurations.isLoading) {
    return {};
  }

  final warnings = <String, TimeLimitWarning>{};
  final configs = configurations.asData?.value ?? [];
  final configMap = {for (final config in configs) config.countryCode: config};

  // Check warnings for each country with time spent
  for (final entry in trackingState.daysPerCountry.entries) {
    final countryCode = entry.key;
    final daysSpent = entry.value;
    final config = configMap[countryCode];

    if (config != null) {
      final defaultLimit = config.defaultVisaLimit;
      if (defaultLimit != null) {
        final warning = _calculateWarning(
          countryCode,
          daysSpent,
          defaultLimit,
          trackingState.currentLocation == countryCode,
        );
        if (warning != null) {
          warnings[countryCode] = warning;
        }
      }
    }
  }

  return warnings;
});

/// Provider for current location time limit status
final currentLocationTimeLimitProvider = Provider<CurrentLocationStatus?>((ref) {
  final trackingState = ref.watch(optimizedTrackingProvider);
  final warnings = ref.watch(timeLimitWarningsProvider);

  if (trackingState is! TrackingDataLoaded || trackingState.currentLocation == null) {
    return null;
  }

  final currentCountry = trackingState.currentLocation!;
  final warning = warnings[currentCountry];
  final daysSpent = trackingState.daysPerCountry[currentCountry] ?? 0;

  return CurrentLocationStatus(
    countryCode: currentCountry,
    daysSpent: daysSpent,
    warning: warning,
  );
});

/// Provider for time limit statistics
final timeLimitStatisticsProvider = FutureProvider<TimeLimitStatistics>((ref) async {
  final service = ref.read(timeLimitManagementServiceProvider);
  final trackingState = ref.watch(optimizedTrackingProvider);
  
  final stats = await service.getStatistics();
  
  if (trackingState is TrackingDataLoaded) {
    final warnings = ref.read(timeLimitWarningsProvider);
    final criticalWarnings = warnings.values.where((w) => w.severity == WarningSeverity.critical).length;
    final highWarnings = warnings.values.where((w) => w.severity == WarningSeverity.high).length;
    
    return TimeLimitStatistics(
      totalConfigurations: stats['totalCountries'] ?? 0,
      totalVisaLimits: stats['totalVisaLimits'] ?? 0,
      criticalWarnings: criticalWarnings,
      highWarnings: highWarnings,
      countriesWithTimeSpent: trackingState.daysPerCountry.length,
      lastModified: stats['lastModified'] != null 
        ? DateTime.parse(stats['lastModified'])
        : null,
    );
  }
  
  return TimeLimitStatistics(
    totalConfigurations: stats['totalCountries'] ?? 0,
    totalVisaLimits: stats['totalVisaLimits'] ?? 0,
    criticalWarnings: 0,
    highWarnings: 0,
    countriesWithTimeSpent: 0,
    lastModified: stats['lastModified'] != null 
      ? DateTime.parse(stats['lastModified'])
      : null,
  );
});

/// Provider for time limit templates
final timeLimitTemplatesProvider = FutureProvider<List<TimeLimitTemplate>>((ref) async {
  final service = ref.read(timeLimitManagementServiceProvider);
  return await service.getAllTemplates();
});

/// Provider for time limit history for a specific country
final timeLimitHistoryProvider = FutureProvider.family<List<TimeLimitHistoryEntry>, String>((ref, countryCode) async {
  final service = ref.read(timeLimitManagementServiceProvider);
  return await service.getHistory(countryCode: countryCode);
});

/// Provider for checking if a country is approaching its time limit
final countryApproachingLimitProvider = Provider.family<bool, String>((ref, countryCode) {
  final warnings = ref.watch(timeLimitWarningsProvider);
  final warning = warnings[countryCode];
  
  return warning != null && 
         (warning.severity == WarningSeverity.high || 
          warning.severity == WarningSeverity.critical);
});

/// Provider for getting time remaining for a country
final timeRemainingProvider = Provider.family<int?, String>((ref, countryCode) {
  final warnings = ref.watch(timeLimitWarningsProvider);
  final warning = warnings[countryCode];
  
  return warning?.daysRemaining;
});

/// Query class for effective time limit provider
class TimeLimitQuery {
  final String countryCode;
  final VisaType visaType;

  const TimeLimitQuery({
    required this.countryCode,
    this.visaType = VisaType.tourist,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLimitQuery &&
          runtimeType == other.runtimeType &&
          countryCode == other.countryCode &&
          visaType == other.visaType;

  @override
  int get hashCode => Object.hash(countryCode, visaType);
}

/// Warning severity levels
enum WarningSeverity {
  low,
  medium,
  high,
  critical,
  exceeded,
}

/// Time limit warning information
class TimeLimitWarning {
  final String countryCode;
  final String countryName;
  final int daysSpent;
  final int maxDays;
  final int daysRemaining;
  final WarningSeverity severity;
  final String message;
  final bool isCurrentLocation;
  final VisaType visaType;

  const TimeLimitWarning({
    required this.countryCode,
    required this.countryName,
    required this.daysSpent,
    required this.maxDays,
    required this.daysRemaining,
    required this.severity,
    required this.message,
    required this.isCurrentLocation,
    required this.visaType,
  });

  /// Get color for this warning level
  String get colorHex {
    switch (severity) {
      case WarningSeverity.low:
        return '#4CAF50'; // Green
      case WarningSeverity.medium:
        return '#FF9800'; // Orange
      case WarningSeverity.high:
        return '#FF5722'; // Deep Orange
      case WarningSeverity.critical:
        return '#F44336'; // Red
      case WarningSeverity.exceeded:
        return '#9C27B0'; // Purple
    }
  }

  /// Get percentage of limit used
  double get percentageUsed {
    return (daysSpent / maxDays * 100).clamp(0, 100);
  }

  /// Whether the limit has been exceeded
  bool get isExceeded => daysSpent >= maxDays;
}

/// Current location status information
class CurrentLocationStatus {
  final String countryCode;
  final int daysSpent;
  final TimeLimitWarning? warning;

  const CurrentLocationStatus({
    required this.countryCode,
    required this.daysSpent,
    this.warning,
  });

  /// Whether there's an active warning
  bool get hasWarning => warning != null;

  /// Whether the limit is exceeded
  bool get isExceeded => warning?.isExceeded ?? false;

  /// Whether approaching limit (within 7 days)
  bool get isApproachingLimit => 
    warning != null && 
    warning!.daysRemaining <= 7 && 
    warning!.daysRemaining > 0;
}

/// Time limit statistics
class TimeLimitStatistics {
  final int totalConfigurations;
  final int totalVisaLimits;
  final int criticalWarnings;
  final int highWarnings;
  final int countriesWithTimeSpent;
  final DateTime? lastModified;

  const TimeLimitStatistics({
    required this.totalConfigurations,
    required this.totalVisaLimits,
    required this.criticalWarnings,
    required this.highWarnings,
    required this.countriesWithTimeSpent,
    this.lastModified,
  });

  /// Total number of warnings
  int get totalWarnings => criticalWarnings + highWarnings;

  /// Whether there are any critical issues
  bool get hasCriticalIssues => criticalWarnings > 0;
}

/// Helper function to calculate warning for a country
TimeLimitWarning? _calculateWarning(
  String countryCode,
  int daysSpent,
  VisaTimeLimit limit,
  bool isCurrentLocation,
) {
  final maxDays = limit.maxStay.totalDays;
  final daysRemaining = maxDays - daysSpent;
  
  // Only show warnings if approaching or exceeding limit
  if (daysRemaining > 30) {
    return null;
  }

  WarningSeverity severity;
  String message;

  if (daysRemaining <= 0) {
    severity = WarningSeverity.exceeded;
    message = 'Time limit exceeded by ${-daysRemaining} days';
  } else if (daysRemaining <= 3) {
    severity = WarningSeverity.critical;
    message = 'Only $daysRemaining days remaining';
  } else if (daysRemaining <= 7) {
    severity = WarningSeverity.high;
    message = '$daysRemaining days remaining';
  } else if (daysRemaining <= 14) {
    severity = WarningSeverity.medium;
    message = '$daysRemaining days remaining';
  } else {
    severity = WarningSeverity.low;
    message = '$daysRemaining days remaining';
  }

  return TimeLimitWarning(
    countryCode: countryCode,
    countryName: countryCode, // Would be replaced with actual country name
    daysSpent: daysSpent,
    maxDays: maxDays,
    daysRemaining: daysRemaining,
    severity: severity,
    message: message,
    isCurrentLocation: isCurrentLocation,
    visaType: limit.visaType,
  );
}

/// Extension to invalidate time limit providers
extension TimeLimitProviderInvalidation on WidgetRef {
  void invalidateTimeLimitProviders([String? countryCode]) {
    invalidate(timeLimitConfigurationsProvider);
    invalidate(timeLimitWarningsProvider);
    invalidate(currentLocationTimeLimitProvider);
    invalidate(timeLimitStatisticsProvider);
    invalidate(timeLimitTemplatesProvider);
    
    if (countryCode != null) {
      invalidate(countryTimeLimitConfigProvider(countryCode));
      invalidate(timeLimitHistoryProvider(countryCode));
    }
  }
}