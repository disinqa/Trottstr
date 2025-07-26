import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/services/relay_management_service.dart';

/// Dialog for adding or editing relay configurations
class RelayAddEditDialog extends HookConsumerWidget {
  final RelayConfig? relay; // null for add, non-null for edit

  const RelayAddEditDialog({super.key, this.relay});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isEditing = relay != null;
    final formKey = useMemoized(() => GlobalKey<FormState>());

    // Form controllers
    final nameController = useTextEditingController(text: relay?.name ?? '');
    final urlController = useTextEditingController(text: relay?.url ?? '');
    final descriptionController = useTextEditingController(
      text: relay?.description ?? '',
    );
    final priorityController = useTextEditingController(
      text: relay?.priority.toString() ?? '0',
    );

    // State
    final isEnabled = useState(relay?.isEnabled ?? true);
    final isLoading = useState(false);

    return AlertDialog(
      title: Text(isEditing ? 'Edit Relay' : 'Add Relay'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Name field
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name *',
                    hintText: 'e.g., Damus Relay',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.label),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Name is required';
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // URL field
                TextFormField(
                  controller: urlController,
                  decoration: const InputDecoration(
                    labelText: 'URL *',
                    hintText: 'wss://relay.example.com',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.link),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'URL is required';
                    }

                    final url = value.trim();
                    if (!url.startsWith('wss://') && !url.startsWith('ws://')) {
                      return 'URL must start with wss:// or ws://';
                    }

                    try {
                      Uri.parse(url);
                    } catch (e) {
                      return 'Invalid URL format';
                    }

                    return null;
                  },
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Description field
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(
                    labelText: 'Description',
                    hintText: 'Brief description of this relay',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.description),
                  ),
                  maxLines: 2,
                  textInputAction: TextInputAction.next,
                ),

                const SizedBox(height: 16),

                // Priority field
                TextFormField(
                  controller: priorityController,
                  decoration: const InputDecoration(
                    labelText: 'Priority',
                    hintText: '0-100 (higher = more important)',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.priority_high),
                  ),
                  keyboardType: TextInputType.number,
                  validator: (value) {
                    if (value != null && value.isNotEmpty) {
                      final priority = int.tryParse(value);
                      if (priority == null) {
                        return 'Priority must be a number';
                      }
                      if (priority < 0 || priority > 100) {
                        return 'Priority must be between 0 and 100';
                      }
                    }
                    return null;
                  },
                  textInputAction: TextInputAction.done,
                ),

                const SizedBox(height: 16),

                // Enabled switch
                SwitchListTile(
                  title: const Text('Enabled'),
                  subtitle: const Text('Whether this relay should be used'),
                  value: isEnabled.value,
                  onChanged: (value) => isEnabled.value = value,
                ),

                if (isEditing) ...[
                  const SizedBox(height: 16),
                  _buildCurrentStatus(context, relay!),
                ],
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: isLoading.value ? null : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: isLoading.value
              ? null
              : () => _saveRelay(
                  context,
                  ref,
                  formKey,
                  nameController,
                  urlController,
                  descriptionController,
                  priorityController,
                  isEnabled.value,
                  isLoading,
                  relay,
                ),
          child: isLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(isEditing ? 'Save Changes' : 'Add Relay'),
        ),
      ],
    );
  }

  Widget _buildCurrentStatus(BuildContext context, RelayConfig relay) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Current Status',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  _getStatusIcon(relay.status),
                  color: _getStatusColor(relay.status),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  _getStatusText(relay.status),
                  style: TextStyle(
                    color: _getStatusColor(relay.status),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (relay.latency != null) ...[
                  const SizedBox(width: 16),
                  Icon(
                    Icons.speed,
                    color: _getLatencyColor(relay.latency!),
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${relay.latency}ms',
                    style: TextStyle(
                      color: _getLatencyColor(relay.latency!),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ],
            ),
            if (relay.lastConnected != null) ...[
              const SizedBox(height: 4),
              Text(
                'Last connected: ${_formatRelativeTime(relay.lastConnected!)}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _saveRelay(
    BuildContext context,
    WidgetRef ref,
    GlobalKey<FormState> formKey,
    TextEditingController nameController,
    TextEditingController urlController,
    TextEditingController descriptionController,
    TextEditingController priorityController,
    bool isEnabled,
    ValueNotifier<bool> isLoading,
    RelayConfig? existingRelay,
  ) async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    isLoading.value = true;

    try {
      final service = ref.read(relayManagementServiceProvider);

      final relayConfig = RelayConfig(
        id:
            existingRelay?.id ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        url: urlController.text.trim(),
        name: nameController.text.trim(),
        description: descriptionController.text.trim().isEmpty
            ? 'User-added relay'
            : descriptionController.text.trim(),
        priority: int.tryParse(priorityController.text) ?? 0,
        isEnabled: isEnabled,
        status: existingRelay?.status ?? RelayStatus.disconnected,
        latency: existingRelay?.latency,
        lastConnected: existingRelay?.lastConnected,
        lastTested: existingRelay?.lastTested,
        metadata: existingRelay?.metadata ?? {},
      );

      if (existingRelay != null) {
        // Update existing relay
        await service.updateRelay(existingRelay.id, relayConfig);
      } else {
        // Add new relay
        await service.addRelay(relayConfig);
      }

      if (context.mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              existingRelay != null
                  ? 'Relay updated successfully'
                  : 'Relay added successfully',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save relay: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }

  Color _getStatusColor(RelayStatus status) {
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

  IconData _getStatusIcon(RelayStatus status) {
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

  String _getStatusText(RelayStatus status) {
    switch (status) {
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
