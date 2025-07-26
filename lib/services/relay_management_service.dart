import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/services/encryption_service.dart';

/// Comprehensive relay management service with batch operations and health monitoring
class RelayManagementService {
  static const String _storageKey = 'relay_configurations';
  static const String _settingsKey = 'relay_management_settings';
  static const String _templatesKey = 'relay_templates';
  static const String _operationsKey = 'relay_batch_operations';

  final Ref _ref;
  final Map<String, RelayConfig> _relays = {};
  final Map<String, RelayTemplate> _templates = {};
  final Map<String, RelayBatchOperation> _operations = {};
  RelayManagementSettings _settings = const RelayManagementSettings();

  // Stream controllers for real-time updates
  final StreamController<Map<String, RelayConfig>> _relaysController = 
      StreamController<Map<String, RelayConfig>>.broadcast();
  final StreamController<RelayManagementSettings> _settingsController = 
      StreamController<RelayManagementSettings>.broadcast();
  final StreamController<Map<String, RelayTemplate>> _templatesController = 
      StreamController<Map<String, RelayTemplate>>.broadcast();
  final StreamController<Map<String, RelayBatchOperation>> _operationsController = 
      StreamController<Map<String, RelayBatchOperation>>.broadcast();

  // Health monitoring timer
  Timer? _healthMonitoringTimer;

  RelayManagementService(this._ref);

  // Streams for reactive updates
  Stream<Map<String, RelayConfig>> get relaysStream => _relaysController.stream;
  Stream<RelayManagementSettings> get settingsStream => _settingsController.stream;
  Stream<Map<String, RelayTemplate>> get templatesStream => _templatesController.stream;
  Stream<Map<String, RelayBatchOperation>> get operationsStream => _operationsController.stream;

  // Getters
  Map<String, RelayConfig> get relays => Map.unmodifiable(_relays);
  RelayManagementSettings get settings => _settings;
  Map<String, RelayTemplate> get templates => Map.unmodifiable(_templates);
  Map<String, RelayBatchOperation> get operations => Map.unmodifiable(_operations);

  /// Initialize the service and load persisted data
  Future<void> initialize() async {
    try {
      await _loadRelays();
      await _loadSettings();
      await _loadTemplates();
      await _loadOperations();
      await _initializeBuiltInTemplates();
      _startHealthMonitoring();
      
      debugPrint('RelayManagementService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize RelayManagementService: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _healthMonitoringTimer?.cancel();
    _relaysController.close();
    _settingsController.close();
    _templatesController.close();
    _operationsController.close();
  }

  // ====== RELAY MANAGEMENT ======

  /// Add a new relay configuration
  Future<void> addRelay(RelayConfig relay) async {
    try {
      _relays[relay.id] = relay;
      await _saveRelays();
      _relaysController.add(Map.from(_relays));
      
      debugPrint('Added relay: ${relay.name} (${relay.url})');
    } catch (e) {
      debugPrint('Failed to add relay: $e');
      rethrow;
    }
  }

  /// Update an existing relay configuration
  Future<void> updateRelay(String id, RelayConfig updatedRelay) async {
    try {
      if (!_relays.containsKey(id)) {
        throw Exception('Relay with id $id not found');
      }
      
      _relays[id] = updatedRelay;
      await _saveRelays();
      _relaysController.add(Map.from(_relays));
      
      debugPrint('Updated relay: ${updatedRelay.name}');
    } catch (e) {
      debugPrint('Failed to update relay: $e');
      rethrow;
    }
  }

  /// Remove a relay configuration
  Future<void> removeRelay(String id) async {
    try {
      final relay = _relays.remove(id);
      if (relay != null) {
        await _saveRelays();
        _relaysController.add(Map.from(_relays));
        debugPrint('Removed relay: ${relay.name}');
      }
    } catch (e) {
      debugPrint('Failed to remove relay: $e');
      rethrow;
    }
  }

  /// Get relay by ID
  RelayConfig? getRelay(String id) => _relays[id];

  /// Get relays by status
  List<RelayConfig> getRelaysByStatus(RelayStatus status) {
    return _relays.values.where((relay) => relay.status == status).toList();
  }

  /// Get enabled relays sorted by priority
  List<RelayConfig> getEnabledRelaysByPriority() {
    return _relays.values
        .where((relay) => relay.isEnabled)
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority));
  }

  // ====== BATCH OPERATIONS ======

