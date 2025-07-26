import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/services/country_tracking_service.dart';

/// Provider for tax residency service
final taxResidencyServiceProvider = Provider<TaxResidencyService>((ref) {
  return TaxResidencyService(ref);
});

/// Service for managing tax residency rules and calculations
class TaxResidencyService {
  final Ref _ref;

  TaxResidencyService(this._ref);

  /// Default tax residency rules for countries (183-day rule is most common)
  static const Map<String, TaxResidencyRule> _defaultRules = {
    // Major countries with clear 183-day rules
    'US': TaxResidencyRule(
      countryCode: 'US',
      countryName: 'United States',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Substantial presence test: 183 days in current year',
    ),
    'GB': TaxResidencyRule(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Statutory residence test: 183 days in tax year (April 6 - April 5)',
    ),
    'DE': TaxResidencyRule(
      countryCode: 'DE',  
      countryName: 'Germany',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or center of vital interests',
    ),
    'FR': TaxResidencyRule(
      countryCode: 'FR',
      countryName: 'France',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residence: 183 days or principal residence in France',
    ),
    'ES': TaxResidencyRule(
      countryCode: 'ES',
      countryName: 'Spain',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days in calendar year',
    ),
    'IT': TaxResidencyRule(
      countryCode: 'IT',
      countryName: 'Italy',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or domicile/residence in Italy',
    ),
    'PT': TaxResidencyRule(
      countryCode: 'PT',
      countryName: 'Portugal',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days in any 12-month period',
    ),
    'NL': TaxResidencyRule(
      countryCode: 'NL',
      countryName: 'Netherlands',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or substantial ties to Netherlands',
    ),
    'CH': TaxResidencyRule(
      countryCode: 'CH',
      countryName: 'Switzerland',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or domicile in Switzerland',
    ),
    'AT': TaxResidencyRule(
      countryCode: 'AT',
      countryName: 'Austria',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or center of vital interests',
    ),
    'CA': TaxResidencyRule(
      countryCode: 'CA',
      countryName: 'Canada',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or significant residential ties',
    ),
    'AU': TaxResidencyRule(
      countryCode: 'AU',
      countryName: 'Australia',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days rule (part of residency tests)',
    ),
    'SG': TaxResidencyRule(
      countryCode: 'SG',
      countryName: 'Singapore',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or more in calendar year',
    ),
    'HK': TaxResidencyRule(
      countryCode: 'HK',
      countryName: 'Hong Kong',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or more in tax year',
    ),
    'JP': TaxResidencyRule(
      countryCode: 'JP',
      countryName: 'Japan',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or domicile in Japan',
    ),
    'KR': TaxResidencyRule(
      countryCode: 'KR',
      countryName: 'South Korea',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or domicile in Korea',
    ),
    // Nordic countries
    'SE': TaxResidencyRule(
      countryCode: 'SE',
      countryName: 'Sweden',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or substantial connection',
    ),
    'NO': TaxResidencyRule(
      countryCode: 'NO',
      countryName: 'Norway',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or substantial connection',
    ),
    'DK': TaxResidencyRule(
      countryCode: 'DK',
      countryName: 'Denmark',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or substantial connection',
    ),
    'FI': TaxResidencyRule(
      countryCode: 'FI',
      countryName: 'Finland',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or essential ties to Finland',
    ),
    // Other European countries
    'BE': TaxResidencyRule(
      countryCode: 'BE',
      countryName: 'Belgium',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or domicile in Belgium',
    ),
    'IE': TaxResidencyRule(
      countryCode: 'IE',
      countryName: 'Ireland',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days in tax year',
    ),
    'LU': TaxResidencyRule(
      countryCode: 'LU',
      countryName: 'Luxembourg',
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 183 days or domicile in Luxembourg',
    ),
    // Countries with different thresholds
    'UAE': TaxResidencyRule(
      countryCode: 'UAE',
      countryName: 'United Arab Emirates',
      maxDays: 90,
      rollingPeriodDays: 365,
      warningThresholdDays: 15,
      description: 'Tax residency: 90 days in consecutive 12 months (for UAE nationals) or 183 days (for others)',
    ),
    'TH': TaxResidencyRule(
      countryCode: 'TH',
      countryName: 'Thailand',
      maxDays: 180,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 180 days or more in tax year',
    ),
    'MY': TaxResidencyRule(
      countryCode: 'MY',
      countryName: 'Malaysia',
      maxDays: 182,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Tax residency: 182 days or more in calendar year',
    ),
  };

