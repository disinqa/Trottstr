import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';

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

  /// Safely decrypt data with automatic fallback for plaintext data
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

      // Try to decrypt - if it fails, assume it's plaintext
      final decrypted = await decryptData(content);
      
      // If decryption returns empty string, it failed
      if (decrypted.isEmpty && content.isNotEmpty) {
        debugPrint('Decryption returned empty, content may be corrupted');
        return '';
      }
      
      debugPrint('Successfully decrypted data');
      return decrypted;
    } catch (e) {
      debugPrint('Decryption failed: $e');
      // If content looks like encrypted data (not JSON), return empty instead of corrupted data
      if (!content.startsWith('[') && !content.startsWith('{')) {
        debugPrint('Content appears encrypted but decryption failed, returning empty');
        return '';
      }
      // If it looks like JSON, it might be legacy plaintext data
      debugPrint('Content looks like JSON, assuming legacy plaintext');
      return content;
    }
  }
}

/// Provider for the encryption service
final encryptionServiceProvider = Provider<EncryptionService>(
  (ref) => EncryptionService(ref),
);