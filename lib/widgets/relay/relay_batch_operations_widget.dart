import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/providers/relay_providers.dart';
import 'package:trottstr/services/relay_management_service.dart';
import 'package:intl/intl.dart';

/// Widget that displays batch operation history and management
class RelayBatchOperationsWidget extends ConsumerWidget {
  const RelayBatchOperationsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          // Tab bar
          const TabBar(
            tabs: [
              Tab(text: 'Active', icon: Icon(Icons.play_circle)),
              Tab(text: 'Completed', icon: Icon(Icons.check_circle)),
              Tab(text: 'Failed', icon: Icon(Icons.error)),
            ],
          ),
          
          // Tab views
          Expanded(
            child: TabBarView(
              children: [
                _ActiveOperationsTab(),
                _CompletedOperationsTab(),
                _FailedOperationsTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Tab showing active/running operations
class _ActiveOperationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeOperations = ref.watch(activeBatchOperationsProvider);
    
    if (activeOperations.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.play_circle_outline,
        title: 'No Active Operations',
        subtitle: 'All batch operations have completed',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: activeOperations.length,
      itemBuilder: (context, index) {
        final operation = activeOperations[index];
        return _buildOperationCard(context, ref, operation, showProgress: true);
      },
    );
  }
}

/// Tab showing completed operations
class _CompletedOperationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final completedOperations = ref.watch(completedBatchOperationsProvider);
    
    if (completedOperations.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.check_circle_outline,
        title: 'No Completed Operations',
        subtitle: 'Completed operations will appear here',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: completedOperations.length,
      itemBuilder: (context, index) {
        final operation = completedOperations[index];
        return _buildOperationCard(context, ref, operation);
      },
    );
  }
}

/// Tab showing failed operations
class _FailedOperationsTab extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final failedOperations = ref.watch(failedBatchOperationsProvider);
    
    if (failedOperations.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.sentiment_satisfied,
        title: 'No Failed Operations',
        subtitle: 'Great! All operations completed successfully',
        color: Colors.green,
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: failedOperations.length,
      itemBuilder: (context, index) {
        final operation = failedOperations[index];
        return _buildOperationCard(context, ref, operation, showRetry: true);
      },
    );
  }
}

Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  Color? color,
}) {
  final effectiveColor = color ?? Theme.of(context).colorScheme.onSurfaceVariant;
  
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: effectiveColor,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: effectiveColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: effectiveColor,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

Widget _buildOperationCard(
  BuildContext context,
  WidgetRef ref,
  RelayBatchOperation operation, {
  bool showProgress = false,
  bool showRetry = false,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              _buildOperationIcon(operation.type),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _getOperationTitle(operation.type),
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${operation.relayIds.length} relay(s)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              _buildStatusChip(context, operation.status),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Progress indicator for active operations
          if (showProgress) _buildProgressIndicator(context, operation),
          
          // Operation details
          _buildOperationDetails(context, operation),
          
          // Actions
          if (showRetry || operation.status == RelayBatchOperationStatus.running)
            _buildActionButtons(context, ref, operation, showRetry),
        ],
      ),
    ),
  );
}

Widget _buildOperationIcon(RelayBatchOperationType type) {
  IconData icon;
  Color color;
  
  switch (type) {
    case RelayBatchOperationType.connect:
      icon = Icons.wifi;
      color = Colors.green;
      break;
    case RelayBatchOperationType.disconnect:
      icon = Icons.wifi_off;
      color = Colors.orange;
      break;
    case RelayBatchOperationType.test:
      icon = Icons.speed;
      color = Colors.blue;
      break;
    case RelayBatchOperationType.enable:
      icon = Icons.check_circle;
      color = Colors.green;
      break;
    case RelayBatchOperationType.disable:
      icon = Icons.cancel;
      color = Colors.grey;
      break;
    case RelayBatchOperationType.delete:
      icon = Icons.delete;
      color = Colors.red;
      break;
    case RelayBatchOperationType.updatePriority:
      icon = Icons.priority_high;
      color = Colors.purple;
      break;
    case RelayBatchOperationType.updateSettings:
      icon = Icons.settings;
      color = Colors.blueGrey;
      break;
  }
  
  return CircleAvatar(
    radius: 20,
    backgroundColor: color.withOpacity(0.1),
    child: Icon(icon, color: color, size: 20),
  );
}

Widget _buildStatusChip(BuildContext context, RelayBatchOperationStatus status) {
  Color color;
  String label;
  IconData icon;
  
  switch (status) {
    case RelayBatchOperationStatus.pending:
      color = Colors.orange;
      label = 'Pending';
      icon = Icons.schedule;
      break;
    case RelayBatchOperationStatus.running:
      color = Colors.blue;
      label = 'Running';
      icon = Icons.play_arrow;
      break;
    case RelayBatchOperationStatus.completed:
      color = Colors.green;
      label = 'Completed';
      icon = Icons.check;
      break;
    case RelayBatchOperationStatus.failed:
      color = Colors.red;
      label = 'Failed';
      icon = Icons.error;
      break;
    case RelayBatchOperationStatus.cancelled:
      color = Colors.grey;
      label = 'Cancelled';
      icon = Icons.cancel;
      break;
  }
  
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withOpacity(0.3)),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: TextStyle(
            color: color,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ),
  );
}