  /// Get tax residency rule for a country
  TaxResidencyRule getTaxRule(String countryCode) {
    return _defaultRules[countryCode] ?? TaxResidencyRule(
      countryCode: countryCode,
      countryName: countryCode,
      maxDays: 183,
      rollingPeriodDays: 365,
      warningThresholdDays: 30,
      description: 'Default 183-day rule (verify with local tax authorities)',
    );
  }

  /// Calculate tax residency status for a country in the current year
  Future<TaxResidencyStatus> calculateTaxResidencyStatus(String countryCode) async {
    final rule = getTaxRule(countryCode);
    final countryTrackingService = _ref.read(countryTrackingServiceProvider);
    
    // Get current year entries for the country
    final currentYearEntries = await countryTrackingService.getCurrentYearEntries();
    final countryEntries = currentYearEntries
        .where((entry) => entry.countryCode == countryCode)
        .toList();

    // Calculate total days spent
    int totalDays = 0;
    for (final entry in countryEntries) {
      totalDays += entry.daysStayed;
    }

    // Get planned stays for this country
    final plannedStays = await countryTrackingService.getPlannedStays();
    final countryPlannedStays = plannedStays
        .where((stay) => stay.countryCode == countryCode)
        .toList();

    // Add planned days to total
    int plannedDays = 0;
    for (final stay in countryPlannedStays) {
      // Only count planned stays that are in the current tax year
      if (stay.startDate.year == DateTime.now().year || 
          stay.endDate.year == DateTime.now().year) {
        plannedDays += stay.daysCount;
      }
    }

    final totalIncludingPlanned = totalDays + plannedDays;
    final daysRemaining = rule.maxDays - totalIncludingPlanned;
    final isAtRisk = daysRemaining <= rule.warningThresholdDays;
    final isOverLimit = totalIncludingPlanned > rule.maxDays;

    return TaxResidencyStatus(
      countryCode: countryCode,
      rule: rule,
      actualDaysSpent: totalDays,
      plannedDays: plannedDays,
      totalDaysIncludingPlanned: totalIncludingPlanned,
      daysRemaining: daysRemaining,
      isAtRisk: isAtRisk,
      isOverLimit: isOverLimit,
      calculationDate: DateTime.now(),
      contributingEntries: countryEntries,
      contributingPlannedStays: countryPlannedStays,
    );
  }

  /// Calculate tax residency status for all countries with entries
  Future<Map<String, TaxResidencyStatus>> calculateAllTaxResidencyStatus() async {
    final countryTrackingService = _ref.read(countryTrackingServiceProvider);
    final currentYearEntries = await countryTrackingService.getCurrentYearEntries();
    final plannedStays = await countryTrackingService.getPlannedStays();
    
    // Get unique country codes from entries and planned stays
    final countryCodes = <String>{
      ...currentYearEntries.map((entry) => entry.countryCode),
      ...plannedStays.map((stay) => stay.countryCode),
    };

    final results = <String, TaxResidencyStatus>{};
    
    for (final countryCode in countryCodes) {
      results[countryCode] = await calculateTaxResidencyStatus(countryCode);
    }

    return results;
  }

  /// Get countries that are at risk of exceeding tax residency limits
  Future<List<TaxResidencyStatus>> getCountriesAtRisk() async {
    final allStatus = await calculateAllTaxResidencyStatus();
    return allStatus.values
        .where((status) => status.isAtRisk || status.isOverLimit)
        .toList()
      ..sort((a, b) => a.daysRemaining.compareTo(b.daysRemaining));
  }

  /// Get countries that have exceeded tax residency limits
  Future<List<TaxResidencyStatus>> getCountriesOverLimit() async {
    final allStatus = await calculateAllTaxResidencyStatus();
    return allStatus.values
        .where((status) => status.isOverLimit)
        .toList()
      ..sort((a, b) => b.totalDaysIncludingPlanned.compareTo(a.totalDaysIncludingPlanned));
  }

