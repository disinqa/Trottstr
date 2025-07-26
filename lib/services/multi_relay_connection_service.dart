import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/models/multi_relay_connection_models.dart';
import 'package:trottstr/services/encryption_service.dart';
import 'package:trottstr/services/relay_management_service.dart';

/// Service for managing concurrent multi-relay connections
class MultiRelayConnectionService {
  static const String _storageKey = 'multi_relay_connections';
  static const String _settingsKey = 'multi_relay_connection_settings';
  static const String _activeConnectionKey = 'active_multi_relay_connection';

  final Ref _ref;
  final Map<String, MultiRelayConnection> _connections = {};
  MultiRelayConnection? _activeConnection;
  MultiRelayConnectionSettings _settings = const MultiRelayConnectionSettings();

  // Stream controllers for real-time updates
  final StreamController<Map<String, MultiRelayConnection>> _connectionsController = 
      StreamController<Map<String, MultiRelayConnection>>.broadcast();
  final StreamController<MultiRelayConnection?> _activeConnectionController = 
      StreamController<MultiRelayConnection?>.broadcast();
  final StreamController<MultiRelayConnectionSettings> _settingsController = 
      StreamController<MultiRelayConnectionSettings>.broadcast();

  // Connection management
  final Map<String, Timer> _connectionTimers = {};
  final Map<String, StreamSubscription> _healthMonitors = {};
  Timer? _priorityRotationTimer;
  Timer? _failoverTimer;

  MultiRelayConnectionService(this._ref);

  // Streams for reactive updates
  Stream<Map<String, MultiRelayConnection>> get connectionsStream => _connectionsController.stream;
  Stream<MultiRelayConnection?> get activeConnectionStream => _activeConnectionController.stream;
  Stream<MultiRelayConnectionSettings> get settingsStream => _settingsController.stream;

  // Getters
  Map<String, MultiRelayConnection> get connections => Map.unmodifiable(_connections);
  MultiRelayConnection? get activeConnection => _activeConnection;
  MultiRelayConnectionSettings get settings => _settings;

  /// Initialize the service and load persisted data
  Future<void> initialize() async {
    try {
      await _loadConnections();
      await _loadSettings();
      await _loadActiveConnection();
      _startHealthMonitoring();
      _startPriorityRotation();
      
      debugPrint('MultiRelayConnectionService initialized successfully');
    } catch (e) {
      debugPrint('Failed to initialize MultiRelayConnectionService: $e');
      rethrow;
    }
  }

  /// Dispose resources
  void dispose() {
    _connectionTimers.values.forEach((timer) => timer.cancel());
    _healthMonitors.values.forEach((subscription) => subscription.cancel());
    _priorityRotationTimer?.cancel();
    _failoverTimer?.cancel();
    _connectionsController.close();
    _activeConnectionController.close();
    _settingsController.close();
  }

  // ====== CONNECTION MANAGEMENT ======

  /// Create a new multi-relay connection
  Future<void> createConnection(MultiRelayConnection connection) async {
    try {
      _connections[connection.id] = connection;
      await _saveConnections();
      _connectionsController.add(Map.from(_connections));
      
      debugPrint('Created multi-relay connection: ${connection.name}');
    } catch (e) {
      debugPrint('Failed to create connection: $e');
      rethrow;
    }
  }

  /// Update an existing connection
  Future<void> updateConnection(String connectionId, MultiRelayConnection updatedConnection) async {
    try {
      if (!_connections.containsKey(connectionId)) {
        throw Exception('Connection with id $connectionId not found');
      }
      
      _connections[connectionId] = updatedConnection;
      await _saveConnections();
      _connectionsController.add(Map.from(_connections));
      
      // Update active connection if it's the one being updated
      if (_activeConnection?.id == connectionId) {
        _activeConnection = updatedConnection;
        _activeConnectionController.add(_activeConnection);
        await _saveActiveConnection();
      }
      
      debugPrint('Updated connection: ${updatedConnection.name}');
    } catch (e) {
      debugPrint('Failed to update connection: $e');
      rethrow;
    }
  }

  /// Delete a connection
  Future<void> deleteConnection(String connectionId) async {
    try {
      final connection = _connections.remove(connectionId);
      if (connection != null) {
        // Disconnect if it's the active connection
        if (_activeConnection?.id == connectionId) {
          await deactivateConnection();
        }
        
        await _saveConnections();
        _connectionsController.add(Map.from(_connections));
        debugPrint('Deleted connection: ${connection.name}');
      }
    } catch (e) {
      debugPrint('Failed to delete connection: $e');
      rethrow;
    }
  }

