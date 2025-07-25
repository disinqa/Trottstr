import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/models/custom_country_settings.dart';
import 'package:trottstr/services/encryption_service.dart';
import 'package:trottstr/services/custom_country_settings_service.dart';

/// Service for tracking country stays and calculating tax residency risks
class CountryTrackingService {
  final Ref _ref;

  CountryTrackingService(this._ref);

  static const String _countryEntriesKey = 'country_entries';
  static const String _plannedStaysKey = 'planned_stays';
  static const String _currentLocationKey = 'current_location';

  /// Get all country entries for the current year
  Future<List<CountryEntry>> getCurrentYearEntries() async {
    final entries = await _getAllEntries();
    final currentYear = DateTime.now().year;

    return entries
        .where((entry) => entry.entryDate.year == currentYear)
        .toList()
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
  }

  /// Get all country entries (all years)
  Future<List<CountryEntry>> _getAllEntries() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return [];

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_countryEntriesKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) return [];

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return [];

      // Decrypt the content before parsing
      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(
        encryptedContent,
      );

      // Handle different return types from safeDecryptData
      String jsonString;
      if (decryptedData is String) {
        jsonString = decryptedData;
      } else if (decryptedData is Map<String, dynamic>) {
        // If it returns a Map directly, encode it back to JSON string
        jsonString = json.encode(decryptedData);
      } else {
        debugPrint(
          'Unexpected decrypted data type: ${decryptedData.runtimeType}',
        );
        return [];
      }

      if (jsonString.isEmpty) return [];

      // Validate that we have proper JSON, not encrypted data
      try {
        if (jsonString.startsWith('[') || jsonString.startsWith('{')) {
          final List<dynamic> jsonList = json.decode(jsonString);
          return jsonList.map((json) => CountryEntry.fromJson(json)).toList();
        } else {
          // If it doesn't look like JSON, it might be encrypted data that failed to decrypt
          debugPrint('Received non-JSON data, possibly failed decryption');
          return [];
        }
      } catch (e) {
        debugPrint('Error parsing country entries JSON: $e');
        return [];
      }
    } catch (e) {
      debugPrint('Error in _getAllEntries: $e');
      return [];
    }
  }

  /// Save country entries to storage
  Future<void> _saveEntries(List<CountryEntry> entries) async {
    final signer = _ref.read(Signer.activeSignerProvider);
    if (signer == null) throw Exception('User not signed in');

    final jsonString = json.encode(entries.map((e) => e.toJson()).toList());

    // Encrypt the data before storing
    final encryptionService = _ref.read(encryptionServiceProvider);
    final encryptedContent = await encryptionService.safeEncryptData(
      jsonString,
    );

    final customData = PartialCustomData(
      identifier: _countryEntriesKey,
      content: encryptedContent,
    );
    final signedData = await customData.signWith(signer);

    await _ref.storage.save({signedData});
    await _ref.storage.publish({signedData});
  }

  /// Add a new country entry
  Future<void> addCountryEntry(CountryEntry entry) async {
    final entries = await _getAllEntries();
    entries.add(entry);
    // Sort entries by date to maintain chronological order
    entries.sort((a, b) => a.entryDate.compareTo(b.entryDate));
    await _saveEntries(entries);
  }

  /// Get all country entries with calculated exit information
  Future<List<CountryEntryWithExit>> getAllEntriesWithExitInfo() async {
    final entries = await _getAllEntries();
    return entries.map((entry) => CountryEntryWithExit(entry: entry)).toList();
  }

  /// Get current year entries with exit information
  Future<List<CountryEntryWithExit>> getCurrentYearEntriesWithExitInfo() async {
    final allEntriesWithExit = await getAllEntriesWithExitInfo();
    final currentYear = DateTime.now().year;

    return allEntriesWithExit
        .where(
          (entryWithExit) => entryWithExit.entry.entryDate.year == currentYear,
        )
        .toList();
  }

  /// Add manual exit functionality
  Future<void> addManualExit({
    required DateTime exitDate,
    String? notes,
  }) async {
    final entries = await _getAllEntries();

    // Find entries without an exit date
    final currentEntries = entries
        .where((entry) => entry.exitDate == null)
        .toList();

    if (currentEntries.isEmpty) {
      throw Exception('No current check-in to exit from');
    }

    // Get the latest entry without exit date
    currentEntries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
    final currentEntry = currentEntries.first;

    // Update the entry with exit date
    final updatedEntry = currentEntry.addExit(exitDate);

    // Replace the entry in the list
    final entryIndex = entries.indexWhere((e) => e.id == currentEntry.id);
    if (entryIndex != -1) {
      entries[entryIndex] = updatedEntry;
      await _saveEntries(entries);
    }
  }

  /// Get complete travel history with all details
  Future<List<CountryEntryWithExit>> getCompleteHistory() async {
    return getAllEntriesWithExitInfo();
  }

  /// Record entry to a country
  Future<void> recordCountryEntry({
    required String countryCode,
    DateTime? entryDate,
    String? notes,
    String? location,
    String? purpose,
  }) async {
    final upperCountryCode = countryCode.toUpperCase();
    final newEntryDate = entryDate ?? DateTime.now();

    final entries = await _getAllEntries();

    // Find any existing entries without exit dates (current locations)
    final currentEntries = entries
        .where((entry) => entry.exitDate == null)
        .toList();

    // Auto-exit any current entries by setting their exit date to the day before new entry
    for (final currentEntry in currentEntries) {
      final exitDate = DateTime(
        newEntryDate.year,
        newEntryDate.month,
        newEntryDate.day - 1,
      );

      // Update the entry with exit date
      final updatedEntry = currentEntry.addExit(exitDate);
      final entryIndex = entries.indexWhere((e) => e.id == currentEntry.id);
      if (entryIndex != -1) {
        entries[entryIndex] = updatedEntry;
      }
    }

    // Create new entry (without exit date, making it current)
    final newEntry = CountryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      countryCode: upperCountryCode,
      entryDate: newEntryDate,
      notes: notes,
      location: location,
      purpose: purpose,
    );

    entries.add(newEntry);

    // Sort entries by date to maintain chronological order
    entries.sort((a, b) => a.entryDate.compareTo(b.entryDate));

    await _saveEntries(entries);
  }

  /// Get planned stays
  Future<List<PlannedStay>> getPlannedStays() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return [];

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_plannedStaysKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) return [];

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return [];

      // Decrypt the content before parsing
      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(
        encryptedContent,
      );

      // Handle different return types from safeDecryptData
      String jsonString;
      if (decryptedData is String) {
        jsonString = decryptedData;
      } else if (decryptedData is Map<String, dynamic>) {
        // If it returns a Map directly, encode it back to JSON string
        jsonString = json.encode(decryptedData);
      } else {
        debugPrint(
          'Unexpected decrypted data type: ${decryptedData.runtimeType}',
        );
        return [];
      }

      if (jsonString.isEmpty) return [];

      try {
        final List<dynamic> jsonList = json.decode(jsonString);
        return jsonList.map((json) => PlannedStay.fromJson(json)).toList();
      } catch (e) {
        debugPrint('Error parsing planned stays JSON: $e');
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Save planned stays
  Future<void> _savePlannedStays(List<PlannedStay> plannedStays) async {
    final signer = _ref.read(Signer.activeSignerProvider);
    if (signer == null) throw Exception('User not signed in');

    final jsonString = json.encode(
      plannedStays.map((e) => e.toJson()).toList(),
    );

    // Encrypt the data before storing
    final encryptionService = _ref.read(encryptionServiceProvider);
    final encryptedContent = await encryptionService.safeEncryptData(
      jsonString,
    );

    final customData = PartialCustomData(
      identifier: _plannedStaysKey,
      content: encryptedContent,
    );
    final signedData = await customData.signWith(signer);

    await _ref.storage.save({signedData});
    await _ref.storage.publish({signedData});
  }

  /// Add a planned stay
  Future<void> addPlannedStay(PlannedStay plannedStay) async {
    final plannedStays = await getPlannedStays();
    plannedStays.add(plannedStay);
    await _savePlannedStays(plannedStays);
  }

  /// Remove a planned stay
  Future<void> removePlannedStay(String id) async {
    final plannedStays = await getPlannedStays();
    plannedStays.removeWhere((stay) => stay.id == id);
    await _savePlannedStays(plannedStays);
  }

  /// Calculate days spent in each country for the current year
  Future<Map<String, int>> calculateDaysPerCountry() async {
    final entries = await getCurrentYearEntries();
    final plannedStays = await getPlannedStays();
    final currentYear = DateTime.now().year;

    // Calculate from actual stays
    final Map<String, int> actualDays = _calculateActualDays(entries);

    // Add planned future days
    final Map<String, int> plannedDays = _calculatePlannedDays(
      plannedStays,
      currentYear,
    );

    // Combine actual and planned days
    final Map<String, int> totalDays = <String, int>{};

    // Add actual days
    actualDays.forEach((country, days) {
      totalDays[country] = (totalDays[country] ?? 0) + days;
    });

    // Add planned days
    plannedDays.forEach((country, days) {
      totalDays[country] = (totalDays[country] ?? 0) + days;
    });

    return totalDays;
  }

  /// Calculate actual days from country entries with explicit exit dates
  Map<String, int> _calculateActualDays(List<CountryEntry> entries) {
    final Map<String, int> daysPerCountry = <String, int>{};

    for (final entry in entries) {
      final country = entry.countryCode;
      final daysStayed = entry.daysStayed;

      daysPerCountry[country] = (daysPerCountry[country] ?? 0) + daysStayed;
    }

    return daysPerCountry;
  }

  /// Calculate planned days for a specific year
  Map<String, int> _calculatePlannedDays(
    List<PlannedStay> plannedStays,
    int year,
  ) {
    final Map<String, int> plannedDays = <String, int>{};
    final yearStart = DateTime(year, 1, 1);
    final yearEnd = DateTime(year, 12, 31, 23, 59, 59);

    for (final stay in plannedStays) {
      if (stay.endDate.isBefore(yearStart) || stay.startDate.isAfter(yearEnd)) {
        continue; // Stay is outside the target year
      }

      // Calculate overlap with the year
      final effectiveStart = stay.startDate.isBefore(yearStart)
          ? yearStart
          : stay.startDate;
      final effectiveEnd = stay.endDate.isAfter(yearEnd)
          ? yearEnd
          : stay.endDate;

      final days = effectiveEnd.difference(effectiveStart).inDays + 1;
      plannedDays[stay.countryCode] =
          (plannedDays[stay.countryCode] ?? 0) + days;
    }

    return plannedDays;
  }

  /// Calculate tax residency risks for all countries
  Future<Map<String, TaxResidencyRisk>> calculateTaxResidencyRisks() async {
    final daysPerCountry = await calculateDaysPerCountry();
    final customSettingsService = _ref.read(
      customCountrySettingsServiceProvider,
    );
    final Map<String, TaxResidencyRisk> risks = <String, TaxResidencyRisk>{};

    for (final entry in daysPerCountry.entries) {
      final countryCode = entry.key;
      final days = entry.value;

      // Check for custom settings first
      final customSettings = await customSettingsService
          .getCustomSettingsForCountry(countryCode);
      final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);

      final threshold =
          customSettings?.customDaysThreshold ??
          rule?.daysThreshold ??
          DefaultTaxResidencyRules.defaultThreshold;

      final risk = TaxResidencyRisk(
        countryCode: countryCode,
        countryName: rule?.countryName ?? countryCode,
        currentDays: days,
        threshold: threshold,
        rule: rule,
        customSettings: customSettings,
      );

      risks[countryCode] = risk;
    }

    return risks;
  }

  /// Get current location based on latest entry without exit date
  Future<String?> getCurrentLocation() async {
    try {
      final entries = await _getAllEntries();
      debugPrint('getCurrentLocation: Found ${entries.length} entries');

      // Find the latest entry without an exit date
      final currentEntries = entries
          .where((entry) => entry.exitDate == null)
          .toList();
      debugPrint(
        'getCurrentLocation: Found ${currentEntries.length} current entries',
      );

      if (currentEntries.isEmpty) {
        // Try to get from stored current location as fallback
        debugPrint(
          'getCurrentLocation: No current entries, checking stored location',
        );
        return await _getStoredCurrentLocation();
      }

      // Sort by entry date and get the latest one
      currentEntries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      final countryCode = currentEntries.first.countryCode;
      debugPrint('getCurrentLocation: Returning country code: $countryCode');

      return countryCode;
    } catch (e) {
      debugPrint('getCurrentLocation error: $e');
      return null;
    }
  }

  /// Get stored current location (with decryption)
  Future<String?> _getStoredCurrentLocation() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return null;

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_currentLocationKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) return null;

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return null;

      // Decrypt the content
      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(
        encryptedContent,
      );

      // Handle different return types from safeDecryptData
      String? decryptedLocation;
      try {
        if (decryptedData is String) {
          decryptedLocation = decryptedData;
        } else {
          // For any other type, try to convert to string
          decryptedLocation = decryptedData?.toString();
        }
      } catch (e) {
        debugPrint('Error processing decrypted current location data: $e');
        return null;
      }

      return decryptedLocation?.isNotEmpty == true ? decryptedLocation : null;
    } catch (e) {
      return null;
    }
  }

  /// Save current location to storage
  Future<void> _saveCurrentLocation(String? countryCode) async {
    final signer = _ref.read(Signer.activeSignerProvider);
    if (signer == null) throw Exception('User not signed in');

    // Encrypt the location data before storing
    final encryptionService = _ref.read(encryptionServiceProvider);
    final encryptedContent = await encryptionService.safeEncryptData(
      countryCode ?? '',
    );

    final customData = PartialCustomData(
      identifier: _currentLocationKey,
      content: encryptedContent,
    );
    final signedData = await customData.signWith(signer);

    await _ref.storage.save({signedData});
    await _ref.storage.publish({signedData});
  }

  /// Exit from current country by clearing the current location
  Future<void> exitCurrentCountry(DateTime exitDate) async {
    final currentLocation = await getCurrentLocation();
    if (currentLocation == null) return;

    // Clear the current location (exit means absence of being in any country)
    await _saveCurrentLocation(null);
  }
}

