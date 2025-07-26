import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/time_limit_models.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/services/encryption_service.dart';

/// Comprehensive service for managing country-specific time limits with visa support
class TimeLimitManagementService {
  final Ref _ref;

  TimeLimitManagementService(this._ref);

  static const String _timeLimitConfigsKey = 'time_limit_configs';
  static const String _timeLimitTemplatesKey = 'time_limit_templates';
  static const String _timeLimitHistoryKey = 'time_limit_history';

  /// Get all country time limit configurations
  Future<List<CountryTimeLimitConfig>> getAllConfigurations() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return [];

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_timeLimitConfigsKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) return [];

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return [];

      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(encryptedContent);
      
      if (decryptedData.isEmpty) return [];

      try {
        if (decryptedData.startsWith('[') || decryptedData.startsWith('{')) {
          final List<dynamic> jsonList = json.decode(decryptedData);
          return jsonList.map((json) => CountryTimeLimitConfig.fromJson(json)).toList();
        } else {
          debugPrint('Received non-JSON data, possibly failed decryption');
          return [];
        }
      } catch (e) {
        debugPrint('Error parsing time limit configurations JSON: $e');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getAllConfigurations: $e');
      return [];
    }
  }

  /// Save time limit configurations to storage
  Future<void> _saveConfigurations(List<CountryTimeLimitConfig> configs) async {
    final signer = _ref.read(Signer.activeSignerProvider);
    if (signer == null) throw Exception('User not signed in');

    final jsonString = json.encode(configs.map((c) => c.toJson()).toList());

    final encryptionService = _ref.read(encryptionServiceProvider);
    final encryptedContent = await encryptionService.safeEncryptData(jsonString);

    final customData = PartialCustomData(
      identifier: _timeLimitConfigsKey,
      content: encryptedContent,
    );
    final signedData = await customData.signWith(signer);

    await _ref.storage.save({signedData});
    await _ref.storage.publish({signedData});
  }

  /// Get configuration for a specific country
  Future<CountryTimeLimitConfig?> getConfigurationForCountry(String countryCode) async {
    final allConfigs = await getAllConfigurations();
    try {
      return allConfigs.firstWhere(
        (config) => config.countryCode == countryCode.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a country has custom configuration
  Future<bool> hasCustomConfiguration(String countryCode) async {
    final config = await getConfigurationForCountry(countryCode);
    return config != null;
  }

  /// Set time limit configuration for a country
  Future<void> setCountryConfiguration(CountryTimeLimitConfig config) async {
    final allConfigs = await getAllConfigurations();
    final existingIndex = allConfigs.indexWhere(
      (c) => c.countryCode == config.countryCode,
    );

    final now = DateTime.now();
    CountryTimeLimitConfig updatedConfig;

    if (existingIndex >= 0) {
      // Update existing configuration
      final oldConfig = allConfigs[existingIndex];
      updatedConfig = config.copyWith(
        createdAt: oldConfig.createdAt,
        updatedAt: now,
      );
      allConfigs[existingIndex] = updatedConfig;

      // Record history
      await _addHistoryEntry(TimeLimitHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        countryCode: config.countryCode,
        action: 'updated',
        oldData: oldConfig.toJson(),
        newData: updatedConfig.toJson(),
        timestamp: now,
      ));
    } else {
      // Add new configuration
      updatedConfig = config.copyWith(
        createdAt: now,
        updatedAt: now,
      );
      allConfigs.add(updatedConfig);

      // Record history
      await _addHistoryEntry(TimeLimitHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        countryCode: config.countryCode,
        action: 'created',
        oldData: {},
        newData: updatedConfig.toJson(),
        timestamp: now,
      ));
    }

    await _saveConfigurations(allConfigs);
  }

  /// Remove configuration for a country
  Future<void> removeCountryConfiguration(String countryCode) async {
    final allConfigs = await getAllConfigurations();
    final existingIndex = allConfigs.indexWhere(
      (c) => c.countryCode == countryCode.toUpperCase(),
    );

    if (existingIndex >= 0) {
      final oldConfig = allConfigs[existingIndex];
      allConfigs.removeAt(existingIndex);

      // Record history
      await _addHistoryEntry(TimeLimitHistoryEntry(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        countryCode: countryCode.toUpperCase(),
        action: 'deleted',
        oldData: oldConfig.toJson(),
        newData: {},
        timestamp: DateTime.now(),
      ));

      await _saveConfigurations(allConfigs);
    }
  }

  /// Add or update visa time limit for a country
  Future<void> setVisaTimeLimit({
    required String countryCode,
    required String countryName,
    required VisaTimeLimit visaLimit,
  }) async {
    final config = await getConfigurationForCountry(countryCode) ??
        CountryTimeLimitConfig(
          countryCode: countryCode.toUpperCase(),
          countryName: countryName,
          visaLimits: [],
          createdAt: DateTime.now(),
        );

    final existingLimitIndex = config.visaLimits.indexWhere(
      (limit) => limit.visaType == visaLimit.visaType,
    );

    final updatedLimits = List<VisaTimeLimit>.from(config.visaLimits);
    final now = DateTime.now();

    if (existingLimitIndex >= 0) {
      // Update existing visa limit
      updatedLimits[existingLimitIndex] = visaLimit.copyWith(
        createdAt: updatedLimits[existingLimitIndex].createdAt,
        updatedAt: now,
      );
    } else {
      // Add new visa limit
      updatedLimits.add(visaLimit.copyWith(
        createdAt: now,
        updatedAt: now,
      ));
    }

    final updatedConfig = config.copyWith(
      visaLimits: updatedLimits,
      updatedAt: now,
    );

    await setCountryConfiguration(updatedConfig);
  }

  /// Remove visa time limit for a country
  Future<void> removeVisaTimeLimit({
    required String countryCode,
    required VisaType visaType,
  }) async {
    final config = await getConfigurationForCountry(countryCode);
    if (config == null) return;

    final updatedLimits = config.visaLimits
        .where((limit) => limit.visaType != visaType)
        .toList();

    if (updatedLimits.length < config.visaLimits.length) {
      final updatedConfig = config.copyWith(
        visaLimits: updatedLimits,
        updatedAt: DateTime.now(),
      );

      await setCountryConfiguration(updatedConfig);
    }
  }

  /// Get effective time limit for a country and visa type
  Future<TimeDuration> getEffectiveTimeLimit({
    required String countryCode,
    VisaType visaType = VisaType.tourist,
  }) async {
    final config = await getConfigurationForCountry(countryCode);
    
    // Check for custom configuration first
    if (config != null) {
      final visaLimit = config.getLimitForVisaType(visaType);
      if (visaLimit != null) {
        return visaLimit.maxStay;
      }
      
      // If specific visa type not found, try default
      final defaultLimit = config.defaultVisaLimit;
      if (defaultLimit != null) {
        return defaultLimit.maxStay;
      }
    }

    // Fall back to default tax residency rules
    final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);
    final days = rule?.daysThreshold ?? DefaultTaxResidencyRules.defaultThreshold;
    
    return TimeDuration.fromDays(days);
  }

  /// Validate time limit configuration
  TimeLimitValidationResult validateConfiguration(CountryTimeLimitConfig config) {
    final errors = <String>[];
    final warnings = <String>[];

    // Basic validation
    if (config.countryCode.isEmpty) {
      errors.add('Country code cannot be empty');
    }

    if (config.countryName.isEmpty) {
      errors.add('Country name cannot be empty');
    }

    if (config.visaLimits.isEmpty) {
      warnings.add('No visa types configured for this country');
    }

    // Validate each visa limit
    for (final visaLimit in config.visaLimits) {
      if (visaLimit.maxStay.value <= 0) {
        errors.add('${visaLimit.visaType.displayName}: Maximum stay must be greater than 0');
      }

      if (visaLimit.maxStay.totalDays > 3650) { // 10 years
        warnings.add('${visaLimit.visaType.displayName}: Very long stay period (${visaLimit.maxStay.displayString})');
      }

      if (visaLimit.perPeriod != null) {
        if (visaLimit.perPeriod!.totalDays <= visaLimit.maxStay.totalDays) {
          errors.add('${visaLimit.visaType.displayName}: Period must be longer than maximum stay');
        }
      }
    }

    // Check for duplicate visa types
    final visaTypes = config.visaLimits.map((limit) => limit.visaType).toList();
    final uniqueVisaTypes = visaTypes.toSet();
    if (visaTypes.length != uniqueVisaTypes.length) {
      errors.add('Duplicate visa types found');
    }

    return TimeLimitValidationResult(
      isValid: errors.isEmpty,
      errors: errors,
      warnings: warnings,
    );
  }

  /// Bulk update multiple countries
  Future<Map<String, bool>> bulkUpdateCountries({
    required List<String> countryCodes,
    required List<VisaTimeLimit> visaLimits,
    String? notes,
  }) async {
    final results = <String, bool>{};
    
    for (final countryCode in countryCodes) {
      try {
        // Get country name from existing config or default rules
        final existingConfig = await getConfigurationForCountry(countryCode);
        final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);
        final countryName = existingConfig?.countryName ?? 
                          rule?.countryName ?? 
                          countryCode;

        final config = CountryTimeLimitConfig(
          countryCode: countryCode.toUpperCase(),
          countryName: countryName,
          visaLimits: visaLimits,
          notes: notes,
          createdAt: DateTime.now(),
        );

        final validation = validateConfiguration(config);
        if (validation.isValid) {
          await setCountryConfiguration(config);
          results[countryCode] = true;
        } else {
          debugPrint('Validation failed for $countryCode: ${validation.errors}');
          results[countryCode] = false;
        }
      } catch (e) {
        debugPrint('Error updating $countryCode: $e');
        results[countryCode] = false;
      }
    }

    return results;
  }

  /// Get all available templates
  Future<List<TimeLimitTemplate>> getAllTemplates() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return _getBuiltInTemplates();

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_timeLimitTemplatesKey},
          },
          limit: 1,
        ).toRequest(),
      );

      final userTemplates = <TimeLimitTemplate>[];
      if (customDataList.isNotEmpty) {
        final latestData = customDataList.first;
        final encryptedContent = latestData.content;

        if (encryptedContent.isNotEmpty) {
          final encryptionService = _ref.read(encryptionServiceProvider);
          final decryptedData = await encryptionService.safeDecryptData(encryptedContent);
          
          if (decryptedData.isNotEmpty && 
              (decryptedData.startsWith('[') || decryptedData.startsWith('{'))) {
            final List<dynamic> jsonList = json.decode(decryptedData);
            userTemplates.addAll(
              jsonList.map((json) => TimeLimitTemplate.fromJson(json)),
            );
          }
        }
      }

      // Combine built-in and user templates
      return [..._getBuiltInTemplates(), ...userTemplates];
    } catch (e) {
      debugPrint('Error loading templates: $e');
      return _getBuiltInTemplates();
    }
  }

  /// Get built-in templates
  List<TimeLimitTemplate> _getBuiltInTemplates() {
    final now = DateTime.now();
    
    return [
      TimeLimitTemplate(
        id: 'schengen_tourist',
        name: 'Schengen Tourist',
        description: 'Standard tourist limits for Schengen Area countries',
        category: 'Tourist',
        defaultLimits: [
          VisaTimeLimit(
            visaType: VisaType.tourist,
            maxStay: const TimeDuration(value: 90, unit: TimeUnit.days),
            perPeriod: const TimeDuration(value: 180, unit: TimeUnit.days),
            description: '90 days in any 180-day period',
            isDefault: true,
            createdAt: now,
          ),
        ],
        isBuiltIn: true,
        createdAt: now,
      ),
      TimeLimitTemplate(
        id: 'us_standard',
        name: 'US Standard',
        description: 'Standard US visa limits',
        category: 'Popular Destinations',
        defaultLimits: [
          VisaTimeLimit(
            visaType: VisaType.tourist,
            maxStay: const TimeDuration(value: 90, unit: TimeUnit.days),
            description: 'Tourist/Business visitor',
            isDefault: true,
            createdAt: now,
          ),
          VisaTimeLimit(
            visaType: VisaType.business,
            maxStay: const TimeDuration(value: 183, unit: TimeUnit.days),
            description: 'Business activities',
            createdAt: now,
          ),
        ],
        isBuiltIn: true,
        createdAt: now,
      ),
      TimeLimitTemplate(
        id: 'nomad_friendly',
        name: 'Digital Nomad Friendly',
        description: 'Countries with favorable digital nomad policies',
        category: 'Digital Nomad',
        defaultLimits: [
          VisaTimeLimit(
            visaType: VisaType.tourist,
            maxStay: const TimeDuration(value: 90, unit: TimeUnit.days),
            description: 'Tourist stay',
            createdAt: now,
          ),
          VisaTimeLimit(
            visaType: VisaType.nomad,
            maxStay: const TimeDuration(value: 1, unit: TimeUnit.years),
            description: 'Digital nomad visa',
            isDefault: true,
            createdAt: now,
          ),
        ],
        isBuiltIn: true,
        createdAt: now,
      ),
      TimeLimitTemplate(
        id: 'short_stay',
        name: 'Short Stay',
        description: 'Countries with short tourist stay limits',
        category: 'Tourist',
        defaultLimits: [
          VisaTimeLimit(
            visaType: VisaType.tourist,
            maxStay: const TimeDuration(value: 30, unit: TimeUnit.days),
            description: 'Short tourist stay',
            isDefault: true,
            createdAt: now,
          ),
        ],
        isBuiltIn: true,
        createdAt: now,
      ),
    ];
  }

  /// Apply template to countries
  Future<Map<String, bool>> applyTemplateToCountries({
    required String templateId,
    required List<String> countryCodes,
    String? additionalNotes,
  }) async {
    final templates = await getAllTemplates();
    final template = templates.where((t) => t.id == templateId).firstOrNull;
    
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    return await bulkUpdateCountries(
      countryCodes: countryCodes,
      visaLimits: template.defaultLimits,
      notes: additionalNotes ?? template.description,
    );
  }

  /// Export time limit configurations
  Future<Map<String, dynamic>> exportConfigurations(TimeLimitExportConfig exportConfig) async {
    final allConfigs = await getAllConfigurations();
    
    // Filter configurations based on export config
    final filteredConfigs = allConfigs.where((config) {
      if (!exportConfig.exportAllCountries && 
          !exportConfig.countryCodes.contains(config.countryCode)) {
        return false;
      }
      return true;
    }).map((config) {
      // Filter visa types if specified
      if (!exportConfig.exportAllVisaTypes) {
        final filteredLimits = config.visaLimits
            .where((limit) => exportConfig.visaTypes.contains(limit.visaType))
            .toList();
        return config.copyWith(visaLimits: filteredLimits);
      }
      return config;
    }).toList();

    final exportData = <String, dynamic>{
      'configurations': filteredConfigs.map((c) => c.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'exportConfig': {
        'countryCodes': exportConfig.countryCodes,
        'visaTypes': exportConfig.visaTypes.map((v) => v.name).toList(),
        'format': exportConfig.format,
      },
    };

    if (exportConfig.includeTemplates) {
      final templates = await getAllTemplates();
      exportData['templates'] = templates.map((t) => t.toJson()).toList();
    }

    if (exportConfig.includeHistory) {
      final history = await getHistory();
      exportData['history'] = history.map((h) => h.toJson()).toList();
    }

    return exportData;
  }

  /// Get history of changes
  Future<List<TimeLimitHistoryEntry>> getHistory({String? countryCode}) async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return [];

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_timeLimitHistoryKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) return [];

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return [];

      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(encryptedContent);
      
      if (decryptedData.isEmpty) return [];

      final List<dynamic> jsonList = json.decode(decryptedData);
      final allHistory = jsonList
          .map((json) => TimeLimitHistoryEntry.fromJson(json))
          .toList();

      // Filter by country if specified
      if (countryCode != null) {
        return allHistory
            .where((entry) => entry.countryCode == countryCode.toUpperCase())
            .toList();
      }

      return allHistory;
    } catch (e) {
      debugPrint('Error loading history: $e');
      return [];
    }
  }

  /// Add history entry
  Future<void> _addHistoryEntry(TimeLimitHistoryEntry entry) async {
    try {
      final currentHistory = await getHistory();
      currentHistory.add(entry);

      // Keep only last 1000 entries
      if (currentHistory.length > 1000) {
        currentHistory.removeRange(0, currentHistory.length - 1000);
      }

      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return;

      final jsonString = json.encode(currentHistory.map((h) => h.toJson()).toList());

      final encryptionService = _ref.read(encryptionServiceProvider);
      final encryptedContent = await encryptionService.safeEncryptData(jsonString);

      final customData = PartialCustomData(
        identifier: _timeLimitHistoryKey,
        content: encryptedContent,
      );
      final signedData = await customData.signWith(signer);

      await _ref.storage.save({signedData});
      await _ref.storage.publish({signedData});
    } catch (e) {
      debugPrint('Error saving history: $e');
    }
  }

  /// Get statistics about time limit configurations
  Future<Map<String, dynamic>> getStatistics() async {
    final allConfigs = await getAllConfigurations();
    final history = await getHistory();

    final visaTypeCounts = <VisaType, int>{};
    final countryCount = allConfigs.length;
    var totalVisaLimits = 0;

    for (final config in allConfigs) {
      totalVisaLimits += config.visaLimits.length;
      for (final limit in config.visaLimits) {
        visaTypeCounts[limit.visaType] = (visaTypeCounts[limit.visaType] ?? 0) + 1;
      }
    }

    return {
      'totalCountries': countryCount,
      'totalVisaLimits': totalVisaLimits,
      'visaTypeCounts': visaTypeCounts.map(
        (type, count) => MapEntry(type.displayName, count),
      ),
      'historyEntries': history.length,
      'lastModified': allConfigs.isNotEmpty
          ? allConfigs
              .map((c) => c.updatedAt ?? c.createdAt)
              .reduce((a, b) => a.isAfter(b) ? a : b)
              .toIso8601String()
          : null,
    };
  }
}

/// Provider for time limit management service
final timeLimitManagementServiceProvider = Provider<TimeLimitManagementService>(
  (ref) => TimeLimitManagementService(ref),
);