  /// Execute a batch operation on multiple relays
  Future<RelayBatchOperation> executeBatchOperation(
    RelayBatchOperationType type,
    List<String> relayIds, {
    Map<String, dynamic> parameters = const {},
  }) async {
    final operation = RelayBatchOperation(
      id: _generateId(),
      type: type,
      relayIds: relayIds,
      parameters: parameters,
      createdAt: DateTime.now(),
    );

    try {
      _operations[operation.id] = operation;
      _operationsController.add(Map.from(_operations));

      // Update operation status to running
      final runningOperation = operation.copyWith(
        status: RelayBatchOperationStatus.running,
      );
      _operations[operation.id] = runningOperation;
      _operationsController.add(Map.from(_operations));

      // Execute the operation
      final results = <String, dynamic>{};
      
      for (final relayId in relayIds) {
        try {
          final result = await _executeSingleOperation(type, relayId, parameters);
          results[relayId] = result;
        } catch (e) {
          results[relayId] = {'error': e.toString()};
        }
      }

      // Complete the operation
      final completedOperation = runningOperation.copyWith(
        status: RelayBatchOperationStatus.completed,
        completedAt: DateTime.now(),
        results: results,
      );

      _operations[operation.id] = completedOperation;
      await _saveOperations();
      _operationsController.add(Map.from(_operations));

      return completedOperation;
    } catch (e) {
      // Mark operation as failed
      final failedOperation = operation.copyWith(
        status: RelayBatchOperationStatus.failed,
        completedAt: DateTime.now(),
        errorMessage: e.toString(),
      );

      _operations[operation.id] = failedOperation;
      await _saveOperations();
      _operationsController.add(Map.from(_operations));

      debugPrint('Batch operation failed: $e');
      rethrow;
    }
  }

  /// Execute a single operation on a relay
  Future<Map<String, dynamic>> _executeSingleOperation(
    RelayBatchOperationType type,
    String relayId,
    Map<String, dynamic> parameters,
  ) async {
    final relay = _relays[relayId];
    if (relay == null) {
      throw Exception('Relay not found: $relayId');
    }

    switch (type) {
      case RelayBatchOperationType.connect:
        return await _connectRelay(relay);
      case RelayBatchOperationType.disconnect:
        return await _disconnectRelay(relay);
      case RelayBatchOperationType.test:
        return await _testRelay(relay);
      case RelayBatchOperationType.enable:
        return await _enableRelay(relay);
      case RelayBatchOperationType.disable:
        return await _disableRelay(relay);
      case RelayBatchOperationType.delete:
        return await _deleteRelay(relay);
      case RelayBatchOperationType.updatePriority:
        return await _updateRelayPriority(relay, parameters['priority'] as int);
      case RelayBatchOperationType.updateSettings:
        return await _updateRelaySettings(relay, parameters);
    }
  }

  /// Cancel a running batch operation
  Future<void> cancelBatchOperation(String operationId) async {
    final operation = _operations[operationId];
    if (operation != null && operation.status == RelayBatchOperationStatus.running) {
      final cancelledOperation = operation.copyWith(
        status: RelayBatchOperationStatus.cancelled,
        completedAt: DateTime.now(),
      );

      _operations[operationId] = cancelledOperation;
      await _saveOperations();
      _operationsController.add(Map.from(_operations));
    }
  }

  // ====== RELAY OPERATIONS ======

  Future<Map<String, dynamic>> _connectRelay(RelayConfig relay) async {
    try {
      _relays[relay.id] = relay.copyWith(status: RelayStatus.connecting);
      _relaysController.add(Map.from(_relays));

      // Simulate connection attempt
      await Future.delayed(Duration(seconds: 1 + Random().nextInt(3)));
      
      final success = Random().nextBool(); // 50% success rate for demo
      if (success) {
        final latency = 50 + Random().nextInt(200);
        _relays[relay.id] = relay.copyWith(
          status: RelayStatus.connected,
          latency: latency,
          lastConnected: DateTime.now(),
        );
        await _saveRelays();
        _relaysController.add(Map.from(_relays));
        return {'success': true, 'latency': latency};
      } else {
        _relays[relay.id] = relay.copyWith(status: RelayStatus.error);
        await _saveRelays();
        _relaysController.add(Map.from(_relays));
        throw Exception('Connection failed');
      }
    } catch (e) {
      _relays[relay.id] = relay.copyWith(status: RelayStatus.error);
      await _saveRelays();
      _relaysController.add(Map.from(_relays));
      rethrow;
    }
  }

