import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/multi_relay_connection_models.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/providers/multi_relay_providers.dart';

/// Enhanced relay tile with multi-selection support and priority indicators
class MultiRelayTileWidget extends ConsumerWidget {
  final ConnectedRelay connectedRelay;
  final bool isInConnection;
  final bool isSelectable;
  final bool isDraggable;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String)? onMenuAction;
  final int? visualIndex; // For drag operations

  const MultiRelayTileWidget({
    super.key,
    required this.connectedRelay,
    this.isInConnection = false,
    this.isSelectable = true,
    this.isDraggable = false,
    this.onTap,
    this.onLongPress,
    this.onMenuAction,
    this.visualIndex,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectionState = ref.watch(relaySelectionStateProvider);
    final multiRelayManager = ref.watch(multiRelayManagerProvider);
    final isSelected =
        isInConnection ||
        (isSelectable &&
            selectionState.isRelaySelected(connectedRelay.relayId));
    final isDragActive = selectionState.isDragActive;
    final isDraggedItem =
        selectionState.draggedRelayId == connectedRelay.relayId;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getBorderColor(context, isSelected, isDraggedItem),
          width: isSelected ? 2 : 1,
        ),
        color: _getTileColor(context, isSelected, isDraggedItem),
        boxShadow: isSelected
            ? [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ]
            : [],
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (isSelectable) {
            multiRelayManager.toggleRelaySelection(connectedRelay.relayId);
          }
          onTap?.call();
        },
        onLongPress: () {
          if (isSelectable && !selectionState.isMultiSelectMode) {
            multiRelayManager.enterMultiSelectMode();
            multiRelayManager.toggleRelaySelection(connectedRelay.relayId);
          }
          onLongPress?.call();
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Selection checkbox or priority badge
              _buildLeadingWidget(context, isSelected),
              const SizedBox(width: 12),

              // Relay info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildTitleRow(context),
                    const SizedBox(height: 4),
                    _buildSubtitle(context),
                    const SizedBox(height: 8),
                    _buildChipsRow(context),
                  ],
                ),
              ),

              // Trailing widgets (drag handle, menu, etc.)
              _buildTrailingWidget(context, ref),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLeadingWidget(BuildContext context, bool isSelected) {
    if (isInConnection) {
      // Show priority badge for connected relays
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _getPriorityColor(context),
          shape: BoxShape.circle,
          border: Border.all(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
        ),
        child: Center(
          child: Text(
            connectedRelay.priorityOrder.toString(),
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      );
    } else if (isSelectable) {
      // Show checkbox for selectable relays
      return Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: isSelected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.surface,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.outline,
            width: 2,
          ),
        ),
        child: isSelected
            ? Icon(
                Icons.check,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 20,
              )
            : null,
      );
    } else {
      // Show status icon for non-selectable relays
      return CircleAvatar(
        backgroundColor: _getStatusColor(context).withOpacity(0.1),
        child: Icon(
          _getStatusIcon(),
          color: _getStatusColor(context),
          size: 20,
        ),
      );
    }
  }

  Widget _buildTitleRow(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            connectedRelay.relayConfig.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: connectedRelay.relayConfig.isEnabled
                  ? null
                  : TextDecoration.lineThrough,
            ),
          ),
        ),
        if (isInConnection)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: _getPriorityColor(context).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _getPriorityColor(context).withOpacity(0.3),
              ),
            ),
            child: Text(
              connectedRelay.priorityDisplayName,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _getPriorityColor(context),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSubtitle(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _formatUrl(connectedRelay.relayConfig.url),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          connectedRelay.relayConfig.description,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildChipsRow(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 4,
      children: [
        _buildConnectionStatusChip(context),
        if (connectedRelay.relayConfig.latency != null)
          _buildLatencyChip(context),
        _buildHealthChip(context),
        if (isInConnection && connectedRelay.connectedAt != null)
          _buildConnectionTimeChip(context),
      ],
    );
  }

  Widget _buildConnectionStatusChip(BuildContext context) {
    final status = connectedRelay.connectionStatus;
    final color = _getConnectionStatusColor(context, status);
    final text = _getConnectionStatusText(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatencyChip(BuildContext context) {
    final latency = connectedRelay.relayConfig.latency!;
    final color = _getLatencyColor(latency);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${latency}ms',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthChip(BuildContext context) {
    final health = connectedRelay.relayConfig.healthScore;
    final healthPercent = (health * 100).round();
    final color = _getHealthColor(health);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.health_and_safety, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '$healthPercent%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConnectionTimeChip(BuildContext context) {
    final connectedAt = connectedRelay.connectedAt!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.access_time,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            _formatRelativeTime(connectedAt),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrailingWidget(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (isDraggable)
          ReorderableDragStartListener(
            index: visualIndex ?? 0,
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.drag_handle,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          )
        else
          PopupMenuButton<String>(
            onSelected: onMenuAction,
            itemBuilder: (context) => _buildMenuItems(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              child: Icon(
                Icons.more_vert,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  List<PopupMenuEntry<String>> _buildMenuItems(BuildContext context) {
    final relay = connectedRelay.relayConfig;
    final items = <PopupMenuEntry<String>>[];

    if (isInConnection) {
      items.addAll([
        PopupMenuItem(
          value: 'remove_from_connection',
          child: ListTile(
            leading: const Icon(Icons.remove_circle_outline),
            title: const Text('Remove from Connection'),
            dense: true,
          ),
        ),
        PopupMenuItem(
          value: 'adjust_priority',
          child: ListTile(
            leading: const Icon(Icons.low_priority),
            title: const Text('Adjust Priority'),
            dense: true,
          ),
        ),
        const PopupMenuDivider(),
      ]);
    } else {
      items.add(
        PopupMenuItem(
          value: 'add_to_connection',
          child: ListTile(
            leading: const Icon(Icons.add_circle_outline),
            title: const Text('Add to Connection'),
            dense: true,
          ),
        ),
      );
    }

    // Connection actions
    if (relay.status == RelayStatus.disconnected) {
      items.add(
        PopupMenuItem(
          value: 'connect',
          child: ListTile(
            leading: const Icon(Icons.wifi),
            title: const Text('Connect'),
            dense: true,
          ),
        ),
      );
    } else if (relay.status == RelayStatus.connected) {
      items.add(
        PopupMenuItem(
          value: 'disconnect',
          child: ListTile(
            leading: const Icon(Icons.wifi_off),
            title: const Text('Disconnect'),
            dense: true,
          ),
        ),
      );
    }

    items.addAll([
      PopupMenuItem(
        value: 'test',
        child: ListTile(
          leading: const Icon(Icons.speed),
          title: const Text('Test Connection'),
          dense: true,
        ),
      ),
      const PopupMenuDivider(),
      PopupMenuItem(
        value: 'edit',
        child: ListTile(
          leading: const Icon(Icons.edit),
          title: const Text('Edit'),
          dense: true,
        ),
      ),
    ]);

    return items;
  }

  // Styling helper methods
  Color _getBorderColor(
    BuildContext context,
    bool isSelected,
    bool isDraggedItem,
  ) {
    if (isDraggedItem) {
      return Theme.of(context).colorScheme.primary.withOpacity(0.8);
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.primary;
    }
    return Theme.of(context).colorScheme.outline.withOpacity(0.3);
  }

  Color _getTileColor(
    BuildContext context,
    bool isSelected,
    bool isDraggedItem,
  ) {
    if (isDraggedItem) {
      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.8);
    }
    if (isSelected) {
      return Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3);
    }
    return Theme.of(context).colorScheme.surface;
  }

  Color _getPriorityColor(BuildContext context) {
    switch (connectedRelay.priorityOrder) {
      case 1:
        return Colors.amber; // Primary
      case 2:
        return Colors.orange; // Secondary
      case 3:
        return Colors.deepOrange; // Tertiary
      default:
        return Theme.of(context).colorScheme.secondary;
    }
  }

  Color _getStatusColor(BuildContext context) {
    switch (connectedRelay.relayConfig.status) {
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

  IconData _getStatusIcon() {
    switch (connectedRelay.relayConfig.status) {
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

  Color _getConnectionStatusColor(
    BuildContext context,
    RelayConnectionStatus status,
  ) {
    switch (status) {
      case RelayConnectionStatus.primaryConnected:
        return Colors.green;
      case RelayConnectionStatus.secondaryConnected:
        return Colors.blue;
      case RelayConnectionStatus.selectedDisconnected:
        return Colors.orange;
      case RelayConnectionStatus.unselected:
        return Colors.grey;
      case RelayConnectionStatus.connecting:
        return Colors.amber;
      case RelayConnectionStatus.error:
        return Colors.red;
    }
  }

  String _getConnectionStatusText(RelayConnectionStatus status) {
    switch (status) {
      case RelayConnectionStatus.primaryConnected:
        return 'Primary';
      case RelayConnectionStatus.secondaryConnected:
        return 'Secondary';
      case RelayConnectionStatus.selectedDisconnected:
        return 'Selected';
      case RelayConnectionStatus.unselected:
        return 'Available';
      case RelayConnectionStatus.connecting:
        return 'Connecting';
      case RelayConnectionStatus.error:
        return 'Error';
    }
  }

  Color _getLatencyColor(int latency) {
    if (latency < 50) return Colors.green;
    if (latency < 100) return Colors.orange;
    return Colors.red;
  }

  Color _getHealthColor(double health) {
    if (health >= 0.8) return Colors.green;
    if (health >= 0.6) return Colors.orange;
    if (health >= 0.4) return Colors.deepOrange;
    return Colors.red;
  }

  String _formatUrl(String url) {
    return url.replaceFirst('wss://', '').replaceFirst('ws://', '');
  }

  String _formatRelativeTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
