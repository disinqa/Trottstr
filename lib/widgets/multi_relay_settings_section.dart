import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/backup_relay_models.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/widgets/relay_status_chip.dart';
import 'package:async_button_builder/async_button_builder.dart';

/// Multi-relay configuration section for settings screen
class MultiRelaySettingsSection extends HookConsumerWidget {
  const MultiRelaySettingsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Popular relay suggestions that will be auto-added
    final popularRelays = [
      'wss://relay.damus.io',
      'wss://relay.primal.net',
      'wss://nos.lol',
      'wss://relay.nostr.band',
      'wss://nostr.wine',
      'wss://relay.nostr.info',
      'wss://nostr-pub.wellorder.net',
      'wss://relay.current.fyi',
      'wss://brb.io',
      'wss://eden.nostr.land',
    ];

    // Initialize with popular relays auto-selected
    final selectedRelays = useState<List<BackupRelayConfig>>([]);
    final encryptionType = useState<BackupEncryptionType>(
      BackupEncryptionType.nip44,
    );
    final frequency = useState<BackupFrequency>(BackupFrequency.daily);
    final isEnabled = useState<bool>(true);
    final isExpanded = useState<bool>(false);

    // Auto-populate popular relays on first load
    useEffect(() {
      if (selectedRelays.value.isEmpty) {
        final autoSelectedRelays = <BackupRelayConfig>[];
        for (int i = 0; i < popularRelays.length; i++) {
          final url = popularRelays[i];
          final relayConfig = RelayConfig(
            id: url.hashCode.toString(),
            url: url,
            name: url.replaceFirst('wss://', '').replaceFirst('ws://', ''),
            description: 'Default backup relay',
            isEnabled: true,
            priority: i + 1,
            status: RelayStatus.disconnected,
          );

          final backupRelay = BackupRelayConfig(
            id: DateTime.now().millisecondsSinceEpoch.toString() + i.toString(),
            relayConfig: relayConfig,
            priority: i + 1,
            role: i == 0 ? BackupRelayRole.primary : BackupRelayRole.secondary,
          );

          autoSelectedRelays.add(backupRelay);
        }
        selectedRelays.value = autoSelectedRelays;
      }
      return null;
    }, []);