  Future<Map<String, dynamic>> _disconnectRelay(RelayConfig relay) async {
    _relays[relay.id] = relay.copyWith(
      status: RelayStatus.disconnected,
      latency: null,
    );
    await _saveRelays();
    _relaysController.add(Map.from(_relays));
    return {'success': true};
  }

  Future<Map<String, dynamic>> _testRelay(RelayConfig relay) async {
    try {
      // Test relay connectivity and measure latency
      final stopwatch = Stopwatch()..start();
      
      // Simulate network test
      await Future.delayed(Duration(milliseconds: 500 + Random().nextInt(1000)));
      
      stopwatch.stop();
      final latency = stopwatch.elapsedMilliseconds;
      
      _relays[relay.id] = relay.copyWith(
        latency: latency,
        lastTested: DateTime.now(),
      );
      await _saveRelays();
      _relaysController.add(Map.from(_relays));
      
      return {
        'success': true,
        'latency': latency,
        'timestamp': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> _enableRelay(RelayConfig relay) async {
    _relays[relay.id] = relay.copyWith(isEnabled: true);
    await _saveRelays();
    _relaysController.add(Map.from(_relays));
    return {'success': true};
  }

  Future<Map<String, dynamic>> _disableRelay(RelayConfig relay) async {
    _relays[relay.id] = relay.copyWith(
      isEnabled: false,
      status: RelayStatus.disconnected,
    );
    await _saveRelays();
    _relaysController.add(Map.from(_relays));
    return {'success': true};
  }

  Future<Map<String, dynamic>> _deleteRelay(RelayConfig relay) async {
    _relays.remove(relay.id);
    await _saveRelays();
    _relaysController.add(Map.from(_relays));
    return {'success': true};
  }

  Future<Map<String, dynamic>> _updateRelayPriority(RelayConfig relay, int priority) async {
    _relays[relay.id] = relay.copyWith(priority: priority);
    await _saveRelays();
    _relaysController.add(Map.from(_relays));
    return {'success': true, 'priority': priority};
  }

  Future<Map<String, dynamic>> _updateRelaySettings(
    RelayConfig relay,
    Map<String, dynamic> newSettings,
  ) async {
    final updatedMetadata = Map<String, dynamic>.from(relay.metadata);
    updatedMetadata.addAll(newSettings);
    
    _relays[relay.id] = relay.copyWith(metadata: updatedMetadata);
    await _saveRelays();
    _relaysController.add(Map.from(_relays));
    return {'success': true};
  }

  // ====== RELAY DISCOVERY ======

  /// Discover relays based on travel destinations or general discovery
  Future<List<RelayDiscoveryResult>> discoverRelays({
    List<String>? destinations,
    int maxResults = 20,
  }) async {
    try {
      final results = <RelayDiscoveryResult>[];
      
      // Built-in relay list for discovery
      final discoveryRelays = [
        {'url': 'wss://relay.damus.io', 'name': 'Damus Relay', 'description': 'Popular general-purpose relay'},
        {'url': 'wss://nostr.wine', 'name': 'Nostr Wine', 'description': 'High-performance relay'},
        {'url': 'wss://relay.nostr.info', 'name': 'Nostr Info', 'description': 'Community relay'},
        {'url': 'wss://relay.snort.social', 'name': 'Snort Social', 'description': 'Social-focused relay'},
        {'url': 'wss://nos.lol', 'name': 'nos.lol', 'description': 'Fast and reliable'},
        {'url': 'wss://relay.current.fyi', 'name': 'Current FYI', 'description': 'News and updates'},
        {'url': 'wss://brb.io', 'name': 'BRB.io', 'description': 'Business relay'},
        {'url': 'wss://relay.nostrich.de', 'name': 'Nostrich DE', 'description': 'European relay'},
        {'url': 'wss://relay.nostr.bg', 'name': 'Nostr BG', 'description': 'Bulgarian relay'},
        {'url': 'wss://nostr.fmt.wiz.biz', 'name': 'Wiz Biz', 'description': 'Japan-based relay'},
        {'url': 'wss://relay.nostr.ch', 'name': 'Nostr CH', 'description': 'Swiss relay'},
        {'url': 'wss://nostr.mom', 'name': 'Nostr Mom', 'description': 'Family-friendly relay'},
        {'url': 'wss://relay.orangepill.dev', 'name': 'Orange Pill', 'description': 'Bitcoin-focused relay'},
        {'url': 'wss://relay.nostr.pro', 'name': 'Nostr Pro', 'description': 'Professional relay'},
        {'url': 'wss://relay.bitcoin.ninja', 'name': 'Bitcoin Ninja', 'description': 'Bitcoin community relay'},
      ];

      for (final relayData in discoveryRelays.take(maxResults)) {
        if (!_relays.containsKey(relayData['url'])) {
          // Simulate latency test
          final latency = 50 + Random().nextInt(200);
          final score = _calculateDiscoveryScore(latency, destinations, relayData);
          
          results.add(RelayDiscoveryResult(
            url: relayData['url']!,
            name: relayData['name'],
            description: relayData['description'],
            latency: latency,
            isReachable: Random().nextDouble() > 0.1, // 90% reachable
            discoveredAt: DateTime.now(),
            score: score,
          ));
        }
      }

      // Sort by score (best first)
      results.sort((a, b) => b.score.compareTo(a.score));
      
      return results.take(maxResults).toList();
    } catch (e) {
      debugPrint('Relay discovery failed: $e');
      return [];
    }
  }

  double _calculateDiscoveryScore(
    int latency,
    List<String>? destinations,
    Map<String, String> relayData,
  ) {
    double score = 0.5; // Base score
    
    // Latency score
    if (latency < 50) {
      score += 0.3;
    } else if (latency < 100) {
      score += 0.2;
    } else if (latency < 200) {
      score += 0.1;
    }
    
    // Geographic relevance (simplified)
    if (destinations != null) {
      for (final destination in destinations) {
        if (relayData['description']?.toLowerCase().contains(destination.toLowerCase()) == true ||
            relayData['url']?.toLowerCase().contains(destination.toLowerCase()) == true) {
          score += 0.2;
        }
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  // ====== TEMPLATES ======

  /// Create a new relay template
  Future<void> createTemplate(RelayTemplate template) async {
    _templates[template.id] = template;
    await _saveTemplates();
    _templatesController.add(Map.from(_templates));
  }

  /// Apply a template to current relay configuration
  Future<void> applyTemplate(String templateId, {bool replaceExisting = false}) async {
    final template = _templates[templateId];
    if (template == null) {
      throw Exception('Template not found: $templateId');
    }

    try {
      if (replaceExisting) {
        _relays.clear();
      }

      for (final relay in template.relays) {
        final newRelay = relay.copyWith(
          id: _generateId(),
          template: template,
        );
        _relays[newRelay.id] = newRelay;
      }

      await _saveRelays();
      _relaysController.add(Map.from(_relays));
      
      debugPrint('Applied template: ${template.name}');
    } catch (e) {
      debugPrint('Failed to apply template: $e');
      rethrow;
    }
  }

  /// Export relay configuration as JSON
  Map<String, dynamic> exportConfiguration() {
    return {
      'relays': _relays.values.map((relay) => relay.toJson()).toList(),
      'settings': _settings.toJson(),
      'templates': _templates.values.map((template) => template.toJson()).toList(),
      'exportedAt': DateTime.now().toIso8601String(),
      'version': '1.0.0',
    };
  }

  /// Import relay configuration from JSON
  Future<void> importConfiguration(
    Map<String, dynamic> config, {
    bool replaceExisting = false,
  }) async {
    try {
      if (replaceExisting) {
        _relays.clear();
        _templates.clear();
      }

      // Import relays
      if (config['relays'] != null) {
        for (final relayJson in config['relays'] as List<dynamic>) {
          final relay = RelayConfig.fromJson(relayJson as Map<String, dynamic>);
          _relays[relay.id] = relay;
        }
      }

      // Import templates
      if (config['templates'] != null) {
        for (final templateJson in config['templates'] as List<dynamic>) {
          final template = RelayTemplate.fromJson(templateJson as Map<String, dynamic>);
          _templates[template.id] = template;
        }
      }

      // Import settings
      if (config['settings'] != null) {
        _settings = RelayManagementSettings.fromJson(
          config['settings'] as Map<String, dynamic>,
        );
      }

      await _saveRelays();
      await _saveTemplates();
      await _saveSettings();

      _relaysController.add(Map.from(_relays));
      _templatesController.add(Map.from(_templates));
      _settingsController.add(_settings);

      debugPrint('Configuration imported successfully');
    } catch (e) {
      debugPrint('Failed to import configuration: $e');
      rethrow;
    }
  }

  // ====== SETTINGS ======

  /// Update relay management settings
  Future<void> updateSettings(RelayManagementSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    _settingsController.add(_settings);

    // Restart health monitoring if interval changed
    if (_settings.enableHealthMonitoring) {
      _restartHealthMonitoring();
    } else {
      _healthMonitoringTimer?.cancel();
    }
  }

  // ====== HEALTH MONITORING ======

  void _startHealthMonitoring() {
    if (_settings.enableHealthMonitoring) {
      _healthMonitoringTimer = Timer.periodic(_settings.healthCheckInterval, (_) {
        _performHealthCheck();
      });
    }
  }

  void _restartHealthMonitoring() {
    _healthMonitoringTimer?.cancel();
    _startHealthMonitoring();
  }

  Future<void> _performHealthCheck() async {
    final enabledRelays = _relays.values.where((relay) => relay.isEnabled).toList();
    
    for (final relay in enabledRelays) {
      if (relay.status == RelayStatus.connected) {
        try {
          await _testRelay(relay);
        } catch (e) {
          debugPrint('Health check failed for ${relay.name}: $e');
        }
      }
    }
  }

  // ====== PERSISTENCE ======

  Future<void> _loadRelays() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return;

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

      if (customDataList.isEmpty) return;

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return;

      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(encryptedContent);

      if (decryptedData.isEmpty) return;

      if (decryptedData.startsWith('{')) {
        final relaysData = jsonDecode(decryptedData) as Map<String, dynamic>;
        for (final entry in relaysData.entries) {
          final relay = RelayConfig.fromJson(entry.value as Map<String, dynamic>);
          _relays[entry.key] = relay;
        }
      }
    } catch (e) {
      debugPrint('Failed to load relays: $e');
    }
  }

  Future<void> _saveRelays() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) throw Exception('User not signed in');

      final relaysData = <String, dynamic>{};
      for (final entry in _relays.entries) {
        relaysData[entry.key] = entry.value.toJson();
      }

      final jsonString = jsonEncode(relaysData);
      final encryptionService = _ref.read(encryptionServiceProvider);
      final encryptedContent = await encryptionService.safeEncryptData(jsonString);

      final customData = PartialCustomData(
        identifier: _storageKey,
        content: encryptedContent,
      );
      final signedData = await customData.signWith(signer);

      await _ref.storage.save({signedData});
      await _ref.storage.publish({signedData});
    } catch (e) {
      debugPrint('Failed to save relays: $e');
    }
  }

  Future<void> _loadSettings() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return;

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_settingsKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) return;

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return;

      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(encryptedContent);

