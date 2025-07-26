import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/multi_relay_connection_models.dart';
import 'package:trottstr/providers/multi_relay_providers.dart';
import 'package:trottstr/widgets/relay/multi_relay_tile_widget.dart';
import 'package:trottstr/widgets/relay/draggable_relay_list_widget.dart';

/// Comprehensive panel for multi-relay selection and management
class MultiRelaySelectionPanel extends ConsumerStatefulWidget {
  final VoidCallback? onConnectionCreated;
  final Function(String, String)? onRelayMenuAction;

  const MultiRelaySelectionPanel({
    super.key,
    this.onConnectionCreated,
    this.onRelayMenuAction,
  });

  @override
  ConsumerState<MultiRelaySelectionPanel> createState() => _MultiRelaySelectionPanelState();
}

class _MultiRelaySelectionPanelState extends ConsumerState<MultiRelaySelectionPanel>
    with TickerProviderStateMixin {
  late TabController _tabController;
  final TextEditingController _connectionNameController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _connectionNameController.text = 'Multi-Relay Connection ${DateTime.now().millisecondsSinceEpoch}';
  }

  @override
  void dispose() {
    _tabController.dispose();
    _connectionNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final selectionState = ref.watch(relaySelectionStateProvider);
    final selectedRelays = ref.watch(selectedConnectedRelaysProvider);
    final availableRelays = ref.watch(availableRelayTilesProvider);
    final currentConnection = ref.watch(currentMultiRelayConnectionProvider);
    final multiRelayManager = ref.watch(multiRelayManagerProvider);
    final stats = ref.watch(multiRelayConnectionStatsProvider);

    return Card(
      margin: const EdgeInsets.all(16),
      elevation: 8,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildHeader(context, selectionState, multiRelayManager, stats),
          if (currentConnection != null) 
            _buildConnectionInfo(context, currentConnection, stats),
          _buildTabBar(context),
          _buildTabContent(context, selectedRelays, availableRelays, multiRelayManager),
          if (selectionState.selectedRelayIds.isNotEmpty || currentConnection != null)
            _buildActionButtons(context, selectionState, multiRelayManager, currentConnection),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    RelaySelectionState selectionState,
    MultiRelayManager multiRelayManager,
    MultiRelayConnectionStats stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.hub,
                color: Theme.of(context).colorScheme.primary,
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Multi-Relay Connection',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    Text(
                      'Select and prioritize multiple relays for redundant connections',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              if (selectionState.isMultiSelectMode)
                _buildSelectionActions(context, multiRelayManager),
            ],
          ),
          if (stats.totalSelected > 0) ...[
            const SizedBox(height: 12),
            _buildStatsRow(context, stats),
          ],
        ],
      ),
    );
  }

  Widget _buildSelectionActions(BuildContext context, MultiRelayManager multiRelayManager) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextButton.icon(
          onPressed: multiRelayManager.selectAllRelays,
          icon: const Icon(Icons.select_all),
          label: const Text('All'),
        ),
        TextButton.icon(
          onPressed: multiRelayManager.clearSelection,
          icon: const Icon(Icons.clear),
          label: const Text('Clear'),
        ),
        IconButton(
          onPressed: multiRelayManager.exitMultiSelectMode,
          icon: const Icon(Icons.close),
          tooltip: 'Exit selection mode',
        ),
      ],
    );
  }

  Widget _buildStatsRow(BuildContext context, MultiRelayConnectionStats stats) {
    return Row(
      children: [
        _buildStatChip(context, '${stats.totalSelected}', 'Selected', Icons.radio_button_checked),
        const SizedBox(width: 8),
        _buildStatChip(context, '${stats.connected}', 'Connected', Icons.wifi, Colors.green),
        const SizedBox(width: 8),
        _buildStatChip(context, '${stats.errors}', 'Errors', Icons.error, Colors.red),
        const SizedBox(width: 8),
        _buildStatChip(context, '${(stats.overallHealth * 100).round()}%', 'Health', Icons.health_and_safety),
      ],
    );
  }

  Widget _buildStatChip(BuildContext context, String value, String label, IconData icon, [Color? color]) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: chipColor.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: chipColor),
          const SizedBox(width: 4),
          Text(
            value,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 2),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: chipColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionInfo(
    BuildContext context,
    MultiRelayConnection connection,
    MultiRelayConnectionStats stats,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  connection.name,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: connection.isActive ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  connection.isActive ? 'ACTIVE' : 'INACTIVE',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: connection.isActive ? Colors.green : Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Created ${_formatDateTime(connection.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(BuildContext context) {
    return TabBar(
      controller: _tabController,
      tabs: const [
        Tab(text: 'Selected Relays', icon: Icon(Icons.check_circle)),
        Tab(text: 'Available Relays', icon: Icon(Icons.radio_button_unchecked)),
      ],
    );
  }

  Widget _buildTabContent(
    BuildContext context,
    List<ConnectedRelay> selectedRelays,
    List<ConnectedRelay> availableRelays,
    MultiRelayManager multiRelayManager,
  ) {
    return SizedBox(
      height: 400,
      child: TabBarView(
        controller: _tabController,
        children: [
          _buildSelectedRelaysTab(context, selectedRelays),
          _buildAvailableRelaysTab(context, availableRelays, multiRelayManager),
        ],
      ),
    );
  }

  Widget _buildSelectedRelaysTab(BuildContext context, List<ConnectedRelay> selectedRelays) {
    if (selectedRelays.isEmpty) {
      return _buildEmptySelectedState(context);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.drag_indicator,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Drag to reorder priority (higher = more priority)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: DraggableRelayListWidget(
            relays: selectedRelays,
            isDragEnabled: true,
            onMenuAction: widget.onRelayMenuAction,
            onOrderChanged: () {
              // Handle priority changes
            },
          ),
        ),
      ],
    );
  }

  Widget _buildAvailableRelaysTab(
    BuildContext context,
    List<ConnectedRelay> availableRelays,
    MultiRelayManager multiRelayManager,
  ) {
    if (availableRelays.isEmpty) {
      return _buildEmptyAvailableState(context);
    }

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(
                Icons.touch_app,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Tap to select relays, long press to enter multi-select mode',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            itemCount: availableRelays.length,
            itemBuilder: (context, index) {
              final relay = availableRelays[index];
              return MultiRelayTileWidget(
                connectedRelay: relay,
                isInConnection: false,
                isSelectable: true,
                onMenuAction: (action) => widget.onRelayMenuAction?.call(relay.relayId, action),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptySelectedState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No relays selected',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Switch to the Available Relays tab to select relays',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAvailableState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.wifi_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            'No available relays',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'All configured relays are already selected',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.7),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    RelaySelectionState selectionState,
    MultiRelayManager multiRelayManager,
    MultiRelayConnection? currentConnection,
  ) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
      ),
      child: Column(
        children: [
          if (currentConnection == null && selectionState.selectedRelayIds.isNotEmpty) ...[
            TextField(
              controller: _connectionNameController,
              decoration: const InputDecoration(
                labelText: 'Connection Name',
                hintText: 'Enter a name for this multi-relay connection',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              if (currentConnection != null) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => multiRelayManager.connectToSelectedRelays(),
                    icon: const Icon(Icons.play_arrow),
                    label: const Text('Connect All'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _showConnectionSettings(context),
                    icon: const Icon(Icons.settings),
                    label: const Text('Settings'),
                  ),
                ),
              ] else if (selectionState.selectedRelayIds.isNotEmpty) ...[
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => _createConnection(multiRelayManager),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Connection'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: multiRelayManager.clearSelection,
                    icon: const Icon(Icons.clear),
                    label: const Text('Clear Selection'),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  void _createConnection(MultiRelayManager multiRelayManager) async {
    if (_connectionNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a connection name')),
      );
      return;
    }

    await multiRelayManager.createMultiRelayConnection(_connectionNameController.text.trim());
    widget.onConnectionCreated?.call();
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Multi-relay connection created successfully')),
      );
    }
  }

  void _showConnectionSettings(BuildContext context) {
    // Show connection settings dialog
    showDialog(
      context: context,
      builder: (context) => const AlertDialog(
        title: Text('Connection Settings'),
        content: Text('Connection settings will be implemented here'),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} at ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}