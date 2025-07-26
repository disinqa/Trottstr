import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/services/relay_management_service.dart';

/// Provider for relay configurations
final relayConfigurationsProvider = StreamProvider<Map<String, RelayConfig>>((ref) {
  final service = ref.watch(relayManagementServiceProvider);
  return service.relaysStream;
});

/// Provider for relay management settings
final relaySettingsProvider = StreamProvider<RelayManagementSettings>((ref) {
  final service = ref.watch(relayManagementServiceProvider);
  return service.settingsStream;
});

/// Provider for relay templates
final relayTemplatesProvider = StreamProvider<Map<String, RelayTemplate>>((ref) {
  final service = ref.watch(relayManagementServiceProvider);
  return service.templatesStream;
});

/// Provider for relay batch operations
final relayBatchOperationsProvider = StreamProvider<Map<String, RelayBatchOperation>>((ref) {
  final service = ref.watch(relayManagementServiceProvider);
  return service.operationsStream;
});

/// Provider for connected relays only
final connectedRelaysProvider = Provider<List<RelayConfig>>((ref) {
  final relaysAsync = ref.watch(relayConfigurationsProvider);
  return relaysAsync.when(
    data: (relays) => relays.values
        .where((relay) => relay.status == RelayStatus.connected)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for enabled relays sorted by priority
final enabledRelaysByPriorityProvider = Provider<List<RelayConfig>>((ref) {
  final relaysAsync = ref.watch(relayConfigurationsProvider);
  return relaysAsync.when(
    data: (relays) => relays.values
        .where((relay) => relay.isEnabled)
        .toList()
      ..sort((a, b) => b.priority.compareTo(a.priority)),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for disabled relays
final disabledRelaysProvider = Provider<List<RelayConfig>>((ref) {
  final relaysAsync = ref.watch(relayConfigurationsProvider);
  return relaysAsync.when(
    data: (relays) => relays.values
        .where((relay) => !relay.isEnabled)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for relays with errors
final errorRelaysProvider = Provider<List<RelayConfig>>((ref) {
  final relaysAsync = ref.watch(relayConfigurationsProvider);
  return relaysAsync.when(
    data: (relays) => relays.values
        .where((relay) => relay.status == RelayStatus.error)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for relay statistics
final relayStatisticsProvider = Provider<RelayStatistics>((ref) {
  final relaysAsync = ref.watch(relayConfigurationsProvider);
  return relaysAsync.when(
    data: (relays) {
      final relayList = relays.values.toList();
      final totalRelays = relayList.length;
      final connectedRelays = relayList.where((r) => r.status == RelayStatus.connected).length;
      final enabledRelays = relayList.where((r) => r.isEnabled).length;
      final errorRelays = relayList.where((r) => r.status == RelayStatus.error).length;
      
      final latencies = relayList
          .where((r) => r.latency != null)
          .map((r) => r.latency!)
          .toList();
      
      final averageLatency = latencies.isNotEmpty
          ? latencies.reduce((a, b) => a + b) / latencies.length
          : 0.0;
      
      final healthScores = relayList.map((r) => r.healthScore).toList();
      final averageHealth = healthScores.isNotEmpty
          ? healthScores.reduce((a, b) => a + b) / healthScores.length
          : 0.0;

      return RelayStatistics(
        totalRelays: totalRelays,
        connectedRelays: connectedRelays,
        enabledRelays: enabledRelays,
        errorRelays: errorRelays,
        averageLatency: averageLatency,
        averageHealth: averageHealth,
      );
    },
    loading: () => const RelayStatistics(
      totalRelays: 0,
      connectedRelays: 0,
      enabledRelays: 0,
      errorRelays: 0,
      averageLatency: 0.0,
      averageHealth: 0.0,
    ),
    error: (_, __) => const RelayStatistics(
      totalRelays: 0,
      connectedRelays: 0,
      enabledRelays: 0,
      errorRelays: 0,
      averageLatency: 0.0,
      averageHealth: 0.0,
    ),
  );
});

/// Provider for built-in templates
final builtInTemplatesProvider = Provider<List<RelayTemplate>>((ref) {
  final templatesAsync = ref.watch(relayTemplatesProvider);
  return templatesAsync.when(
    data: (templates) => templates.values
        .where((template) => template.isBuiltIn)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for custom templates
final customTemplatesProvider = Provider<List<RelayTemplate>>((ref) {
  final templatesAsync = ref.watch(relayTemplatesProvider);
  return templatesAsync.when(
    data: (templates) => templates.values
        .where((template) => !template.isBuiltIn)
        .toList(),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for active batch operations
final activeBatchOperationsProvider = Provider<List<RelayBatchOperation>>((ref) {
  final operationsAsync = ref.watch(relayBatchOperationsProvider);
  return operationsAsync.when(
    data: (operations) => operations.values
        .where((op) => op.status == RelayBatchOperationStatus.running)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for completed batch operations
final completedBatchOperationsProvider = Provider<List<RelayBatchOperation>>((ref) {
  final operationsAsync = ref.watch(relayBatchOperationsProvider);
  return operationsAsync.when(
    data: (operations) => operations.values
        .where((op) => op.status == RelayBatchOperationStatus.completed)
        .toList()
      ..sort((a, b) => b.completedAt?.compareTo(a.completedAt ?? DateTime.now()) ?? 0),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for failed batch operations
final failedBatchOperationsProvider = Provider<List<RelayBatchOperation>>((ref) {
  final operationsAsync = ref.watch(relayBatchOperationsProvider);
  return operationsAsync.when(
    data: (operations) => operations.values
        .where((op) => op.status == RelayBatchOperationStatus.failed)
        .toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt)),
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Provider for relay health monitoring status
final relayHealthMonitoringProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(relaySettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.enableHealthMonitoring,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for relay auto-discovery status
final relayAutoDiscoveryProvider = Provider<bool>((ref) {
  final settingsAsync = ref.watch(relaySettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.enableAutoDiscovery,
    loading: () => false,
    error: (_, __) => false,
  );
});

/// Provider for relay connection timeout
final relayConnectionTimeoutProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(relaySettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.connectionTimeout,
    loading: () => 30,
    error: (_, __) => 30,
  );
});

/// Provider for max concurrent connections
final maxConcurrentConnectionsProvider = Provider<int>((ref) {
  final settingsAsync = ref.watch(relaySettingsProvider);
  return settingsAsync.when(
    data: (settings) => settings.maxConcurrentConnections,
    loading: () => 10,
    error: (_, __) => 10,
  );
});

/// Provider for relay discovery results (family provider for different criteria)
final relayDiscoveryProvider = FutureProvider.family<List<RelayDiscoveryResult>, RelayDiscoveryParams>((ref, params) async {
  final service = ref.watch(relayManagementServiceProvider);
  return service.discoverRelays(
    destinations: params.destinations,
    maxResults: params.maxResults,
  );
});

/// Provider for relay by ID
final relayByIdProvider = Provider.family<RelayConfig?, String>((ref, relayId) {
  final relaysAsync = ref.watch(relayConfigurationsProvider);
  return relaysAsync.when(
    data: (relays) => relays[relayId],
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for template by ID
final templateByIdProvider = Provider.family<RelayTemplate?, String>((ref, templateId) {
  final templatesAsync = ref.watch(relayTemplatesProvider);
  return templatesAsync.when(
    data: (templates) => templates[templateId],
    loading: () => null,
    error: (_, __) => null,
  );
});

/// Provider for batch operation by ID
final batchOperationByIdProvider = Provider.family<RelayBatchOperation?, String>((ref, operationId) {
  final operationsAsync = ref.watch(relayBatchOperationsProvider);
  return operationsAsync.when(
    data: (operations) => operations[operationId],
    loading: () => null,
    error: (_, __) => null,
  );
});

/// State provider for selected relays (for batch operations)
final selectedRelaysProvider = StateProvider<Set<String>>((ref) => {});

/// State provider for relay filter criteria
final relayFilterProvider = StateProvider<RelayFilter>((ref) => const RelayFilter());

/// Filtered relays provider based on current filter
final filteredRelaysProvider = Provider<List<RelayConfig>>((ref) {
  final relaysAsync = ref.watch(relayConfigurationsProvider);
  final filter = ref.watch(relayFilterProvider);
  
  return relaysAsync.when(
    data: (relays) {
      var filteredRelays = relays.values.toList();
      
      // Apply status filter
      if (filter.status != null) {
        filteredRelays = filteredRelays.where((relay) => relay.status == filter.status).toList();
      }
      
      // Apply enabled filter
      if (filter.enabledOnly != null) {
        filteredRelays = filteredRelays.where((relay) => relay.isEnabled == filter.enabledOnly).toList();
      }
      
      // Apply search query
      if (filter.searchQuery != null && filter.searchQuery!.isNotEmpty) {
        final query = filter.searchQuery!.toLowerCase();
        filteredRelays = filteredRelays.where((relay) =>
            relay.name.toLowerCase().contains(query) ||
            relay.url.toLowerCase().contains(query) ||
            relay.description.toLowerCase().contains(query)
        ).toList();
      }
      
      // Apply sorting
      switch (filter.sortBy) {
        case RelaySortBy.name:
          filteredRelays.sort((a, b) => a.name.compareTo(b.name));
          break;
        case RelaySortBy.priority:
          filteredRelays.sort((a, b) => b.priority.compareTo(a.priority));
          break;
        case RelaySortBy.latency:
          filteredRelays.sort((a, b) {
            final aLatency = a.latency ?? 9999;
            final bLatency = b.latency ?? 9999;
            return aLatency.compareTo(bLatency);
          });
          break;
        case RelaySortBy.health:
          filteredRelays.sort((a, b) => b.healthScore.compareTo(a.healthScore));
          break;
        case RelaySortBy.status:
          filteredRelays.sort((a, b) => a.status.index.compareTo(b.status.index));
          break;
        case RelaySortBy.lastConnected:
          filteredRelays.sort((a, b) {
            final aTime = a.lastConnected ?? DateTime(1970);
            final bTime = b.lastConnected ?? DateTime(1970);
            return bTime.compareTo(aTime);
          });
          break;
      }
      
      if (filter.sortDescending) {
        filteredRelays = filteredRelays.reversed.toList();
      }
      
      return filteredRelays;
    },
    loading: () => [],
    error: (_, __) => [],
  );
});

/// Statistics model for relay overview
class RelayStatistics {
  final int totalRelays;
  final int connectedRelays;
  final int enabledRelays;
  final int errorRelays;
  final double averageLatency;
  final double averageHealth;

  const RelayStatistics({
    required this.totalRelays,
    required this.connectedRelays,
    required this.enabledRelays,
    required this.errorRelays,
    required this.averageLatency,
    required this.averageHealth,
  });

  double get connectionRate => totalRelays > 0 ? connectedRelays / totalRelays : 0.0;
  double get errorRate => totalRelays > 0 ? errorRelays / totalRelays : 0.0;
  double get enabledRate => totalRelays > 0 ? enabledRelays / totalRelays : 0.0;
}

/// Parameters for relay discovery
class RelayDiscoveryParams {
  final List<String>? destinations;
  final int maxResults;

  const RelayDiscoveryParams({
    this.destinations,
    this.maxResults = 20,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RelayDiscoveryParams &&
        other.destinations == destinations &&
        other.maxResults == maxResults;
  }

  @override
  int get hashCode => Object.hash(destinations, maxResults);
}

/// Filter criteria for relays
class RelayFilter {
  final RelayStatus? status;
  final bool? enabledOnly;
  final String? searchQuery;
  final RelaySortBy sortBy;
  final bool sortDescending;

  const RelayFilter({
    this.status,
    this.enabledOnly,
    this.searchQuery,
    this.sortBy = RelaySortBy.priority,
    this.sortDescending = false,
  });

  RelayFilter copyWith({
    RelayStatus? status,
    bool? enabledOnly,
    String? searchQuery,
    RelaySortBy? sortBy,
    bool? sortDescending,
  }) {
    return RelayFilter(
      status: status ?? this.status,
      enabledOnly: enabledOnly ?? this.enabledOnly,
      searchQuery: searchQuery ?? this.searchQuery,
      sortBy: sortBy ?? this.sortBy,
      sortDescending: sortDescending ?? this.sortDescending,
    );
  }
}

/// Sorting options for relays
enum RelaySortBy {
  name,
  priority,
  latency,
  health,
  status,
  lastConnected,
}