      if (decryptedData.isEmpty) return;

      if (decryptedData.startsWith('{')) {
        final settingsData = jsonDecode(decryptedData) as Map<String, dynamic>;
        _settings = RelayManagementSettings.fromJson(settingsData);
      }
    } catch (e) {
      debugPrint('Failed to load settings: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) throw Exception('User not signed in');

      final jsonString = jsonEncode(_settings.toJson());
      final encryptionService = _ref.read(encryptionServiceProvider);
      final encryptedContent = await encryptionService.safeEncryptData(jsonString);

      final customData = PartialCustomData(
        identifier: _settingsKey,
        content: encryptedContent,
      );
      final signedData = await customData.signWith(signer);

      await _ref.storage.save({signedData});
      await _ref.storage.publish({signedData});
    } catch (e) {
      debugPrint('Failed to save settings: $e');
    }
  }

  Future<void> _loadTemplates() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return;

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_templatesKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) return;

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return;

      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(encryptedContent);

      if (decryptedData.isEmpty) return;

      if (decryptedData.startsWith('{')) {
        final templatesData = jsonDecode(decryptedData) as Map<String, dynamic>;
        for (final entry in templatesData.entries) {
          final template = RelayTemplate.fromJson(entry.value as Map<String, dynamic>);
          _templates[entry.key] = template;
        }
      }
    } catch (e) {
      debugPrint('Failed to load templates: $e');
    }
  }

  Future<void> _saveTemplates() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) throw Exception('User not signed in');

      final templatesData = <String, dynamic>{};
      for (final entry in _templates.entries) {
        templatesData[entry.key] = entry.value.toJson();
      }

      final jsonString = jsonEncode(templatesData);
      final encryptionService = _ref.read(encryptionServiceProvider);
      final encryptedContent = await encryptionService.safeEncryptData(jsonString);

      final customData = PartialCustomData(
        identifier: _templatesKey,
        content: encryptedContent,
      );
      final signedData = await customData.signWith(signer);

      await _ref.storage.save({signedData});
      await _ref.storage.publish({signedData});
    } catch (e) {
      debugPrint('Failed to save templates: $e');
    }
  }

  Future<void> _loadOperations() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return;

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_operationsKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) return;

      final latestData = customDataList.first;
      final encryptedContent = latestData.content;

      if (encryptedContent.isEmpty) return;

      final encryptionService = _ref.read(encryptionServiceProvider);
      final decryptedData = await encryptionService.safeDecryptData(encryptedContent);

      if (decryptedData.isEmpty) return;

      if (decryptedData.startsWith('{')) {
        final operationsData = jsonDecode(decryptedData) as Map<String, dynamic>;
        for (final entry in operationsData.entries) {
          final operation = RelayBatchOperation.fromJson(entry.value as Map<String, dynamic>);
          _operations[entry.key] = operation;
        }
      }
    } catch (e) {
      debugPrint('Failed to load operations: $e');
    }
  }

  Future<void> _saveOperations() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) throw Exception('User not signed in');

      final operationsData = <String, dynamic>{};
      for (final entry in _operations.entries) {
        operationsData[entry.key] = entry.value.toJson();
      }

      final jsonString = jsonEncode(operationsData);
      final encryptionService = _ref.read(encryptionServiceProvider);
      final encryptedContent = await encryptionService.safeEncryptData(jsonString);

      final customData = PartialCustomData(
        identifier: _operationsKey,
        content: encryptedContent,
      );
      final signedData = await customData.signWith(signer);

      await _ref.storage.save({signedData});
      await _ref.storage.publish({signedData});
    } catch (e) {
      debugPrint('Failed to save operations: $e');
    }
  }

  // ====== BUILT-IN TEMPLATES ======

  Future<void> _initializeBuiltInTemplates() async {
    if (_templates.isEmpty) {
      final builtInTemplates = [
        RelayTemplate(
          id: 'general-purpose',
          name: 'General Purpose',
          description: 'A balanced set of popular and reliable relays',
          isBuiltIn: true,
          relays: [
            RelayConfig(
              id: 'damus',
              url: 'wss://relay.damus.io',
              name: 'Damus Relay',
              description: 'Popular general-purpose relay',
              priority: 100,
            ),
            RelayConfig(
              id: 'nostr-wine',
              url: 'wss://nostr.wine',
              name: 'Nostr Wine',
              description: 'High-performance relay',
              priority: 90,
            ),
            RelayConfig(
              id: 'nos-lol',
              url: 'wss://nos.lol',
              name: 'nos.lol',
              description: 'Fast and reliable',
              priority: 80,
            ),
          ],
        ),
        RelayTemplate(
          id: 'european',
          name: 'European Relays',
          description: 'Relays optimized for European users',
          isBuiltIn: true,
          relays: [
            RelayConfig(
              id: 'nostrich-de',
              url: 'wss://relay.nostrich.de',
              name: 'Nostrich DE',
              description: 'German relay',
              priority: 100,
            ),
            RelayConfig(
              id: 'nostr-ch',
              url: 'wss://relay.nostr.ch',
              name: 'Nostr CH',
              description: 'Swiss relay',
              priority: 90,
            ),
            RelayConfig(
              id: 'nostr-bg',
              url: 'wss://relay.nostr.bg',
              name: 'Nostr BG',
              description: 'Bulgarian relay',
              priority: 80,
            ),
          ],
        ),
        RelayTemplate(
          id: 'high-performance',
          name: 'High Performance',
          description: 'Fast relays with low latency',
          isBuiltIn: true,
          relays: [
            RelayConfig(
              id: 'nostr-wine-hp',
              url: 'wss://nostr.wine',
              name: 'Nostr Wine',
              description: 'High-performance relay',
              priority: 100,
            ),
            RelayConfig(
              id: 'brb-io-hp',
              url: 'wss://brb.io',
              name: 'BRB.io',
              description: 'Business relay',
              priority: 90,
            ),
          ],
        ),
      ];

      for (final template in builtInTemplates) {
        _templates[template.id] = template;
      }
      
      await _saveTemplates();
      _templatesController.add(Map.from(_templates));
    }
  }

  // ====== UTILITIES ======

  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}

/// Provider for the relay management service
final relayManagementServiceProvider = Provider<RelayManagementService>(
  (ref) => RelayManagementService(ref),
);