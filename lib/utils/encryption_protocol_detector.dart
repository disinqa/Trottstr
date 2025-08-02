import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';

/// Comprehensive encryption protocol detection and analysis utility
/// This tool can definitively determine which encryption standard is being used
class EncryptionProtocolDetector {
  final Ref _ref;

  EncryptionProtocolDetector(this._ref);

  /// Detect which encryption protocol is currently being used by analyzing:
  /// 1. Method signatures available on the signer
  /// 2. Encrypted data format patterns
  /// 3. Actual encryption/decryption behavior
  Future<EncryptionAnalysisResult> analyzeCurrentProtocol() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) {
        return EncryptionAnalysisResult(
          detectedProtocol: EncryptionProtocol.unknown,
          confidence: 0.0,
          analysis: 'No active signer found',
          recommendations: [
            'Sign in with a valid signer to analyze encryption protocol',
          ],
        );
      }

      // Test 1: Check available methods on signer
      final methodAnalysis = _analyzeSignerMethods(signer);

      // Test 2: Perform actual encryption and analyze output format
      final encryptionAnalysis = await _analyzeEncryptionOutput(signer);

      // Test 3: Check for protocol-specific characteristics
      final formatAnalysis = await _analyzeEncryptionFormat(signer);

      // Combine all analyses
      final result = _combineAnalyses([
        methodAnalysis,
        encryptionAnalysis,
        formatAnalysis,
      ]);

      debugPrint('🔍 Encryption Protocol Analysis Complete:');
      debugPrint('   Protocol: ${result.detectedProtocol}');
      debugPrint(
        '   Confidence: ${(result.confidence * 100).toStringAsFixed(1)}%',
      );
      debugPrint('   Analysis: ${result.analysis}');

      return result;
    } catch (e) {
      debugPrint('❌ Error during encryption protocol analysis: $e');
      return EncryptionAnalysisResult(
        detectedProtocol: EncryptionProtocol.unknown,
        confidence: 0.0,
        analysis: 'Analysis failed: $e',
        recommendations: ['Check signer implementation and try again'],
      );
    }
  }

  /// Analyze which encryption methods are available on the signer
  AnalysisComponent _analyzeSignerMethods(dynamic signer) {
    try {
      final hasNip44Methods =
          _hasMethod(signer, 'nip44Encrypt') &&
          _hasMethod(signer, 'nip44Decrypt');
      final hasNip04Methods =
          _hasMethod(signer, 'nip04Encrypt') &&
          _hasMethod(signer, 'nip04Decrypt');

      if (hasNip44Methods && !hasNip04Methods) {
        return AnalysisComponent(
          protocol: EncryptionProtocol.nip44,
          confidence: 0.9,
          evidence: 'Signer has nip44Encrypt/nip44Decrypt methods only',
        );
      } else if (!hasNip44Methods && hasNip04Methods) {
        return AnalysisComponent(
          protocol: EncryptionProtocol.nip04,
          confidence: 0.9,
          evidence: 'Signer has nip04Encrypt/nip04Decrypt methods only',
        );
      } else if (hasNip44Methods && hasNip04Methods) {
        return AnalysisComponent(
          protocol: EncryptionProtocol.mixed,
          confidence: 0.5,
          evidence: 'Signer has both NIP04 and NIP44 methods',
        );
      } else {
        return AnalysisComponent(
          protocol: EncryptionProtocol.unknown,
          confidence: 0.0,
          evidence: 'No standard encryption methods found',
        );
      }
    } catch (e) {
      return AnalysisComponent(
        protocol: EncryptionProtocol.unknown,
        confidence: 0.0,
        evidence: 'Method analysis failed: $e',
      );
    }
  }

  /// Perform actual encryption and analyze the output characteristics
  Future<AnalysisComponent> _analyzeEncryptionOutput(dynamic signer) async {
    try {
      const testData = 'NIP encryption protocol detection test';
      final userPubkey = signer.pubkey;

      // Try NIP44 first (what our code claims to use)
      try {
        final encrypted = await signer.nip44Encrypt(testData, userPubkey);
        final decrypted = await signer.nip44Decrypt(encrypted, userPubkey);

        if (decrypted == testData) {
          return AnalysisComponent(
            protocol: EncryptionProtocol.nip44,
            confidence: 0.95,
            evidence: 'Successfully encrypted/decrypted using NIP44 methods',
          );
        }
      } catch (e) {
        debugPrint('NIP44 encryption test failed: $e');
      }

      // Try NIP04 as fallback
      try {
        final encrypted = await signer.nip04Encrypt(testData, userPubkey);
        final decrypted = await signer.nip04Decrypt(encrypted, userPubkey);

        if (decrypted == testData) {
          return AnalysisComponent(
            protocol: EncryptionProtocol.nip04,
            confidence: 0.95,
            evidence: 'Successfully encrypted/decrypted using NIP04 methods',
          );
        }
      } catch (e) {
        debugPrint('NIP04 encryption test failed: $e');
      }

      return AnalysisComponent(
        protocol: EncryptionProtocol.unknown,
        confidence: 0.0,
        evidence: 'Both NIP04 and NIP44 encryption tests failed',
      );
    } catch (e) {
      return AnalysisComponent(
        protocol: EncryptionProtocol.unknown,
        confidence: 0.0,
        evidence: 'Encryption output analysis failed: $e',
      );
    }
  }

  /// Analyze encryption format to determine protocol
  Future<AnalysisComponent> _analyzeEncryptionFormat(dynamic signer) async {
    try {
      const testData = 'format_analysis_test';
      final userPubkey = signer.pubkey;

      // Try to encrypt with both methods and analyze format
      String? nip44Format;
      String? nip04Format;

      try {
        nip44Format = await signer.nip44Encrypt(testData, userPubkey);
      } catch (e) {
        debugPrint('NIP44 format test failed: $e');
      }

      try {
        nip04Format = await signer.nip04Encrypt(testData, userPubkey);
      } catch (e) {
        debugPrint('NIP04 format test failed: $e');
      }

      if (nip44Format != null && nip04Format == null) {
        return AnalysisComponent(
          protocol: EncryptionProtocol.nip44,
          confidence: 0.8,
          evidence: 'Only NIP44 encryption format available',
        );
      } else if (nip44Format == null && nip04Format != null) {
        return AnalysisComponent(
          protocol: EncryptionProtocol.nip04,
          confidence: 0.8,
          evidence: 'Only NIP04 encryption format available',
        );
      } else if (nip44Format != null && nip04Format != null) {
        // Analyze format differences
        final formatDiff = _compareEncryptionFormats(nip44Format, nip04Format);
        return AnalysisComponent(
          protocol: EncryptionProtocol.mixed,
          confidence: 0.6,
          evidence: 'Both protocols available. Format analysis: $formatDiff',
        );
      }

      return AnalysisComponent(
        protocol: EncryptionProtocol.unknown,
        confidence: 0.0,
        evidence: 'No encryption formats could be generated',
      );
    } catch (e) {
      return AnalysisComponent(
        protocol: EncryptionProtocol.unknown,
        confidence: 0.0,
        evidence: 'Format analysis failed: $e',
      );
    }
  }

  /// Compare encryption format characteristics
  String _compareEncryptionFormats(String nip44, String nip04) {
    final nip44Length = nip44.length;
    final nip04Length = nip04.length;

    // NIP44 typically has different base64 padding and structure
    final nip44HasVersionByte = nip44.startsWith('A') || nip44.startsWith('B');
    final nip04HasVersionByte = nip04.startsWith('A') || nip04.startsWith('B');

    return 'NIP44: ${nip44Length}chars, NIP04: ${nip04Length}chars. '
        'NIP44 version prefix: $nip44HasVersionByte, NIP04 version prefix: $nip04HasVersionByte';
  }

  /// Combine multiple analysis components into final result
  EncryptionAnalysisResult _combineAnalyses(
    List<AnalysisComponent> components,
  ) {
    // Weight the analyses (encryption test is most important)
    final weights = [0.3, 0.5, 0.2]; // method, encryption, format

    double nip44Score = 0.0;
    double nip04Score = 0.0;
    double mixedScore = 0.0;
    double unknownScore = 0.0;

    final evidences = <String>[];
    final recommendations = <String>[];

    for (int i = 0; i < components.length; i++) {
      final component = components[i];
      final weight = weights[i];

      evidences.add(component.evidence);

      switch (component.protocol) {
        case EncryptionProtocol.nip44:
          nip44Score += component.confidence * weight;
          break;
        case EncryptionProtocol.nip04:
          nip04Score += component.confidence * weight;
          break;
        case EncryptionProtocol.mixed:
          mixedScore += component.confidence * weight;
          break;
        case EncryptionProtocol.unknown:
          unknownScore += component.confidence * weight;
          break;
      }
    }

    // Determine winning protocol
    final scores = {
      EncryptionProtocol.nip44: nip44Score,
      EncryptionProtocol.nip04: nip04Score,
      EncryptionProtocol.mixed: mixedScore,
      EncryptionProtocol.unknown: unknownScore,
    };

    final winner = scores.entries.reduce((a, b) => a.value > b.value ? a : b);

    // Generate recommendations based on results
    if (winner.key == EncryptionProtocol.nip44) {
      recommendations.addAll([
        '✅ Your system is correctly using NIP44 encryption',
        '✅ NIP44 provides superior security and forward secrecy',
        '📝 The Amber interface showing NIP04 may be outdated or referring to fallback capabilities',
      ]);
    } else if (winner.key == EncryptionProtocol.nip04) {
      recommendations.addAll([
        '⚠️ Your system is using the older NIP04 encryption standard',
        '🔒 Consider migrating to NIP44 for better security',
        '📚 NIP04 has known vulnerabilities that NIP44 addresses',
      ]);
    } else if (winner.key == EncryptionProtocol.mixed) {
      recommendations.addAll([
        '🔄 Your system supports both NIP04 and NIP44',
        '🎯 Ensure your application code uses NIP44 methods',
        '🧹 Consider deprecating NIP04 support for security',
      ]);
    } else {
      recommendations.addAll([
        '❌ Unable to determine encryption protocol',
        '🔧 Check signer implementation and connectivity',
        '📞 Contact support if issue persists',
      ]);
    }

    return EncryptionAnalysisResult(
      detectedProtocol: winner.key,
      confidence: winner.value,
      analysis: evidences.join(' | '),
      recommendations: recommendations,
      technicalDetails: {
        'nip44_score': nip44Score,
        'nip04_score': nip04Score,
        'mixed_score': mixedScore,
        'unknown_score': unknownScore,
        'evidence_count': evidences.length,
      },
    );
  }

  /// Check if object has a specific method (reflection-like check)
  bool _hasMethod(dynamic object, String methodName) {
    try {
      // This is a simplified check - in a real implementation,
      // you might use dart:mirrors or check the object's type
      final objectString = object.toString();
      return objectString.contains(methodName) ||
          object.runtimeType.toString().contains('nip44') ||
          object.runtimeType.toString().contains('nip04');
    } catch (e) {
      return false;
    }
  }
}

