import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:trottstr/models/backup_relay_models.dart';

/// Service for managing multi-relay encrypted backups
class MultiRelayBackupService {
  final Ref _ref;
  final List<EncryptedBackupConfig> _configurations = [];
  Timer? _backupTimer;

  MultiRelayBackupService(this._ref);

  /// Get all backup configurations
  List<EncryptedBackupConfig> get configurations => List.unmodifiable(_configurations);

  /// Save a new backup configuration
  Future<void> saveBackupConfiguration(EncryptedBackupConfig config) async {
    // Remove existing config with same ID
    _configurations.removeWhere((c) => c.id == config.id);
    
    // Add new config
    _configurations.add(config);
    
    // Save to local storage as CustomData
    await _saveConfigToStorage(config);
    
    // Schedule backup if enabled
    if (config.isEnabled && config.frequency != BackupFrequency.manual) {
      _scheduleBackup(config);
    }
    
    debugPrint('Backup configuration "${config.name}" saved successfully');
  }

  /// Remove a backup configuration
  Future<void> removeBackupConfiguration(String configId) async {
    _configurations.removeWhere((c) => c.id == configId);
    
    // Remove from storage
    await _removeConfigFromStorage(configId);
    
    debugPrint('Backup configuration removed: $configId');
  }

  /// Test connection to all relays in a configuration
  Future<Map<String, RelayTestResult>> testRelayConnections(List<BackupRelayConfig> relays) async {
    final results = <String, RelayTestResult>{};
    
    for (final relay in relays) {
      try {
        debugPrint('Testing relay: ${relay.relayConfig.url}');
        
        // Simulate connection test (replace with actual WebSocket test)
        await Future.delayed(Duration(milliseconds: 500 + (relays.indexOf(relay) * 200)));
        
        // Mock successful connection for now
        results[relay.id] = RelayTestResult(
          relayId: relay.id,
          url: relay.relayConfig.url,
          isConnected: true,
          latencyMs: 150 + (relays.indexOf(relay) * 50),
          error: null,
          testedAt: DateTime.now(),
        );
        
      } catch (e) {
        results[relay.id] = RelayTestResult(
          relayId: relay.id,
          url: relay.relayConfig.url,
          isConnected: false,
          latencyMs: null,
          error: e.toString(),
          testedAt: DateTime.now(),
        );
      }
    }
    
    return results;
  }

