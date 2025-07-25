import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

/// Relay server selection interface with connection status and latency testing
class RelayServerSection extends HookConsumerWidget {
  const RelayServerSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedRelay = useState<String>('wss://relay.damus.io');
    final connectionStatus = useState<ConnectionStatus>(ConnectionStatus.disconnected);
    final latency = useState<int?>(null);
    final isTestingLatency = useState<bool>(false);

    return Column(
      children: [
        // Current Relay Status
        _buildCurrentRelayStatus(context, selectedRelay.value, connectionStatus.value, latency.value),
        
        const Divider(height: 1),
        
        // Relay Server Selection
        _buildRelaySelection(context, selectedRelay, connectionStatus, isTestingLatency),
        
        const Divider(height: 1),
        
        // Connection Settings
        _buildConnectionSettings(context),
        
        const Divider(height: 1),
        
        // Test Connection Button
        _buildTestConnectionButton(context, selectedRelay.value, connectionStatus, latency, isTestingLatency),
      ],
    );
  }

  Widget _buildCurrentRelayStatus(
    BuildContext context,
    String currentRelay,
    ConnectionStatus status,
    int? latency,
  ) {
    Color statusColor;
    IconData statusIcon;
    String statusText;

    switch (status) {
      case ConnectionStatus.connected:
        statusColor = Colors.green;
        statusIcon = Icons.wifi;
        statusText = 'Connected';
        break;
      case ConnectionStatus.connecting:
        statusColor = Colors.orange;
        statusIcon = Icons.wifi_find;
        statusText = 'Connecting...';
        break;
      case ConnectionStatus.disconnected:
        statusColor = Colors.red;
        statusIcon = Icons.wifi_off;
        statusText = 'Disconnected';
        break;
      case ConnectionStatus.error:
        statusColor = Colors.red.shade800;
        statusIcon = Icons.error;
        statusText = 'Connection Error';
        break;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withOpacity(0.1),
        child: Icon(
          statusIcon,
          color: statusColor,
          size: 20,
        ),
      ),
      title: Text(
        'Current Relay',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _formatRelayUrl(currentRelay),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontFamily: 'monospace',
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor.withOpacity(0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
              if (latency != null && status == ConnectionStatus.connected) ...[
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${latency}ms',
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRelaySelection(
    BuildContext context,
    ValueNotifier<String> selectedRelay,
    ValueNotifier<ConnectionStatus> connectionStatus,
    ValueNotifier<bool> isTestingLatency,
  ) {
    final relayServers = [
      RelayServer('wss://relay.damus.io', 'Damus Relay', 'Popular general-purpose relay'),
      RelayServer('wss://nostr.wine', 'Nostr Wine', 'High-performance relay'),
      RelayServer('wss://relay.nostr.info', 'Nostr Info', 'Community relay'),
      RelayServer('wss://relay.snort.social', 'Snort Social', 'Social-focused relay'),
      RelayServer('wss://nos.lol', 'nos.lol', 'Fast and reliable'),
      RelayServer('wss://relay.current.fyi', 'Current FYI', 'News and updates'),
      RelayServer('wss://brb.io', 'BRB.io', 'Business relay'),
      RelayServer('wss://relay.nostrich.de', 'Nostrich DE', 'European relay'),
    ];

    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.dns,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        'Available Relays',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Select from ${relayServers.length} available relay servers',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      children: relayServers.map((relay) {
        final isSelected = selectedRelay.value == relay.url;
        return ListTile(
          dense: true,
          leading: Radio<String>(
            value: relay.url,
            groupValue: selectedRelay.value,
            onChanged: (value) {
              if (value != null) {
                selectedRelay.value = value;
                connectionStatus.value = ConnectionStatus.disconnected;
              }
            },
          ),
          title: Text(
            relay.name,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                relay.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              Text(
                _formatRelayUrl(relay.url),
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontFamily: 'monospace',
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          trailing: isTestingLatency.value
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : IconButton(
                icon: const Icon(Icons.speed, size: 20),
                onPressed: () => _testRelayLatency(context, relay, isTestingLatency),
                tooltip: 'Test latency',
              ),
          onTap: () {
            selectedRelay.value = relay.url;
            connectionStatus.value = ConnectionStatus.disconnected;
          },
        );
      }).toList(),
    );
  }

  Widget _buildConnectionSettings(BuildContext context) {
    return ExpansionTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          Icons.tune,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        'Connection Settings',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Advanced connection options',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      children: [
        SwitchListTile(
          dense: true,
          title: const Text('Auto Reconnect'),
          subtitle: const Text('Automatically reconnect when connection is lost'),
          value: true,
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Auto reconnect setting updated')),
            );
          },
        ),
        SwitchListTile(
          dense: true,
          title: const Text('Use Multiple Relays'),
          subtitle: const Text('Connect to multiple relays for redundancy'),
          value: false,
          onChanged: (value) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Multiple relay setting updated')),
            );
          },
        ),
        ListTile(
          dense: true,
          title: const Text('Connection Timeout'),
          subtitle: const Text('Time to wait for connection (seconds)'),
          trailing: DropdownButton<int>(
            value: 30,
            items: [10, 20, 30, 60, 120].map((seconds) {
              return DropdownMenuItem(
                value: seconds,
                child: Text('${seconds}s'),
              );
            }).toList(),
            onChanged: (value) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Timeout set to ${value}s')),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildTestConnectionButton(
    BuildContext context,
    String relayUrl,
    ValueNotifier<ConnectionStatus> connectionStatus,
    ValueNotifier<int?> latency,
    ValueNotifier<bool> isTestingLatency,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.network_ping,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        'Test Connection',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Text(
        'Test connectivity and measure latency',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: ElevatedButton.icon(
        onPressed: isTestingLatency.value
          ? null
          : () => _testConnection(context, relayUrl, connectionStatus, latency, isTestingLatency),
        icon: isTestingLatency.value
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_arrow, size: 18),
        label: Text(isTestingLatency.value ? 'Testing...' : 'Test'),
      ),
    );
  }

  String _formatRelayUrl(String url) {
    return url.replaceFirst('wss://', '').replaceFirst('ws://', '');
  }

  void _testRelayLatency(BuildContext context, RelayServer relay, ValueNotifier<bool> isTestingLatency) {
    isTestingLatency.value = true;
    
    // Simulate latency test
    Future.delayed(const Duration(seconds: 2), () {
      isTestingLatency.value = false;
      final latency = 50 + (relay.url.hashCode % 200); // Simulate latency 50-250ms
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${relay.name}: ${latency}ms latency'),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  void _testConnection(
    BuildContext context,
    String relayUrl,
    ValueNotifier<ConnectionStatus> connectionStatus,
    ValueNotifier<int?> latency,
    ValueNotifier<bool> isTestingLatency,
  ) {
    isTestingLatency.value = true;
    connectionStatus.value = ConnectionStatus.connecting;
    
    // Simulate connection test
    Future.delayed(const Duration(seconds: 3), () {
      isTestingLatency.value = false;
      
      // Simulate successful connection (90% success rate)
      final success = (relayUrl.hashCode % 10) < 9;
      
      if (success) {
        connectionStatus.value = ConnectionStatus.connected;
        latency.value = 50 + (relayUrl.hashCode % 150); // 50-200ms
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.green),
                const SizedBox(width: 8),
                Text('Connected successfully! Latency: ${latency.value}ms'),
              ],
            ),
            backgroundColor: Colors.green.shade100,
          ),
        );
      } else {
        connectionStatus.value = ConnectionStatus.error;
        latency.value = null;
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(Icons.error, color: Colors.red),
                SizedBox(width: 8),
                Text('Connection failed. Please try again.'),
              ],
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    });
  }
}

/// Represents a relay server configuration
class RelayServer {
  final String url;
  final String name;
  final String description;

  const RelayServer(this.url, this.name, this.description);
}

/// Connection status enumeration
enum ConnectionStatus {
  disconnected,
  connecting,
  connected,
  error,
}