  /// Activate a multi-relay connection
  Future<void> activateConnection(String connectionId) async {
    try {
      final connection = _connections[connectionId];
      if (connection == null) {
        throw Exception('Connection not found: $connectionId');
      }

      // Deactivate current connection first
      if (_activeConnection != null) {
        await deactivateConnection();
      }

      _activeConnection = connection.copyWith(isActive: true, lastUpdated: DateTime.now());
      _connections[connectionId] = _activeConnection!;
      
      await _saveActiveConnection();
      await _saveConnections();
      
      _activeConnectionController.add(_activeConnection);
      _connectionsController.add(Map.from(_connections));

      // Start connecting to relays based on priority and settings
      await _connectToSelectedRelays();
      
      debugPrint('Activated connection: ${connection.name}');
    } catch (e) {
      debugPrint('Failed to activate connection: $e');
      rethrow;
    }
  }

  /// Deactivate the current connection
  Future<void> deactivateConnection() async {
    try {
      if (_activeConnection == null) return;

      // Disconnect from all relays in the connection (optional based on settings)
      if (!_settings.enableAutomaticFailover) {
        await _disconnectFromAllRelays();
      }

      final deactivatedConnection = _activeConnection!.copyWith(
        isActive: false,
        lastUpdated: DateTime.now(),
      );
      
      _connections[_activeConnection!.id] = deactivatedConnection;
      _activeConnection = null;

      await _saveActiveConnection();
      await _saveConnections();
      
      _activeConnectionController.add(null);
      _connectionsController.add(Map.from(_connections));
      
      debugPrint('Deactivated connection');
    } catch (e) {
      debugPrint('Failed to deactivate connection: $e');
      rethrow;
    }
  }

  /// Connect to selected relays based on priority
  Future<void> _connectToSelectedRelays() async {
    if (_activeConnection == null) return;

    final relayService = _ref.read(relayManagementServiceProvider);
    final selectedRelays = _activeConnection!.relaysByPriority
        .where((relay) => relay.isSelected)
        .take(_settings.maxConcurrentConnections)
        .toList();

    final connectionTasks = <Future>[];
    
    for (final relay in selectedRelays) {
      connectionTasks.add(_connectToRelay(relay, relayService));
    }

    try {
      await Future.wait(connectionTasks);
    } catch (e) {
      debugPrint('Some relay connections failed: $e');
    }
  }

  /// Connect to a specific relay with retry logic
  Future<void> _connectToRelay(ConnectedRelay relay, RelayManagementService relayService) async {
    try {
      final result = await relayService.executeBatchOperation(
        RelayBatchOperationType.connect,
        [relay.relayId],
      );

      // Update relay connection status
      await _updateRelayConnectionStatus(relay.relayId, true, DateTime.now());
      
      debugPrint('Connected to relay: ${relay.relayConfig.name}');
    } catch (e) {
      debugPrint('Failed to connect to relay ${relay.relayConfig.name}: $e');
      
      // Update relay connection status
      await _updateRelayConnectionStatus(relay.relayId, false, null);
      
      // Trigger failover if enabled
      if (_settings.enableAutomaticFailover) {
        _scheduleFailover(relay);
      }
    }
  }

  /// Update relay connection status in the active connection
  Future<void> _updateRelayConnectionStatus(String relayId, bool isConnected, DateTime? connectedAt) async {
    if (_activeConnection == null) return;

    final updatedRelays = _activeConnection!.connectedRelays.map((relay) {
      if (relay.relayId == relayId) {
        return relay.copyWith(
          isConnected: isConnected,
          connectedAt: connectedAt,
          lastStatusChange: DateTime.now(),
        );
      }
      return relay;
    }).toList();

    final updatedConnection = _activeConnection!.copyWith(
      connectedRelays: updatedRelays,
      lastUpdated: DateTime.now(),
    );

    await updateConnection(_activeConnection!.id, updatedConnection);
  }

