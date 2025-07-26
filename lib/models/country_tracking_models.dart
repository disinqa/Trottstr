import 'package:flutter/foundation.dart';

/// Simple data model for country entries
@immutable
class CountryEntry {
  final String id;
  final String countryCode;
  final DateTime entryTime;
  final DateTime? exitTime;
  final String purpose;
  final String location;
  final bool isPlanned;
  final String notes;

  const CountryEntry({
    required this.id,
    required this.countryCode,
    required this.entryTime,
    this.exitTime,
    this.purpose = '',
    this.location = '',
    this.isPlanned = false,
    this.notes = '',
  });

  /// Duration in the country (in days)
  int get durationDays {
    final exit = exitTime ?? DateTime.now();
    return exit.difference(entryTime).inDays;
  }

  /// Whether the entry is currently active (user is in the country)
  bool get isActive => exitTime == null && !isPlanned;

  /// Year of the entry for tax calculation purposes
  int get taxYear => entryTime.year;

  CountryEntry copyWith({
    String? id,
    String? countryCode,
    DateTime? entryTime,
    DateTime? exitTime,
    String? purpose,
    String? location,
    bool? isPlanned,
    String? notes,
  }) {
    return CountryEntry(
      id: id ?? this.id,
      countryCode: countryCode ?? this.countryCode,
      entryTime: entryTime ?? this.entryTime,
      exitTime: exitTime ?? this.exitTime,
      purpose: purpose ?? this.purpose,
      location: location ?? this.location,
      isPlanned: isPlanned ?? this.isPlanned,
      notes: notes ?? this.notes,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'countryCode': countryCode,
      'entryTime': entryTime.millisecondsSinceEpoch,
      'exitTime': exitTime?.millisecondsSinceEpoch,
      'purpose': purpose,
      'location': location,
      'isPlanned': isPlanned,
      'notes': notes,
    };
  }