  /// Check if a planned trip would cause tax residency issues
  Future<List<TaxResidencyWarning>> checkPlannedTrip({
    required String countryCode,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final warnings = <TaxResidencyWarning>[];
    final tripDays = endDate.difference(startDate).inDays + 1;
    
    // Get current status
    final currentStatus = await calculateTaxResidencyStatus(countryCode);
    final newTotal = currentStatus.totalDaysIncludingPlanned + tripDays;
    final rule = currentStatus.rule;
    
    if (newTotal > rule.maxDays) {
      warnings.add(TaxResidencyWarning(
        type: TaxResidencyWarningType.exceededLimit,
        countryCode: countryCode,
        message: 'This trip would cause you to exceed the ${rule.maxDays}-day limit for ${rule.countryName}. '
            'New total would be $newTotal days.',
        severity: WarningSeventeenity.critical,
        daysOverLimit: newTotal - rule.maxDays,
        affectedDays: tripDays,
      ));
    } else if (newTotal > rule.maxDays - rule.warningThresholdDays) {
      warnings.add(TaxResidencyWarning(
        type: TaxResidencyWarningType.approachingLimit,
        countryCode: countryCode,
        message: 'This trip would bring you close to the ${rule.maxDays}-day limit for ${rule.countryName}. '
            'New total would be $newTotal days (${rule.maxDays - newTotal} days remaining).',
        severity: WarningSeventeenity.high,
        daysOverLimit: 0,
        affectedDays: tripDays,
      ));
    }
    
    return warnings;
  }

  /// Generate tax residency summary for a specific year
  Future<TaxResidencySummary> generateYearSummary([int? year]) async {
    year ??= DateTime.now().year;
    
    final allStatus = await calculateAllTaxResidencyStatus();
    final countriesAtRisk = allStatus.values.where((s) => s.isAtRisk).length;
    final countriesOverLimit = allStatus.values.where((s) => s.isOverLimit).length;
    final totalCountries = allStatus.length;
    
    // Calculate total days traveled
    int totalDaysTraveled = 0;
    for (final status in allStatus.values) {
      totalDaysTraveled += status.actualDaysSpent;
    }
    
    return TaxResidencySummary(
      year: year,
      totalCountries: totalCountries,
      countriesAtRisk: countriesAtRisk,
      countriesOverLimit: countriesOverLimit,
      totalDaysTraveled: totalDaysTraveled,
      statusByCountry: allStatus,
      generatedAt: DateTime.now(),
    );
  }
}

/// Tax residency rule for a country
class TaxResidencyRule {
  final String countryCode;
  final String countryName;
  final int maxDays;
  final int rollingPeriodDays;
  final int warningThresholdDays;
  final String description;
  final bool isCustomRule;

  const TaxResidencyRule({
    required this.countryCode,
    required this.countryName,
    required this.maxDays,
    required this.rollingPeriodDays,
    required this.warningThresholdDays,
    required this.description,
    this.isCustomRule = false,
  });

  TaxResidencyRule copyWith({
    String? countryCode,
    String? countryName,
    int? maxDays,
    int? rollingPeriodDays,
    int? warningThresholdDays,
    String? description,
    bool? isCustomRule,
  }) {
    return TaxResidencyRule(
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      maxDays: maxDays ?? this.maxDays,
      rollingPeriodDays: rollingPeriodDays ?? this.rollingPeriodDays,
      warningThresholdDays: warningThresholdDays ?? this.warningThresholdDays,
      description: description ?? this.description,
      isCustomRule: isCustomRule ?? this.isCustomRule,
    );
  }
}

/// Tax residency status for a country
class TaxResidencyStatus {
  final String countryCode;
  final TaxResidencyRule rule;
  final int actualDaysSpent;
  final int plannedDays;
  final int totalDaysIncludingPlanned;
  final int daysRemaining;
  final bool isAtRisk;
  final bool isOverLimit;
  final DateTime calculationDate;
  final List<CountryEntry> contributingEntries;
  final List<PlannedStay> contributingPlannedStays;

  const TaxResidencyStatus({
    required this.countryCode,
    required this.rule,
    required this.actualDaysSpent,
    required this.plannedDays,
    required this.totalDaysIncludingPlanned,
    required this.daysRemaining,
    required this.isAtRisk,
    required this.isOverLimit,
    required this.calculationDate,
    required this.contributingEntries,
    required this.contributingPlannedStays,
  });

