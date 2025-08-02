import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';

/// Custom exception for encryption/decryption failures that preserves original data
class EncryptionException implements Exception {
  final String message;
  final String originalData;

  const EncryptionException(this.message, this.originalData);

  @override
  String toString() => 'EncryptionException: $message';
}

/// Service for encrypting and decrypting sensitive data using NIP-44
/// This service encrypts data with the user's own public key for self-encryption
class EncryptionService {
  final Ref _ref;

  EncryptionService(this._ref);

  /// Encrypt data using NIP-44 with the user's own public key (self-encryption)
  Future<String> encryptData(String plaintext) async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) {
        throw Exception('User not signed in - cannot encrypt data');
      }

      // Use the user's own public key for self-encryption
      final userPubkey = signer.pubkey;
      
      // Encrypt the data using NIP-44
      final encryptedContent = await signer.nip44Encrypt(
        plaintext,
        userPubkey,
      );

      debugPrint('Data encrypted successfully');
      return encryptedContent;
    } catch (e) {
      debugPrint('Failed to encrypt data: $e');
      rethrow;
    }
  }

  /// Decrypt data using NIP-44 with the user's own public key (self-decryption)
  Future<String> decryptData(String encryptedContent) async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) {
        throw Exception('User not signed in - cannot decrypt data');
      }

      // Use the user's own public key for self-decryption
      final userPubkey = signer.pubkey;
      
      // Decrypt the data using NIP-44
      final decryptedContent = await signer.nip44Decrypt(
        encryptedContent,
        userPubkey,
      );

      debugPrint('Data decrypted successfully');
      return decryptedContent;
    } catch (e) {
      debugPrint('Failed to decrypt data: $e');
      // Return empty string on decryption failure to gracefully handle corrupted data
      return '';
    }
  }

  /// Check if the current user can encrypt/decrypt data
  bool canEncrypt() {
    final signer = _ref.read(Signer.activeSignerProvider);
    return signer != null;
  }

  /// Safely encrypt data with fallback to plaintext if encryption fails
  Future<String> safeEncryptData(String plaintext) async {
    try {
      if (!canEncrypt()) {
        debugPrint('Cannot encrypt - user not signed in, storing as plaintext');
        return plaintext;
      }
      
      return await encryptData(plaintext);
    } catch (e) {
      debugPrint('Encryption failed, falling back to plaintext: $e');
      return plaintext;
    }
  }

  /// Safely decrypt data with robust error handling and retry logic
  Future<String> safeDecryptData(String content) async {
    try {
      if (!canEncrypt()) {
        debugPrint('Cannot decrypt - user not signed in, assuming plaintext');
        return content;
      }

      // Check if content looks like plaintext JSON (starts with [ or {)
      if (content.startsWith('[') || content.startsWith('{')) {
        debugPrint('Content appears to be plaintext JSON, skipping decryption');
        return content;
      }

      // Try to decrypt with retry logic
      final decrypted = await _decryptWithRetry(content, maxRetries: 3);
      
      // Validate decrypted content
      if (decrypted.isEmpty && content.isNotEmpty) {
        debugPrint('Decryption failed after retries - preserving encrypted data for recovery');
        throw EncryptionException('Decryption failed after multiple attempts', content);
      }
      
      // Validate JSON structure if decryption succeeded
      if (decrypted.isNotEmpty && !_isValidJson(decrypted)) {
        debugPrint('Decrypted content is not valid JSON - possible corruption');
        throw EncryptionException('Decrypted content validation failed', content);
      }
      
      debugPrint('Successfully decrypted and validated data');
      return decrypted;
    } catch (e) {
      if (e is EncryptionException) {
        // Preserve original encrypted data for potential recovery
        debugPrint('Encryption error: ${e.message} - Original data preserved');
        rethrow;
      }
      
      debugPrint('Decryption failed: $e');
      // If content looks like encrypted data (not JSON), preserve it
      if (!content.startsWith('[') && !content.startsWith('{')) {
        debugPrint('Content appears encrypted but decryption failed - preserving for recovery');
        throw EncryptionException('Failed to decrypt non-JSON content: $e', content);
      }
      // If it looks like JSON, it might be legacy plaintext data
      debugPrint('Content looks like JSON, assuming legacy plaintext');
      return content;
    }
  }

  /// Decrypt with exponential backoff retry logic
  Future<String> _decryptWithRetry(String content, {int maxRetries = 3}) async {
    for (int attempt = 1; attempt <= maxRetries; attempt++) {
      try {
        final result = await decryptData(content);
        if (result.isNotEmpty) {
          return result;
        }
        // If empty but no exception, treat as failure
        if (attempt < maxRetries) {
          final delay = Duration(milliseconds: 100 * attempt); // Exponential backoff
          debugPrint('Decryption attempt $attempt failed, retrying in ${delay.inMilliseconds}ms');
          await Future.delayed(delay);
        }
      } catch (e) {
        debugPrint('Decryption attempt $attempt failed: $e');
        if (attempt == maxRetries) {
          rethrow;
        }
        final delay = Duration(milliseconds: 100 * attempt);
        await Future.delayed(delay);
      }
    }
    return '';
  }

  /// Validate JSON structure
  bool _isValidJson(String jsonString) {
    try {
      if (jsonString.trim().isEmpty) return false;
      final decoded = json.decode(jsonString);
      return decoded != null;
    } catch (e) {
      return false;
    }
  }
}

/// Provider for the encryption service
final encryptionServiceProvider = Provider<EncryptionService>(
  (ref) => EncryptionService(ref),
);