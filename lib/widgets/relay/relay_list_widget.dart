import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/providers/relay_providers.dart';
import 'package:trottstr/services/relay_management_service.dart';
import 'package:trottstr/widgets/relay/relay_card_widget.dart';

/// Widget that displays a list of relays with drag-and-drop reordering
class RelayListWidget extends HookConsumerWidget {
  const RelayListWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filteredRelaysAsync = ref.watch(filteredRelaysProvider);
    final selectedRelays = ref.watch(selectedRelaysProvider);
    final isSelectionMode = selectedRelays.isNotEmpty;

    return filteredRelaysAsync.isEmpty
        ? _buildEmptyState(context)
        : _buildRelayList(context, ref, filteredRelaysAsync, isSelectionMode);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.dns_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Relays Found',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Add your first relay to get started',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: () => _showAddRelayDialog(context),
            icon: const Icon(Icons.add),
            label: const Text('Add Relay'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () => _showDiscoveryDialog(context),
            icon: const Icon(Icons.search),
            label: const Text('Discover Relays'),
          ),
        ],
      ),
    );
  }

  Widget _buildRelayList(
    BuildContext context,
    WidgetRef ref,
    List<RelayConfig> relays,
    bool isSelectionMode,
  ) {
    return Column(
      children: [
        // Selection header
        if (isSelectionMode) _buildSelectionHeader(context, ref),
        
        // Relay list
        Expanded(
          child: ReorderableListView.builder(
            itemCount: relays.length,
            onReorder: (oldIndex, newIndex) => _reorderRelays(ref, relays, oldIndex, newIndex),
            itemBuilder: (context, index) {
              final relay = relays[index];
              return _buildRelayListItem(context, ref, relay, index, isSelectionMode);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSelectionHeader(BuildContext context, WidgetRef ref) {
    final selectedRelays = ref.watch(selectedRelaysProvider);
    final relaysAsync = ref.watch(relayConfigurationsProvider);
    
    return relaysAsync.when(
      data: (allRelays) => Container(
        color: Theme.of(context).colorScheme.primaryContainer,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(
              Icons.checklist,
              color: Theme.of(context).colorScheme.onPrimaryContainer,
            ),
            const SizedBox(width: 12),
            Text(
              '${selectedRelays.length} relay(s) selected',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
            const Spacer(),
            TextButton(
              onPressed: () => _selectAll(ref, allRelays.values.toList()),
              child: Text(
                selectedRelays.length == allRelays.length ? 'Deselect All' : 'Select All',
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onPrimaryContainer,
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () => ref.read(selectedRelaysProvider.notifier).state = {},
              icon: Icon(
                Icons.close,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
              tooltip: 'Clear selection',
            ),
          ],
        ),
      ),
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildRelayListItem(
    BuildContext context,
    WidgetRef ref,
    RelayConfig relay,
    int index,
    bool isSelectionMode,
  ) {
    final selectedRelays = ref.watch(selectedRelaysProvider);
    final isSelected = selectedRelays.contains(relay.id);

    return Card(
      key: ValueKey(relay.id),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: RelayCardWidget(
        relay: relay,
        isSelected: isSelected,
        isSelectionMode: isSelectionMode,
        onTap: () => _handleRelayTap(ref, relay, isSelectionMode),
        onLongPress: () => _toggleSelection(ref, relay.id),
        onMenuAction: (action) => _handleMenuAction(context, ref, relay, action),
        showReorderHandle: !isSelectionMode,
      ),
    );
  }

  void _handleRelayTap(WidgetRef ref, RelayConfig relay, bool isSelectionMode) {
    if (isSelectionMode) {
      _toggleSelection(ref, relay.id);
    } else {
      // Show relay details or edit dialog
      _showRelayDetails(relay);
    }
  }

  void _toggleSelection(WidgetRef ref, String relayId) {
    final currentSelection = ref.read(selectedRelaysProvider);
    final newSelection = Set<String>.from(currentSelection);
    
    if (newSelection.contains(relayId)) {
      newSelection.remove(relayId);
    } else {
      newSelection.add(relayId);
    }
    
    ref.read(selectedRelaysProvider.notifier).state = newSelection;
  }

  void _selectAll(WidgetRef ref, List<RelayConfig> allRelays) {
    final currentSelection = ref.read(selectedRelaysProvider);
    
    if (currentSelection.length == allRelays.length) {
      // Deselect all
      ref.read(selectedRelaysProvider.notifier).state = {};
    } else {
      // Select all
      ref.read(selectedRelaysProvider.notifier).state = 
          allRelays.map((relay) => relay.id).toSet();
    }
  }

  void _reorderRelays(
    WidgetRef ref,
    List<RelayConfig> relays,
    int oldIndex,
    int newIndex,
  ) {
    // Adjust newIndex if moving down
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    // Calculate new priorities based on position
    final relayService = ref.read(relayManagementServiceProvider);
    final reorderedRelay = relays[oldIndex];
    
    // Update priority based on new position
    final newPriority = relays.length - newIndex;
    
    relayService.updateRelay(
      reorderedRelay.id,
      reorderedRelay.copyWith(priority: newPriority),
    );
  }

  void _handleMenuAction(
    BuildContext context,
    WidgetRef ref,
    RelayConfig relay,
    String action,
  ) {
    final relayService = ref.read(relayManagementServiceProvider);
    
    switch (action) {
      case 'connect':
        _connectRelay(relayService, relay);
        break;
      case 'disconnect':
        _disconnectRelay(relayService, relay);
        break;
      case 'test':
        _testRelay(relayService, relay);
        break;
      case 'edit':
        _showEditRelayDialog(context, relay);
        break;
      case 'delete':
        _showDeleteConfirmation(context, ref, relay);
        break;
      case 'toggle_enabled':
        _toggleRelayEnabled(relayService, relay);
        break;
    }
  }

  Future<void> _connectRelay(RelayManagementService service, RelayConfig relay) async {
    try {
      await service.executeBatchOperation(
        RelayBatchOperationType.connect,
        [relay.id],
      );
    } catch (e) {
      debugPrint('Failed to connect relay: $e');
    }
  }

  Future<void> _disconnectRelay(RelayManagementService service, RelayConfig relay) async {
    try {
      await service.executeBatchOperation(
        RelayBatchOperationType.disconnect,
        [relay.id],
      );
    } catch (e) {
      debugPrint('Failed to disconnect relay: $e');
    }
  }

  Future<void> _testRelay(RelayManagementService service, RelayConfig relay) async {
    try {
      await service.executeBatchOperation(
        RelayBatchOperationType.test,
        [relay.id],
      );
    } catch (e) {
      debugPrint('Failed to test relay: $e');
    }
  }

  Future<void> _toggleRelayEnabled(RelayManagementService service, RelayConfig relay) async {
    try {
      final operation = relay.isEnabled 
          ? RelayBatchOperationType.disable 
          : RelayBatchOperationType.enable;
      
      await service.executeBatchOperation(operation, [relay.id]);
    } catch (e) {
      debugPrint('Failed to toggle relay state: $e');
    }
  }

  void _showRelayDetails(RelayConfig relay) {
    // TODO: Implement relay details dialog
  }

  void _showAddRelayDialog(BuildContext context) {
    // TODO: Implement add relay dialog
  }

  void _showEditRelayDialog(BuildContext context, RelayConfig relay) {
    // TODO: Implement edit relay dialog
  }

  void _showDiscoveryDialog(BuildContext context) {
    // TODO: Implement discovery dialog
  }

  Future<void> _showDeleteConfirmation(
    BuildContext context,
    WidgetRef ref,
    RelayConfig relay,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Relay'),
        content: Text('Are you sure you want to delete "${relay.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final relayService = ref.read(relayManagementServiceProvider);
      try {
        await relayService.removeRelay(relay.id);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Deleted "${relay.name}"')),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete relay: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}