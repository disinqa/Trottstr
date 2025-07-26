import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/models/multi_relay_connection_models.dart';
import 'package:trottstr/providers/relay_providers.dart';
import 'package:trottstr/providers/multi_relay_providers.dart';
import 'package:trottstr/services/relay_management_service.dart';
import 'package:trottstr/widgets/relay/multi_relay_selection_panel.dart';
import 'package:trottstr/widgets/relay/relay_filter_widget.dart';

/// Enhanced relay management screen with multi-relay connection support
class RelayManagementScreen extends ConsumerStatefulWidget {
  const RelayManagementScreen({super.key});

  @override
  ConsumerState<RelayManagementScreen> createState() =>
      _RelayManagementScreenState();
}

class _RelayManagementScreenState extends ConsumerState<RelayManagementScreen>
    with TickerProviderStateMixin {
  late TabController _tabController;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, -1), end: Offset.zero).animate(
          CurvedAnimation(
            parent: _animationController,
            curve: Curves.elasticOut,
          ),
        );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final relayStats = ref.watch(relayStatisticsProvider);
    final multiRelayStats = ref.watch(multiRelayConnectionStatsProvider);
    final currentConnection = ref.watch(currentMultiRelayConnectionProvider);
    final selectionState = ref.watch(relaySelectionStateProvider);
    final healthWarnings = ref.watch(connectionHealthWarningsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relay Management'),
        elevation: 0,
        backgroundColor: Theme.of(context).colorScheme.surface,
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        actions: [
          IconButton(
            onPressed: () => _showRelayDiscovery(context),
            icon: const Icon(Icons.explore),
            tooltip: 'Discover Relays',
          ),
          IconButton(
            onPressed: () => _showImportExport(context),
            icon: const Icon(Icons.import_export),
            tooltip: 'Import/Export',
          ),
          PopupMenuButton<String>(
            onSelected: _handleMenuAction,
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'settings',
                child: ListTile(
                  leading: Icon(Icons.settings),
                  title: Text('Settings'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'templates',
                child: ListTile(
                  leading: Icon(Icons.library_books),
                  title: Text('Templates'),
                  dense: true,
                ),
              ),
              const PopupMenuItem(
                value: 'health_check',
                child: ListTile(
                  leading: Icon(Icons.health_and_safety),
                  title: Text('Health Check'),
                  dense: true,
                ),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Overview', icon: Icon(Icons.dashboard)),
            Tab(text: 'Single Relays', icon: Icon(Icons.wifi)),
            Tab(text: 'Multi-Relay', icon: Icon(Icons.hub)),
          ],
        ),
      ),
      body: Column(
        children: [
          // Health warnings banner
          if (healthWarnings.isNotEmpty)
            _buildHealthWarningsBanner(context, healthWarnings),

          // Connection status banner
          if (currentConnection != null)
            _buildConnectionStatusBanner(
              context,
              currentConnection,
              multiRelayStats,
            ),

          // Main content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(context, relayStats, multiRelayStats),
                _buildSingleRelaysTab(context),
                _buildMultiRelayTab(context),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: _buildFloatingActionButton(context, selectionState),
    );
  }

  Widget _buildHealthWarningsBanner(
    BuildContext context,
    List<String> warnings,
  ) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning, color: Colors.orange, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Connection Health Warnings',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Colors.orange,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ...warnings.map(
                (warning) => Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 28),
                      Icon(Icons.circle, size: 4, color: Colors.orange),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          warning,
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: Colors.orange.shade700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionStatusBanner(
    BuildContext context,
    MultiRelayConnection connection,
    MultiRelayConnectionStats stats,
  ) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.hub,
              color: Theme.of(context).colorScheme.onPrimary,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  connection.name,
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  '${stats.connected}/${stats.totalSelected} connected • ${(stats.overallHealth * 100).round()}% health',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          _buildConnectionHealthIndicator(context, stats.overallHealth),
        ],
      ),
    );
  }

  Widget _buildConnectionHealthIndicator(BuildContext context, double health) {
    final color = health >= 0.8
        ? Colors.green
        : health >= 0.6
        ? Colors.orange
        : Colors.red;

    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        shape: BoxShape.circle,
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Center(
        child: Text(
          '${(health * 100).round()}%',
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: color,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewTab(
    BuildContext context,
    RelayStatistics relayStats,
    MultiRelayConnectionStats multiRelayStats,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Overall statistics
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Relay Statistics',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildRelayStatsGrid(context, relayStats),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Multi-relay connection stats
          if (multiRelayStats.totalSelected > 0)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Relay Connection',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildMultiRelayStats(context, multiRelayStats),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),

          // Quick actions
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Quick Actions',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildQuickActions(context),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultiRelayStats(
    BuildContext context,
    MultiRelayConnectionStats stats,
  ) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '${stats.totalSelected}',
                'Selected',
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '${stats.connected}',
                'Connected',
                Icons.wifi,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '${(stats.overallHealth * 100).round()}%',
                'Health',
                Icons.health_and_safety,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '${stats.averageLatency.round()}ms',
                'Latency',
                Icons.speed,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String value,
    String label,
    IconData icon, [
    Color? color,
  ]) {
    final cardColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: cardColor.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: cardColor, size: 20),
          const SizedBox(height: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: cardColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: cardColor),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _tabController.animateTo(2),
                icon: const Icon(Icons.hub),
                label: const Text('Multi-Relay Setup'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showRelayDiscovery(context),
                icon: const Icon(Icons.explore),
                label: const Text('Discover Relays'),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _performHealthCheck(),
                icon: const Icon(Icons.health_and_safety),
                label: const Text('Health Check'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showImportExport(context),
                icon: const Icon(Icons.import_export),
                label: const Text('Import/Export'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSingleRelaysTab(BuildContext context) {
    final filteredRelays = ref.watch(filteredRelaysProvider);
    final selectedRelays = ref.watch(selectedRelaysProvider);

    return Column(
      children: [
        // Filter widget
        RelayFilterWidget(),

        // Relay list
        Expanded(
          child: filteredRelays.isEmpty
              ? _buildEmptyRelayState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(8),
                  itemCount: filteredRelays.length,
                  itemBuilder: (context, index) {
                    final relay = filteredRelays[index];
                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: _getRelayStatusColor(
                            relay.status,
                          ).withOpacity(0.1),
                          child: Icon(
                            _getRelayStatusIcon(relay.status),
                            color: _getRelayStatusColor(relay.status),
                          ),
                        ),
                        title: Text(relay.name),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(relay.url.replaceFirst('wss://', '')),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                _buildStatusChip(context, relay.status),
                                if (relay.latency != null) ...[
                                  const SizedBox(width: 8),
                                  _buildLatencyChip(context, relay.latency!),
                                ],
                              ],
                            ),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (action) =>
                              _handleRelayAction(action, relay),
                          itemBuilder: (context) => [
                            if (relay.status == RelayStatus.disconnected)
                              const PopupMenuItem(
                                value: 'connect',
                                child: ListTile(
                                  leading: Icon(Icons.wifi),
                                  title: Text('Connect'),
                                  dense: true,
                                ),
                              )
                            else if (relay.status == RelayStatus.connected)
                              const PopupMenuItem(
                                value: 'disconnect',
                                child: ListTile(
                                  leading: Icon(Icons.wifi_off),
                                  title: Text('Disconnect'),
                                  dense: true,
                                ),
                              ),
                            const PopupMenuItem(
                              value: 'test',
                              child: ListTile(
                                leading: Icon(Icons.speed),
                                title: Text('Test'),
                                dense: true,
                              ),
                            ),
                            const PopupMenuItem(
                              value: 'edit',
                              child: ListTile(
                                leading: Icon(Icons.edit),
                                title: Text('Edit'),
                                dense: true,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildMultiRelayTab(BuildContext context) {
    return const MultiRelaySelectionPanel();
  }

  Widget _buildEmptyRelayState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: Theme.of(
              context,
            ).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No relays found',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add some relays to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: () => _showAddRelayDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Relay'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(BuildContext context, RelayStatus status) {
    final color = _getRelayStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        status.name.toUpperCase(),
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _buildLatencyChip(BuildContext context, int latency) {
    final color = latency < 100
        ? Colors.green
        : latency < 300
        ? Colors.orange
        : Colors.red;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        '${latency}ms',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget? _buildFloatingActionButton(
    BuildContext context,
    RelaySelectionState selectionState,
  ) {
    if (selectionState.isMultiSelectMode) {
      return FloatingActionButton.extended(
        onPressed: () => _createMultiRelayConnection(context),
        icon: const Icon(Icons.hub),
        label: const Text('Create Connection'),
      );
    }

    return FloatingActionButton(
      onPressed: () => _showAddRelayDialog(context),
      child: const Icon(Icons.add),
    );
  }

  // Helper methods for styling
  Color _getRelayStatusColor(RelayStatus status) {
    switch (status) {
      case RelayStatus.connected:
        return Colors.green;
      case RelayStatus.connecting:
        return Colors.orange;
      case RelayStatus.disconnected:
        return Colors.grey;
      case RelayStatus.error:
        return Colors.red;
      case RelayStatus.testing:
        return Colors.blue;
    }
  }

  IconData _getRelayStatusIcon(RelayStatus status) {
    switch (status) {
      case RelayStatus.connected:
        return Icons.wifi;
      case RelayStatus.connecting:
        return Icons.wifi_find;
      case RelayStatus.disconnected:
        return Icons.wifi_off;
      case RelayStatus.error:
        return Icons.error;
      case RelayStatus.testing:
        return Icons.bolt;
    }
  }

  Widget _buildRelayStatsGrid(BuildContext context, RelayStatistics stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '${stats.totalRelays}',
                'Total',
                Icons.router,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '${stats.connectedRelays}',
                'Connected',
                Icons.wifi,
                Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '${stats.enabledRelays}',
                'Enabled',
                Icons.check_circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '${stats.errorRelays}',
                'Errors',
                Icons.error,
                Colors.red,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _buildStatCard(
                context,
                '${stats.averageLatency.round()}ms',
                'Avg Latency',
                Icons.speed,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildStatCard(
                context,
                '${(stats.averageHealth * 100).round()}%',
                'Avg Health',
                Icons.health_and_safety,
              ),
            ),
          ],
        ),
      ],
    );
  }

  // Action handlers
  void _handleMenuAction(String action) {
    switch (action) {
      case 'settings':
        _showSettings(context);
        break;
      case 'templates':
        _showTemplates(context);
        break;
      case 'health_check':
        _performHealthCheck();
        break;
    }
  }

  void _handleRelayAction(String action, RelayConfig relay) async {
    final relayService = ref.read(relayManagementServiceProvider);

    try {
      switch (action) {
        case 'connect':
        case 'disconnect':
        case 'test':
          await relayService.executeBatchOperation(
            action == 'connect'
                ? RelayBatchOperationType.connect
                : action == 'disconnect'
                ? RelayBatchOperationType.disconnect
                : RelayBatchOperationType.test,
            [relay.id],
          );
          break;
        case 'edit':
          _showEditRelayDialog(context, relay);
          break;
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Action failed: $e')));
      }
    }
  }

  // Dialog methods
  void _showAddRelayDialog(BuildContext context) {
    // Show add relay dialog
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Add Relay'),
        content: Text('Add relay dialog will be implemented here'),
      ),
    );
  }

  void _showEditRelayDialog(BuildContext context, RelayConfig relay) {
    // Show edit relay dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Edit ${relay.name}'),
        content: const Text('Edit relay dialog will be implemented here'),
      ),
    );
  }

  void _showRelayDiscovery(BuildContext context) {
    // Show relay discovery dialog
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Discover Relays'),
        content: Text('Relay discovery will be implemented here'),
      ),
    );
  }

  void _showImportExport(BuildContext context) {
    // Show import/export dialog
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Import/Export'),
        content: Text('Import/Export functionality will be implemented here'),
      ),
    );
  }

  void _showSettings(BuildContext context) {
    // Show settings dialog
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Relay Settings'),
        content: Text('Relay settings will be implemented here'),
      ),
    );
  }

  void _showTemplates(BuildContext context) {
    // Show templates dialog
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Relay Templates'),
        content: Text('Relay templates will be implemented here'),
      ),
    );
  }

  void _createMultiRelayConnection(BuildContext context) {
    _tabController.animateTo(2);
  }

  void _performHealthCheck() async {
    final relayService = ref.read(relayManagementServiceProvider);
    final relays = ref.read(relayConfigurationsProvider).value;

    if (relays == null || relays.isEmpty) return;

    try {
      await relayService.executeBatchOperation(
        RelayBatchOperationType.test,
        relays.keys.toList(),
      );

      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Health check completed')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Health check failed: $e')));
      }
    }
  }
}
