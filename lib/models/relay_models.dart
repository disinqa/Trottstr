import 'package:flutter/foundation.dart';

/// Represents a relay server with all its configuration and status information
@immutable
class RelayConfig {
  final String id;
  final String url;
  final String name;
  final String description;
  final bool isEnabled;
  final int priority;
  final RelayStatus status;
  final int? latency;
  final DateTime? lastConnected;
  final DateTime? lastTested;
  final Map<String, dynamic> metadata;
  final RelayTemplate? template;

  const RelayConfig({
    required this.id,
    required this.url,
    required this.name,
    required this.description,
    this.isEnabled = true,
    this.priority = 0,
    this.status = RelayStatus.disconnected,
    this.latency,
    this.lastConnected,
    this.lastTested,
    this.metadata = const {},
    this.template,
  });

  RelayConfig copyWith({
    String? id,
    String? url,
    String? name,
    String? description,
    bool? isEnabled,
    int? priority,
    RelayStatus? status,
    int? latency,
    DateTime? lastConnected,
    DateTime? lastTested,
    Map<String, dynamic>? metadata,
    RelayTemplate? template,
  }) {
    return RelayConfig(
      id: id ?? this.id,
      url: url ?? this.url,
      name: name ?? this.name,
      description: description ?? this.description,
      isEnabled: isEnabled ?? this.isEnabled,
      priority: priority ?? this.priority,
      status: status ?? this.status,
      latency: latency ?? this.latency,
      lastConnected: lastConnected ?? this.lastConnected,
      lastTested: lastTested ?? this.lastTested,
      metadata: metadata ?? this.metadata,
      template: template ?? this.template,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'url': url,
      'name': name,
      'description': description,
      'isEnabled': isEnabled,
      'priority': priority,
      'status': status.name,
      'latency': latency,
      'lastConnected': lastConnected?.toIso8601String(),
      'lastTested': lastTested?.toIso8601String(),
      'metadata': metadata,
      'template': template?.toJson(),
    };
  }

