import 'package:flutter/foundation.dart';
import 'package:trottstr/models/relay_models.dart';

/// Represents a multi-relay connection configuration
@immutable
class MultiRelayConnection {
  final String id;
  final String name;
  final List<ConnectedRelay> connectedRelays;
  final DateTime createdAt;
  final DateTime? lastUpdated;
  final bool isActive;
  final Map<String, dynamic> metadata;

  const MultiRelayConnection({
    required this.id,
    required this.name,
    required this.connectedRelays,
    required this.createdAt,
    this.lastUpdated,
    this.isActive = true,
    this.metadata = const {},
  });

  MultiRelayConnection copyWith({
    String? id,
    String? name,
    List<ConnectedRelay>? connectedRelays,
    DateTime? createdAt,
    DateTime? lastUpdated,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return MultiRelayConnection(
      id: id ?? this.id,
      name: name ?? this.name,
      connectedRelays: connectedRelays ?? this.connectedRelays,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'connectedRelays': connectedRelays.map((relay) => relay.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'lastUpdated': lastUpdated?.toIso8601String(),
      'isActive': isActive,
      'metadata': metadata,
    };
  }

  factory MultiRelayConnection.fromJson(Map<String, dynamic> json) {
    return MultiRelayConnection(
      id: json['id'] as String,
      name: json['name'] as String,
      connectedRelays: (json['connectedRelays'] as List<dynamic>)
          .map((relayJson) => ConnectedRelay.fromJson(relayJson as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      lastUpdated: json['lastUpdated'] != null
          ? DateTime.parse(json['lastUpdated'] as String)
          : null,
      isActive: json['isActive'] as bool? ?? true,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Get connected relays sorted by priority (highest first)
  List<ConnectedRelay> get relaysByPriority {
    final sortedRelays = List<ConnectedRelay>.from(connectedRelays);
    sortedRelays.sort((a, b) => b.priorityOrder.compareTo(a.priorityOrder));
    return sortedRelays;
  }

  /// Get the primary relay (highest priority)
  ConnectedRelay? get primaryRelay {
    if (connectedRelays.isEmpty) return null;
    return relaysByPriority.first;
  }

  /// Get all currently connected relays
  List<ConnectedRelay> get activeRelays {
    return connectedRelays.where((relay) => relay.isConnected).toList();
  }

  /// Calculate the overall connection health score
  double get connectionHealthScore {
    if (connectedRelays.isEmpty) return 0.0;
    
    final connectedCount = activeRelays.length;
    final totalCount = connectedRelays.length;
    final connectionRatio = connectedCount / totalCount;
    
    // Weight by priority - higher priority relays contribute more to health
    double weightedHealth = 0.0;
    double totalWeight = 0.0;
    
    for (final relay in connectedRelays) {
      final weight = relay.priorityOrder.toDouble();
      totalWeight += weight;
      if (relay.isConnected) {
        weightedHealth += weight * relay.relayConfig.healthScore;
      }
    }
    
    final averageHealth = totalWeight > 0 ? weightedHealth / totalWeight : 0.0;
    
    // Combine connection ratio and average health
    return (connectionRatio * 0.6 + averageHealth * 0.4).clamp(0.0, 1.0);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is MultiRelayConnection && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents a relay within a multi-relay connection with priority and selection state
@immutable
class ConnectedRelay {
  final String relayId;
  final RelayConfig relayConfig;
  final int priorityOrder;
  final bool isSelected;
  final bool isConnected;
  final DateTime? connectedAt;
  final DateTime? lastStatusChange;
  final Map<String, dynamic> connectionMetadata;

  const ConnectedRelay({
    required this.relayId,
    required this.relayConfig,
    required this.priorityOrder,
    this.isSelected = true,
    this.isConnected = false,
    this.connectedAt,
    this.lastStatusChange,
    this.connectionMetadata = const {},
  });

  ConnectedRelay copyWith({
    String? relayId,
    RelayConfig? relayConfig,
    int? priorityOrder,
    bool? isSelected,
    bool? isConnected,
    DateTime? connectedAt,
    DateTime? lastStatusChange,
    Map<String, dynamic>? connectionMetadata,
  }) {
    return ConnectedRelay(
      relayId: relayId ?? this.relayId,
      relayConfig: relayConfig ?? this.relayConfig,
      priorityOrder: priorityOrder ?? this.priorityOrder,
      isSelected: isSelected ?? this.isSelected,
      isConnected: isConnected ?? this.isConnected,
      connectedAt: connectedAt ?? this.connectedAt,
      lastStatusChange: lastStatusChange ?? this.lastStatusChange,
      connectionMetadata: connectionMetadata ?? this.connectionMetadata,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'relayId': relayId,
      'relayConfig': relayConfig.toJson(),
      'priorityOrder': priorityOrder,
      'isSelected': isSelected,
      'isConnected': isConnected,
      'connectedAt': connectedAt?.toIso8601String(),
      'lastStatusChange': lastStatusChange?.toIso8601String(),
      'connectionMetadata': connectionMetadata,
    };
  }

  factory ConnectedRelay.fromJson(Map<String, dynamic> json) {
    return ConnectedRelay(
      relayId: json['relayId'] as String,
      relayConfig: RelayConfig.fromJson(json['relayConfig'] as Map<String, dynamic>),
      priorityOrder: json['priorityOrder'] as int,
      isSelected: json['isSelected'] as bool? ?? true,
      isConnected: json['isConnected'] as bool? ?? false,
      connectedAt: json['connectedAt'] != null
          ? DateTime.parse(json['connectedAt'] as String)
          : null,
      lastStatusChange: json['lastStatusChange'] != null
          ? DateTime.parse(json['lastStatusChange'] as String)
          : null,
      connectionMetadata: json['connectionMetadata'] as Map<String, dynamic>? ?? {},
    );
  }

  /// Get display name for priority (e.g., "Primary", "Secondary", etc.)
  String get priorityDisplayName {
    switch (priorityOrder) {
      case 1:
        return 'Primary';
      case 2:
        return 'Secondary';
      case 3:
        return 'Tertiary';
      default:
        return 'Priority $priorityOrder';
    }
  }

  /// Get connection status with priority context
  RelayConnectionStatus get connectionStatus {
    if (!isSelected) return RelayConnectionStatus.unselected;
    if (isConnected) {
      return priorityOrder == 1 
          ? RelayConnectionStatus.primaryConnected
          : RelayConnectionStatus.secondaryConnected;
    }
    return RelayConnectionStatus.selectedDisconnected;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ConnectedRelay && 
           other.relayId == relayId && 
           other.priorityOrder == priorityOrder;
  }

  @override
  int get hashCode => Object.hash(relayId, priorityOrder);
}

/// Enhanced connection status for multi-relay context
enum RelayConnectionStatus {
  unselected,
  selectedDisconnected,
  primaryConnected,
  secondaryConnected,
  connecting,
  error,
}

/// UI state for relay selection and drag operations
@immutable
class RelaySelectionState {
  final Set<String> selectedRelayIds;
  final bool isMultiSelectMode;
  final String? draggedRelayId;
  final int? dragTargetIndex;
  final bool isDragActive;

  const RelaySelectionState({
    this.selectedRelayIds = const {},
    this.isMultiSelectMode = false,
    this.draggedRelayId,
    this.dragTargetIndex,
    this.isDragActive = false,
  });

  RelaySelectionState copyWith({
    Set<String>? selectedRelayIds,
    bool? isMultiSelectMode,
    String? draggedRelayId,
    int? dragTargetIndex,
    bool? isDragActive,
  }) {
    return RelaySelectionState(
      selectedRelayIds: selectedRelayIds ?? this.selectedRelayIds,
      isMultiSelectMode: isMultiSelectMode ?? this.isMultiSelectMode,
      draggedRelayId: draggedRelayId ?? this.draggedRelayId,
      dragTargetIndex: dragTargetIndex ?? this.dragTargetIndex,
      isDragActive: isDragActive ?? this.isDragActive,
    );
  }

  /// Toggle selection of a relay
  RelaySelectionState toggleRelay(String relayId) {
    final newSelected = Set<String>.from(selectedRelayIds);
    if (newSelected.contains(relayId)) {
      newSelected.remove(relayId);
    } else {
      newSelected.add(relayId);
    }
    return copyWith(selectedRelayIds: newSelected);
  }

  /// Select all relays from a list
  RelaySelectionState selectAll(List<String> relayIds) {
    return copyWith(selectedRelayIds: Set<String>.from(relayIds));
  }

  /// Clear all selections
  RelaySelectionState clearSelection() {
    return copyWith(selectedRelayIds: {});
  }

  /// Check if a relay is selected
  bool isRelaySelected(String relayId) {
    return selectedRelayIds.contains(relayId);
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelaySelectionState &&
           other.selectedRelayIds == selectedRelayIds &&
           other.isMultiSelectMode == isMultiSelectMode &&
           other.draggedRelayId == draggedRelayId &&
           other.dragTargetIndex == dragTargetIndex &&
           other.isDragActive == isDragActive;
  }

  @override
  int get hashCode => Object.hash(
        selectedRelayIds,
        isMultiSelectMode,
        draggedRelayId,
        dragTargetIndex,
        isDragActive,
      );
}

/// Configuration for multi-relay connection behavior
@immutable
class MultiRelayConnectionSettings {
  final int maxConcurrentConnections;
  final bool enableAutomaticFailover;
  final Duration failoverDelay;
  final bool enableLoadBalancing;
  final LoadBalancingStrategy loadBalancingStrategy;
  final bool enablePriorityRotation;
  final Duration priorityRotationInterval;
  final bool enableConnectionHealthMonitoring;
  final Duration healthCheckInterval;

  const MultiRelayConnectionSettings({
    this.maxConcurrentConnections = 5,
    this.enableAutomaticFailover = true,
    this.failoverDelay = const Duration(seconds: 5),
    this.enableLoadBalancing = false,
    this.loadBalancingStrategy = LoadBalancingStrategy.priority,
    this.enablePriorityRotation = false,
    this.priorityRotationInterval = const Duration(minutes: 30),
    this.enableConnectionHealthMonitoring = true,
    this.healthCheckInterval = const Duration(minutes: 2),
  });

  MultiRelayConnectionSettings copyWith({
    int? maxConcurrentConnections,
    bool? enableAutomaticFailover,
    Duration? failoverDelay,
    bool? enableLoadBalancing,
    LoadBalancingStrategy? loadBalancingStrategy,
    bool? enablePriorityRotation,
    Duration? priorityRotationInterval,
    bool? enableConnectionHealthMonitoring,
    Duration? healthCheckInterval,
  }) {
    return MultiRelayConnectionSettings(
      maxConcurrentConnections: maxConcurrentConnections ?? this.maxConcurrentConnections,
      enableAutomaticFailover: enableAutomaticFailover ?? this.enableAutomaticFailover,
      failoverDelay: failoverDelay ?? this.failoverDelay,
      enableLoadBalancing: enableLoadBalancing ?? this.enableLoadBalancing,
      loadBalancingStrategy: loadBalancingStrategy ?? this.loadBalancingStrategy,
      enablePriorityRotation: enablePriorityRotation ?? this.enablePriorityRotation,
      priorityRotationInterval: priorityRotationInterval ?? this.priorityRotationInterval,
      enableConnectionHealthMonitoring: enableConnectionHealthMonitoring ?? this.enableConnectionHealthMonitoring,
      healthCheckInterval: healthCheckInterval ?? this.healthCheckInterval,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'maxConcurrentConnections': maxConcurrentConnections,
      'enableAutomaticFailover': enableAutomaticFailover,
      'failoverDelay': failoverDelay.inMilliseconds,
      'enableLoadBalancing': enableLoadBalancing,
      'loadBalancingStrategy': loadBalancingStrategy.name,
      'enablePriorityRotation': enablePriorityRotation,
      'priorityRotationInterval': priorityRotationInterval.inMilliseconds,
      'enableConnectionHealthMonitoring': enableConnectionHealthMonitoring,
      'healthCheckInterval': healthCheckInterval.inMilliseconds,
    };
  }

  factory MultiRelayConnectionSettings.fromJson(Map<String, dynamic> json) {
    return MultiRelayConnectionSettings(
      maxConcurrentConnections: json['maxConcurrentConnections'] as int? ?? 5,
      enableAutomaticFailover: json['enableAutomaticFailover'] as bool? ?? true,
      failoverDelay: Duration(milliseconds: json['failoverDelay'] as int? ?? 5000),
      enableLoadBalancing: json['enableLoadBalancing'] as bool? ?? false,
      loadBalancingStrategy: LoadBalancingStrategy.values.firstWhere(
        (strategy) => strategy.name == json['loadBalancingStrategy'],
        orElse: () => LoadBalancingStrategy.priority,
      ),
      enablePriorityRotation: json['enablePriorityRotation'] as bool? ?? false,
      priorityRotationInterval: Duration(milliseconds: json['priorityRotationInterval'] as int? ?? 1800000),
      enableConnectionHealthMonitoring: json['enableConnectionHealthMonitoring'] as bool? ?? true,
      healthCheckInterval: Duration(milliseconds: json['healthCheckInterval'] as int? ?? 120000),
    );
  }
}

/// Load balancing strategies for multi-relay connections
enum LoadBalancingStrategy {
  priority,      // Use priority order
  roundRobin,    // Rotate through available relays
  latency,       // Prefer lowest latency
  health,        // Prefer highest health score
  random,        // Random selection
}

/// Drag and drop operation data
@immutable
class RelayDragData {
  final String relayId;
  final int currentIndex;
  final int currentPriority;
  final RelayConfig relayConfig;

  const RelayDragData({
    required this.relayId,
    required this.currentIndex,
    required this.currentPriority,
    required this.relayConfig,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayDragData && other.relayId == relayId;
  }

  @override
  int get hashCode => relayId.hashCode;
}