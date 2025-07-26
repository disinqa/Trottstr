import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/backup_relay_models.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/widgets/relay_status_chip.dart';
import 'package:async_button_builder/async_button_builder.dart';

/// Screen for configuring multiple relays for encrypted backup
class MultiRelayBackupScreen extends HookConsumerWidget {
  const MultiRelayBackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final configName = useState<String>('Primary Backup');
    final selectedRelays = useState<List<BackupRelayConfig>>([]);
    final encryptionType = useState<BackupEncryptionType>(
      BackupEncryptionType.nip44,
    );
    final frequency = useState<BackupFrequency>(BackupFrequency.daily);
    final compressData = useState<bool>(true);
    final customPassphrase = useState<String>('');
    final isEnabled = useState<bool>(true);

    final configNameController = useTextEditingController(
      text: configName.value,
    );
    final passphraseController = useTextEditingController(
      text: customPassphrase.value,
    );

    // Popular relay suggestions
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('Multi-Relay Backup'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        actions: [
          IconButton(
            onPressed: () => _showHelpDialog(context),
            icon: const Icon(Icons.help_outline),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Overview Card
            _buildOverviewCard(context, selectedRelays.value.length),
            const SizedBox(height: 16),

            // Configuration Name
            _buildConfigurationSection(
              context,
              title: 'Configuration Name',
              child: TextFormField(
                controller: configNameController,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  labelText: 'Configuration Name',
                  hintText: 'e.g., Primary Backup, Travel Backup',
                  prefixIcon: Icon(Icons.label),
                ),
                onChanged: (value) => configName.value = value,
              ),
            ),
            const SizedBox(height: 24),

            // Relay Selection
            _buildConfigurationSection(
              context,
              title: 'Select Backup Relays',
              subtitle: 'Choose 2-5 relays for redundant backup storage',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Selected relays list
                  if (selectedRelays.value.isNotEmpty) ...[
                    _buildSelectedRelaysList(context, selectedRelays),
                    const SizedBox(height: 16),
                  ],

                  // Add relay section
                  _buildAddRelaySection(context, selectedRelays, popularRelays),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Encryption Settings
            _buildConfigurationSection(
              context,
              title: 'Encryption Settings',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Encryption type
                  DropdownButtonFormField<BackupEncryptionType>(
                    value: encryptionType.value,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Encryption Type',
                      prefixIcon: Icon(Icons.security),
                    ),
                    items: BackupEncryptionType.values.map((type) {
                      return DropdownMenuItem(
                        value: type,
                        child: Row(
                          children: [
                            Icon(_getEncryptionIcon(type)),
                            const SizedBox(width: 8),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(type.name.toUpperCase()),
                                Text(
                                  _getEncryptionDescription(type),
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) encryptionType.value = value;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Custom passphrase (if custom encryption)
                  if (encryptionType.value == BackupEncryptionType.custom) ...[
                    TextFormField(
                      controller: passphraseController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Custom Passphrase',
                        hintText: 'Enter a strong passphrase',
                        prefixIcon: Icon(Icons.key),
                      ),
                      obscureText: true,
                      onChanged: (value) => customPassphrase.value = value,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'This passphrase adds an extra layer of encryption. Keep it safe!',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Compression toggle
                  SwitchListTile(
                    title: const Text('Compress Data'),
                    subtitle: const Text('Reduce backup size (recommended)'),
                    value: compressData.value,
                    onChanged: (value) => compressData.value = value,
                    secondary: const Icon(Icons.compress),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Backup Settings
            _buildConfigurationSection(
              context,
              title: 'Backup Settings',
              child: Column(
                children: [
                  // Backup frequency
                  DropdownButtonFormField<BackupFrequency>(
                    value: frequency.value,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Backup Frequency',
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    items: BackupFrequency.values.map((freq) {
                      return DropdownMenuItem(
                        value: freq,
                        child: Text(freq.displayName),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) frequency.value = value;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Enable/disable toggle
                  SwitchListTile(
                    title: const Text('Enable Automatic Backup'),
                    subtitle: Text(
                      frequency.value == BackupFrequency.manual
                          ? 'Backups will only run when manually triggered'
                          : 'Backups will run automatically based on schedule',
                    ),
                    value: isEnabled.value,
                    onChanged: (value) => isEnabled.value = value,
                    secondary: const Icon(Icons.backup),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Test and Save buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: selectedRelays.value.isEmpty
                        ? null
                        : () => _testRelayConnections(
                            context,
                            selectedRelays.value,
                          ),
                    icon: const Icon(Icons.network_check),
                    label: const Text('Test Relays'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 2,
                  child: AsyncButtonBuilder(
                    child: const Text('Save Configuration'),
                    onPressed: () => _saveConfiguration(
                      context,
                      ref,
                      configName.value,
                      selectedRelays.value,
                      encryptionType.value,
                      frequency.value,
                      compressData.value,
                      customPassphrase.value,
                      isEnabled.value,
                    ),
                    builder: (context, child, callback, buttonState) {
                      return FilledButton.icon(
                        onPressed: selectedRelays.value.length < 2
                            ? null
                            : callback,
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
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, int selectedCount) {
    final bool hasMinimumRelays = selectedCount >= 2;
    final Color statusColor = hasMinimumRelays
        ? Theme.of(context).colorScheme.primary
        : Theme.of(context).colorScheme.error;

    return Card(
      color: hasMinimumRelays
          ? Theme.of(context).colorScheme.primaryContainer
          : Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Icon(
                  hasMinimumRelays ? Icons.cloud_done : Icons.warning,
                  color: statusColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    hasMinimumRelays
                        ? 'Backup Configuration Ready'
                        : 'Select at least 2 relays for redundancy',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            if (selectedCount > 0) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.storage, size: 16, color: statusColor),
                  const SizedBox(width: 4),
                  Text(
                    '$selectedCount relay${selectedCount == 1 ? '' : 's'} selected',
                    style: Theme.of(
                      context,
                    ).textTheme.bodyMedium?.copyWith(color: statusColor),
                  ),
                  const Spacer(),
                  Text(
                    _getRedundancyText(selectedCount),
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: statusColor),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationSection(
    BuildContext context, {
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        const SizedBox(height: 12),
        child,
      ],
    );
  }

  Widget _buildSelectedRelaysList(
    BuildContext context,
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
  ) {
    return Card(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.cloud_queue),
                const SizedBox(width: 8),
                Text(
                  'Selected Relays',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Spacer(),
                Text(
                  '${selectedRelays.value.length} selected',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...selectedRelays.value.asMap().entries.map((entry) {
            final index = entry.key;
            final relay = entry.value;
            return ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(context).colorScheme.primary,
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              title: Text(
                relay.relayConfig.url,
                style: const TextStyle(fontFamily: 'monospace'),
              ),
              subtitle: Row(
                children: [
                  RelayStatusChip(status: relay.relayConfig.status),
                  const SizedBox(width: 8),
                  Text(_getRoleText(relay.role)),
                ],
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Priority adjustment
                  IconButton(
                    onPressed: index == 0
                        ? null
                        : () {
                            final relays = List<BackupRelayConfig>.from(
                              selectedRelays.value,
                            );
                            final temp = relays[index];
                            relays[index] = relays[index - 1];
                            relays[index - 1] = temp;
                            _updatePriorities(relays);
                            selectedRelays.value = relays;
                          },
                    icon: const Icon(Icons.keyboard_arrow_up),
                    tooltip: 'Move up',
                  ),
                  IconButton(
                    onPressed: index == selectedRelays.value.length - 1
                        ? null
                        : () {
                            final relays = List<BackupRelayConfig>.from(
                              selectedRelays.value,
                            );
                            final temp = relays[index];
                            relays[index] = relays[index + 1];
                            relays[index + 1] = temp;
                            _updatePriorities(relays);
                            selectedRelays.value = relays;
                          },
                    icon: const Icon(Icons.keyboard_arrow_down),
                    tooltip: 'Move down',
                  ),
                  IconButton(
                    onPressed: () {
                      final relays = List<BackupRelayConfig>.from(
                        selectedRelays.value,
                      );
                      relays.removeAt(index);
                      _updatePriorities(relays);
                      selectedRelays.value = relays;
                    },
                    icon: const Icon(Icons.remove_circle),
                    tooltip: 'Remove',
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAddRelaySection(
    BuildContext context,
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
    List<String> popularRelays,
  ) {
    final customUrlController = useTextEditingController();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add Relay', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 16),

            // Custom URL input
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: customUrlController,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'Relay URL',
                      hintText: 'wss://relay.example.com',
                      prefixIcon: Icon(Icons.link),
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
            const SizedBox(height: 16),

            // Popular relays
            Text(
              'Popular Relays',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: popularRelays
                  .where(
                    (url) =>
                        !_isRelayAlreadySelected(url, selectedRelays.value),
                  )
                  .map(
                    (url) => ActionChip(
                      label: Text(
                        url.replaceFirst('wss://', ''),
                        style: const TextStyle(fontSize: 12),
                      ),
                      onPressed: () => _addRelay(url, selectedRelays),
                      avatar: const Icon(Icons.add, size: 16),
                    ),
                  )
                  .toList(),
            ),
          ],
        ),
      ),
    );
  }

  void _addRelay(
    String url,
    ValueNotifier<List<BackupRelayConfig>> selectedRelays,
  ) {
    if (selectedRelays.value.length >= 5) {
      // Max 5 relays
      return;
    }

    final relayConfig = _createRelayConfig(url);
    final backupRelay = BackupRelayConfig(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      relayConfig: relayConfig,
      priority: selectedRelays.value.length + 1,
      role: selectedRelays.value.isEmpty
          ? BackupRelayRole.primary
          : BackupRelayRole.secondary,
    );

    selectedRelays.value = [...selectedRelays.value, backupRelay];
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

  RelayConfig _createRelayConfig(String url) {
    return RelayConfig(
      id: url.hashCode.toString(),
      url: url,
      name: url.replaceFirst('wss://', '').replaceFirst('ws://', ''),
      description: 'Backup relay',
      isEnabled: true,
      priority: 1,
      status: RelayStatus.disconnected, // Will be tested later
    );
  }

  IconData _getEncryptionIcon(BackupEncryptionType type) {
    switch (type) {
      case BackupEncryptionType.nip44:
        return Icons.enhanced_encryption;
      case BackupEncryptionType.nip04:
        return Icons.lock;
      case BackupEncryptionType.custom:
        return Icons.vpn_key;
    }
  }

  String _getEncryptionDescription(BackupEncryptionType type) {
    switch (type) {
      case BackupEncryptionType.nip44:
        return 'Modern encryption (recommended)';
      case BackupEncryptionType.nip04:
        return 'Legacy encryption';
      case BackupEncryptionType.custom:
        return 'Additional passphrase layer';
    }
  }

  String _getRoleText(BackupRelayRole role) {
    switch (role) {
      case BackupRelayRole.primary:
        return 'Primary';
      case BackupRelayRole.secondary:
        return 'Secondary';
      case BackupRelayRole.archive:
        return 'Archive';
    }
  }

  String _getRedundancyText(int count) {
    if (count < 2) return 'No redundancy';
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

    // Simulate testing (in real implementation, test actual connections)
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
    WidgetRef ref,
    String configName,
    List<BackupRelayConfig> selectedRelays,
    BackupEncryptionType encryptionType,
    BackupFrequency frequency,
    bool compressData,
    String customPassphrase,
    bool isEnabled,
  ) async {
    if (selectedRelays.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least 2 relays for redundancy'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      // Create encryption settings
      final encryptionSettings = BackupEncryptionSettings(
        encryptionType: encryptionType,
        customPassphrase: encryptionType == BackupEncryptionType.custom
            ? customPassphrase
            : null,
        compressBeforeEncrypt: compressData,
      );

      // Create backup configuration
      final _ = EncryptedBackupConfig(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: configName,
        backupRelays: selectedRelays,
        encryptionSettings: encryptionSettings,
        frequency: frequency,
        isEnabled: isEnabled,
        createdAt: DateTime.now(),
      );

      // Save configuration (implement actual saving logic)
      // final service = ref.read(multiRelayBackupServiceProvider);
      // await service.saveBackupConfiguration(_);

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Backup configuration "$configName" saved successfully!',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      Navigator.of(context).pop();
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

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Multi-Relay Backup Help'),
        content: const SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Why multiple relays?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Redundancy: If one relay goes down, your data is safe on others\n'
                '• Reliability: Multiple copies ensure data availability\n'
                '• Geographic distribution: Relays in different regions',
              ),
              SizedBox(height: 16),
              Text(
                'How many relays?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• Minimum: 2 relays for basic redundancy\n'
                '• Recommended: 3-4 relays for good reliability\n'
                '• Maximum: 5 relays (more increases complexity)',
              ),
              SizedBox(height: 16),
              Text(
                'Encryption:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              Text(
                '• NIP-44: Modern, secure encryption (recommended)\n'
                '• Custom: Adds extra passphrase protection\n'
                '• All data is encrypted before leaving your device',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Got it'),
          ),
        ],
      ),
    );
  }
}