  /// Perform backup to all configured relays
  Future<BackupResult> performBackup(EncryptedBackupConfig config) async {
    try {
      debugPrint('Starting backup: ${config.name}');
      
      // Get all tracking data to backup
      final trackingData = await _gatherTrackingData();
      
      // Encrypt the data
      final encryptedData = await _encryptBackupData(trackingData, config.encryptionSettings);
      
      // Upload to each relay
      final uploadResults = <String, bool>{};
      for (final relayConfig in config.backupRelays) {
        try {
          final success = await _uploadToRelay(relayConfig, encryptedData);
          uploadResults[relayConfig.id] = success;
        } catch (e) {
          uploadResults[relayConfig.id] = false;
          debugPrint('Failed to upload to relay ${relayConfig.relayConfig.url}: $e');
        }
      }
      
      final successfulUploads = uploadResults.values.where((success) => success).length;
      final result = BackupResult(
        configId: config.id,
        timestamp: DateTime.now(),
        totalRelays: config.backupRelays.length,
        successfulRelays: successfulUploads,
        failedRelays: config.backupRelays.length - successfulUploads,
        dataSize: encryptedData.length,
        isSuccess: successfulUploads > 0,
      );
      
      debugPrint('Backup completed: ${result.isSuccess ? 'Success' : 'Failed'} '
          '(${result.successfulRelays}/${result.totalRelays} relays)');
      
      return result;
      
    } catch (e) {
      debugPrint('Backup failed: $e');
      return BackupResult(
        configId: config.id,
        timestamp: DateTime.now(),
        totalRelays: config.backupRelays.length,
        successfulRelays: 0,
        failedRelays: config.backupRelays.length,
        dataSize: 0,
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  /// Restore data from backup
  Future<RestoreResult> restoreFromBackup(EncryptedBackupConfig config) async {
    try {
      debugPrint('Starting restore from: ${config.name}');
      
      // Try to download from relays (in priority order)
      final sortedRelays = List<BackupRelayConfig>.from(config.backupRelays)
        ..sort((a, b) => a.priority.compareTo(b.priority));
      
      for (final relayConfig in sortedRelays) {
        try {
          final encryptedData = await _downloadFromRelay(relayConfig);
          if (encryptedData != null) {
            // Decrypt and restore
            final trackingData = await _decryptBackupData(encryptedData, config.encryptionSettings);
            await _restoreTrackingData(trackingData);
            
            return RestoreResult(
              configId: config.id,
              timestamp: DateTime.now(),
              sourceRelayId: relayConfig.id,
              dataSize: encryptedData.length,
              isSuccess: true,
            );
          }
        } catch (e) {
          debugPrint('Failed to restore from relay ${relayConfig.relayConfig.url}: $e');
          continue;
        }
      }
      
      throw Exception('No valid backup found on any relay');
      
    } catch (e) {
      debugPrint('Restore failed: $e');
      return RestoreResult(
        configId: config.id,
        timestamp: DateTime.now(),
        sourceRelayId: null,
        dataSize: 0,
        isSuccess: false,
        error: e.toString(),
      );
    }
  }

  /// Schedule automatic backups
  void _scheduleBackup(EncryptedBackupConfig config) {
    _backupTimer?.cancel();
    
    Duration interval;
    switch (config.frequency) {
      case BackupFrequency.hourly:
        interval = const Duration(hours: 1);
        break;
      case BackupFrequency.daily:
        interval = const Duration(days: 1);
        break;
      case BackupFrequency.weekly:
        interval = const Duration(days: 7);
        break;
      case BackupFrequency.monthly:
        interval = const Duration(days: 30);
        break;
      case BackupFrequency.manual:
        return; // No scheduling needed
    }
    
    _backupTimer = Timer.periodic(interval, (timer) {
      performBackup(config).then((result) {
        debugPrint('Scheduled backup completed: ${result.isSuccess}');
      }).catchError((error) {
        debugPrint('Scheduled backup failed: $error');
      });
    });
  }

  /// Gather all tracking data for backup
  Future<Map<String, dynamic>> _gatherTrackingData() async {
    final storage = _ref.read(storageNotifierProvider.notifier);
    
    // Get all country tracking events
    final countryEntries = await storage.query(RequestFilter(kinds: {30100}).toRequest());
    final plannedStays = await storage.query(RequestFilter(kinds: {30101}).toRequest());
    final taxResidencyEvents = await storage.query(RequestFilter(kinds: {30102}).toRequest());
    final configEvents = await storage.query(RequestFilter(kinds: {30103}).toRequest());
    
    return {
      'version': '1.0',
      'timestamp': DateTime.now().toIso8601String(),
      'countryEntries': countryEntries.map((e) => e.toMap()).toList(),
      'plannedStays': plannedStays.map((e) => e.toMap()).toList(),
      'taxResidencyEvents': taxResidencyEvents.map((e) => e.toMap()).toList(),
      'configEvents': configEvents.map((e) => e.toMap()).toList(),
    };
  }

  /// Encrypt backup data
  Future<List<int>> _encryptBackupData(
    Map<String, dynamic> data,
    BackupEncryptionSettings settings,
  ) async {
    final jsonData = jsonEncode(data);
    final bytes = utf8.encode(jsonData);
    
    // Compress if enabled
    List<int> finalBytes = bytes;
    if (settings.compressBeforeEncrypt) {
      finalBytes = gzip.encode(bytes);
    }
    
    // For now, just use a simple encryption scheme
    // In production, this would use proper NIP-44/NIP-04 encryption
    switch (settings.encryptionType) {
      case BackupEncryptionType.nip44:
      case BackupEncryptionType.nip04:
        // Simplified encryption for demo
        final encrypted = <int>[];
        for (int i = 0; i < finalBytes.length; i++) {
          encrypted.add(finalBytes[i] ^ 42); // Simple XOR encryption
        }
        return encrypted;
        
      case BackupEncryptionType.custom:
        // Use custom passphrase encryption
        if (settings.customPassphrase == null) {
          throw Exception('Custom passphrase required for custom encryption');
        }
        
        final passBytes = utf8.encode(settings.customPassphrase!);
        final encrypted = <int>[];
        for (int i = 0; i < finalBytes.length; i++) {
          encrypted.add(finalBytes[i] ^ passBytes[i % passBytes.length]);
        }
        return encrypted;
    }
  }

  /// Decrypt backup data
  Future<Map<String, dynamic>> _decryptBackupData(
    List<int> encryptedData,
    BackupEncryptionSettings settings,
  ) async {
    List<int> decryptedBytes;
    
    // Decrypt based on type (simplified for demo)
    switch (settings.encryptionType) {
      case BackupEncryptionType.nip44:
      case BackupEncryptionType.nip04:
        // Simplified decryption for demo
        decryptedBytes = <int>[];
        for (int i = 0; i < encryptedData.length; i++) {
          decryptedBytes.add(encryptedData[i] ^ 42); // Simple XOR decryption
        }
        break;
        
      case BackupEncryptionType.custom:
        if (settings.customPassphrase == null) {
          throw Exception('Custom passphrase required for custom decryption');
        }
        
        final passBytes = utf8.encode(settings.customPassphrase!);
        decryptedBytes = <int>[];
        for (int i = 0; i < encryptedData.length; i++) {
          decryptedBytes.add(encryptedData[i] ^ passBytes[i % passBytes.length]);
        }
        break;
    }
    
    // Decompress if needed
    if (settings.compressBeforeEncrypt) {
      decryptedBytes = gzip.decode(decryptedBytes);
    }
    
    final jsonString = utf8.decode(decryptedBytes);
    return jsonDecode(jsonString) as Map<String, dynamic>;
  }

  /// Upload encrypted data to relay
  Future<bool> _uploadToRelay(BackupRelayConfig relayConfig, List<int> encryptedData) async {
    // Simplified implementation for demo
    // In production, this would create a proper Nostr event and publish it
    debugPrint('Uploading ${encryptedData.length} bytes to ${relayConfig.relayConfig.url}');
    
    // Simulate network upload delay
    await Future.delayed(Duration(milliseconds: 500));
    
    // Simulate success (90% chance)
    return DateTime.now().millisecond % 10 != 0;
  }

  /// Download encrypted data from relay
  Future<List<int>?> _downloadFromRelay(BackupRelayConfig relayConfig) async {
    // Simplified implementation for demo
    debugPrint('Downloading backup from ${relayConfig.relayConfig.url}');
    
    // Simulate network download delay
    await Future.delayed(Duration(milliseconds: 300));
    
    // Simulate finding backup (80% chance)
    if (DateTime.now().millisecond % 5 == 0) {
      return null; // No backup found
    }
    
    // Return dummy encrypted data
    return utf8.encode('dummy_encrypted_backup_data');
  }

  /// Restore tracking data from backup
  Future<void> _restoreTrackingData(Map<String, dynamic> data) async {
    // Simplified implementation for demo
    debugPrint('Restoring tracking data with ${data.keys.length} categories');
    
    // In production, this would properly parse and restore the events
    // For now, just log what would be restored
    final countryEntries = data['countryEntries'] as List? ?? [];
    final plannedStays = data['plannedStays'] as List? ?? [];
    final taxResidencyEvents = data['taxResidencyEvents'] as List? ?? [];
    final configEvents = data['configEvents'] as List? ?? [];
    
    final totalEvents = countryEntries.length + plannedStays.length + 
                       taxResidencyEvents.length + configEvents.length;
    
    debugPrint('Would restore $totalEvents events from backup');
  }

  /// Save configuration to local storage
  Future<void> _saveConfigToStorage(EncryptedBackupConfig config) async {
    // Simplified implementation for demo
    debugPrint('Saving backup configuration "${config.name}" to local storage');
    
    // In production, this would use CustomData to store the configuration
    // For now, just simulate saving
    await Future.delayed(Duration(milliseconds: 100));
  }

  /// Remove configuration from local storage
  Future<void> _removeConfigFromStorage(String configId) async {
    // Simplified implementation for demo
    debugPrint('Removing backup configuration: $configId');
    
    // In production, this would query and remove the actual configuration
    await Future.delayed(Duration(milliseconds: 100));
  }

  /// Dispose resources
  void dispose() {
    _backupTimer?.cancel();
  }
}

/// Provider for multi-relay backup service
final multiRelayBackupServiceProvider = Provider<MultiRelayBackupService>((ref) {
  final service = MultiRelayBackupService(ref);
  ref.onDispose(service.dispose);
  return service;
});

/// Result of testing relay connections
class RelayTestResult {
  final String relayId;
  final String url;
  final bool isConnected;
  final int? latencyMs;
  final String? error;
  final DateTime testedAt;

  RelayTestResult({
    required this.relayId,
    required this.url,
    required this.isConnected,
    this.latencyMs,
    this.error,
    required this.testedAt,
  });
}

/// Result of backup operation
class BackupResult {
  final String configId;
  final DateTime timestamp;
  final int totalRelays;
  final int successfulRelays;
  final int failedRelays;
  final int dataSize;
  final bool isSuccess;
  final String? error;

  BackupResult({
    required this.configId,
    required this.timestamp,
    required this.totalRelays,
    required this.successfulRelays,
    required this.failedRelays,
    required this.dataSize,
    required this.isSuccess,
    this.error,
  });
}

/// Result of restore operation
class RestoreResult {
  final String configId;
  final DateTime timestamp;
  final String? sourceRelayId;
  final int dataSize;
  final bool isSuccess;
  final String? error;

  RestoreResult({
    required this.configId,
    required this.timestamp,
    this.sourceRelayId,
    required this.dataSize,
    required this.isSuccess,
    this.error,
  });
}