  /// Risk level based on days remaining
  RiskLevel get riskLevel {
    if (isOverLimit) return RiskLevel.critical;
    if (daysRemaining <= 7) return RiskLevel.high;
    if (daysRemaining <= rule.warningThresholdDays) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Percentage of time limit used
  double get usagePercentage => totalDaysIncludingPlanned / rule.maxDays;

  /// Whether user can safely stay more days
  bool get canStayMore => daysRemaining > 0;

  /// Safe days that can be added without triggering warnings
  int get safeDaysRemaining => (daysRemaining - rule.warningThresholdDays).clamp(0, rule.maxDays);
}

/// Tax residency warning
class TaxResidencyWarning {
  final TaxResidencyWarningType type;
  final String countryCode;
  final String message;
  final WarningSeventeenity severity;
  final int daysOverLimit;
  final int affectedDays;

  const TaxResidencyWarning({
    required this.type,
    required this.countryCode,
    required this.message,
    required this.severity,
    required this.daysOverLimit,
    required this.affectedDays,
  });
}

/// Tax residency summary for a year
class TaxResidencySummary {
  final int year;
  final int totalCountries;
  final int countriesAtRisk;
  final int countriesOverLimit;
  final int totalDaysTraveled;
  final Map<String, TaxResidencyStatus> statusByCountry;
  final DateTime generatedAt;

  const TaxResidencySummary({
    required this.year,
    required this.totalCountries,
    required this.countriesAtRisk,
    required this.countriesOverLimit,
    required this.totalDaysTraveled,
    required this.statusByCountry,
    required this.generatedAt,
  });

  /// Get countries sorted by risk level
  List<TaxResidencyStatus> get countriesByRisk {
    final list = statusByCountry.values.toList();
    list.sort((a, b) {
      // First sort by risk level (critical first)
      final riskComparison = b.riskLevel.index.compareTo(a.riskLevel.index);
      if (riskComparison != 0) return riskComparison;
      
      // Then by days remaining (fewer remaining first)
      return a.daysRemaining.compareTo(b.daysRemaining);
    });
    return list;
  }

  /// Overall risk assessment
  String get overallRiskAssessment {
    if (countriesOverLimit > 0) {
      return 'Critical: $countriesOverLimit countries over limit';
    } else if (countriesAtRisk > 0) {
      return 'Warning: $countriesAtRisk countries at risk';
    } else {
      return 'Good: No countries at risk';
    }
  }
}

/// Risk levels for tax residency
enum RiskLevel {
  low,
  medium,
  high,
  critical,
}

/// Types of tax residency warnings
enum TaxResidencyWarningType {
  approachingLimit,
  exceededLimit,
  plannedExceedance,
  ruleChanged,
}

/// Warning severity levels
enum WarningSeventeenity {
  low,
  medium,
  high,
  critical,
}

/// Extensions for risk levels
extension RiskLevelExtensions on RiskLevel {
  String get displayName {
    switch (this) {
      case RiskLevel.low:
        return 'Low Risk';
      case RiskLevel.medium:
        return 'Medium Risk';
      case RiskLevel.high:
        return 'High Risk';
      case RiskLevel.critical:
        return 'Critical Risk';
    }
  }

  String get colorHex {
    switch (this) {
      case RiskLevel.low:
        return '#4CAF50'; // Green
      case RiskLevel.medium:
        return '#FF9800'; // Orange
      case RiskLevel.high:
        return '#F44336'; // Red
      case RiskLevel.critical:
        return '#D32F2F'; // Dark Red
    }
  }
}

/// Extensions for warning severity
extension WarningSeverityExtensions on WarningSeventeenity {
  String get displayName {
    switch (this) {
      case WarningSeventeenity.low:
        return 'Low';
      case WarningSeventeenity.medium:
        return 'Medium';
      case WarningSeventeenity.high:
        return 'High';
      case WarningSeventeenity.critical:
        return 'Critical';
    }
  }

  String get colorHex {
    switch (this) {
      case WarningSeventeenity.low:
        return '#4CAF50'; // Green
      case WarningSeventeenity.medium:
        return '#FF9800'; // Orange
      case WarningSeventeenity.high:
        return '#F44336'; // Red
      case WarningSeventeenity.critical:
        return '#D32F2F'; // Dark Red
    }
  }
}