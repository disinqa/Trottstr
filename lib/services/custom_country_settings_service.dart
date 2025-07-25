import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/encryption_service.dart';
import 'package:trottstr/models/custom_country_settings.dart';
import 'package:trottstr/models/tax_residency_rule.dart';

/// Service for managing custom country time limit settings with encrypted storage
class CustomCountrySettingsService {
  final Ref _ref;

  CustomCountrySettingsService(this._ref);

  static const String _customCountrySettingsKey = 'custom_country_settings';

  /// Get all custom country settings
  Future<List<CustomCountrySettings>> getCustomCountrySettings() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return [];

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_customCountrySettingsKey},
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
      final decryptedData = await encryptionService.safeDecryptData(encryptedContent);
      
      // Handle different return types from safeDecryptData
      String jsonString;
      jsonString = decryptedData;
          
      if (jsonString.isEmpty) return [];

      // Validate that we have proper JSON, not encrypted data
      try {
        if (jsonString.startsWith('[') || jsonString.startsWith('{')) {
          final List<dynamic> jsonList = json.decode(jsonString);
          return jsonList.map((json) => CustomCountrySettings.fromJson(json)).toList();
        } else {
          // If it doesn't look like JSON, it might be encrypted data that failed to decrypt
          debugPrint('Received non-JSON data, possibly failed decryption');
          return [];
        }
      } catch (e) {
        debugPrint('Error parsing custom country settings JSON: $e');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getCustomCountrySettings: $e');
      return [];
    }
  }

  /// Get custom settings for a specific country
  Future<CustomCountrySettings?> getCustomSettingsForCountry(String countryCode) async {
    final allSettings = await getCustomCountrySettings();
    try {
      return allSettings.firstWhere(
        (settings) => settings.countryCode == countryCode.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Check if a country has custom settings
  Future<bool> hasCustomSettings(String countryCode) async {
    final settings = await getCustomSettingsForCountry(countryCode);
    return settings != null;
  }

  /// Save custom country settings to storage
  Future<void> _saveCustomCountrySettings(List<CustomCountrySettings> settings) async {
    final signer = _ref.read(Signer.activeSignerProvider);
    if (signer == null) throw Exception('User not signed in');

    final jsonString = json.encode(settings.map((s) => s.toJson()).toList());

    // Encrypt the data before storing
    final encryptionService = _ref.read(encryptionServiceProvider);
    final encryptedContent = await encryptionService.safeEncryptData(jsonString);

    final customData = PartialCustomData(
      identifier: _customCountrySettingsKey,
      content: encryptedContent,
    );
    final signedData = await customData.signWith(signer);

    await _ref.storage.save({signedData});
    await _ref.storage.publish({signedData});
  }

  /// Set custom time limit for a country
  Future<CustomCountrySettingsResult> setCustomTimeLimit({
    required String countryCode,
    required String countryName,
    required int daysThreshold,
    String? notes,
  }) async {
    try {
      final upperCountryCode = countryCode.toUpperCase();
      final allSettings = await getCustomCountrySettings();
      
      // Check if settings already exist for this country
      final existingIndex = allSettings.indexWhere(
        (settings) => settings.countryCode == upperCountryCode,
      );

      final now = DateTime.now();
      
      if (existingIndex >= 0) {
        // Update existing settings
        final existingSettings = allSettings[existingIndex];
        allSettings[existingIndex] = existingSettings.copyWith(
          countryName: countryName,
          customDaysThreshold: daysThreshold,
          updatedAt: now,
          notes: notes,
        );
      } else {
        // Add new settings
        final newSettings = CustomCountrySettings(
          countryCode: upperCountryCode,
          countryName: countryName,
          customDaysThreshold: daysThreshold,
          createdAt: now,
          notes: notes,
        );
        allSettings.add(newSettings);
      }

      await _saveCustomCountrySettings(allSettings);
      return CustomCountrySettingsResult.success;
    } catch (e) {
      debugPrint('Error setting custom time limit: $e');
      return CustomCountrySettingsResult.error;
    }
  }

  /// Remove custom settings for a country
  Future<CustomCountrySettingsResult> removeCustomSettings(String countryCode) async {
    try {
      final upperCountryCode = countryCode.toUpperCase();
      final allSettings = await getCustomCountrySettings();
      
      // Check if settings exist for this country
      final existingIndex = allSettings.indexWhere(
        (settings) => settings.countryCode == upperCountryCode,
      );

      if (existingIndex < 0) {
        return CustomCountrySettingsResult.notFound;
      }

      // Remove the settings
      allSettings.removeAt(existingIndex);
      await _saveCustomCountrySettings(allSettings);
      
      return CustomCountrySettingsResult.success;
    } catch (e) {
      debugPrint('Error removing custom settings: $e');
      return CustomCountrySettingsResult.error;
    }
  }

  /// Get effective time limit for a country (custom if available, otherwise default)
  Future<int> getEffectiveTimeLimit(String countryCode) async {
    final customSettings = await getCustomSettingsForCountry(countryCode);
    if (customSettings != null) {
      return customSettings.customDaysThreshold;
    }

    // Fall back to default tax residency rules
    final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);
    return rule?.daysThreshold ?? DefaultTaxResidencyRules.defaultThreshold;
  }

  /// Get all countries with custom settings as a map
  Future<Map<String, CustomCountrySettings>> getCustomSettingsMap() async {
    final settings = await getCustomCountrySettings();
    return {for (final setting in settings) setting.countryCode: setting};
  }

  /// Update notes for a country's custom settings
  Future<CustomCountrySettingsResult> updateNotes(String countryCode, String? notes) async {
    try {
      final upperCountryCode = countryCode.toUpperCase();
      final allSettings = await getCustomCountrySettings();
      
      final existingIndex = allSettings.indexWhere(
        (settings) => settings.countryCode == upperCountryCode,
      );

      if (existingIndex < 0) {
        return CustomCountrySettingsResult.notFound;
      }

      // Update notes
      final existingSettings = allSettings[existingIndex];
      allSettings[existingIndex] = existingSettings.copyWith(
        notes: notes,
        updatedAt: DateTime.now(),
      );

      await _saveCustomCountrySettings(allSettings);
      return CustomCountrySettingsResult.success;
    } catch (e) {
      debugPrint('Error updating notes: $e');
      return CustomCountrySettingsResult.error;
    }
  }
}

/// Provider for custom country settings service
final customCountrySettingsServiceProvider = Provider<CustomCountrySettingsService>(
  (ref) => CustomCountrySettingsService(ref),
);