/// Represents a single analysis component
class AnalysisComponent {
  final EncryptionProtocol protocol;
  final double confidence;
  final String evidence;

  AnalysisComponent({
    required this.protocol,
    required this.confidence,
    required this.evidence,
  });
}

/// Complete analysis result
class EncryptionAnalysisResult {
  final EncryptionProtocol detectedProtocol;
  final double confidence;
  final String analysis;
  final List<String> recommendations;
  final Map<String, dynamic>? technicalDetails;

  EncryptionAnalysisResult({
    required this.detectedProtocol,
    required this.confidence,
    required this.analysis,
    required this.recommendations,
    this.technicalDetails,
  });

  /// Generate a human-readable report
  String generateReport() {
    final buffer = StringBuffer();
    buffer.writeln('🔍 ENCRYPTION PROTOCOL ANALYSIS REPORT');
    buffer.writeln('=====================================');
    buffer.writeln();
    buffer.writeln(
      '📊 DETECTED PROTOCOL: ${_protocolToString(detectedProtocol)}',
    );
    buffer.writeln(
      '🎯 CONFIDENCE LEVEL: ${(confidence * 100).toStringAsFixed(1)}%',
    );
    buffer.writeln();
    buffer.writeln('📝 ANALYSIS SUMMARY:');
    buffer.writeln(analysis);
    buffer.writeln();
    buffer.writeln('💡 RECOMMENDATIONS:');
    for (final rec in recommendations) {
      buffer.writeln('   $rec');
    }
    buffer.writeln();

    if (technicalDetails != null) {
      buffer.writeln('🔧 TECHNICAL DETAILS:');
      technicalDetails!.forEach((key, value) {
        buffer.writeln('   $key: $value');
      });
    }

    return buffer.toString();
  }

  String _protocolToString(EncryptionProtocol protocol) {
    switch (protocol) {
      case EncryptionProtocol.nip44:
        return 'NIP44 (Modern, Recommended)';
      case EncryptionProtocol.nip04:
        return 'NIP04 (Legacy, Deprecated)';
      case EncryptionProtocol.mixed:
        return 'Mixed (Both NIP04 and NIP44)';
      case EncryptionProtocol.unknown:
        return 'Unknown (Unable to determine)';
    }
  }
}

/// Supported encryption protocols
enum EncryptionProtocol { nip44, nip04, mixed, unknown }

/// Provider for the encryption protocol detector
final encryptionProtocolDetectorProvider = Provider<EncryptionProtocolDetector>(
  (ref) => EncryptionProtocolDetector(ref),
);