  factory RelayConfig.fromJson(Map<String, dynamic> json) {
    return RelayConfig(
      id: json['id'] as String,
      url: json['url'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      isEnabled: json['isEnabled'] as bool? ?? true,
      priority: json['priority'] as int? ?? 0,
      status: RelayStatus.values.firstWhere(
        (status) => status.name == json['status'],
        orElse: () => RelayStatus.disconnected,
      ),
      latency: json['latency'] as int?,
      lastConnected: json['lastConnected'] != null
          ? DateTime.parse(json['lastConnected'] as String)
          : null,
      lastTested: json['lastTested'] != null
          ? DateTime.parse(json['lastTested'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      template: json['template'] != null
          ? RelayTemplate.fromJson(json['template'] as Map<String, dynamic>)
          : null,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayConfig && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  /// Gets the health score based on status, latency, and reliability
  double get healthScore {
    double score = 0.0;
    
    // Base score from status
    switch (status) {
      case RelayStatus.connected:
        score += 0.5;
        break;
      case RelayStatus.connecting:
        score += 0.2;
        break;
      case RelayStatus.disconnected:
        score += 0.0;
        break;
      case RelayStatus.error:
        score -= 0.2;
        break;
      case RelayStatus.testing:
        score += 0.1;
        break;
    }
    
    // Latency score (better latency = higher score)
    if (latency != null) {
      if (latency! < 50) {
        score += 0.3;
      } else if (latency! < 100) {
        score += 0.2;
      } else if (latency! < 200) {
        score += 0.1;
      }
    }
    
    // Reliability score based on recent connections
    if (lastConnected != null) {
      final daysSinceConnected = DateTime.now().difference(lastConnected!).inDays;
      if (daysSinceConnected < 1) {
        score += 0.2;
      } else if (daysSinceConnected < 7) {
        score += 0.1;
      }
    }
    
    return score.clamp(0.0, 1.0);
  }

  /// Gets the display color based on health and status
  String get statusColorHex {
    switch (status) {
      case RelayStatus.connected:
        return '#4CAF50'; // Green
      case RelayStatus.connecting:
        return '#FF9800'; // Orange
      case RelayStatus.disconnected:
        return '#9E9E9E'; // Grey
      case RelayStatus.error:
        return '#F44336'; // Red
      case RelayStatus.testing:
        return '#2196F3'; // Blue
    }
  }
}

/// Represents the connection status of a relay
enum RelayStatus {
  disconnected,
  connecting,
  connected,
  error,
  testing,
}

/// Represents a relay template for quick setup
@immutable
class RelayTemplate {
  final String id;
  final String name;
  final String description;
  final List<RelayConfig> relays;
  final Map<String, dynamic> settings;
  final bool isBuiltIn;
  final DateTime? createdAt;
  final String? createdBy;

  const RelayTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.relays,
    this.settings = const {},
    this.isBuiltIn = false,
    this.createdAt,
    this.createdBy,
  });

  RelayTemplate copyWith({
    String? id,
    String? name,
    String? description,
    List<RelayConfig>? relays,
    Map<String, dynamic>? settings,
    bool? isBuiltIn,
    DateTime? createdAt,
    String? createdBy,
  }) {
    return RelayTemplate(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      relays: relays ?? this.relays,
      settings: settings ?? this.settings,
      isBuiltIn: isBuiltIn ?? this.isBuiltIn,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'relays': relays.map((relay) => relay.toJson()).toList(),
      'settings': settings,
      'isBuiltIn': isBuiltIn,
      'createdAt': createdAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  factory RelayTemplate.fromJson(Map<String, dynamic> json) {
    return RelayTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      relays: (json['relays'] as List<dynamic>)
          .map((relayJson) => RelayConfig.fromJson(relayJson as Map<String, dynamic>))
          .toList(),
      settings: json['settings'] as Map<String, dynamic>? ?? {},
      isBuiltIn: json['isBuiltIn'] as bool? ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : null,
      createdBy: json['createdBy'] as String?,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayTemplate && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Represents a batch operation on multiple relays
@immutable
class RelayBatchOperation {
  final String id;
  final RelayBatchOperationType type;
  final List<String> relayIds;
  final Map<String, dynamic> parameters;
  final RelayBatchOperationStatus status;
  final DateTime createdAt;
  final DateTime? completedAt;
  final String? errorMessage;
  final Map<String, dynamic> results;

  const RelayBatchOperation({
    required this.id,
    required this.type,
    required this.relayIds,
    this.parameters = const {},
    this.status = RelayBatchOperationStatus.pending,
    required this.createdAt,
    this.completedAt,
    this.errorMessage,
    this.results = const {},
  });

  RelayBatchOperation copyWith({
    String? id,
    RelayBatchOperationType? type,
    List<String>? relayIds,
    Map<String, dynamic>? parameters,
    RelayBatchOperationStatus? status,
    DateTime? createdAt,
    DateTime? completedAt,
    String? errorMessage,
    Map<String, dynamic>? results,
  }) {
    return RelayBatchOperation(
      id: id ?? this.id,
      type: type ?? this.type,
      relayIds: relayIds ?? this.relayIds,
      parameters: parameters ?? this.parameters,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
      errorMessage: errorMessage ?? this.errorMessage,
      results: results ?? this.results,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.name,
      'relayIds': relayIds,
      'parameters': parameters,
      'status': status.name,
      'createdAt': createdAt.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'errorMessage': errorMessage,
      'results': results,
    };
  }

  factory RelayBatchOperation.fromJson(Map<String, dynamic> json) {
    return RelayBatchOperation(
      id: json['id'] as String,
      type: RelayBatchOperationType.values.firstWhere(
        (type) => type.name == json['type'],
      ),
      relayIds: (json['relayIds'] as List<dynamic>).cast<String>(),
      parameters: json['parameters'] as Map<String, dynamic>? ?? {},
      status: RelayBatchOperationStatus.values.firstWhere(
        (status) => status.name == json['status'],
      ),
      createdAt: DateTime.parse(json['createdAt'] as String),
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'] as String)
          : null,
      errorMessage: json['errorMessage'] as String?,
      results: json['results'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayBatchOperation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Types of batch operations that can be performed on relays
enum RelayBatchOperationType {
  connect,
  disconnect,
  test,
  enable,
  disable,
  delete,
  updatePriority,
  updateSettings,
}

/// Status of a batch operation
enum RelayBatchOperationStatus {
  pending,
  running,
  completed,
  failed,
  cancelled,
}

/// Represents relay discovery results
@immutable
class RelayDiscoveryResult {
  final String url;
  final String? name;
  final String? description;
  final int? latency;
  final bool isReachable;
  final DateTime discoveredAt;
  final Map<String, dynamic> metadata;
  final double score;

  const RelayDiscoveryResult({
    required this.url,
    this.name,
    this.description,
    this.latency,
    required this.isReachable,
    required this.discoveredAt,
    this.metadata = const {},
    required this.score,
  });

  RelayDiscoveryResult copyWith({
    String? url,
    String? name,
    String? description,
    int? latency,
    bool? isReachable,
    DateTime? discoveredAt,
    Map<String, dynamic>? metadata,
    double? score,
  }) {
    return RelayDiscoveryResult(
      url: url ?? this.url,
      name: name ?? this.name,
      description: description ?? this.description,
      latency: latency ?? this.latency,
      isReachable: isReachable ?? this.isReachable,
      discoveredAt: discoveredAt ?? this.discoveredAt,
      metadata: metadata ?? this.metadata,
      score: score ?? this.score,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'url': url,
      'name': name,
      'description': description,
      'latency': latency,
      'isReachable': isReachable,
      'discoveredAt': discoveredAt.toIso8601String(),
      'metadata': metadata,
      'score': score,
    };
  }

  factory RelayDiscoveryResult.fromJson(Map<String, dynamic> json) {
    return RelayDiscoveryResult(
      url: json['url'] as String,
      name: json['name'] as String?,
      description: json['description'] as String?,
      latency: json['latency'] as int?,
      isReachable: json['isReachable'] as bool,
      discoveredAt: DateTime.parse(json['discoveredAt'] as String),
      metadata: json['metadata'] as Map<String, dynamic>? ?? {},
      score: (json['score'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayDiscoveryResult && other.url == url;
  }

  @override
  int get hashCode => url.hashCode;
}

/// Represents relay management settings
@immutable
class RelayManagementSettings {
  final bool autoReconnect;
  final int connectionTimeout;
  final int maxConcurrentConnections;
  final bool enableHealthMonitoring;
  final Duration healthCheckInterval;
  final bool enableAutoDiscovery;
  final List<String> discoveryUrls;
  final Map<String, dynamic> customSettings;

  const RelayManagementSettings({
    this.autoReconnect = true,
    this.connectionTimeout = 30,
    this.maxConcurrentConnections = 10,
    this.enableHealthMonitoring = true,
    this.healthCheckInterval = const Duration(minutes: 5),
    this.enableAutoDiscovery = false,
    this.discoveryUrls = const [],
    this.customSettings = const {},
  });

  RelayManagementSettings copyWith({
    bool? autoReconnect,
    int? connectionTimeout,
    int? maxConcurrentConnections,
    bool? enableHealthMonitoring,
    Duration? healthCheckInterval,
    bool? enableAutoDiscovery,
    List<String>? discoveryUrls,
    Map<String, dynamic>? customSettings,
  }) {
    return RelayManagementSettings(
      autoReconnect: autoReconnect ?? this.autoReconnect,
      connectionTimeout: connectionTimeout ?? this.connectionTimeout,
      maxConcurrentConnections: maxConcurrentConnections ?? this.maxConcurrentConnections,
      enableHealthMonitoring: enableHealthMonitoring ?? this.enableHealthMonitoring,
      healthCheckInterval: healthCheckInterval ?? this.healthCheckInterval,
      enableAutoDiscovery: enableAutoDiscovery ?? this.enableAutoDiscovery,
      discoveryUrls: discoveryUrls ?? this.discoveryUrls,
      customSettings: customSettings ?? this.customSettings,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'autoReconnect': autoReconnect,
      'connectionTimeout': connectionTimeout,
      'maxConcurrentConnections': maxConcurrentConnections,
      'enableHealthMonitoring': enableHealthMonitoring,
      'healthCheckInterval': healthCheckInterval.inMilliseconds,
      'enableAutoDiscovery': enableAutoDiscovery,
      'discoveryUrls': discoveryUrls,
      'customSettings': customSettings,
    };
  }

  factory RelayManagementSettings.fromJson(Map<String, dynamic> json) {
    return RelayManagementSettings(
      autoReconnect: json['autoReconnect'] as bool? ?? true,
      connectionTimeout: json['connectionTimeout'] as int? ?? 30,
      maxConcurrentConnections: json['maxConcurrentConnections'] as int? ?? 10,
      enableHealthMonitoring: json['enableHealthMonitoring'] as bool? ?? true,
      healthCheckInterval: Duration(
        milliseconds: json['healthCheckInterval'] as int? ?? 300000,
      ),
      enableAutoDiscovery: json['enableAutoDiscovery'] as bool? ?? false,
      discoveryUrls: (json['discoveryUrls'] as List<dynamic>?)?.cast<String>() ?? [],
      customSettings: json['customSettings'] as Map<String, dynamic>? ?? {},
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayManagementSettings &&
        other.autoReconnect == autoReconnect &&
        other.connectionTimeout == connectionTimeout &&
        other.maxConcurrentConnections == maxConcurrentConnections &&
        other.enableHealthMonitoring == enableHealthMonitoring &&
        other.healthCheckInterval == healthCheckInterval &&
        other.enableAutoDiscovery == enableAutoDiscovery;
  }

  @override
  int get hashCode => Object.hash(
        autoReconnect,
        connectionTimeout,
        maxConcurrentConnections,
        enableHealthMonitoring,
        healthCheckInterval,
        enableAutoDiscovery,
      );
}