import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:trottstr/utils/country_tax_defaults.dart';
import 'package:trottstr/services/encryption_service.dart';

/// Provider for managing country-specific tax residency limits
class CountryTaxLimitsNotifier extends StateNotifier<Map<String, int>> {
  final Ref _ref;
  static const String _storageKey = 'country_tax_limits';

  CountryTaxLimitsNotifier(this._ref) : super({}) {
    _loadLimits();
  }

  /// Load tax limits from storage
  Future<void> _loadLimits() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) {
        // Start with empty state - only user customizations
        state = {};
        return;
      }

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_storageKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) {
        // Start with empty state - only user customizations
        state = {};
        return;
      }

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) {
        state = {};
        return;
      }

      // Decrypt the content before parsing with enhanced error handling
      final encryptionService = _ref.read(encryptionServiceProvider);

      try {
        final decryptedData = await encryptionService.safeDecryptData(
          encryptedContent,
        );

        if (decryptedData.isEmpty) {
          debugPrint('No decrypted country tax limits data available');
          state = {};
          return;
        }

        // Parse and validate JSON data - handle both Map and List formats for backward compatibility
        final dynamic parsedData = json.decode(decryptedData);
        final Map<String, int> limits = {};

        if (parsedData is Map<String, dynamic>) {
          // New format: Direct Map
          parsedData.forEach((key, value) {
            if (value is int) {
              limits[key] = value;
            }
          });
        } else if (parsedData is List<dynamic>) {
          // Legacy format: Could be a list of objects - skip for now and start fresh
          debugPrint(
            'Found legacy list format data, starting with empty limits',
          );
          // We'll let the user re-add their custom limits
        } else {
          debugPrint('Unknown data format, starting with empty limits');
        }

        // Only store user customizations, not defaults
        state = limits;
        debugPrint(
          'Successfully loaded ${limits.length} custom country tax limits',
        );
      } on EncryptionException catch (e) {
        debugPrint('Encryption error loading country tax limits: ${e.message}');
        debugPrint('Original encrypted data preserved for potential recovery');
        state = {};
      } catch (e) {
        debugPrint('Error parsing country tax limits: $e');
        state = {};
      }
    } catch (e) {
      debugPrint('Error loading country tax limits: $e');
      state = {};
    }
  }

  /// Save tax limits to storage
  Future<void> _saveLimits() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) {
        throw Exception('User not signed in');
      }

      final jsonString = json.encode(state);

      // Encrypt the data before storing
      final encryptionService = _ref.read(encryptionServiceProvider);
      final encryptedContent = await encryptionService.safeEncryptData(
        jsonString,
      );

      final customData = PartialCustomData(
        identifier: _storageKey,
        content: encryptedContent,
      );
      final signedData = await customData.signWith(signer);

      await _ref.storage.save({signedData});
      await _ref.storage.publish({signedData});
    } catch (e) {
      debugPrint('Error saving country tax limits: $e');
      rethrow;
    }
  }

  /// Add or update a country's tax limit
  /// Only stores if different from real-world default
  Future<void> setCountryLimit(String countryCode, int days) async {
    final upperCode = countryCode.toUpperCase();
    final defaultLimit = CountryTaxDefaults.getDefaultLimit(upperCode);

    final newState = Map<String, int>.from(state);

    if (days == defaultLimit) {
      // If setting to default, remove any existing customization
      newState.remove(upperCode);
    } else {
      // Only store if different from default
      newState[upperCode] = days;
    }

    state = newState;
    await _saveLimits();
  }

  /// Remove a country's custom limit (will fall back to default)
  Future<void> removeCountryLimit(String countryCode) async {
    final newState = Map<String, int>.from(state);
    newState.remove(countryCode.toUpperCase());
    state = newState;
    await _saveLimits();
  }

  /// Get the effective tax limit for a specific country
  /// This will return the user's custom limit if set, otherwise the real-world default
  int getLimitForCountry(String countryCode) {
    final upperCode = countryCode.toUpperCase();
    return state[upperCode] ?? CountryTaxDefaults.getDefaultLimit(upperCode);
  }

  /// Get the real-world default limit for a country
  int getDefaultLimitForCountry(String countryCode) {
    return CountryTaxDefaults.getDefaultLimit(countryCode);
  }

  /// Check if a country has a user-customized limit (different from default)
  bool hasCustomLimit(String countryCode) {
    final upperCode = countryCode.toUpperCase();
    if (!state.containsKey(upperCode)) return false;

    final userValue = state[upperCode]!;
    final defaultValue = CountryTaxDefaults.getDefaultLimit(upperCode);
    return userValue != defaultValue;
  }

  /// Get all user-customized limits (only countries with values different from defaults)
  Map<String, int> getCustomLimits() {
    return Map.fromEntries(
      state.entries.where((entry) {
        final defaultLimit = CountryTaxDefaults.getDefaultLimit(entry.key);
        return entry.value != defaultLimit;
      }),
    );
  }

  /// Reset all limits (clear all customizations)
  Future<void> resetToDefaults() async {
    state = {};
    await _saveLimits();
  }

  /// Clean up any stored values that match defaults
  Future<void> cleanupDefaultValues() async {
    final newState = <String, int>{};

    for (final entry in state.entries) {
      final defaultLimit = CountryTaxDefaults.getDefaultLimit(entry.key);
      if (entry.value != defaultLimit) {
        newState[entry.key] = entry.value;
      }
    }

    if (newState.length != state.length) {
      state = newState;
      await _saveLimits();
    }
  }

  /// Restore a country to its real-world default (remove customization)
  Future<void> restoreCountryToDefault(String countryCode) async {
    final newState = Map<String, int>.from(state);
    newState.remove(countryCode.toUpperCase());
    state = newState;
    await _saveLimits();
  }
}

/// Provider for country tax limits
final countryTaxLimitsProvider =
    StateNotifierProvider<CountryTaxLimitsNotifier, Map<String, int>>(
      (ref) => CountryTaxLimitsNotifier(ref),
    );

/// Provider for getting the limit of a specific country
final countryLimitProvider = Provider.family<int, String>((ref, countryCode) {
  final limits = ref.watch(countryTaxLimitsProvider);
  final upperCode = countryCode.toUpperCase();
  return limits[upperCode] ?? CountryTaxDefaults.getDefaultLimit(upperCode);
});

/// Provider for getting custom limits count
final customLimitsCountProvider = Provider<int>((ref) {
  final limits = ref.watch(countryTaxLimitsProvider);
  return limits.entries.where((entry) {
    final defaultLimit = CountryTaxDefaults.getDefaultLimit(entry.key);
    return entry.value != defaultLimit;
  }).length;
});