  factory CountryEntry.fromJson(Map<String, dynamic> json) {
    return CountryEntry(
      id: json['id'] as String,
      countryCode: json['countryCode'] as String,
      entryTime: DateTime.fromMillisecondsSinceEpoch(json['entryTime'] as int),
      exitTime: json['exitTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['exitTime'] as int)
          : null,
      purpose: json['purpose'] as String? ?? '',
      location: json['location'] as String? ?? '',
      isPlanned: json['isPlanned'] as bool? ?? false,
      notes: json['notes'] as String? ?? '',
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryEntry && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Simple data model for country tax rules
@immutable
class CountryTaxRule {
  final String countryCode;
  final String countryName;
  final int maxDaysBeforeTaxResident;
  final int rollingPeriodDays;
  final int warningThresholdDays;
  final String ruleDescription;
  final bool isCustomRule;
  final Map<String, String> ruleMetadata;

  const CountryTaxRule({
    required this.countryCode,
    required this.countryName,
    this.maxDaysBeforeTaxResident = 183,
    this.rollingPeriodDays = 365,
    this.warningThresholdDays = 30,
    this.ruleDescription = '',
    this.isCustomRule = false,
    this.ruleMetadata = const {},
  });

  CountryTaxRule copyWith({
    String? countryCode,
    String? countryName,
    int? maxDaysBeforeTaxResident,
    int? rollingPeriodDays,
    int? warningThresholdDays,
    String? ruleDescription,
    bool? isCustomRule,
    Map<String, String>? ruleMetadata,
  }) {
    return CountryTaxRule(
      countryCode: countryCode ?? this.countryCode,
      countryName: countryName ?? this.countryName,
      maxDaysBeforeTaxResident:
          maxDaysBeforeTaxResident ?? this.maxDaysBeforeTaxResident,
      rollingPeriodDays: rollingPeriodDays ?? this.rollingPeriodDays,
      warningThresholdDays: warningThresholdDays ?? this.warningThresholdDays,
      ruleDescription: ruleDescription ?? this.ruleDescription,
      isCustomRule: isCustomRule ?? this.isCustomRule,
      ruleMetadata: ruleMetadata ?? this.ruleMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'countryCode': countryCode,
      'countryName': countryName,
      'maxDaysBeforeTaxResident': maxDaysBeforeTaxResident,
      'rollingPeriodDays': rollingPeriodDays,
      'warningThresholdDays': warningThresholdDays,
      'ruleDescription': ruleDescription,
      'isCustomRule': isCustomRule,
      'ruleMetadata': ruleMetadata,
    };
  }

  factory CountryTaxRule.fromJson(Map<String, dynamic> json) {
    return CountryTaxRule(
      countryCode: json['countryCode'] as String,
      countryName: json['countryName'] as String,
      maxDaysBeforeTaxResident: json['maxDaysBeforeTaxResident'] as int? ?? 183,
      rollingPeriodDays: json['rollingPeriodDays'] as int? ?? 365,
      warningThresholdDays: json['warningThresholdDays'] as int? ?? 30,
      ruleDescription: json['ruleDescription'] as String? ?? '',
      isCustomRule: json['isCustomRule'] as bool? ?? false,
      ruleMetadata: Map<String, String>.from(
        json['ruleMetadata'] as Map? ?? {},
      ),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryTaxRule && other.countryCode == countryCode;
  }

  @override
  int get hashCode => countryCode.hashCode;
}

/// Simple data model for travel warnings
@immutable
class TravelWarning {
  final String id;
  final String countryCode;
  final TravelWarningType warningType;
  final int daysRemaining;
  final int currentDays;
  final int maxAllowedDays;
  final String message;
  final WarningSeverity severity;
  final bool isAcknowledged;
  final DateTime createdAt;

  const TravelWarning({
    required this.id,
    required this.countryCode,
    required this.warningType,
    required this.daysRemaining,
    required this.currentDays,
    required this.maxAllowedDays,
    required this.message,
    this.severity = WarningSeverity.medium,
    this.isAcknowledged = false,
    required this.createdAt,
  });

  TravelWarning copyWith({
    String? id,
    String? countryCode,
    TravelWarningType? warningType,
    int? daysRemaining,
    int? currentDays,
    int? maxAllowedDays,
    String? message,
    WarningSeverity? severity,
    bool? isAcknowledged,
    DateTime? createdAt,
  }) {
    return TravelWarning(
      id: id ?? this.id,
      countryCode: countryCode ?? this.countryCode,
      warningType: warningType ?? this.warningType,
      daysRemaining: daysRemaining ?? this.daysRemaining,
      currentDays: currentDays ?? this.currentDays,
      maxAllowedDays: maxAllowedDays ?? this.maxAllowedDays,
      message: message ?? this.message,
      severity: severity ?? this.severity,
      isAcknowledged: isAcknowledged ?? this.isAcknowledged,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'countryCode': countryCode,
      'warningType': warningType.name,
      'daysRemaining': daysRemaining,
      'currentDays': currentDays,
      'maxAllowedDays': maxAllowedDays,
      'message': message,
      'severity': severity.name,
      'isAcknowledged': isAcknowledged,
      'createdAt': createdAt.millisecondsSinceEpoch,
    };
  }

  factory TravelWarning.fromJson(Map<String, dynamic> json) {
    return TravelWarning(
      id: json['id'] as String,
      countryCode: json['countryCode'] as String,
      warningType: TravelWarningType.values.firstWhere(
        (type) => type.name == json['warningType'],
        orElse: () => TravelWarningType.approachingLimit,
      ),
      daysRemaining: json['daysRemaining'] as int,
      currentDays: json['currentDays'] as int,
      maxAllowedDays: json['maxAllowedDays'] as int,
      message: json['message'] as String,
      severity: WarningSeverity.values.firstWhere(
        (sev) => sev.name == json['severity'],
        orElse: () => WarningSeverity.medium,
      ),
      isAcknowledged: json['isAcknowledged'] as bool? ?? false,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is TravelWarning && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Tax residency calculation result
@immutable
class TaxResidencyStatus {
  final String countryCode;
  final int totalDaysSpent;
  final int maxAllowedDays;
  final int daysRemaining;
  final bool isAtRisk;
  final DateTime calculationDate;
  final List<CountryEntry> contributingEntries;

  const TaxResidencyStatus({
    required this.countryCode,
    required this.totalDaysSpent,
    required this.maxAllowedDays,
    required this.daysRemaining,
    required this.isAtRisk,
    required this.calculationDate,
    required this.contributingEntries,
  });

  /// Gets the percentage of time limit used
  double get usagePercentage => totalDaysSpent / maxAllowedDays;

  /// Whether user has exceeded the limit
  bool get isOverLimit => totalDaysSpent > maxAllowedDays;

  /// Risk level based on days remaining
  RiskLevel get riskLevel {
    if (isOverLimit) return RiskLevel.exceeded;
    if (daysRemaining <= 7) return RiskLevel.critical;
    if (daysRemaining <= 30) return RiskLevel.high;
    if (daysRemaining <= 60) return RiskLevel.medium;
    return RiskLevel.low;
  }
}

/// Tax residency risk assessment
@immutable
class TaxResidencyRisk {
  final String countryCode;
  final String countryName;
  final int currentDays;
  final int threshold;
  final int daysRemaining;
  final double percentageUsed;
  final RiskLevel riskLevel;
  final bool isExceeded;

  const TaxResidencyRisk({
    required this.countryCode,
    required this.countryName,
    required this.currentDays,
    required this.threshold,
    required this.daysRemaining,
    required this.percentageUsed,
    required this.riskLevel,
    required this.isExceeded,
  });
}

/// Travel stats summary
@immutable
class TravelStats {
  final int countriesCount;
  final int totalDays;
  final int totalEntries;
  final String currentStatus;
  final List<CountrySummary> countryBreakdown;

  const TravelStats({
    required this.countriesCount,
    required this.totalDays,
    required this.totalEntries,
    required this.currentStatus,
    required this.countryBreakdown,
  });
}

/// Country summary for travel stats
@immutable
class CountrySummary {
  final String countryCode;
  final String countryName;
  final int daysSpent;
  final int entries;
  final TaxResidencyRisk? risk;

  const CountrySummary({
    required this.countryCode,
    required this.countryName,
    required this.daysSpent,
    required this.entries,
    this.risk,
  });
}

/// Country information model
@immutable
class CountryInfo {
  final String code;
  final String name;
  final String flag;
  final CountryTaxRule? taxRule;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
    this.taxRule,
  });

  CountryInfo copyWith({
    String? code,
    String? name,
    String? flag,
    CountryTaxRule? taxRule,
  }) {
    return CountryInfo(
      code: code ?? this.code,
      name: name ?? this.name,
      flag: flag ?? this.flag,
      taxRule: taxRule ?? this.taxRule,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryInfo && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;
}

/// Enums for travel warning types
enum TravelWarningType {
  approachingLimit,
  exceededLimit,
  plannedExceedance,
  ruleChanged,
}

/// Warning severity levels
enum WarningSeverity { low, medium, high, critical }

/// Risk levels for tax residency
enum RiskLevel { low, medium, high, critical, exceeded }

/// Tracking data state classes
abstract class TrackingDataState {}

class TrackingDataLoading extends TrackingDataState {}

class TrackingDataLoaded extends TrackingDataState {
  final List<CountryEntry> entries;
  final List<TravelWarning> warnings;
  final Map<String, CountryTaxRule> taxRules;

  TrackingDataLoaded({
    required this.entries,
    required this.warnings,
    required this.taxRules,
  });
}

class TrackingDataError extends TrackingDataState {
  final String error;

  TrackingDataError(this.error);
}

/// Extension methods for travel warnings
extension TravelWarningExtensions on TravelWarningType {
  String get displayName {
    switch (this) {
      case TravelWarningType.approachingLimit:
        return 'Approaching Tax Residency Limit';
      case TravelWarningType.exceededLimit:
        return 'Tax Residency Limit Exceeded';
      case TravelWarningType.plannedExceedance:
        return 'Planned Travel Will Exceed Limit';
      case TravelWarningType.ruleChanged:
        return 'Tax Rule Changed';
    }
  }

  String get description {
    switch (this) {
      case TravelWarningType.approachingLimit:
        return 'You are approaching the tax residency threshold for this country';
      case TravelWarningType.exceededLimit:
        return 'You have exceeded the tax residency threshold for this country';
      case TravelWarningType.plannedExceedance:
        return 'Your planned travel will exceed the tax residency threshold';
      case TravelWarningType.ruleChanged:
        return 'The tax residency rules for this country have been updated';
    }
  }
}

extension WarningSeverityExtensions on WarningSeverity {
  String get displayName {
    switch (this) {
      case WarningSeverity.low:
        return 'Low';
      case WarningSeverity.medium:
        return 'Medium';
      case WarningSeverity.high:
        return 'High';
      case WarningSeverity.critical:
        return 'Critical';
    }
  }

  String get colorHex {
    switch (this) {
      case WarningSeverity.low:
        return '#4CAF50'; // Green
      case WarningSeverity.medium:
        return '#FF9800'; // Orange
      case WarningSeverity.high:
        return '#F44336'; // Red
      case WarningSeverity.critical:
        return '#D32F2F'; // Dark Red
    }
  }
}

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
      case RiskLevel.exceeded:
        return 'Limit Exceeded';
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
      case RiskLevel.exceeded:
        return '#B71C1C'; // Very Dark Red
    }
  }
}
