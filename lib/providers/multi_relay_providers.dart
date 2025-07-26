import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/multi_relay_connection_models.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/providers/relay_providers.dart';
import 'package:trottstr/services/relay_management_service.dart';

/// Provider for relay selection state (multi-select and drag operations)
final relaySelectionStateProvider = StateProvider<RelaySelectionState>((ref) {
  return const RelaySelectionState();
});

/// Provider for multi-relay connection settings
final multiRelayConnectionSettingsProvider = StateProvider<MultiRelayConnectionSettings>((ref) {
  return const MultiRelayConnectionSettings();
});

/// Provider for the current multi-relay connection
final currentMultiRelayConnectionProvider = StateProvider<MultiRelayConnection?>((ref) {
  return null;
});

/// Provider for available relays formatted as ConnectedRelay objects
final availableConnectedRelaysProvider = Provider<List<ConnectedRelay>>((ref) {
  final relaysAsync = ref.watch(relayConfigurationsProvider);
  
  return relaysAsync.when(
    data: (relays) {
      final relayList = relays.values.toList();
      relayList.sort((a, b) => b.priority.compareTo(a.priority));
      
      return relayList.asMap().entries.map((entry) {
        final index = entry.key;
        final relay = entry.value;
        
        return ConnectedRelay(
          relayId: relay.id,
          relayConfig: relay,
          priorityOrder: index + 1,
          isSelected: false,
          isConnected: relay.status == RelayStatus.connected,
        );
      }).toList();
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for selected relays as ConnectedRelay objects
final selectedConnectedRelaysProvider = Provider<List<ConnectedRelay>>((ref) {
  final selectionState = ref.watch(relaySelectionStateProvider);
  final availableRelays = ref.watch(availableConnectedRelaysProvider);
  final currentConnection = ref.watch(currentMultiRelayConnectionProvider);
  
  if (currentConnection != null) {
    // Return relays from current connection, maintaining their priority order
    return currentConnection.connectedRelays;
  }
  
  // Return newly selected relays with assigned priorities
  return availableRelays
      .where((relay) => selectionState.isRelaySelected(relay.relayId))
      .toList();
});

/// Provider for relay tiles (available relays not yet selected)
final availableRelayTilesProvider = Provider<List<ConnectedRelay>>((ref) {
  final selectionState = ref.watch(relaySelectionStateProvider);
  final availableRelays = ref.watch(availableConnectedRelaysProvider);
  final currentConnection = ref.watch(currentMultiRelayConnectionProvider);
  
  final selectedIds = currentConnection?.connectedRelays.map((r) => r.relayId).toSet() ?? 
                      selectionState.selectedRelayIds;
  
  return availableRelays
      .where((relay) => !selectedIds.contains(relay.relayId))
      .toList();
});

/// Provider for multi-relay connection statistics
final multiRelayConnectionStatsProvider = Provider<MultiRelayConnectionStats>((ref) {
  final currentConnection = ref.watch(currentMultiRelayConnectionProvider);
  
  if (currentConnection == null) {
    return const MultiRelayConnectionStats(
      totalSelected: 0,
      connected: 0,
      connecting: 0,
      disconnected: 0,
      errors: 0,
      averageLatency: 0.0,
      overallHealth: 0.0,
    );
  }
  
  final relays = currentConnection.connectedRelays;
  final connected = relays.where((r) => r.isConnected && r.relayConfig.status == RelayStatus.connected).length;
  final connecting = relays.where((r) => r.relayConfig.status == RelayStatus.connecting).length;
  final disconnected = relays.where((r) => !r.isConnected || r.relayConfig.status == RelayStatus.disconnected).length;
  final errors = relays.where((r) => r.relayConfig.status == RelayStatus.error).length;
  
  final latencies = relays
      .where((r) => r.relayConfig.latency != null)
      .map((r) => r.relayConfig.latency!)
      .toList();
  
  final averageLatency = latencies.isNotEmpty
      ? latencies.reduce((a, b) => a + b) / latencies.length
      : 0.0;
  
  return MultiRelayConnectionStats(
    totalSelected: relays.length,
    connected: connected,
    connecting: connecting,
    disconnected: disconnected,
    errors: errors,
    averageLatency: averageLatency,
    overallHealth: currentConnection.connectionHealthScore,
  );
});

/// Provider for drag operation state
final relayDragStateProvider = StateProvider<RelayDragData?>((ref) => null);

/// Provider for managing multi-relay operations
final multiRelayManagerProvider = Provider<MultiRelayManager>((ref) {
  return MultiRelayManager(ref);
});

/// Provider for checking if a relay can be connected
final canConnectRelayProvider = Provider.family<bool, String>((ref, relayId) {
  final settings = ref.watch(multiRelayConnectionSettingsProvider);
  final currentConnection = ref.watch(currentMultiRelayConnectionProvider);
  
  if (currentConnection == null) return true;
  
  final connectedCount = currentConnection.activeRelays.length;
  return connectedCount < settings.maxConcurrentConnections;
});

/// Provider for priority suggestions when adding new relays
final nextPrioritySuggestionProvider = Provider<int>((ref) {
  final currentConnection = ref.watch(currentMultiRelayConnectionProvider);
  
  if (currentConnection == null || currentConnection.connectedRelays.isEmpty) {
    return 1;
  }
  
  final maxPriority = currentConnection.connectedRelays
      .map((r) => r.priorityOrder)
      .reduce((a, b) => a > b ? a : b);
  
  return maxPriority + 1;
});

/// Provider for connection health warnings
final connectionHealthWarningsProvider = Provider<List<String>>((ref) {
  final currentConnection = ref.watch(currentMultiRelayConnectionProvider);
  final settings = ref.watch(multiRelayConnectionSettingsProvider);
  final warnings = <String>[];
  
  if (currentConnection == null) return warnings;
  
  final stats = ref.watch(multiRelayConnectionStatsProvider);
  
  // Check for no connections
  if (stats.connected == 0) {
    warnings.add('No relays are currently connected');
  }
  
  // Check for low connection count
  if (stats.connected == 1 && currentConnection.connectedRelays.length > 1) {
    warnings.add('Only one relay connected - consider checking other relays');
  }
  
  // Check for high error rate
  if (stats.errors > 0 && stats.errors / stats.totalSelected > 0.3) {
    warnings.add('High error rate detected - ${stats.errors} of ${stats.totalSelected} relays have errors');
  }
  
  // Check for poor health
  if (stats.overallHealth < 0.5) {
    warnings.add('Poor connection health detected');
  }
  
  // Check for high latency
  if (stats.averageLatency > 500) {
    warnings.add('High average latency: ${stats.averageLatency.round()}ms');
  }
  
  // Check for exceeding max connections
  if (stats.connected > settings.maxConcurrentConnections) {
    warnings.add('Connected to more relays than configured maximum (${settings.maxConcurrentConnections})');
  }
  
  return warnings;
});

/// Manager class for multi-relay operations
class MultiRelayManager {
  final Ref _ref;
  
  MultiRelayManager(this._ref);
  
  /// Toggle selection of a relay
  void toggleRelaySelection(String relayId) {
    final currentState = _ref.read(relaySelectionStateProvider);
    final newState = currentState.toggleRelay(relayId);
    _ref.read(relaySelectionStateProvider.notifier).state = newState;
  }
  
  /// Enter multi-select mode
  void enterMultiSelectMode() {
    final currentState = _ref.read(relaySelectionStateProvider);
    _ref.read(relaySelectionStateProvider.notifier).state = 
        currentState.copyWith(isMultiSelectMode: true);
  }
  
  /// Exit multi-select mode
  void exitMultiSelectMode() {
    final currentState = _ref.read(relaySelectionStateProvider);
    _ref.read(relaySelectionStateProvider.notifier).state = 
        currentState.copyWith(
          isMultiSelectMode: false,
          selectedRelayIds: {},
        );
  }
  
  /// Select all available relays
  void selectAllRelays() {
    final availableRelays = _ref.read(availableRelayTilesProvider);
    final relayIds = availableRelays.map((r) => r.relayId).toList();
    
    final currentState = _ref.read(relaySelectionStateProvider);
    _ref.read(relaySelectionStateProvider.notifier).state = 
        currentState.selectAll(relayIds);
  }
  
  /// Clear all selections
  void clearSelection() {
    final currentState = _ref.read(relaySelectionStateProvider);
    _ref.read(relaySelectionStateProvider.notifier).state = 
        currentState.clearSelection();
  }
  
  /// Create multi-relay connection from selected relays
  Future<void> createMultiRelayConnection(String connectionName) async {
    final selectedRelays = _ref.read(selectedConnectedRelaysProvider);
    if (selectedRelays.isEmpty) return;
    
    // Assign priority order based on current selection order
    final prioritizedRelays = selectedRelays.asMap().entries.map((entry) {
      final index = entry.key;
      final relay = entry.value;
      return relay.copyWith(priorityOrder: index + 1);
    }).toList();
    
    final connection = MultiRelayConnection(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      name: connectionName,
      connectedRelays: prioritizedRelays,
      createdAt: DateTime.now(),
      isActive: true,
    );
    
    _ref.read(currentMultiRelayConnectionProvider.notifier).state = connection;
    
    // Clear selection after creating connection
    clearSelection();
    exitMultiSelectMode();
  }
  
  /// Update relay priority in current connection
  void updateRelayPriority(String relayId, int newPriority) {
    final currentConnection = _ref.read(currentMultiRelayConnectionProvider);
    if (currentConnection == null) return;
    
    final updatedRelays = currentConnection.connectedRelays.map((relay) {
      if (relay.relayId == relayId) {
        return relay.copyWith(priorityOrder: newPriority);
      }
      return relay;
    }).toList();
    
    // Re-sort and reassign priorities to maintain consistency
    updatedRelays.sort((a, b) => a.priorityOrder.compareTo(b.priorityOrder));
    final reorderedRelays = updatedRelays.asMap().entries.map((entry) {
      final index = entry.key;
      final relay = entry.value;
      return relay.copyWith(priorityOrder: index + 1);
    }).toList();
    
    final updatedConnection = currentConnection.copyWith(
      connectedRelays: reorderedRelays,
      lastUpdated: DateTime.now(),
    );
    
    _ref.read(currentMultiRelayConnectionProvider.notifier).state = updatedConnection;
  }
  
  /// Reorder relays by moving from one position to another
  void reorderRelays(int oldIndex, int newIndex) {
    final currentConnection = _ref.read(currentMultiRelayConnectionProvider);
    if (currentConnection == null) return;
    
    final relays = List<ConnectedRelay>.from(currentConnection.connectedRelays);
    final movedRelay = relays.removeAt(oldIndex);
    relays.insert(newIndex, movedRelay);
    
    // Reassign priority order based on new positions
    final reorderedRelays = relays.asMap().entries.map((entry) {
      final index = entry.key;
      final relay = entry.value;
      return relay.copyWith(priorityOrder: index + 1);
    }).toList();
    
    final updatedConnection = currentConnection.copyWith(
      connectedRelays: reorderedRelays,
      lastUpdated: DateTime.now(),
    );
    
    _ref.read(currentMultiRelayConnectionProvider.notifier).state = updatedConnection;
  }
  
  /// Add a relay to current connection
  void addRelayToConnection(String relayId) {
    final currentConnection = _ref.read(currentMultiRelayConnectionProvider);
    if (currentConnection == null) return;
    
    final availableRelays = _ref.read(availableConnectedRelaysProvider);
    final relayToAdd = availableRelays.firstWhere((r) => r.relayId == relayId);
    
    final nextPriority = _ref.read(nextPrioritySuggestionProvider);
    final newRelay = relayToAdd.copyWith(
      priorityOrder: nextPriority,
      isSelected: true,
    );
    
    final updatedRelays = [...currentConnection.connectedRelays, newRelay];
    
    final updatedConnection = currentConnection.copyWith(
      connectedRelays: updatedRelays,
      lastUpdated: DateTime.now(),
    );
    
    _ref.read(currentMultiRelayConnectionProvider.notifier).state = updatedConnection;
  }
  
  /// Remove a relay from current connection
  void removeRelayFromConnection(String relayId) {
    final currentConnection = _ref.read(currentMultiRelayConnectionProvider);
    if (currentConnection == null) return;
    
    final updatedRelays = currentConnection.connectedRelays
        .where((relay) => relay.relayId != relayId)
        .toList();
    
    // Reassign priorities after removal
    final reorderedRelays = updatedRelays.asMap().entries.map((entry) {
      final index = entry.key;
      final relay = entry.value;
      return relay.copyWith(priorityOrder: index + 1);
    }).toList();
    
    final updatedConnection = currentConnection.copyWith(
      connectedRelays: reorderedRelays,
      lastUpdated: DateTime.now(),
    );
    
    _ref.read(currentMultiRelayConnectionProvider.notifier).state = updatedConnection;
  }
  
  /// Connect to all selected relays in the connection
  Future<void> connectToSelectedRelays() async {
    final currentConnection = _ref.read(currentMultiRelayConnectionProvider);
    if (currentConnection == null) return;
    
    final service = _ref.read(relayManagementServiceProvider);
    final settings = _ref.read(multiRelayConnectionSettingsProvider);
    
    // Connect to relays based on priority, up to max concurrent connections
    final relaysToConnect = currentConnection.relaysByPriority
        .take(settings.maxConcurrentConnections)
        .where((relay) => relay.isSelected)
        .toList();
    
    for (final relay in relaysToConnect) {
      try {
        await service.executeBatchOperation(
          RelayBatchOperationType.connect,
          [relay.relayId],
        );
      } catch (e) {
        // Handle individual connection failures
        print('Failed to connect to ${relay.relayConfig.name}: $e');
      }
    }
  }
  
  /// Start drag operation
  void startDrag(String relayId, int currentIndex, int currentPriority, RelayConfig relayConfig) {
    final dragData = RelayDragData(
      relayId: relayId,
      currentIndex: currentIndex,
      currentPriority: currentPriority,
      relayConfig: relayConfig,
    );
    
    _ref.read(relayDragStateProvider.notifier).state = dragData;
    
    final currentState = _ref.read(relaySelectionStateProvider);
    _ref.read(relaySelectionStateProvider.notifier).state = 
        currentState.copyWith(isDragActive: true, draggedRelayId: relayId);
  }
  
  /// End drag operation
  void endDrag() {
    _ref.read(relayDragStateProvider.notifier).state = null;
    
    final currentState = _ref.read(relaySelectionStateProvider);
    _ref.read(relaySelectionStateProvider.notifier).state = 
        currentState.copyWith(
          isDragActive: false, 
          draggedRelayId: null,
          dragTargetIndex: null,
        );
  }
}

/// Statistics for multi-relay connections
class MultiRelayConnectionStats {
  final int totalSelected;
  final int connected;
  final int connecting;
  final int disconnected;
  final int errors;
  final double averageLatency;
  final double overallHealth;

  const MultiRelayConnectionStats({
    required this.totalSelected,
    required this.connected,
    required this.connecting,
    required this.disconnected,
    required this.errors,
    required this.averageLatency,
    required this.overallHealth,
  });

  double get connectionRate => totalSelected > 0 ? connected / totalSelected : 0.0;
  double get errorRate => totalSelected > 0 ? errors / totalSelected : 0.0;
  bool get hasIssues => errors > 0 || overallHealth < 0.7;
}