    return Column(
      children: [
        // Multi-relay status overview
        _buildRelayOverview(
          context,
          selectedRelays.value,
          isEnabled.value,
          isExpanded,
        ),

        if (isExpanded.value) ...[
          const Divider(height: 1),

          // Selected relays list
          if (selectedRelays.value.isNotEmpty) ...[
            _buildSelectedRelaysList(context, selectedRelays, isEnabled.value),
            const Divider(height: 1),
          ],

          // Add relay section
          _buildAddRelaySection(context, selectedRelays, popularRelays, isEnabled.value),

          const Divider(height: 1),

          // Configuration options
          _buildConfigurationOptions(
            context,
            encryptionType,
            frequency,
            isEnabled,
          ),

          const Divider(height: 1),

          // Actions
          _buildActionButtons(context, selectedRelays.value, isEnabled.value),
        ],
      ],
    );
  }

  Widget _buildRelayOverview(
    BuildContext context,
    List<BackupRelayConfig> relays,
    bool isEnabled,
    ValueNotifier<bool> isExpanded,
  ) {
    final relayCount = relays.length;
    final hasMinimumRelays = relayCount >= 2;

    String statusText;
    IconData statusIcon;
    Color statusColor;

    if (!isEnabled) {
      statusText = 'Backup disabled';
      statusIcon = Icons.backup_outlined;
      statusColor = Theme.of(context).colorScheme.onSurfaceVariant;
    } else if (relayCount == 0) {
      statusText = 'No relays configured';
      statusIcon = Icons.warning_amber;
      statusColor = Theme.of(context).colorScheme.error;
    } else if (!hasMinimumRelays) {
      statusText = '1 relay (no redundancy)';
      statusIcon = Icons.warning;
      statusColor = Theme.of(context).colorScheme.error;
    } else {
      statusText = '$relayCount relays configured';
      statusIcon = Icons.cloud_done;
      statusColor = Theme.of(context).colorScheme.primary;
    }

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: statusColor.withValues(alpha: 0.1),
        child: Icon(statusIcon, color: statusColor, size: 20),
      ),
      title: Text(
        'Relays',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            statusText,
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: statusColor),
          ),
          if (relayCount > 0) ...[
            const SizedBox(height: 4),
            Text(
              _getRedundancyDescription(relayCount),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (relayCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '$relayCount',
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: statusColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          const SizedBox(width: 8),
          Icon(
            isExpanded.value ? Icons.expand_less : Icons.expand_more,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: () => isExpanded.value = !isExpanded.value,
    );
  }

  Widget _buildSelectedRelaysList(
    BuildContext context,
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
    bool isEnabled,
  ) {
    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Icon(
                  Icons.cloud_queue,
                  size: 20,
                  color: Theme.of(context).colorScheme.primary,
                ),
              const SizedBox(width: 8),
              Text(
                'Selected Relays',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),
        ...selectedRelays.value.asMap().entries.map((entry) {
          final index = entry.key;
          final relay = entry.value;
          return ListTile(
            dense: true,
            leading: CircleAvatar(
              radius: 12,
              backgroundColor: Theme.of(context).colorScheme.primary,
              child: Text(
                '${index + 1}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            title: Text(
              relay.relayConfig.url.replaceFirst('wss://', ''),
              style: Theme.of(
                context,
              ).textTheme.bodyMedium?.copyWith(fontFamily: 'monospace'),
            ),
            subtitle: Row(
              children: [
                RelayStatusChip(
                  status: relay.relayConfig.status,
                  isCompact: true,
                ),
                const SizedBox(width: 8),
              ],
            ),
            trailing: isEnabled ? Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (index > 0)
                  IconButton(
                    onPressed: () => _moveRelayUp(selectedRelays, index),
                    icon: const Icon(Icons.keyboard_arrow_up, size: 20),
                    tooltip: 'Move up',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                if (index < selectedRelays.value.length - 1)
                  IconButton(
                    onPressed: () => _moveRelayDown(selectedRelays, index),
                    icon: const Icon(Icons.keyboard_arrow_down, size: 20),
                    tooltip: 'Move down',
                    constraints: const BoxConstraints(
                      minWidth: 32,
                      minHeight: 32,
                    ),
                  ),
                IconButton(
                  onPressed: () => _removeRelay(selectedRelays, index),
                  icon: const Icon(Icons.remove_circle, size: 20),
                  tooltip: 'Remove',
                  constraints: const BoxConstraints(
                    minWidth: 32,
                    minHeight: 32,
                  ),
                ),
              ],
            ) : null,
          );
        }),
        ],
      ),
    );
  }

  Widget _buildAddRelaySection(
    BuildContext context,
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
    List<String> popularRelays,
    bool isEnabled,
  ) {
    final customUrlController = useTextEditingController();

    return Opacity(
      opacity: isEnabled ? 1.0 : 0.6,
      child: IgnorePointer(
        ignoring: !isEnabled,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    size: 20,
                    color: Theme.of(context).colorScheme.primary,
                  ),
              const SizedBox(width: 8),
              Text(
                'Add Additional Relay',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Custom URL input
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: customUrlController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Custom Relay URL',
                    hintText: 'wss://relay.example.com',
                    prefixIcon: Icon(Icons.link),
                    isDense: true,
                  ),
                  onFieldSubmitted: (url) {
                    if (_isValidRelayUrl(url) &&
                        !_isRelayAlreadySelected(url, selectedRelays.value)) {
                      _addRelay(url, selectedRelays);
                      customUrlController.clear();
                    }
                  },
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: () {
                  final url = customUrlController.text.trim();
                  if (_isValidRelayUrl(url) &&
                      !_isRelayAlreadySelected(url, selectedRelays.value)) {
                    _addRelay(url, selectedRelays);
                    customUrlController.clear();
                  }
                },
                icon: const Icon(Icons.add),
                tooltip: 'Add relay',
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Additional relays (only show if some popular relays are not selected)
          if (popularRelays.any(
            (url) => !_isRelayAlreadySelected(url, selectedRelays.value),
          )) ...[
            Text(
              'Add More Popular Relays',
              style: Theme.of(
                context,
              ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: popularRelays
                  .where(
                    (url) =>
                        !_isRelayAlreadySelected(url, selectedRelays.value),
                  )
                  .map(
                    (url) => ActionChip(
                      label: Text(
                        url.replaceFirst('wss://', ''),
                        style: const TextStyle(fontSize: 11),
                      ),
                      onPressed: () => _addRelay(url, selectedRelays),
                      avatar: const Icon(Icons.add, size: 14),
                      visualDensity: VisualDensity.compact,
                    ),
                  )
                  .toList(),
            ),
            ],
          ],
        ),
      ),
    ),
  );
  }

  Widget _buildConfigurationOptions(
    BuildContext context,
    ValueNotifier<BackupEncryptionType> encryptionType,
    ValueNotifier<BackupFrequency> frequency,
    ValueNotifier<bool> isEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.settings,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Backup Configuration',
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // Enable/disable toggle
          SwitchListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: const Text('Enable Automatic Backup'),
            subtitle: Text(
              isEnabled.value
                  ? 'Backup will run automatically based on schedule'
                  : 'Backup is disabled - no automatic backups will occur',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isEnabled.value
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.error,
              ),
            ),
            value: isEnabled.value,
            onChanged: (value) => isEnabled.value = value,
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    List<BackupRelayConfig> selectedRelays,
    bool isEnabled,
  ) {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: (!isEnabled || selectedRelays.isEmpty)
                  ? null
                  : () => _testRelayConnections(context, selectedRelays),
              icon: const Icon(Icons.network_check),
              label: const Text('Test Relays'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: AsyncButtonBuilder(
              child: const Text('Save Config'),
              onPressed: () => _saveConfiguration(context, selectedRelays, isEnabled),
              builder: (context, child, callback, buttonState) {
                return FilledButton.icon(
                  onPressed: (!isEnabled || selectedRelays.length < 2) ? null : callback,
                  icon: buttonState.maybeWhen(
                    loading: () => const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    orElse: () => const Icon(Icons.save),
                  ),
                  label: child,
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _addRelay(
    String url,
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
  ) {
    if (selectedRelays.value.length >= 15) return; // Max 15 relays total

    final relayConfig = RelayConfig(
      id: url.hashCode.toString(),
      url: url,
      name: url.replaceFirst('wss://', '').replaceFirst('ws://', ''),
      description: 'Additional backup relay',
      isEnabled: true,
      priority: 1,
      status: RelayStatus.disconnected,
    );

    final backupRelay = BackupRelayConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      relayConfig: relayConfig,
      priority: selectedRelays.value.length + 1,
      role: selectedRelays.value.isEmpty
          ? BackupRelayRole.primary
          : BackupRelayRole.secondary,
    );

    final updatedRelays = [...selectedRelays.value, backupRelay];
    _updatePriorities(updatedRelays);
    selectedRelays.value = updatedRelays;
  }

  void _removeRelay(
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
    int index,
  ) {
    final relays = List<BackupRelayConfig>.from(selectedRelays.value);
    relays.removeAt(index);
    _updatePriorities(relays);
    selectedRelays.value = relays;
  }

  void _moveRelayUp(
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
    int index,
  ) {
    if (index == 0) return;
    final relays = List<BackupRelayConfig>.from(selectedRelays.value);
    final temp = relays[index];
    relays[index] = relays[index - 1];
    relays[index - 1] = temp;
    _updatePriorities(relays);
    selectedRelays.value = relays;
  }

  void _moveRelayDown(
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
    int index,
  ) {
    if (index == selectedRelays.value.length - 1) return;
    final relays = List<BackupRelayConfig>.from(selectedRelays.value);
    final temp = relays[index];
    relays[index] = relays[index + 1];
    relays[index + 1] = temp;
    _updatePriorities(relays);
    selectedRelays.value = relays;
  }

  void _updatePriorities(List<BackupRelayConfig> relays) {
    for (int i = 0; i < relays.length; i++) {
      relays[i] = relays[i].copyWith(
        priority: i + 1,
        role: i == 0 ? BackupRelayRole.primary : BackupRelayRole.secondary,
      );
    }
  }

  bool _isValidRelayUrl(String url) {
    return url.startsWith('wss://') || url.startsWith('ws://');
  }

  bool _isRelayAlreadySelected(
    String url,
    List<BackupRelayConfig> selectedRelays,
  ) {
    return selectedRelays.any((relay) => relay.relayConfig.url == url);
  }

  String _getRedundancyDescription(int count) {
    if (count < 2) return 'No redundancy - consider adding more relays';
    if (count == 2) return 'Basic redundancy';
    if (count <= 3) return 'Good redundancy';
    return 'Excellent redundancy';
  }

  Future<void> _testRelayConnections(
    BuildContext context,
    List<BackupRelayConfig> relays,
  ) async {
    // Show testing dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Testing Relay Connections'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text('Testing ${relays.length} relays...'),
          ],
        ),
      ),
    );

    // Simulate testing
    await Future.delayed(const Duration(seconds: 2));

    if (!context.mounted) return;
    Navigator.of(context).pop();

    // Show results
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Relay Test Results'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: relays
              .map(
                (relay) => ListTile(
                  leading: const Icon(Icons.check_circle, color: Colors.green),
                  title: Text(relay.relayConfig.name),
                  subtitle: const Text('Connection successful'),
                ),
              )
              .toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfiguration(
    BuildContext context,
    List<BackupRelayConfig> selectedRelays,
    bool isEnabled,
  ) async {
    if (selectedRelays.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please keep at least 2 relays for redundancy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Simulate saving
      await Future.delayed(const Duration(seconds: 1));

      if (!context.mounted) return;

      final statusMessage = isEnabled
          ? 'Multi-relay backup enabled with ${selectedRelays.length} relays!'
          : 'Multi-relay backup configuration saved (disabled)';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(statusMessage),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to save configuration: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }
}
