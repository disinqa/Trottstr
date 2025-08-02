import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';

/// Quick diagnostic utility for encryption protocol verification
/// This provides a simple way to verify encryption protocol in production
class QuickEncryptionDiagnostic {
  final Ref _ref;

  QuickEncryptionDiagnostic(this._ref);

  /// Quick check of current encryption protocol
  /// Returns a simple status report for monitoring/logging
  Future<EncryptionStatusReport> quickCheck() async {
    final report = EncryptionStatusReport();

    try {
      final signer = _ref.read(Signer.activeSignerProvider);

      if (signer == null) {
        report.status = EncryptionStatus.noSigner;
        report.message = 'No active signer - cannot verify encryption';
        return report;
      }

      // Check if NIP44 methods are available and working
      try {
        const testData = 'quick_diagnostic_test';
        final userPubkey = signer.pubkey;

        // Test NIP44 encryption/decryption
        final encrypted = await signer.nip44Encrypt(testData, userPubkey);
        final decrypted = await signer.nip44Decrypt(encrypted, userPubkey);

        if (decrypted == testData) {
          report.status = EncryptionStatus.nip44Working;
          report.protocol = 'NIP44';
          report.message = 'NIP44 encryption verified and working correctly';
          report.isSecure = true;
        } else {
          report.status = EncryptionStatus.nip44Failed;
          report.protocol = 'NIP44';
          report.message = 'NIP44 encryption test failed - decryption mismatch';
          report.isSecure = false;
        }
      } catch (e) {
        // NIP44 failed, check if NIP04 is being used instead
        try {
          const testData = 'quick_diagnostic_test_nip04';
          final userPubkey = signer.pubkey;

          final encrypted = await signer.nip04Encrypt(testData, userPubkey);
          final decrypted = await signer.nip04Decrypt(encrypted, userPubkey);

          if (decrypted == testData) {
            report.status = EncryptionStatus.nip04Working;
            report.protocol = 'NIP04';
            report.message = 'WARNING: Using deprecated NIP04 encryption';
            report.isSecure = false; // NIP04 is considered insecure
            report.recommendations.add(
              'Upgrade to NIP44 encryption immediately',
            );
          } else {
            report.status = EncryptionStatus.bothFailed;
            report.message = 'Both NIP44 and NIP04 encryption tests failed';
            report.isSecure = false;
          }
        } catch (nip04Error) {
          report.status = EncryptionStatus.bothFailed;
          report.message = 'Both NIP44 and NIP04 encryption failed';
          report.isSecure = false;
          report.technicalDetails['nip44_error'] = e.toString();
          report.technicalDetails['nip04_error'] = nip04Error.toString();
        }
      }
    } catch (e) {
      report.status = EncryptionStatus.error;
      report.message = 'Diagnostic failed: $e';
      report.isSecure = false;
      report.technicalDetails['error'] = e.toString();
    }

    // Add timestamp
    report.timestamp = DateTime.now();

    // Log result
    debugPrint(
      '🔍 Encryption Diagnostic: ${report.status.name} - ${report.message}',
    );

    return report;
  }

  /// Generate a simple JSON report for logging/monitoring
  Future<String> generateJsonReport() async {
    final report = await quickCheck();
    return json.encode(report.toJson());
  }

  /// Check if current encryption meets security standards
  Future<bool> isSecurityCompliant() async {
    final report = await quickCheck();
    return report.isSecure && report.protocol == 'NIP44';
  }
}

/// Simple status report for encryption diagnostics
class EncryptionStatusReport {
  EncryptionStatus status = EncryptionStatus.unknown;
  String protocol = 'Unknown';
  String message = '';
  bool isSecure = false;
  DateTime? timestamp;
  List<String> recommendations = [];
  Map<String, dynamic> technicalDetails = {};

  /// Convert to JSON for logging/monitoring
  Map<String, dynamic> toJson() => {
    'status': status.name,
    'protocol': protocol,
    'message': message,
    'isSecure': isSecure,
    'timestamp': timestamp?.toIso8601String(),
    'recommendations': recommendations,
    'technicalDetails': technicalDetails,
  };

  /// Generate a human-readable summary
  String get summary => '$protocol: $message (Secure: $isSecure)';
}

/// Encryption status enumeration
enum EncryptionStatus {
  unknown,
  noSigner,
  nip44Working,
  nip44Failed,
  nip04Working,
  bothFailed,
  error,
}

/// Provider for quick encryption diagnostic
final quickEncryptionDiagnosticProvider = Provider<QuickEncryptionDiagnostic>(
  (ref) => QuickEncryptionDiagnostic(ref),
);

/// Convenience provider for security compliance check
final encryptionComplianceProvider = FutureProvider<bool>((ref) async {
  final diagnostic = ref.read(quickEncryptionDiagnosticProvider);
  return await diagnostic.isSecurityCompliant();
});

/// Convenience provider for current encryption status
final encryptionStatusProvider = FutureProvider<EncryptionStatusReport>((
  ref,
) async {
  final diagnostic = ref.read(quickEncryptionDiagnosticProvider);
  return await diagnostic.quickCheck();
});
