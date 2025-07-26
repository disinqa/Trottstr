import 'package:flutter/foundation.dart';
import 'package:trottstr/models/relay_models.dart';

/// Configuration for encrypted backup to multiple relays
@immutable
class EncryptedBackupConfig {
  final String id;
  final String name;
  final List<BackupRelayConfig> backupRelays;
  final BackupEncryptionSettings encryptionSettings;
  final BackupFrequency frequency;
  final bool isEnabled;
  final DateTime? lastBackup;
  final DateTime createdAt;
  final DateTime? lastModified;
  final Map<String, dynamic> metadata;

  const EncryptedBackupConfig({
    required this.id,
    required this.name,
    required this.backupRelays,
    required this.encryptionSettings,
    this.frequency = BackupFrequency.daily,
    this.isEnabled = true,
    this.lastBackup,
    required this.createdAt,
    this.lastModified,
    this.metadata = const {},
  });

  EncryptedBackupConfig copyWith({
    String? id,
    String? name,
    List<BackupRelayConfig>? backupRelays,
    BackupEncryptionSettings? encryptionSettings,
    BackupFrequency? frequency,
    bool? isEnabled,
    DateTime? lastBackup,
    DateTime? createdAt,
    DateTime? lastModified,
    Map<String, dynamic>? metadata,
  }) {
    return EncryptedBackupConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      backupRelays: backupRelays ?? this.backupRelays,
      encryptionSettings: encryptionSettings ?? this.encryptionSettings,
      frequency: frequency ?? this.frequency,
      isEnabled: isEnabled ?? this.isEnabled,
      lastBackup: lastBackup ?? this.lastBackup,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? this.lastModified,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'backupRelays': backupRelays.map((relay) => relay.toJson()).toList(),
      'encryptionSettings': encryptionSettings.toJson(),
      'frequency': frequency.name,
      'isEnabled': isEnabled,
      'lastBackup': lastBackup?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'lastModified': lastModified?.toIso8601String(),
      'metadata': metadata,
    };
  }

  Map<String, dynamic> toMap() => toJson();

  factory EncryptedBackupConfig.fromJson(Map<String, dynamic> json) {
    return EncryptedBackupConfig(
      id: json['id'] as String,
      name: json['name'] as String,
      backupRelays: (json['backupRelays'] as List<dynamic>)
          .map((relayJson) => BackupRelayConfig.fromJson(relayJson as Map<String, dynamic>))
          .toList(),
      encryptionSettings: BackupEncryptionSettings.fromJson(
          json['encryptionSettings'] as Map<String, dynamic>),
      frequency: BackupFrequency.values.firstWhere(
        (freq) => freq.name == json['frequency'],
        orElse: () => BackupFrequency.daily,
      ),
      isEnabled: json['isEnabled'] as bool? ?? true,
      lastBackup: json['lastBackup'] != null
          ? DateTime.parse(json['lastBackup'] as String)
          : null,
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastModified: json['lastModified'] != null
          ? DateTime.parse(json['lastModified'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Gets the active backup relays that are connected and enabled
  List<BackupRelayConfig> get activeBackupRelays =>
      backupRelays.where((relay) => relay.isEnabled && relay.isHealthy).toList();

  /// Gets the overall backup configuration health score
  double get healthScore {
    if (backupRelays.isEmpty) return 0.0;
    
    final healthyRelays = activeBackupRelays.length;
    final totalRelays = backupRelays.length;
    
    return healthyRelays / totalRelays;
  }

  /// Checks if backup configuration meets redundancy requirements
  bool get meetsRedundancyRequirements => activeBackupRelays.length >= 2;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is EncryptedBackupConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Configuration for a specific relay used for backup
@immutable
class BackupRelayConfig {
  final String id;
  final RelayConfig relayConfig;
  final int priority;
  final bool isEnabled;
  final BackupRelayRole role;
  final DateTime? lastBackupSuccess;
  final DateTime? lastBackupAttempt;
  final String? lastError;
  final Map<String, dynamic> backupMetadata;

  const BackupRelayConfig({
    required this.id,
    required this.relayConfig,
    required this.priority,
    this.isEnabled = true,
    this.role = BackupRelayRole.primary,
    this.lastBackupSuccess,
    this.lastBackupAttempt,
    this.lastError,
    this.backupMetadata = const {},
  });

  BackupRelayConfig copyWith({
    String? id,
    RelayConfig? relayConfig,
    int? priority,
    bool? isEnabled,
    BackupRelayRole? role,
    DateTime? lastBackupSuccess,
    DateTime? lastBackupAttempt,
    String? lastError,
    Map<String, dynamic>? backupMetadata,
  }) {
    return BackupRelayConfig(
      id: id ?? this.id,
      relayConfig: relayConfig ?? this.relayConfig,
      priority: priority ?? this.priority,
      isEnabled: isEnabled ?? this.isEnabled,
      role: role ?? this.role,
      lastBackupSuccess: lastBackupSuccess ?? this.lastBackupSuccess,
      lastBackupAttempt: lastBackupAttempt ?? this.lastBackupAttempt,
      lastError: lastError ?? this.lastError,
      backupMetadata: backupMetadata ?? this.backupMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'relayConfig': relayConfig.toJson(),
      'priority': priority,
      'isEnabled': isEnabled,
      'role': role.name,
      'lastBackupSuccess': lastBackupSuccess?.toIso8601String(),
      'lastBackupAttempt': lastBackupAttempt?.toIso8601String(),
      'lastError': lastError,
      'backupMetadata': backupMetadata,
    };
  }

  factory BackupRelayConfig.fromJson(Map<String, dynamic> json) {
    return BackupRelayConfig(
      id: json['id'] as String,
      relayConfig: RelayConfig.fromJson(json['relayConfig'] as Map<String, dynamic>),
      priority: json['priority'] as int,
      isEnabled: json['isEnabled'] as bool? ?? true,
      role: BackupRelayRole.values.firstWhere(
        (role) => role.name == json['role'],
        orElse: () => BackupRelayRole.primary,
      ),
      lastBackupSuccess: json['lastBackupSuccess'] != null
          ? DateTime.parse(json['lastBackupSuccess'] as String)
          : null,
      lastBackupAttempt: json['lastBackupAttempt'] != null
          ? DateTime.parse(json['lastBackupAttempt'] as String)
          : null,
      lastError: json['lastError'] as String?,
      backupMetadata: json['backupMetadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Checks if the backup relay is healthy and available
  bool get isHealthy {
    // Check if relay is connected and enabled
    if (!isEnabled || relayConfig.status != RelayStatus.connected) {
      return false;
    }
    
    // Check if last backup was successful and recent
    if (lastBackupSuccess != null) {
      final daysSinceLastSuccess = DateTime.now().difference(lastBackupSuccess!).inDays;
      if (daysSinceLastSuccess > 7) return false; // Consider unhealthy if no successful backup in a week
    }
    
    // Check if there's a recent error
    if (lastError != null && lastBackupAttempt != null) {
      final hoursSinceError = DateTime.now().difference(lastBackupAttempt!).inHours;
      if (hoursSinceError < 24) return false; // Consider unhealthy if error in last 24 hours
    }
    
    return true;
  }

  /// Gets the backup reliability score
  double get reliabilityScore {
    double score = 0.0;
    
    // Base score from relay health
    score += relayConfig.healthScore * 0.4;
    
    // Success rate score
    if (lastBackupSuccess != null) {
      final daysSinceSuccess = DateTime.now().difference(lastBackupSuccess!).inDays;
      if (daysSinceSuccess < 1) {
        score += 0.3;
      } else if (daysSinceSuccess < 3) {
        score += 0.2;
      } else if (daysSinceSuccess < 7) {
        score += 0.1;
      }
    }
    
    // Error penalty
    if (lastError != null && lastBackupAttempt != null) {
      final hoursSinceError = DateTime.now().difference(lastBackupAttempt!).inHours;
      if (hoursSinceError < 6) {
        score -= 0.2;
      } else if (hoursSinceError < 24) {
        score -= 0.1;
      }
    }
    
    // Role bonus
    if (role == BackupRelayRole.primary) {
      score += 0.1;
    }
    
    return score.clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupRelayConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Encryption settings for backup data
@immutable
class BackupEncryptionSettings {
  final BackupEncryptionType encryptionType;
  final String? customPassphrase; // For additional encryption layer
  final bool compressBeforeEncrypt;
  final int encryptionStrength;
  final Map<String, dynamic> encryptionMetadata;

  const BackupEncryptionSettings({
    this.encryptionType = BackupEncryptionType.nip44,
    this.customPassphrase,
    this.compressBeforeEncrypt = true,
    this.encryptionStrength = 256,
    this.encryptionMetadata = const {},
  });

  BackupEncryptionSettings copyWith({
    BackupEncryptionType? encryptionType,
    String? customPassphrase,
    bool? compressBeforeEncrypt,
    int? encryptionStrength,
    Map<String, dynamic>? encryptionMetadata,
  }) {
    return BackupEncryptionSettings(
      encryptionType: encryptionType ?? this.encryptionType,
      customPassphrase: customPassphrase ?? this.customPassphrase,
      compressBeforeEncrypt: compressBeforeEncrypt ?? this.compressBeforeEncrypt,
      encryptionStrength: encryptionStrength ?? this.encryptionStrength,
      encryptionMetadata: encryptionMetadata ?? this.encryptionMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'encryptionType': encryptionType.name,
      'customPassphrase': customPassphrase,
      'compressBeforeEncrypt': compressBeforeEncrypt,
      'encryptionStrength': encryptionStrength,
      'encryptionMetadata': encryptionMetadata,
    };
  }

  factory BackupEncryptionSettings.fromJson(Map<String, dynamic> json) {
    return BackupEncryptionSettings(
      encryptionType: BackupEncryptionType.values.firstWhere(
        (type) => type.name == json['encryptionType'],
        orElse: () => BackupEncryptionType.nip44,
      ),
      customPassphrase: json['customPassphrase'] as String?,
      compressBeforeEncrypt: json['compressBeforeEncrypt'] as bool? ?? true,
      encryptionStrength: json['encryptionStrength'] as int? ?? 256,
      encryptionMetadata: json['encryptionMetadata'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupEncryptionSettings &&
        other.encryptionType == encryptionType &&
        other.customPassphrase == customPassphrase &&
        other.compressBeforeEncrypt == compressBeforeEncrypt &&
        other.encryptionStrength == encryptionStrength;
  }

  @override
  int get hashCode => Object.hash(
        encryptionType,
        customPassphrase,
        compressBeforeEncrypt,
        encryptionStrength,
      );
}

/// Represents a backup operation across multiple relays
@immutable
class MultiRelayBackupOperation {
  final String id;
  final String configId;
  final BackupOperationType operationType;
  final DateTime startedAt;
  final DateTime? completedAt;
  final BackupOperationStatus status;
  final Map<String, BackupRelayResult> relayResults;
  final String? errorMessage;
  final Map<String, dynamic> operationMetadata;

  const MultiRelayBackupOperation({
    required this.id,
    required this.configId,
    required this.operationType,
    required this.startedAt,
    this.completedAt,
    this.status = BackupOperationStatus.running,
    this.relayResults = const {},
    this.errorMessage,
    this.operationMetadata = const {},
  });

  MultiRelayBackupOperation copyWith({
    String? id,
    String? configId,
    BackupOperationType? operationType,
    DateTime? startedAt,
    DateTime? completedAt,
    BackupOperationStatus? status,
    Map<String, BackupRelayResult>? relayResults,
    String? errorMessage,
    Map<String, dynamic>? operationMetadata,
  }) {
    return MultiRelayBackupOperation(
      id: id ?? this.id,
      configId: configId ?? this.configId,
      operationType: operationType ?? this.operationType,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
      status: status ?? this.status,
      relayResults: relayResults ?? this.relayResults,
      errorMessage: errorMessage ?? this.errorMessage,
      operationMetadata: operationMetadata ?? this.operationMetadata,
    );
  }

  /// Gets the success rate across all relay operations
  double get successRate {
    if (relayResults.isEmpty) return 0.0;
    
    final successfulResults = relayResults.values
        .where((result) => result.status == BackupRelayResultStatus.success)
        .length;
    
    return successfulResults / relayResults.length;
  }

  /// Checks if the operation meets minimum redundancy requirements
  bool get meetsRedundancyRequirements {
    final successfulResults = relayResults.values
        .where((result) => result.status == BackupRelayResultStatus.success)
        .length;
    
    return successfulResults >= 2; // At least 2 successful backups for redundancy
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MultiRelayBackupOperation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Result of backup operation on a specific relay
@immutable
class BackupRelayResult {
  final String relayId;
  final BackupRelayResultStatus status;
  final DateTime timestamp;
  final String? errorMessage;
  final int? dataSize;
  final String? backupHash;
  final Map<String, dynamic> resultMetadata;

  const BackupRelayResult({
    required this.relayId,
    required this.status,
    required this.timestamp,
    this.errorMessage,
    this.dataSize,
    this.backupHash,
    this.resultMetadata = const {},
  });

  BackupRelayResult copyWith({
    String? relayId,
    BackupRelayResultStatus? status,
    DateTime? timestamp,
    String? errorMessage,
    int? dataSize,
    String? backupHash,
    Map<String, dynamic>? resultMetadata,
  }) {
    return BackupRelayResult(
      relayId: relayId ?? this.relayId,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
      errorMessage: errorMessage ?? this.errorMessage,
      dataSize: dataSize ?? this.dataSize,
      backupHash: backupHash ?? this.backupHash,
      resultMetadata: resultMetadata ?? this.resultMetadata,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is BackupRelayResult && 
           other.relayId == relayId && 
           other.timestamp == timestamp;
  }

  @override
  int get hashCode => Object.hash(relayId, timestamp);
}

/// Frequency options for automated backups
enum BackupFrequency {
  manual,
  hourly,
  daily,
  weekly,
  monthly,
}

/// Role of a relay in the backup configuration
enum BackupRelayRole {
  primary,
  secondary,
  archive,
}

/// Type of encryption used for backup data
enum BackupEncryptionType {
  nip44,    // NIP-44 encryption (recommended)
  nip04,    // NIP-04 encryption (legacy)
  custom,   // Custom encryption with passphrase
}

/// Type of backup operation
enum BackupOperationType {
  full,
  incremental,
  restore,
  verify,
}

/// Status of a backup operation
enum BackupOperationStatus {
  running,
  completed,
  failed,
  cancelled,
  partialSuccess,
}

/// Status of backup result on a specific relay
enum BackupRelayResultStatus {
  success,
  failed,
  timeout,
  cancelled,
}

/// Extension methods for backup frequency calculations
extension BackupFrequencyExtensions on BackupFrequency {
  Duration? get duration {
    switch (this) {
      case BackupFrequency.manual:
        return null;
      case BackupFrequency.hourly:
        return const Duration(hours: 1);
      case BackupFrequency.daily:
        return const Duration(days: 1);
      case BackupFrequency.weekly:
        return const Duration(days: 7);
      case BackupFrequency.monthly:
        return const Duration(days: 30);
    }
  }

  String get displayName {
    switch (this) {
      case BackupFrequency.manual:
        return 'Manual';
      case BackupFrequency.hourly:
        return 'Hourly';
      case BackupFrequency.daily:
        return 'Daily';
      case BackupFrequency.weekly:
        return 'Weekly';
      case BackupFrequency.monthly:
        return 'Monthly';
    }
  }
}