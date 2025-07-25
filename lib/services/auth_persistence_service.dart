import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service for persisting authentication state securely
class AuthPersistenceService {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
  );

  // Storage keys
  static const _authMethodKey = 'auth_method';
  static const _nsecKey = 'nsec_private_key';

  /// Auth methods
  static const String authMethodAmber = 'amber';
  static const String authMethodNsec = 'nsec';

  /// Save auth method (amber or nsec)
  static Future<void> saveAuthMethod(String method) async {
    try {
      await _storage.write(key: _authMethodKey, value: method);
      debugPrint('Auth method saved: $method');
    } catch (e) {
      debugPrint('Failed to save auth method: $e');
      rethrow;
    }
  }

  /// Get saved auth method
  static Future<String?> getAuthMethod() async {
    try {
      final method = await _storage.read(key: _authMethodKey);
      debugPrint('Retrieved auth method: $method');
      return method;
    } catch (e) {
      debugPrint('Failed to get auth method: $e');
      return null;
    }
  }

  /// Save nsec private key securely
  static Future<void> saveNsec(String nsec) async {
    try {
      await _storage.write(key: _nsecKey, value: nsec);
      debugPrint('Nsec saved securely');
    } catch (e) {
      debugPrint('Failed to save nsec: $e');
      rethrow;
    }
  }

  /// Get saved nsec private key
  static Future<String?> getNsec() async {
    try {
      final nsec = await _storage.read(key: _nsecKey);
      debugPrint('Retrieved nsec: ${nsec != null ? '[HIDDEN]' : 'null'}');
      return nsec;
    } catch (e) {
      debugPrint('Failed to get nsec: $e');
      return null;
    }
  }

  /// Clear all auth state
  static Future<void> clearAuthState() async {
    try {
      await _storage.delete(key: _authMethodKey);
      await _storage.delete(key: _nsecKey);
      debugPrint('Auth state cleared');
    } catch (e) {
      debugPrint('Failed to clear auth state: $e');
      rethrow;
    }
  }

  /// Check if user has saved auth state
  static Future<bool> hasAuthState() async {
    try {
      final method = await getAuthMethod();
      return method != null;
    } catch (e) {
      debugPrint('Failed to check auth state: $e');
      return false;
    }
  }
}