import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/providers/relay_providers.dart';
import 'package:trottstr/models/relay_models.dart';

/// Widget that displays comprehensive relay statistics and analytics
class RelayStatsWidget extends ConsumerWidget {
  const RelayStatsWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(relayStatisticsProvider);
    final relaysAsync = ref.watch(relayConfigurationsProvider);

    return relaysAsync.when(
      data: (relays) =>
          _buildStatsContent(context, statsAsync, relays.values.toList()),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) =>
          Center(child: Text('Error loading relay data: $error')),
    );
  }

  Widget _buildStatsContent(
    BuildContext context,
    RelayStatistics stats,
    List<RelayConfig> relays,
  ) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Overview cards
          _buildOverviewCards(context, stats),
          const SizedBox(height: 24),

          // Status distribution chart
          _buildStatusChart(context, relays),
          const SizedBox(height: 24),

          // Latency distribution
          _buildLatencyChart(context, relays),
          const SizedBox(height: 24),

          // Health scores
          _buildHealthChart(context, relays),
          const SizedBox(height: 24),

          // Connection timeline
          _buildConnectionTimeline(context, relays),
          const SizedBox(height: 24),

          // Performance metrics
          _buildPerformanceMetrics(context, stats, relays),
        ],
      ),
    );
  }

  Widget _buildOverviewCards(BuildContext context, RelayStatistics stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Overview',
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        LayoutBuilder(
          builder: (context, constraints) {
            final isWide = constraints.maxWidth > 800;
            return Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth,
                  child: _buildStatCard(
                    context,
                    title: 'Total Relays',
                    value: stats.totalRelays.toString(),
                    icon: Icons.dns,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth,
                  child: _buildStatCard(
                    context,
                    title: 'Connected',
                    value: stats.connectedRelays.toString(),
                    subtitle:
                        '${(stats.connectionRate * 100).toStringAsFixed(1)}%',
                    icon: Icons.wifi,
                    color: Colors.green,
                  ),
                ),
                SizedBox(
                  width: isWide
                      ? (constraints.maxWidth - 32) / 3
                      : constraints.maxWidth,
                  child: _buildStatCard(
                    context,
                    title: 'Avg Latency',
                    value: '${stats.averageLatency.toStringAsFixed(0)}ms',
                    icon: Icons.speed,
                    color: _getLatencyColor(stats.averageLatency),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    String? subtitle,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
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

  Widget _buildStatusChart(BuildContext context, List<RelayConfig> relays) {
    final statusCounts = <RelayStatus, int>{};
    for (final status in RelayStatus.values) {
      statusCounts[status] = relays.where((r) => r.status == status).length;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Status Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildStatusPieChart(context, statusCounts, relays.length),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: statusCounts.entries.map((entry) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: _getStatusColor(entry.key),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_getStatusLabel(entry.key)}: ${entry.value}',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLatencyChart(BuildContext context, List<RelayConfig> relays) {
    final latencyRelays = relays.where((r) => r.latency != null).toList();
    if (latencyRelays.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Text(
                'Latency Distribution',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 32),
              const Text('No latency data available'),
            ],
          ),
        ),
      );
    }

    // Group latencies into ranges
    final ranges = <String, int>{
      '<50ms': 0,
      '50-100ms': 0,
      '100-200ms': 0,
      '>200ms': 0,
    };

    for (final relay in latencyRelays) {
      final latency = relay.latency!;
      if (latency < 50) {
        ranges['<50ms'] = ranges['<50ms']! + 1;
      } else if (latency < 100) {
        ranges['50-100ms'] = ranges['50-100ms']! + 1;
      } else if (latency < 200) {
        ranges['100-200ms'] = ranges['100-200ms']! + 1;
      } else {
        ranges['>200ms'] = ranges['>200ms']! + 1;
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Latency Distribution',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 200,
              child: _buildLatencyBarChart(context, ranges),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHealthChart(BuildContext context, List<RelayConfig> relays) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Health Scores',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...relays
                .take(5)
                .map(
                  (relay) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                relay.name,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            ),
                            Text(
                              '${(relay.healthScore * 100).toStringAsFixed(1)}%',
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        LinearProgressIndicator(
                          value: relay.healthScore,
                          backgroundColor: Colors.grey.withOpacity(0.2),
                          valueColor: AlwaysStoppedAnimation(
                            _getHealthColor(relay.healthScore),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectionTimeline(
    BuildContext context,
    List<RelayConfig> relays,
  ) {
    final recentlyConnected =
        relays.where((r) => r.lastConnected != null).toList()
          ..sort((a, b) => b.lastConnected!.compareTo(a.lastConnected!));

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent Connections',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            if (recentlyConnected.isEmpty)
              const Text('No recent connections')
            else
              ...recentlyConnected
                  .take(5)
                  .map(
                    (relay) => ListTile(
                      dense: true,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: _getStatusColor(
                          relay.status,
                        ).withOpacity(0.1),
                        child: Icon(
                          _getStatusIcon(relay.status),
                          size: 16,
                          color: _getStatusColor(relay.status),
                        ),
                      ),
                      title: Text(relay.name),
                      subtitle: Text(_formatRelativeTime(relay.lastConnected!)),
                      trailing: relay.latency != null
                          ? Text(
                              '${relay.latency}ms',
                              style: Theme.of(context).textTheme.bodySmall,
                            )
                          : null,
                    ),
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceMetrics(
    BuildContext context,
    RelayStatistics stats,
    List<RelayConfig> relays,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Performance Metrics',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildMetricRow(
              context,
              'Connection Success Rate',
              '${(stats.connectionRate * 100).toStringAsFixed(1)}%',
              Icons.check_circle,
              stats.connectionRate > 0.8 ? Colors.green : Colors.orange,
            ),
            _buildMetricRow(
              context,
              'Error Rate',
              '${(stats.errorRate * 100).toStringAsFixed(1)}%',
              Icons.error,
              stats.errorRate < 0.1 ? Colors.green : Colors.red,
            ),
            _buildMetricRow(
              context,
              'Average Health',
              '${(stats.averageHealth * 100).toStringAsFixed(1)}%',
              Icons.health_and_safety,
              _getHealthColor(stats.averageHealth),
            ),
            _buildMetricRow(
              context,
              'Enabled Relays',
              '${stats.enabledRelays}/${stats.totalRelays}',
              Icons.toggle_on,
              Theme.of(context).colorScheme.primary,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
    Color color,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusPieChart(
    BuildContext context,
    Map<RelayStatus, int> statusCounts,
    int totalRelays,
  ) {
    if (totalRelays == 0) {
      return const Center(child: Text('No relay data available'));
    }

    return Column(
      children: statusCounts.entries.map((entry) {
        final percentage = entry.value / totalRelays;
        final color = _getStatusColor(entry.key);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _getStatusLabel(entry.key),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: LinearProgressIndicator(
                  value: percentage,
                  backgroundColor: Colors.grey.withOpacity(0.2),
                  valueColor: AlwaysStoppedAnimation(color),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 40,
                child: Text(
                  '${entry.value}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLatencyBarChart(BuildContext context, Map<String, int> ranges) {
    final maxValue = ranges.values.isEmpty
        ? 1
        : ranges.values.reduce((a, b) => a > b ? a : b);

    return Column(
      children: ranges.entries.map((entry) {
        final percentage = maxValue > 0 ? entry.value / maxValue : 0.0;
        final color = _getLatencyRangeColor(entry.key);

        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              SizedBox(
                width: 80,
                child: Text(
                  entry.key,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
              Expanded(
                child: Container(
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: percentage,
                    child: Container(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 30,
                child: Text(
                  '${entry.value}',
                  style: Theme.of(
                    context,
                  ).textTheme.bodySmall?.copyWith(fontWeight: FontWeight.bold),
                  textAlign: TextAlign.end,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
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

  String _getStatusLabel(RelayStatus status) {
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

  Color _getLatencyColor(double latency) {
    if (latency < 50) return Colors.green;
    if (latency < 100) return Colors.orange;
    return Colors.red;
  }

  Color _getLatencyRangeColor(String range) {
    switch (range) {
      case '<50ms':
        return Colors.green;
      case '50-100ms':
        return Colors.orange;
      case '100-200ms':
        return Colors.deepOrange;
      case '>200ms':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getHealthColor(double health) {
    if (health >= 0.8) return Colors.green;
    if (health >= 0.6) return Colors.orange;
    if (health >= 0.4) return Colors.deepOrange;
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
