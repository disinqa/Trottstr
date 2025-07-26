import 'package:flutter/foundation.dart';

/// Enum for different time units
enum TimeUnit {
  days,
  weeks,
  months,
  years;

  /// Convert this unit to a human-readable string
  String get displayName {
    switch (this) {
      case TimeUnit.days:
        return 'days';
      case TimeUnit.weeks:
        return 'weeks';
      case TimeUnit.months:
        return 'months';
      case TimeUnit.years:
        return 'years';
    }
  }

  /// Convert this unit to its plural form
  String get pluralName => displayName;

  /// Convert this unit to its singular form
  String get singularName {
    switch (this) {
      case TimeUnit.days:
        return 'day';
      case TimeUnit.weeks:
        return 'week';
      case TimeUnit.months:
        return 'month';
      case TimeUnit.years:
        return 'year';
    }
  }

  /// Get the appropriate name based on the value
  String getDisplayName(int value) {
    return value == 1 ? singularName : pluralName;
  }
}

/// Enum for different visa types
enum VisaType {
  tourist,
  business,
  student,
  work,
  transit,
  diplomatic,
  family,
  retirement,
  nomad,
  investment,
  other;

  /// Convert this visa type to a human-readable string
  String get displayName {
    switch (this) {
      case VisaType.tourist:
        return 'Tourist/Visitor';
      case VisaType.business:
        return 'Business';
      case VisaType.student:
        return 'Student';
      case VisaType.work:
        return 'Work/Employment';
      case VisaType.transit:
        return 'Transit';
      case VisaType.diplomatic:
        return 'Diplomatic';
      case VisaType.family:
        return 'Family/Spouse';
      case VisaType.retirement:
        return 'Retirement';
      case VisaType.nomad:
        return 'Digital Nomad';
      case VisaType.investment:
        return 'Investment/Investor';
      case VisaType.other:
        return 'Other';
    }
  }

  /// Get icon for this visa type
  String get icon {
    switch (this) {
      case VisaType.tourist:
        return '🏖️';
      case VisaType.business:
        return '💼';
      case VisaType.student:
        return '🎓';
      case VisaType.work:
        return '👷';
      case VisaType.transit:
        return '✈️';
      case VisaType.diplomatic:
        return '🏛️';
      case VisaType.family:
        return '👨‍👩‍👧‍👦';
      case VisaType.retirement:
        return '🏡';
      case VisaType.nomad:
        return '💻';
      case VisaType.investment:
        return '💰';
      case VisaType.other:
        return '📝';
    }
  }
}

/// Represents a flexible time duration
@immutable
class TimeDuration {
  final int value;
  final TimeUnit unit;

  const TimeDuration({
    required this.value,
    required this.unit,
  });

  /// Convert this duration to total days
  int get totalDays {
    switch (unit) {
      case TimeUnit.days:
        return value;
      case TimeUnit.weeks:
        return value * 7;
      case TimeUnit.months:
        return value * 30; // Approximate
      case TimeUnit.years:
        return value * 365; // Approximate
    }
  }

  /// Get a human-readable string representation
  String get displayString {
    return '$value ${unit.getDisplayName(value)}';
  }

