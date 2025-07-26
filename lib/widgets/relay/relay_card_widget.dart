import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:intl/intl.dart';

/// Widget that displays an individual relay card with status and actions
class RelayCardWidget extends ConsumerWidget {
  final RelayConfig relay;
  final bool isSelected;
  final bool isSelectionMode;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(String)? onMenuAction;
  final bool showReorderHandle;

  const RelayCardWidget({
    super.key,
    required this.relay,
    this.isSelected = false,
    this.isSelectionMode = false,
    this.onTap,
    this.onLongPress,
    this.onMenuAction,
    this.showReorderHandle = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      onTap: onTap,
      onLongPress: onLongPress,
      selected: isSelected,
      leading: _buildLeading(context),
      title: _buildTitle(context),
      subtitle: _buildSubtitle(context),
      trailing: _buildTrailing(context),
    );
  }

  Widget _buildLeading(BuildContext context) {
    if (isSelectionMode) {
      return Checkbox(value: isSelected, onChanged: (_) => onTap?.call());
    }

    return CircleAvatar(
      backgroundColor: _getStatusColor(context).withOpacity(0.1),
      child: Icon(_getStatusIcon(), color: _getStatusColor(context), size: 20),
    );
  }

  Widget _buildTitle(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            relay.name,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              decoration: relay.isEnabled ? null : TextDecoration.lineThrough,
            ),
          ),
        ),
        if (!relay.isEnabled)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.grey.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              'DISABLED',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Colors.grey,
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
        const SizedBox(height: 4),
        Text(
          _formatUrl(relay.url),
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontFamily: 'monospace',
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          relay.description,
          style: Theme.of(context).textTheme.bodySmall,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            _buildStatusChip(context),
            if (relay.latency != null) _buildLatencyChip(context),
            _buildPriorityChip(context),
            _buildHealthChip(context),
          ],
        ),
      ],
    );
  }

  Widget? _buildTrailing(BuildContext context) {
    if (isSelectionMode) {
      return showReorderHandle
          ? ReorderableDragStartListener(
              index: 0, // This will be set by the parent
              child: const Icon(Icons.drag_handle),
            )
          : null;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (relay.lastConnected != null)
          Tooltip(
            message: 'Last connected: ${_formatDateTime(relay.lastConnected!)}',
            child: Text(
              _formatRelativeTime(relay.lastConnected!),
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        const SizedBox(width: 8),
        PopupMenuButton<String>(
          onSelected: onMenuAction,
          itemBuilder: (context) => [
            if (relay.status == RelayStatus.disconnected)
              PopupMenuItem(
                value: 'connect',
                child: ListTile(
                  leading: const Icon(Icons.wifi),
                  title: const Text('Connect'),
                  dense: true,
                ),
              )
            else if (relay.status == RelayStatus.connected)
              PopupMenuItem(
                value: 'disconnect',
                child: ListTile(
                  leading: const Icon(Icons.wifi_off),
                  title: const Text('Disconnect'),
                  dense: true,
                ),
              ),
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
              value: 'toggle_enabled',
              child: ListTile(
                leading: Icon(
                  relay.isEnabled ? Icons.cancel : Icons.check_circle,
                ),
                title: Text(relay.isEnabled ? 'Disable' : 'Enable'),
                dense: true,
              ),
            ),
            PopupMenuItem(
              value: 'edit',
              child: ListTile(
                leading: const Icon(Icons.edit),
                title: const Text('Edit'),
                dense: true,
              ),
            ),
            const PopupMenuDivider(),
            PopupMenuItem(
              value: 'delete',
              child: ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text(
                  'Delete',
                  style: TextStyle(color: Colors.red),
                ),
                dense: true,
              ),
            ),
          ],
        ),
        if (showReorderHandle)
          ReorderableDragStartListener(
            index: 0, // This will be set by the parent
            child: const Icon(Icons.drag_handle),
          ),
      ],
    );
  }

  Widget _buildStatusChip(BuildContext context) {
    final color = _getStatusColor(context);
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
            _getStatusText(),
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
    final latency = relay.latency!;
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

  Widget _buildPriorityChip(BuildContext context) {
    if (relay.priority == 0) return const SizedBox.shrink();

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
            Icons.priority_high,
            size: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            relay.priority.toString(),
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHealthChip(BuildContext context) {
    final health = relay.healthScore;
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

  Color _getStatusColor(BuildContext context) {
    switch (relay.status) {
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
    switch (relay.status) {
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

  String _getStatusText() {
    switch (relay.status) {
      case RelayStatus.connected:
        return 'Connected';
      case RelayStatus.connecting:
        return 'Connecting';
      case RelayStatus.disconnected:
        return 'Disconnected';
      case RelayStatus.error:
        return 'Error';
      case RelayStatus.testing:
        return 'Testing';
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

  String _formatDateTime(DateTime dateTime) {
    return DateFormat('MMM d, yyyy h:mm a').format(dateTime);
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
