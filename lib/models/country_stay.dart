
/// Represents a country entry record
class CountryEntry {
  final String id;
  final String countryCode;
  final DateTime entryDate;
  final DateTime? exitDate;
  final String? notes;
  final String? location;
  final String? purpose;

  const CountryEntry({
    required this.id,
    required this.countryCode,
    required this.entryDate,
    this.exitDate,
    this.notes,
    this.location,
    this.purpose,
  });

  /// Check if this entry is currently active (no exit date)
  bool get isCurrentLocation => exitDate == null;

  /// Calculate duration of stay
  Duration get stayDuration {
    final endDate = exitDate ?? DateTime.now();
    final entryDay = DateTime(entryDate.year, entryDate.month, entryDate.day);
    final endDay = DateTime(endDate.year, endDate.month, endDate.day);
    return endDay.difference(entryDay);
  }

  /// Calculate number of days stayed
  int get daysStayed {
    return stayDuration.inDays + 1; // +1 to include both entry and exit days
  }

  /// Get a formatted string showing the stay period
  String get stayPeriodString {
    final entryStr = '${entryDate.day}/${entryDate.month}/${entryDate.year}';
    
    if (isCurrentLocation) {
      return 'Entered $entryStr (Currently here - $daysStayed days)';
    }
    
    final exitStr = '${exitDate!.day}/${exitDate!.month}/${exitDate!.year}';
    return 'Stayed $entryStr - $exitStr ($daysStayed days)';
  }

  /// Create an exit record for this entry
  CountryEntry addExit(DateTime exitDate) {
    return copyWith(exitDate: exitDate);
  }

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'countryCode': countryCode,
        'entryDate': entryDate.toIso8601String(),
        if (exitDate != null) 'exitDate': exitDate!.toIso8601String(),
        if (notes != null) 'notes': notes,
        if (location != null) 'location': location,
        if (purpose != null) 'purpose': purpose,
      };

  /// Create from JSON
  factory CountryEntry.fromJson(Map<String, dynamic> json) => CountryEntry(
        id: json['id'],
        countryCode: json['countryCode'],
        entryDate: DateTime.parse(json['entryDate']),
        exitDate: json['exitDate'] != null ? DateTime.parse(json['exitDate']) : null,
        notes: json['notes'],
        location: json['location'],
        purpose: json['purpose'],
      );

  /// Create a copy with modified fields
  CountryEntry copyWith({
    String? id,
    String? countryCode,
    DateTime? entryDate,
    DateTime? exitDate,
    String? notes,
    String? location,
    String? purpose,
  }) =>
      CountryEntry(
        id: id ?? this.id,
        countryCode: countryCode ?? this.countryCode,
        entryDate: entryDate ?? this.entryDate,
        exitDate: exitDate ?? this.exitDate,
        notes: notes ?? this.notes,
        location: location ?? this.location,
        purpose: purpose ?? this.purpose,
      );

  @override
  String toString() => 'Entered $countryCode on ${entryDate.toLocal()}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryEntry &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a planned future stay
class PlannedStay {
  final String id;
  final String countryCode;
  final DateTime startDate;
  final DateTime endDate;
  final String? purpose;
  final String? notes;

  const PlannedStay({
    required this.id,
    required this.countryCode,
    required this.startDate,
    required this.endDate,
    this.purpose,
    this.notes,
  });

  /// Duration of the planned stay
  Duration get duration => endDate.difference(startDate);

  /// Number of days for the planned stay
  int get daysCount => duration.inDays + 1;

  /// Check if the planned stay is current (happening now)
  bool get isCurrent {
    final now = DateTime.now();
    return now.isAfter(startDate) && now.isBefore(endDate);
  }

  /// Check if the planned stay is in the future
  bool get isFuture => DateTime.now().isBefore(startDate);

  /// Check if the planned stay is in the past
  bool get isPast => DateTime.now().isAfter(endDate);

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'id': id,
        'countryCode': countryCode,
        'startDate': startDate.toIso8601String(),
        'endDate': endDate.toIso8601String(),
        if (purpose != null) 'purpose': purpose,
        if (notes != null) 'notes': notes,
      };

  /// Create from JSON
  factory PlannedStay.fromJson(Map<String, dynamic> json) => PlannedStay(
        id: json['id'],
        countryCode: json['countryCode'],
        startDate: DateTime.parse(json['startDate']),
        endDate: DateTime.parse(json['endDate']),
        purpose: json['purpose'],
        notes: json['notes'],
      );

  /// Create a copy with modified fields
  PlannedStay copyWith({
    String? id,
    String? countryCode,
    DateTime? startDate,
    DateTime? endDate,
    String? purpose,
    String? notes,
  }) =>
      PlannedStay(
        id: id ?? this.id,
        countryCode: countryCode ?? this.countryCode,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
        purpose: purpose ?? this.purpose,
        notes: notes ?? this.notes,
      );

  @override
  String toString() => 'Planned stay in $countryCode from $startDate to $endDate';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PlannedStay &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Represents a country entry with calculated exit information
class CountryEntryWithExit {
  final CountryEntry entry;

  const CountryEntryWithExit({
    required this.entry,
  });

  /// Get the exit date (from entry or null if still current)
  DateTime? get exitDate => entry.exitDate;

  /// Get the number of days stayed
  int get daysStayed => entry.daysStayed;

  /// Check if this is the current location
  bool get isCurrentLocation => entry.isCurrentLocation;

  /// Get a formatted string showing the complete stay information
  String get stayDescription => entry.stayPeriodString;

  /// Check if this stay overlaps with a given date range
  bool overlapsWithPeriod(DateTime start, DateTime end) {
    final stayStart = entry.entryDate;
    final stayEnd = entry.exitDate ?? DateTime.now();
    
    return stayStart.isBefore(end) && stayEnd.isAfter(start);
  }
}