  /// Disconnect from all relays
  Future<void> _disconnectFromAllRelays() async {
    if (_activeConnection == null) return;

    final relayService = _ref.read(relayManagementServiceProvider);
    final connectedRelayIds = _activeConnection!.activeRelays
        .map((relay) => relay.relayId)
        .toList();

    if (connectedRelayIds.isNotEmpty) {
      try {
        await relayService.executeBatchOperation(
          RelayBatchOperationType.disconnect,
          connectedRelayIds,
        );
      } catch (e) {
        debugPrint('Failed to disconnect from some relays: $e');
      }
    }
  }

  /// Reorder relays by priority without disconnecting
  Future<void> reorderRelayPriority(String connectionId, List<ConnectedRelay> newOrder) async {
    try {
      final connection = _connections[connectionId];
      if (connection == null) {
        throw Exception('Connection not found: $connectionId');
      }

      // Reassign priority order
      final reorderedRelays = newOrder.asMap().entries.map((entry) {
        final index = entry.key;
        final relay = entry.value;
        return relay.copyWith(priorityOrder: index + 1);
      }).toList();

      final updatedConnection = connection.copyWith(
        connectedRelays: reorderedRelays,
        lastUpdated: DateTime.now(),
      );

      await updateConnection(connectionId, updatedConnection);
      
      // If this is the active connection, apply priority changes to live connections
      if (_activeConnection?.id == connectionId) {
        await _applyPriorityChanges(reorderedRelays);
      }
      
      debugPrint('Reordered relay priorities for connection: ${connection.name}');
    } catch (e) {
      debugPrint('Failed to reorder relay priorities: $e');
      rethrow;
    }
  }

  /// Apply priority changes to live connections without disconnecting
  Future<void> _applyPriorityChanges(List<ConnectedRelay> newOrder) async {
    if (_settings.enableLoadBalancing) {
      // Implement load balancing strategy adjustments
      await _adjustLoadBalancing(newOrder);
    }
    
    // Schedule priority rotation if enabled
    if (_settings.enablePriorityRotation) {
      _restartPriorityRotation();
    }
  }

  /// Adjust load balancing based on new priority order
  Future<void> _adjustLoadBalancing(List<ConnectedRelay> relays) async {
    switch (_settings.loadBalancingStrategy) {
      case LoadBalancingStrategy.priority:
        // Already handled by priority order
        break;
      case LoadBalancingStrategy.latency:
        // Reorder by latency while maintaining connections
        relays.sort((a, b) {
          final aLatency = a.relayConfig.latency ?? 9999;
          final bLatency = b.relayConfig.latency ?? 9999;
          return aLatency.compareTo(bLatency);
        });
        break;
      case LoadBalancingStrategy.health:
        // Reorder by health score
        relays.sort((a, b) => 
            b.relayConfig.healthScore.compareTo(a.relayConfig.healthScore));
        break;
      case LoadBalancingStrategy.roundRobin:
      case LoadBalancingStrategy.random:
        // These strategies don't require reordering
        break;
    }
  }

  /// Schedule failover for a failed relay
  void _scheduleFailover(ConnectedRelay failedRelay) {
    _failoverTimer?.cancel();
    _failoverTimer = Timer(_settings.failoverDelay, () async {
      await _performFailover(failedRelay);
    });
  }

  /// Perform failover to backup relays
  Future<void> _performFailover(ConnectedRelay failedRelay) async {
    if (_activeConnection == null) return;

    // Find next available relay not currently connected
    final availableRelays = _activeConnection!.connectedRelays
        .where((relay) => !relay.isConnected && relay.isSelected)
        .toList();

    if (availableRelays.isNotEmpty) {
      final backupRelay = availableRelays.first;
      final relayService = _ref.read(relayManagementServiceProvider);
      
      try {
        await _connectToRelay(backupRelay, relayService);
        debugPrint('Failover successful: ${failedRelay.relayConfig.name} -> ${backupRelay.relayConfig.name}');
      } catch (e) {
        debugPrint('Failover failed: $e');
      }
    }
  }

  // ====== HEALTH MONITORING ======

  void _startHealthMonitoring() {
    if (_settings.enableConnectionHealthMonitoring) {
      Timer.periodic(_settings.healthCheckInterval, (_) {
        _performHealthCheck();
      });
    }
  }

  Future<void> _performHealthCheck() async {
    if (_activeConnection == null) return;

    final relayService = _ref.read(relayManagementServiceProvider);
    
    for (final relay in _activeConnection!.activeRelays) {
      try {
        await relayService.executeBatchOperation(
          RelayBatchOperationType.test,
          [relay.relayId],
        );
      } catch (e) {
        debugPrint('Health check failed for ${relay.relayConfig.name}: $e');
        
        // Trigger failover if health is consistently poor
        if (_settings.enableAutomaticFailover) {
          _scheduleFailover(relay);
        }
      }
    }
  }