/// Represents tax residency risk for a country
class TaxResidencyRisk {
  final String countryCode;
  final String countryName;
  final int currentDays;
  final int threshold;
  final TaxResidencyRule? rule;
  final CustomCountrySettings? customSettings;

  const TaxResidencyRisk({
    required this.countryCode,
    required this.countryName,
    required this.currentDays,
    required this.threshold,
    this.rule,
    this.customSettings,
  });

  /// Days remaining before becoming tax resident
  int get daysRemaining => threshold - currentDays;

  /// Percentage of threshold reached
  double get percentageUsed => (currentDays / threshold * 100).clamp(0, 100);

  /// Risk level
  RiskLevel get riskLevel {
    if (percentageUsed >= 100) return RiskLevel.exceeded;
    if (percentageUsed >= 90) return RiskLevel.critical;
    if (percentageUsed >= 75) return RiskLevel.high;
    if (percentageUsed >= 50) return RiskLevel.medium;
    return RiskLevel.low;
  }

  /// Whether threshold has been exceeded
  bool get isExceeded => currentDays >= threshold;

  /// Whether close to threshold (within 30 days)
  bool get isCloseToThreshold => daysRemaining <= 30 && daysRemaining > 0;

  /// Whether this country is using custom settings instead of default rules
  bool get hasCustomSettings => customSettings != null;

  /// Get the effective threshold source description
  String get thresholdSource {
    if (hasCustomSettings) {
      return 'Custom limit: $threshold days';
    } else if (rule != null) {
      return 'Default limit: $threshold days';
    } else {
      return 'Default limit: $threshold days';
    }
  }
}

/// Risk level enumeration
enum RiskLevel { low, medium, high, critical, exceeded }

/// Provider for country tracking service
final countryTrackingServiceProvider = Provider<CountryTrackingService>(
  (ref) => CountryTrackingService(ref),
);
