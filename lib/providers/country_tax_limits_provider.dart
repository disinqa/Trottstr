import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';

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
        _setDefaultLimits();
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
        _setDefaultLimits();
        return;
      }

      final latestData = customDataList.first;
      final content = latestData.content;

      if (content.isEmpty) {
        _setDefaultLimits();
        return;
      }

      try {
        final Map<String, dynamic> jsonData = json.decode(content);
        final Map<String, int> limits = {};
        
        jsonData.forEach((key, value) {
          if (value is int) {
            limits[key] = value;
          }
        });

        if (limits.isNotEmpty) {
          state = limits;
        } else {
          _setDefaultLimits();
        }
      } catch (e) {
        debugPrint('Error parsing country tax limits: $e');
        _setDefaultLimits();
      }
    } catch (e) {
      debugPrint('Error loading country tax limits: $e');
      _setDefaultLimits();
    }
  }

  /// Set default limits for common countries
  void _setDefaultLimits() {
    state = {
      'US': 183, // United States
      'GB': 183, // United Kingdom  
      'DE': 183, // Germany
      'FR': 183, // France
      'ES': 183, // Spain
      'IT': 183, // Italy
      'NL': 183, // Netherlands
      'CH': 183, // Switzerland
      'AT': 183, // Austria
      'BE': 183, // Belgium
      'SE': 183, // Sweden
      'NO': 183, // Norway
      'DK': 183, // Denmark
      'FI': 183, // Finland
      'PL': 183, // Poland
      'CZ': 183, // Czech Republic
      'HU': 183, // Hungary
      'PT': 183, // Portugal
      'IE': 183, // Ireland
      'LU': 183, // Luxembourg
      'CA': 183, // Canada
      'AU': 183, // Australia
      'NZ': 183, // New Zealand
      'JP': 183, // Japan
      'SG': 183, // Singapore
    };
  }

  /// Save tax limits to storage
  Future<void> _saveLimits() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) {
        throw Exception('User not signed in');
      }

      final jsonString = json.encode(state);

      final customData = PartialCustomData(
        identifier: _storageKey,
        content: jsonString,
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
  Future<void> setCountryLimit(String countryCode, int days) async {
    final newState = Map<String, int>.from(state);
    newState[countryCode.toUpperCase()] = days;
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

  /// Get the tax limit for a specific country
  int getLimitForCountry(String countryCode) {
    return state[countryCode.toUpperCase()] ?? 183; // Default to 183 days
  }

  /// Get all countries with custom limits (not 183 days)
  Map<String, int> getCustomLimits() {
    return Map.fromEntries(
      state.entries.where((entry) => entry.value != 183),
    );
  }

  /// Reset all limits to default
  Future<void> resetToDefaults() async {
    _setDefaultLimits();
    await _saveLimits();
  }
}

/// Provider for country tax limits
final countryTaxLimitsProvider = StateNotifierProvider<CountryTaxLimitsNotifier, Map<String, int>>(
  (ref) => CountryTaxLimitsNotifier(ref),
);

/// Provider for getting the limit of a specific country
final countryLimitProvider = Provider.family<int, String>((ref, countryCode) {
  final limits = ref.watch(countryTaxLimitsProvider);
  return limits[countryCode.toUpperCase()] ?? 183;
});

/// Provider for getting custom limits count
final customLimitsCountProvider = Provider<int>((ref) {
  final limits = ref.watch(countryTaxLimitsProvider);
  return limits.entries.where((entry) => entry.value != 183).length;
});