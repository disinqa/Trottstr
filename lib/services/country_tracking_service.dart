import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/models/custom_country_settings.dart';
import 'package:trottstr/services/encryption_service.dart';
import 'package:trottstr/services/notification_monitoring_service.dart';
import 'package:trottstr/providers/country_tax_limits_provider.dart';

/// Service for tracking country stays and calculating tax residency risks
class CountryTrackingService {
  final Ref _ref;

  CountryTrackingService(this._ref);

  static const String _countryEntriesKey = 'country_entries';
  static const String _plannedStaysKey = 'planned_stays';
  static const String _currentLocationKey = 'current_location';

  /// Get all country entries for the current year
  Future<List<CountryEntry>> getCurrentYearEntries() async {
    final entries = await getAllEntries();
    final currentYear = DateTime.now().year;

    return entries
        .where((entry) => entry.entryDate.year == currentYear)
        .toList()
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
  }

  /// Get all country entries (all years)
  Future<List<CountryEntry>> getAllEntries() async {
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

      // Decrypt the content before parsing with enhanced error handling
      final encryptionService = _ref.read(encryptionServiceProvider);

      try {
        final decryptedData = await encryptionService.safeDecryptData(
          encryptedContent,
        );

        if (decryptedData.isEmpty) {
          debugPrint('No decrypted data available');
          return [];
        }

        // Parse and validate JSON data - handle both List and Map formats for backward compatibility
        final dynamic parsedData = json.decode(decryptedData);

        if (parsedData is List<dynamic>) {
          // Expected format: List of country entries
          final entries = parsedData
              .map((json) => CountryEntry.fromJson(json))
              .toList();
          debugPrint('Successfully loaded ${entries.length} country entries');
          return entries;
        } else if (parsedData is Map<String, dynamic>) {
          // Legacy format: Could be a single object - convert to list
          debugPrint(
            'Found legacy Map format for country entries, attempting conversion',
          );
          try {
            final entry = CountryEntry.fromJson(parsedData);
            debugPrint('Successfully converted legacy country entry');
            return [entry];
          } catch (e) {
            debugPrint('Failed to convert legacy country entry: $e');
            return [];
          }
        } else {
          debugPrint('Unknown country entries data format, returning empty list');
          return [];
        }
      } on EncryptionException catch (e) {
        debugPrint('Encryption error loading country entries: ${e.message}');
        debugPrint('Original encrypted data preserved for potential recovery');
        // Return empty list but don't lose the encrypted data
        // TODO: Could implement recovery UI here
        return [];
      } catch (e) {
        debugPrint('Error loading country entries: $e');
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
    final entries = await getAllEntries();
    entries.add(entry);
    // Sort entries by date to maintain chronological order
    entries.sort((a, b) => a.entryDate.compareTo(b.entryDate));
    await _saveEntries(entries);

    // Trigger notification monitoring check
    try {
      final monitoringService = _ref.read(
        notificationMonitoringServiceProvider,
      );
      await monitoringService.onCountryEntry(entry.countryCode);
    } catch (e) {
      debugPrint('Error triggering notification monitoring: $e');
    }
  }

  /// Get all country entries with calculated exit information
  Future<List<CountryEntryWithExit>> getAllEntriesWithExitInfo() async {
    final entries = await getAllEntries();
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

    final entries = await getAllEntries();

    // Find any existing entries without exit dates (current locations)
    final currentEntries = entries
        .where((entry) => entry.exitDate == null)
        .toList();

    // Auto-exit any current entries by setting their exit date to the new entry date
    for (final currentEntry in currentEntries) {
      // Use the new entry date as the exit date for previous country
      final exitDate = DateTime(
        newEntryDate.year,
        newEntryDate.month,
        newEntryDate.day,
      );

      // Update the entry with exit date
      final updatedEntry = currentEntry.addExit(exitDate);
      final entryIndex = entries.indexWhere((e) => e.id == currentEntry.id);
      if (entryIndex != -1) {
        entries[entryIndex] = updatedEntry;
      }

      // Trigger notification monitoring for country exit
      try {
        final monitoringService = _ref.read(
          notificationMonitoringServiceProvider,
        );
        await monitoringService.onCountryExit(currentEntry.countryCode);
      } catch (e) {
        debugPrint('Error triggering notification monitoring: $e');
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

    // Trigger notification monitoring check for new entry
    try {
      final monitoringService = _ref.read(
        notificationMonitoringServiceProvider,
      );
      await monitoringService.onCountryEntry(upperCountryCode);
    } catch (e) {
      debugPrint('Error triggering notification monitoring: $e');
    }
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

      // Decrypt the content before parsing with enhanced error handling
      final encryptionService = _ref.read(encryptionServiceProvider);

      try {
        final decryptedData = await encryptionService.safeDecryptData(
          encryptedContent,
        );

        if (decryptedData.isEmpty) {
          debugPrint('No decrypted planned stays data available');
          return [];
        }

        // Parse and validate JSON data - handle both List and Map formats for backward compatibility
        final dynamic parsedData = json.decode(decryptedData);

        if (parsedData is List<dynamic>) {
          // Expected format: List of planned stays
          final plannedStays = parsedData
              .map((json) => PlannedStay.fromJson(json))
              .toList();
          debugPrint(
            'Successfully loaded ${plannedStays.length} planned stays',
          );
          return plannedStays;
        } else if (parsedData is Map<String, dynamic>) {
          // Legacy format: Could be a single object - convert to list
          debugPrint(
            'Found legacy Map format for planned stays, attempting conversion',
          );
          try {
            final stay = PlannedStay.fromJson(parsedData);
            debugPrint('Successfully converted legacy planned stay');
            return [stay];
          } catch (e) {
            debugPrint('Failed to convert legacy planned stay: $e');
            return [];
          }
        } else {
          debugPrint('Unknown planned stays data format, returning empty list');
          return [];
        }
      } on EncryptionException catch (e) {
        debugPrint('Encryption error loading planned stays: ${e.message}');
        debugPrint('Original encrypted data preserved for potential recovery');
        return [];
      } catch (e) {
        debugPrint('Error loading planned stays: $e');
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

  /// Calculate days spent in each country (all historical data plus current year planned stays)
  Future<Map<String, int>> calculateDaysPerCountry() async {
    final entries = await getAllEntries();
    final plannedStays = await getPlannedStays();
    final currentYear = DateTime.now().year;

    // Calculate from actual stays (all historical data)
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
    final countryTaxLimitsNotifier = _ref.read(
      countryTaxLimitsProvider.notifier,
    );
    final Map<String, TaxResidencyRisk> risks = <String, TaxResidencyRisk>{};

    for (final entry in daysPerCountry.entries) {
      final countryCode = entry.key;
      final days = entry.value;

      // Use the new tax limits system to get effective threshold
      final threshold = countryTaxLimitsNotifier.getLimitForCountry(
        countryCode,
      );
      final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);
      final hasCustomLimit = countryTaxLimitsNotifier.hasCustomLimit(
        countryCode,
      );

      // Create custom settings object if there's a custom limit for backward compatibility
      CustomCountrySettings? customSettings;
      if (hasCustomLimit) {
        customSettings = CustomCountrySettings(
          countryCode: countryCode,
          countryName: rule?.countryName ?? countryCode,
          customDaysThreshold: threshold,
          createdAt: DateTime.now(),
        );
      }

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
      final entries = await getAllEntries();
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

      // Decrypt the content with enhanced error handling
      final encryptionService = _ref.read(encryptionServiceProvider);

      try {
        final decryptedData = await encryptionService.safeDecryptData(
          encryptedContent,
        );

        if (decryptedData.isEmpty) {
          debugPrint('No decrypted current location data available');
          return null;
        }

        debugPrint('Successfully loaded current location: $decryptedData');
        return decryptedData;
      } on EncryptionException catch (e) {
        debugPrint('Encryption error loading current location: ${e.message}');
        debugPrint('Original encrypted data preserved for potential recovery');
        return null;
      } catch (e) {
        debugPrint('Error loading current location: $e');
        return null;
      }
    } catch (e) {
      return null;
    }
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