  /// Create from total days (converts to most appropriate unit)
  factory TimeDuration.fromDays(int days) {
    if (days >= 365 && days % 365 == 0) {
      return TimeDuration(value: days ~/ 365, unit: TimeUnit.years);
    } else if (days >= 30 && days % 30 == 0) {
      return TimeDuration(value: days ~/ 30, unit: TimeUnit.months);
    } else if (days >= 7 && days % 7 == 0) {
      return TimeDuration(value: days ~/ 7, unit: TimeUnit.weeks);
    } else {
      return TimeDuration(value: days, unit: TimeUnit.days);
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'value': value,
        'unit': unit.name,
      };

  /// Create from JSON
  factory TimeDuration.fromJson(Map<String, dynamic> json) => TimeDuration(
        value: json['value'] as int,
        unit: TimeUnit.values.firstWhere((e) => e.name == json['unit']),
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeDuration &&
          runtimeType == other.runtimeType &&
          value == other.value &&
          unit == other.unit;

  @override
  int get hashCode => Object.hash(value, unit);

  @override
  String toString() => displayString;
}

/// Represents time limit for a specific visa type in a country
@immutable
class VisaTimeLimit {
  final VisaType visaType;
  final TimeDuration maxStay;
  final TimeDuration? perPeriod; // e.g., 90 days per 180 days
  final String? description;
  final bool isDefault;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const VisaTimeLimit({
    required this.visaType,
    required this.maxStay,
    this.perPeriod,
    this.description,
    this.isDefault = false,
    required this.createdAt,
    this.updatedAt,
  });

  /// Get a description of the limit
  String get limitDescription {
    if (perPeriod != null) {
      return '${maxStay.displayString} per ${perPeriod!.displayString}';
    } else {
      return maxStay.displayString;
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'visaType': visaType.name,
        'maxStay': maxStay.toJson(),
        if (perPeriod != null) 'perPeriod': perPeriod!.toJson(),
        if (description != null) 'description': description,
        'isDefault': isDefault,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
      };

  /// Create from JSON
  factory VisaTimeLimit.fromJson(Map<String, dynamic> json) => VisaTimeLimit(
        visaType: VisaType.values.firstWhere((e) => e.name == json['visaType']),
        maxStay: TimeDuration.fromJson(json['maxStay']),
        perPeriod: json['perPeriod'] != null
            ? TimeDuration.fromJson(json['perPeriod'])
            : null,
        description: json['description'],
        isDefault: json['isDefault'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
      );

  /// Create a copy with updated values
  VisaTimeLimit copyWith({
    VisaType? visaType,
    TimeDuration? maxStay,
    TimeDuration? perPeriod,
    String? description,
    bool? isDefault,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) =>
      VisaTimeLimit(
        visaType: visaType ?? this.visaType,
        maxStay: maxStay ?? this.maxStay,
        perPeriod: perPeriod ?? this.perPeriod,
        description: description ?? this.description,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is VisaTimeLimit &&
          runtimeType == other.runtimeType &&
          visaType == other.visaType &&
          maxStay == other.maxStay &&
          perPeriod == other.perPeriod;

  @override
  int get hashCode => Object.hash(visaType, maxStay, perPeriod);
}

/// Enhanced country time limit configuration
@immutable
class CountryTimeLimitConfig {
  final String countryCode;
  final String countryName;
  final List<VisaTimeLimit> visaLimits;
  final String? notes;
  final bool useCustomDefaults;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic> metadata;

  const CountryTimeLimitConfig({
    required this.countryCode,
    required this.countryName,
    required this.visaLimits,
    this.notes,
    this.useCustomDefaults = false,
    required this.createdAt,
    this.updatedAt,
    this.metadata = const {},
  });

  /// Get the default visa time limit (usually tourist)
  VisaTimeLimit? get defaultVisaLimit {
    // First try to find tourist visa
    try {
      return visaLimits.firstWhere((limit) => limit.visaType == VisaType.tourist);
    } catch (e) {
      // If no tourist visa, return the first one marked as default
      try {
        return visaLimits.firstWhere((limit) => limit.isDefault);
      } catch (e) {
        // If no default, return the first one
        return visaLimits.isNotEmpty ? visaLimits.first : null;
      }
    }
  }

  /// Get time limit for a specific visa type
  VisaTimeLimit? getLimitForVisaType(VisaType visaType) {
    try {
      return visaLimits.firstWhere((limit) => limit.visaType == visaType);
    } catch (e) {
      return null;
    }
  }

  /// Get all visa types configured for this country
  List<VisaType> get configuredVisaTypes {
    return visaLimits.map((limit) => limit.visaType).toList();
  }

  /// Check if this country has custom configuration
  bool get hasCustomConfiguration => visaLimits.isNotEmpty || useCustomDefaults;

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'countryName': countryName,
        'visaLimits': visaLimits.map((limit) => limit.toJson()).toList(),
        if (notes != null) 'notes': notes,
        'useCustomDefaults': useCustomDefaults,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        'metadata': metadata,
      };

  /// Create from JSON
  factory CountryTimeLimitConfig.fromJson(Map<String, dynamic> json) =>
      CountryTimeLimitConfig(
        countryCode: json['countryCode'],
        countryName: json['countryName'],
        visaLimits: (json['visaLimits'] as List<dynamic>)
            .map((limitJson) => VisaTimeLimit.fromJson(limitJson))
            .toList(),
        notes: json['notes'],
        useCustomDefaults: json['useCustomDefaults'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null
            ? DateTime.parse(json['updatedAt'])
            : null,
        metadata: json['metadata'] ?? {},
      );

  /// Create a copy with updated values
  CountryTimeLimitConfig copyWith({
    String? countryCode,
    String? countryName,
    List<VisaTimeLimit>? visaLimits,
    String? notes,
    bool? useCustomDefaults,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) =>
      CountryTimeLimitConfig(
        countryCode: countryCode ?? this.countryCode,
        countryName: countryName ?? this.countryName,
        visaLimits: visaLimits ?? this.visaLimits,
        notes: notes ?? this.notes,
        useCustomDefaults: useCustomDefaults ?? this.useCustomDefaults,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        metadata: metadata ?? this.metadata,
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryTimeLimitConfig &&
          runtimeType == other.runtimeType &&
          countryCode == other.countryCode;

  @override
  int get hashCode => countryCode.hashCode;
}

/// Template for common travel scenarios
@immutable
class TimeLimitTemplate {
  final String id;
  final String name;
  final String description;
  final String? category;
  final List<VisaTimeLimit> defaultLimits;
  final bool isBuiltIn;
  final DateTime createdAt;
  final Map<String, dynamic> metadata;

  const TimeLimitTemplate({
    required this.id,
    required this.name,
    required this.description,
    this.category,
    required this.defaultLimits,
    this.isBuiltIn = false,
    required this.createdAt,
    this.metadata = const {},
  });

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        if (category != null) 'category': category,
        'defaultLimits': defaultLimits.map((limit) => limit.toJson()).toList(),
        'isBuiltIn': isBuiltIn,
        'createdAt': createdAt.toIso8601String(),
        'metadata': metadata,
      };

  /// Create from JSON
  factory TimeLimitTemplate.fromJson(Map<String, dynamic> json) =>
      TimeLimitTemplate(
        id: json['id'],
        name: json['name'],
        description: json['description'],
        category: json['category'],
        defaultLimits: (json['defaultLimits'] as List<dynamic>)
            .map((limitJson) => VisaTimeLimit.fromJson(limitJson))
            .toList(),
        isBuiltIn: json['isBuiltIn'] ?? false,
        createdAt: DateTime.parse(json['createdAt']),
        metadata: json['metadata'] ?? {},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLimitTemplate &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// History entry for tracking changes to time limits
@immutable
class TimeLimitHistoryEntry {
  final String id;
  final String countryCode;
  final String action; // 'created', 'updated', 'deleted', 'visa_added', 'visa_removed'
  final Map<String, dynamic> oldData;
  final Map<String, dynamic> newData;
  final String? notes;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  const TimeLimitHistoryEntry({
    required this.id,
    required this.countryCode,
    required this.action,
    required this.oldData,
    required this.newData,
    this.notes,
    required this.timestamp,
    this.metadata = const {},
  });

  /// Get a human-readable description of the change
  String get changeDescription {
    switch (action) {
      case 'created':
        return 'Created time limit configuration';
      case 'updated':
        return 'Updated time limit configuration';
      case 'deleted':
        return 'Removed time limit configuration';
      case 'visa_added':
        return 'Added visa type configuration';
      case 'visa_removed':
        return 'Removed visa type configuration';
      default:
        return 'Modified configuration';
    }
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() => {
        'id': id,
        'countryCode': countryCode,
        'action': action,
        'oldData': oldData,
        'newData': newData,
        if (notes != null) 'notes': notes,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  /// Create from JSON
  factory TimeLimitHistoryEntry.fromJson(Map<String, dynamic> json) =>
      TimeLimitHistoryEntry(
        id: json['id'],
        countryCode: json['countryCode'],
        action: json['action'],
        oldData: json['oldData'],
        newData: json['newData'],
        notes: json['notes'],
        timestamp: DateTime.parse(json['timestamp']),
        metadata: json['metadata'] ?? {},
      );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TimeLimitHistoryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Validation result for time limit configurations
@immutable
class TimeLimitValidationResult {
  final bool isValid;
  final List<String> errors;
  final List<String> warnings;

  const TimeLimitValidationResult({
    required this.isValid,
    this.errors = const [],
    this.warnings = const [],
  });

  /// Check if there are any issues
  bool get hasIssues => errors.isNotEmpty || warnings.isNotEmpty;

  /// Get all messages (errors and warnings)
  List<String> get allMessages => [...errors, ...warnings];
}

/// Export configuration for time limit data
@immutable
class TimeLimitExportConfig {
  final List<String> countryCodes;
  final List<VisaType> visaTypes;
  final bool includeHistory;
  final bool includeTemplates;
  final String format; // 'json', 'csv', 'xlsx'
  final Map<String, dynamic> options;

  const TimeLimitExportConfig({
    this.countryCodes = const [],
    this.visaTypes = const [],
    this.includeHistory = false,
    this.includeTemplates = false,
    this.format = 'json',
    this.options = const {},
  });

  /// Check if exporting all countries
  bool get exportAllCountries => countryCodes.isEmpty;

  /// Check if exporting all visa types
  bool get exportAllVisaTypes => visaTypes.isEmpty;
}