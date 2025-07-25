import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:models/models.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/encryption_service.dart';

/// Service for managing favorite countries with encrypted storage
class FavoriteCountriesService {
  final Ref _ref;

  FavoriteCountriesService(this._ref);

  static const String _favoriteCountriesKey = 'favorite_countries';
  static const int maxFavoriteCount = 5;

  /// Get all favorite countries
  Future<List<String>> getFavoriteCountries() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return [];

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_favoriteCountriesKey},
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
      jsonString = decryptedData;

      if (jsonString.isEmpty) return [];

      // Validate that we have proper JSON, not encrypted data
      try {
        if (jsonString.startsWith('[') || jsonString.startsWith('{')) {
          final List<dynamic> jsonList = json.decode(jsonString);
          // Filter and convert to strings, handling both string and object formats
          final List<String> favoriteCountries = [];
          for (final item in jsonList) {
            if (item is String) {
              favoriteCountries.add(item);
            } else if (item is Map<String, dynamic>) {
              // Handle legacy format or corrupted data
              // Try to extract country code if it's an object
              if (item.containsKey('code') && item['code'] is String) {
                favoriteCountries.add(item['code']);
              } else if (item.containsKey('countryCode') &&
                  item['countryCode'] is String) {
                favoriteCountries.add(item['countryCode']);
              }
              // Skip invalid objects
            }
            // Skip any other types
          }
          return favoriteCountries;
        } else {
          // If it doesn't look like JSON, it might be encrypted data that failed to decrypt
          debugPrint('Received non-JSON data, possibly failed decryption');
          return [];
        }
      } catch (e) {
        debugPrint('Error parsing favorite countries JSON: $e');
        return [];
      }
    } catch (e) {
      debugPrint('Error in getFavoriteCountries: $e');
      return [];
    }
  }

  /// Save favorite countries to storage
  Future<void> _saveFavoriteCountries(List<String> favoriteCountries) async {
    final signer = _ref.read(Signer.activeSignerProvider);
    if (signer == null) throw Exception('User not signed in');

    final jsonString = json.encode(favoriteCountries);

    // Encrypt the data before storing
    final encryptionService = _ref.read(encryptionServiceProvider);
    final encryptedContent = await encryptionService.safeEncryptData(
      jsonString,
    );

    final customData = PartialCustomData(
      identifier: _favoriteCountriesKey,
      content: encryptedContent,
    );
    final signedData = await customData.signWith(signer);

    await _ref.storage.save({signedData});
    await _ref.storage.publish({signedData});
  }

  /// Add a country to favorites
  Future<FavoriteCountryResult> addFavoriteCountry(String countryCode) async {
    try {
      final upperCountryCode = countryCode.toUpperCase();

      // DEBUG: Print stack trace to see who's calling this
      debugPrint('🔍 DEBUG: addFavoriteCountry called for $upperCountryCode');
      debugPrint('🔍 DEBUG: Stack trace:');
      debugPrint(StackTrace.current.toString());

      final favorites = await getFavoriteCountries();

      // Check if already a favorite
      if (favorites.contains(upperCountryCode)) {
        debugPrint('🔍 DEBUG: $upperCountryCode is already a favorite');
        return FavoriteCountryResult.alreadyFavorite;
      }

      // Check if at max limit
      if (favorites.length >= maxFavoriteCount) {
        debugPrint(
          '🔍 DEBUG: Max favorite limit reached (${favorites.length}/$maxFavoriteCount)',
        );
        return FavoriteCountryResult.maxLimitReached;
      }

      // Add the new favorite
      debugPrint(
        '🔍 DEBUG: Adding $upperCountryCode to favorites. Current favorites: $favorites',
      );
      final updatedFavorites = [...favorites, upperCountryCode];
      await _saveFavoriteCountries(updatedFavorites);
      debugPrint(
        '🔍 DEBUG: Successfully added $upperCountryCode to favorites. New list: $updatedFavorites',
      );

      return FavoriteCountryResult.success;
    } catch (e) {
      debugPrint('🔍 DEBUG: Error adding favorite country: $e');
      return FavoriteCountryResult.error;
    }
  }

  /// Remove a country from favorites
  Future<FavoriteCountryResult> removeFavoriteCountry(
    String countryCode,
  ) async {
    try {
      final upperCountryCode = countryCode.toUpperCase();
      final favorites = await getFavoriteCountries();

      // Check if it's actually a favorite
      if (!favorites.contains(upperCountryCode)) {
        return FavoriteCountryResult.notAFavorite;
      }

      // Remove the favorite
      final updatedFavorites = favorites
          .where((code) => code != upperCountryCode)
          .toList();
      await _saveFavoriteCountries(updatedFavorites);

      return FavoriteCountryResult.success;
    } catch (e) {
      debugPrint('Error removing favorite country: $e');
      return FavoriteCountryResult.error;
    }
  }

  /// Toggle favorite status of a country
  Future<FavoriteCountryResult> toggleFavoriteCountry(
    String countryCode,
  ) async {
    final upperCountryCode = countryCode.toUpperCase();

    // DEBUG: Print stack trace to see who's calling this
    debugPrint('🔍 DEBUG: toggleFavoriteCountry called for $upperCountryCode');
    debugPrint('🔍 DEBUG: Stack trace:');
    debugPrint(StackTrace.current.toString());

    final favorites = await getFavoriteCountries();

    if (favorites.contains(upperCountryCode)) {
      debugPrint('🔍 DEBUG: $upperCountryCode is a favorite, removing it');
      return await removeFavoriteCountry(upperCountryCode);
    } else {
      debugPrint('🔍 DEBUG: $upperCountryCode is not a favorite, adding it');
      return await addFavoriteCountry(upperCountryCode);
    }
  }

  /// Check if a country is a favorite
  Future<bool> isFavoriteCountry(String countryCode) async {
    final favorites = await getFavoriteCountries();
    return favorites.contains(countryCode.toUpperCase());
  }

  /// Get the current count of favorite countries
  Future<int> getFavoriteCount() async {
    final favorites = await getFavoriteCountries();
    return favorites.length;
  }

  /// Check if can add more favorites
  Future<bool> canAddMoreFavorites() async {
    final count = await getFavoriteCount();
    return count < maxFavoriteCount;
  }
}

/// Result enum for favorite country operations
enum FavoriteCountryResult {
  success,
  alreadyFavorite,
  notAFavorite,
  maxLimitReached,
  error,
}

/// Extension to get user-friendly messages for results
extension FavoriteCountryResultExtension on FavoriteCountryResult {
  String get message {
    switch (this) {
      case FavoriteCountryResult.success:
        return 'Success';
      case FavoriteCountryResult.alreadyFavorite:
        return 'Country is already a favorite';
      case FavoriteCountryResult.notAFavorite:
        return 'Country is not a favorite';
      case FavoriteCountryResult.maxLimitReached:
        return 'Maximum of ${FavoriteCountriesService.maxFavoriteCount} favorites allowed';
      case FavoriteCountryResult.error:
        return 'An error occurred';
    }
  }

  bool get isSuccess => this == FavoriteCountryResult.success;
}

/// Provider for favorite countries service
final favoriteCountriesServiceProvider = Provider<FavoriteCountriesService>(
  (ref) => FavoriteCountriesService(ref),
);