Widget _buildProgressIndicator(BuildContext context, RelayBatchOperation operation) {
  // Calculate progress based on completed relays
  final totalRelays = operation.relayIds.length;
  final completedRelays = operation.results.length;
  final progress = totalRelays > 0 ? completedRelays / totalRelays : 0.0;
  
  return Column(
    children: [
      Row(
        children: [
          Expanded(
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.grey.withOpacity(0.2),
              valueColor: AlwaysStoppedAnimation(
                Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$completedRelays/$totalRelays',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
    ],
  );
}

Widget _buildOperationDetails(BuildContext context, RelayBatchOperation operation) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Timestamps
      Row(
        children: [
          Icon(
            Icons.schedule,
            size: 14,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            'Started: ${_formatDateTime(operation.createdAt)}',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      
      if (operation.completedAt != null) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.done,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Completed: ${_formatDateTime(operation.completedAt!)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
      
      // Duration
      if (operation.completedAt != null) ...[
        const SizedBox(height: 4),
        Row(
          children: [
            Icon(
              Icons.timer,
              size: 14,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              'Duration: ${_formatDuration(operation.completedAt!.difference(operation.createdAt))}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ],
      
      // Error message
      if (operation.errorMessage != null) ...[
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error, color: Colors.red, size: 16),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  operation.errorMessage!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.red,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
      
      // Results summary
      if (operation.results.isNotEmpty) ...[
        const SizedBox(height: 8),
        _buildResultsSummary(context, operation),
      ],
    ],
  );
}

Widget _buildResultsSummary(BuildContext context, RelayBatchOperation operation) {
  final successCount = operation.results.values
      .where((result) => result['success'] == true || result['error'] == null)
      .length;
  final errorCount = operation.results.length - successCount;
  
  return ExpansionTile(
    tilePadding: EdgeInsets.zero,
    title: Text(
      'Results: $successCount successful, $errorCount failed',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        fontWeight: FontWeight.w600,
      ),
    ),
    children: operation.results.entries.map((entry) {
      final relayId = entry.key;
      final result = entry.value;
      final isSuccess = result['success'] == true || result['error'] == null;
      
      return ListTile(
        dense: true,
        leading: Icon(
          isSuccess ? Icons.check_circle : Icons.error,
          color: isSuccess ? Colors.green : Colors.red,
          size: 16,
        ),
        title: Text(
          relayId,
          style: Theme.of(context).textTheme.bodySmall,
        ),
        subtitle: result['error'] != null
            ? Text(
                result['error'].toString(),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.red,
                ),
              )
            : null,
      );
    }).toList(),
  );
}

Widget _buildActionButtons(
  BuildContext context,
  WidgetRef ref,
  RelayBatchOperation operation,
  bool showRetry,
) {
  return Padding(
    padding: const EdgeInsets.only(top: 12),
    child: Row(
      children: [
        if (operation.status == RelayBatchOperationStatus.running) ...[
          OutlinedButton.icon(
            onPressed: () => _cancelOperation(ref, operation),
            icon: const Icon(Icons.stop, size: 16),
            label: const Text('Cancel'),
          ),
        ],
        
        if (showRetry) ...[
          FilledButton.icon(
            onPressed: () => _retryOperation(context, ref, operation),
            icon: const Icon(Icons.refresh, size: 16),
            label: const Text('Retry'),
          ),
        ],
        
        const Spacer(),
        
        TextButton.icon(
          onPressed: () => _showOperationDetails(context, operation),
          icon: const Icon(Icons.info, size: 16),
          label: const Text('Details'),
        ),
      ],
    ),
  );
}

void _cancelOperation(WidgetRef ref, RelayBatchOperation operation) {
  final service = ref.read(relayManagementServiceProvider);
  service.cancelBatchOperation(operation.id);
}

void _retryOperation(BuildContext context, WidgetRef ref, RelayBatchOperation operation) {
  // TODO: Implement retry logic
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Retry functionality coming soon!')),
  );
}

void _showOperationDetails(BuildContext context, RelayBatchOperation operation) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(_getOperationTitle(operation.type)),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Operation ID: ${operation.id}'),
            const SizedBox(height: 8),
            Text('Status: ${operation.status.name}'),
            const SizedBox(height: 8),
            Text('Relays: ${operation.relayIds.length}'),
            const SizedBox(height: 8),
            Text('Created: ${_formatDateTime(operation.createdAt)}'),
            if (operation.completedAt != null) ...[
              const SizedBox(height: 8),
              Text('Completed: ${_formatDateTime(operation.completedAt!)}'),
            ],
            if (operation.errorMessage != null) ...[
              const SizedBox(height: 16),
              const Text('Error:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(operation.errorMessage!),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

String _getOperationTitle(RelayBatchOperationType type) {
  switch (type) {
    case RelayBatchOperationType.connect:
      return 'Connect Relays';
    case RelayBatchOperationType.disconnect:
      return 'Disconnect Relays';
    case RelayBatchOperationType.test:
      return 'Test Relays';
    case RelayBatchOperationType.enable:
      return 'Enable Relays';
    case RelayBatchOperationType.disable:
      return 'Disable Relays';
    case RelayBatchOperationType.delete:
      return 'Delete Relays';
    case RelayBatchOperationType.updatePriority:
      return 'Update Priority';
    case RelayBatchOperationType.updateSettings:
      return 'Update Settings';
  }
}

String _formatDateTime(DateTime dateTime) {
  return DateFormat('MMM d, h:mm a').format(dateTime);
}

String _formatDuration(Duration duration) {
  if (duration.inMinutes > 0) {
    return '${duration.inMinutes}m ${duration.inSeconds % 60}s';
  } else {
    return '${duration.inSeconds}s';
  }
}