  // ====== PRIORITY ROTATION ======

  void _startPriorityRotation() {
    if (_settings.enablePriorityRotation) {
      _priorityRotationTimer = Timer.periodic(_settings.priorityRotationInterval, (_) {
        _rotatePriorities();
      });
    }
  }

  void _restartPriorityRotation() {
    _priorityRotationTimer?.cancel();
    _startPriorityRotation();
  }

  Future<void> _rotatePriorities() async {
    if (_activeConnection == null) return;

    final connectedRelays = _activeConnection!.activeRelays.toList();
    if (connectedRelays.length < 2) return;

    // Rotate connected relays (move first to last)
    final rotatedRelays = <ConnectedRelay>[];
    rotatedRelays.addAll(connectedRelays.skip(1));
    rotatedRelays.add(connectedRelays.first);

    await reorderRelayPriority(_activeConnection!.id, rotatedRelays);
    debugPrint('Rotated relay priorities');
  }

  // ====== SETTINGS ======

  /// Update multi-relay connection settings
  Future<void> updateSettings(MultiRelayConnectionSettings newSettings) async {
    _settings = newSettings;
    await _saveSettings();
    _settingsController.add(_settings);

    // Restart timers if intervals changed
    if (_settings.enableConnectionHealthMonitoring) {
      _startHealthMonitoring();
    }
    
    if (_settings.enablePriorityRotation) {
      _restartPriorityRotation();
    } else {
      _priorityRotationTimer?.cancel();
    }
  }

  // ====== PERSISTENCE ======

  Future<void> _loadConnections() async {
    // Implementation similar to relay management service persistence
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return;

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {'#d': {_storageKey}},
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
        final connectionsData = jsonDecode(decryptedData) as Map<String, dynamic>;
        for (final entry in connectionsData.entries) {
          final connection = MultiRelayConnection.fromJson(entry.value as Map<String, dynamic>);
          _connections[entry.key] = connection;
        }
      }
    } catch (e) {
      debugPrint('Failed to load connections: $e');
    }
  }

  Future<void> _saveConnections() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) throw Exception('User not signed in');

      final connectionsData = <String, dynamic>{};
      for (final entry in _connections.entries) {
        connectionsData[entry.key] = entry.value.toJson();
      }

      final jsonString = jsonEncode(connectionsData);
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
      debugPrint('Failed to save connections: $e');
    }
  }

  Future<void> _loadActiveConnection() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) return;

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {'#d': {_activeConnectionKey}},
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
        final activeConnectionData = jsonDecode(decryptedData) as Map<String, dynamic>;
        final connectionId = activeConnectionData['connectionId'] as String?;
        if (connectionId != null && _connections.containsKey(connectionId)) {
          _activeConnection = _connections[connectionId];
        }
      }
    } catch (e) {
      debugPrint('Failed to load active connection: $e');
    }
  }

  Future<void> _saveActiveConnection() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) throw Exception('User not signed in');

      final activeConnectionData = {
        'connectionId': _activeConnection?.id,
        'timestamp': DateTime.now().toIso8601String(),
      };

      final jsonString = jsonEncode(activeConnectionData);
      final encryptionService = _ref.read(encryptionServiceProvider);
      final encryptedContent = await encryptionService.safeEncryptData(jsonString);

      final customData = PartialCustomData(
        identifier: _activeConnectionKey,
        content: encryptedContent,
      );
      final signedData = await customData.signWith(signer);

      await _ref.storage.save({signedData});
      await _ref.storage.publish({signedData});
    } catch (e) {
      debugPrint('Failed to save active connection: $e');
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
          tags: {'#d': {_settingsKey}},
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
        _settings = MultiRelayConnectionSettings.fromJson(settingsData);
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

  /// Utility method to generate unique IDs
  String _generateId() {
    return DateTime.now().millisecondsSinceEpoch.toString() + 
           Random().nextInt(1000).toString();
  }
}

/// Provider for the multi-relay connection service
final multiRelayConnectionServiceProvider = Provider<MultiRelayConnectionService>(
  (ref) => MultiRelayConnectionService(ref),
);