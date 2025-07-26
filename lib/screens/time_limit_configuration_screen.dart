import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/time_limit_models.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/services/time_limit_management_service.dart';
import 'package:trottstr/widgets/country_selector.dart';
import 'package:trottstr/widgets/time_input_widgets.dart';
import 'package:trottstr/widgets/bulk_edit_dialog.dart';
import 'package:trottstr/utils/country_flags.dart';

/// Main screen for configuring country-specific time limits
class TimeLimitConfigurationScreen extends HookConsumerWidget {
  final String? initialCountryCode;

  const TimeLimitConfigurationScreen({
    super.key,
    this.initialCountryCode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLimitService = ref.read(timeLimitManagementServiceProvider);
    final selectedCountryCode = useState<String?>(initialCountryCode);
    final selectedCountryName = useState<String?>(null);
    final currentConfig = useState<CountryTimeLimitConfig?>(null);
    final isLoading = useState<bool>(false);
    final tabController = useTabController(initialLength: 4);

    // Load configuration when country changes
    useEffect(() {
      if (selectedCountryCode.value != null) {
        _loadConfiguration(
          selectedCountryCode.value!,
          timeLimitService,
          currentConfig,
          isLoading,
        );
      }
      return null;
    }, [selectedCountryCode.value]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Time Limit Configuration'),
        actions: [
          if (currentConfig.value != null) ...[
            IconButton(
              onPressed: () => _showExportDialog(context, timeLimitService),
              icon: const Icon(Icons.download),
              tooltip: 'Export Configuration',
            ),
            IconButton(
              onPressed: () => _showHistoryDialog(
                context,
                timeLimitService,
                selectedCountryCode.value!,
              ),
              icon: const Icon(Icons.history),
              tooltip: 'View History',
            ),
          ],
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'bulk_edit':
                  _showBulkEditDialog(context, timeLimitService);
                  break;
                case 'templates':
                  _showTemplatesDialog(context, timeLimitService);
                  break;
                case 'statistics':
                  _showStatisticsDialog(context, timeLimitService);
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'bulk_edit',
                child: ListTile(
                  leading: Icon(Icons.edit_note),
                  title: Text('Bulk Edit'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'templates',
                child: ListTile(
                  leading: Icon(Icons.category),
                  title: Text('Templates'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              const PopupMenuItem(
                value: 'statistics',
                child: ListTile(
                  leading: Icon(Icons.analytics),
                  title: Text('Statistics'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
        bottom: selectedCountryCode.value != null
            ? TabBar(
                controller: tabController,
                tabs: const [
                  Tab(icon: Icon(Icons.edit), text: 'Configure'),
                  Tab(icon: Icon(Icons.card_travel), text: 'Visa Types'),
                  Tab(icon: Icon(Icons.info), text: 'Info'),
                  Tab(icon: Icon(Icons.preview), text: 'Preview'),
                ],
              )
            : null,
      ),
      body: Column(
        children: [
          // Country selector
          CountrySelector(
            selectedCountryCode: selectedCountryCode.value,
            onCountrySelected: (countryCode, countryName) {
              selectedCountryCode.value = countryCode;
              selectedCountryName.value = countryName;
            },
            hintText: 'Select a country to configure time limits',
          ),

          // Main content
          if (selectedCountryCode.value != null)
            Expanded(
              child: isLoading.value
                  ? const Center(child: CircularProgressIndicator())
                  : TabBarView(
                      controller: tabController,
                      children: [
                        _buildConfigurationTab(
                          context,
                          ref,
                          selectedCountryCode.value!,
                          selectedCountryName.value ?? selectedCountryCode.value!,
                          currentConfig,
                          timeLimitService,
                        ),
                        _buildVisaTypesTab(
                          context,
                          currentConfig,
                          timeLimitService,
                          selectedCountryCode.value!,
                          selectedCountryName.value ?? selectedCountryCode.value!,
                        ),
                        _buildInfoTab(
                          context,
                          selectedCountryCode.value!,
                          currentConfig.value,
                        ),
                        _buildPreviewTab(context, currentConfig.value),
                      ],
                    ),
            )
          else
            const Expanded(
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.map,
                      size: 64,
                      color: Colors.grey,
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Select a country to start configuring time limits',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildConfigurationTab(
    BuildContext context,
    WidgetRef ref,
    String countryCode,
    String countryName,
    ValueNotifier<CountryTimeLimitConfig?> currentConfig,
    TimeLimitManagementService timeLimitService,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CountryHeaderCard(
            countryCode: countryCode,
            countryName: countryName,
            config: currentConfig.value,
          ),
          const SizedBox(height: 16),
          _QuickActionsCard(
            countryCode: countryCode,
            countryName: countryName,
            onTemplateApplied: () => _loadConfiguration(
              countryCode,
              timeLimitService,
              currentConfig,
              ValueNotifier(false),
            ),
          ),
          const SizedBox(height: 16),
          _DefaultLimitCard(
            config: currentConfig.value,
            onChanged: (limit) => _updateDefaultLimit(
              countryCode,
              countryName,
              limit,
              currentConfig,
              timeLimitService,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisaTypesTab(
    BuildContext context,
    ValueNotifier<CountryTimeLimitConfig?> currentConfig,
    TimeLimitManagementService timeLimitService,
    String countryCode,
    String countryName,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _VisaTypesManager(
            config: currentConfig.value,
            onConfigChanged: (newConfig) {
              currentConfig.value = newConfig;
              _saveConfiguration(newConfig, timeLimitService);
            },
            countryCode: countryCode,
            countryName: countryName,
          ),
        ],
      ),
    );
  }

  Widget _buildInfoTab(
    BuildContext context,
    String countryCode,
    CountryTimeLimitConfig? config,
  ) {
    final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (rule != null)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Default Tax Residency Rules',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(rule.description),
                    if (rule.additionalNotes != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        rule.additionalNotes!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                    const SizedBox(height: 8),
                    Chip(
                      label: Text('${rule.daysThreshold} days threshold'),
                    ),
                  ],
                ),
              ),
            ),
          if (config != null) ...[
            const SizedBox(height: 16),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Configuration',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text('Created: ${_formatDateTime(config.createdAt)}'),
                    if (config.updatedAt != null)
                      Text('Updated: ${_formatDateTime(config.updatedAt!)}'),
                    if (config.notes != null) ...[
                      const SizedBox(height: 8),
                      Text('Notes: ${config.notes}'),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewTab(BuildContext context, CountryTimeLimitConfig? config) {
    if (config == null) {
      return const Center(
        child: Text('No configuration to preview'),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Configuration Preview',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          ...config.visaLimits.map((limit) => Card(
                child: ListTile(
                  leading: Text(
                    limit.visaType.icon,
                    style: const TextStyle(fontSize: 24),
                  ),
                  title: Text(limit.visaType.displayName),
                  subtitle: Text(limit.limitDescription),
                  trailing: limit.isDefault
                      ? const Chip(label: Text('DEFAULT'))
                      : null,
                ),
              )),
        ],
      ),
    );
  }

  Future<void> _loadConfiguration(
    String countryCode,
    TimeLimitManagementService service,
    ValueNotifier<CountryTimeLimitConfig?> currentConfig,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    try {
      final config = await service.getConfigurationForCountry(countryCode);
      currentConfig.value = config;
    } catch (e) {
      debugPrint('Error loading configuration: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _saveConfiguration(
    CountryTimeLimitConfig config,
    TimeLimitManagementService service,
  ) async {
    try {
      await service.setCountryConfiguration(config);
    } catch (e) {
      debugPrint('Error saving configuration: $e');
    }
  }

  Future<void> _updateDefaultLimit(
    String countryCode,
    String countryName,
    VisaTimeLimit limit,
    ValueNotifier<CountryTimeLimitConfig?> currentConfig,
    TimeLimitManagementService service,
  ) async {
    final config = currentConfig.value ??
        CountryTimeLimitConfig(
          countryCode: countryCode,
          countryName: countryName,
          visaLimits: [],
          createdAt: DateTime.now(),
        );

    final updatedLimits = List<VisaTimeLimit>.from(config.visaLimits);
    final existingIndex = updatedLimits.indexWhere(
      (l) => l.visaType == limit.visaType,
    );

    if (existingIndex >= 0) {
      updatedLimits[existingIndex] = limit;
    } else {
      updatedLimits.add(limit);
    }

    final updatedConfig = config.copyWith(
      visaLimits: updatedLimits,
      updatedAt: DateTime.now(),
    );

    currentConfig.value = updatedConfig;
    await _saveConfiguration(updatedConfig, service);
  }

  void _showExportDialog(BuildContext context, TimeLimitManagementService service) {
    // Implementation for export dialog
    showDialog(
      context: context,
      builder: (context) => _ExportDialog(service: service),
    );
  }

  void _showHistoryDialog(
    BuildContext context,
    TimeLimitManagementService service,
    String countryCode,
  ) {
    // Implementation for history dialog
    showDialog(
      context: context,
      builder: (context) => _HistoryDialog(
        service: service,
        countryCode: countryCode,
      ),
    );
  }

  void _showBulkEditDialog(BuildContext context, TimeLimitManagementService service) {
    showDialog(
      context: context,
      builder: (context) => BulkEditDialog(service: service),
    );
  }

  void _showTemplatesDialog(BuildContext context, TimeLimitManagementService service) {
    // Implementation for templates dialog
    showDialog(
      context: context,
      builder: (context) => _TemplatesDialog(service: service),
    );
  }

  void _showStatisticsDialog(BuildContext context, TimeLimitManagementService service) {
    // Implementation for statistics dialog
    showDialog(
      context: context,
      builder: (context) => _StatisticsDialog(service: service),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
  }
}

/// Widget for displaying country header information
class _CountryHeaderCard extends StatelessWidget {
  final String countryCode;
  final String countryName;
  final CountryTimeLimitConfig? config;

  const _CountryHeaderCard({
    required this.countryCode,
    required this.countryName,
    this.config,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Text(
              CountryFlags.getFlagOptimized(countryCode),
              style: const TextStyle(fontSize: 48),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    countryName,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    countryCode,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if (config != null) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: [
                        Chip(
                          label: Text('${config!.visaLimits.length} visa types'),
                        ),
                        if (config!.hasCustomConfiguration)
                          const Chip(
                            label: Text('CUSTOM'),
                            backgroundColor: Colors.blue,
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Widget for quick actions and templates
class _QuickActionsCard extends HookConsumerWidget {
  final String countryCode;
  final String countryName;
  final VoidCallback? onTemplateApplied;

  const _QuickActionsCard({
    required this.countryCode,
    required this.countryName,
    this.onTemplateApplied,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final timeLimitService = ref.read(timeLimitManagementServiceProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => _applySchengenTemplate(timeLimitService),
                  icon: const Icon(Icons.euro),
                  label: const Text('Schengen Rules'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _applyUSTemplate(timeLimitService),
                  icon: const Icon(Icons.flag),
                  label: const Text('US Rules'),
                ),
                ElevatedButton.icon(
                  onPressed: () => _applyNomadTemplate(timeLimitService),
                  icon: const Icon(Icons.laptop),
                  label: const Text('Nomad Friendly'),
                ),
                OutlinedButton.icon(
                  onPressed: () => _clearConfiguration(timeLimitService),
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear All'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _applySchengenTemplate(TimeLimitManagementService service) async {
    try {
      await service.applyTemplateToCountries(
        templateId: 'schengen_tourist',
        countryCodes: [countryCode],
      );
      onTemplateApplied?.call();
    } catch (e) {
      debugPrint('Error applying Schengen template: $e');
    }
  }

  Future<void> _applyUSTemplate(TimeLimitManagementService service) async {
    try {
      await service.applyTemplateToCountries(
        templateId: 'us_standard',
        countryCodes: [countryCode],
      );
      onTemplateApplied?.call();
    } catch (e) {
      debugPrint('Error applying US template: $e');
    }
  }

  Future<void> _applyNomadTemplate(TimeLimitManagementService service) async {
    try {
      await service.applyTemplateToCountries(
        templateId: 'nomad_friendly',
        countryCodes: [countryCode],
      );
      onTemplateApplied?.call();
    } catch (e) {
      debugPrint('Error applying nomad template: $e');
    }
  }

  Future<void> _clearConfiguration(TimeLimitManagementService service) async {
    try {
      await service.removeCountryConfiguration(countryCode);
      onTemplateApplied?.call();
    } catch (e) {
      debugPrint('Error clearing configuration: $e');
    }
  }
}

/// Widget for managing default time limit
class _DefaultLimitCard extends HookWidget {
  final CountryTimeLimitConfig? config;
  final ValueChanged<VisaTimeLimit>? onChanged;

  const _DefaultLimitCard({
    this.config,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final defaultLimit = config?.defaultVisaLimit;
    final showEditor = useState<bool>(false);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Default Time Limit',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                if (defaultLimit != null)
                  IconButton(
                    onPressed: () => showEditor.value = !showEditor.value,
                    icon: Icon(showEditor.value ? Icons.close : Icons.edit),
                  )
                else
                  FilledButton(
                    onPressed: () => showEditor.value = true,
                    child: const Text('Add Default'),
                  ),
              ],
            ),
            if (defaultLimit != null && !showEditor.value) ...[
              const SizedBox(height: 12),
              ListTile(
                leading: Text(
                  defaultLimit.visaType.icon,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(defaultLimit.visaType.displayName),
                subtitle: Text(defaultLimit.limitDescription),
                contentPadding: EdgeInsets.zero,
              ),
            ],
            if (showEditor.value) ...[
              const SizedBox(height: 16),
              VisaTimeLimitEditor(
                initialLimit: defaultLimit,
                showRemoveButton: false,
                onChanged: (limit) {
                  final updatedLimit = limit.copyWith(isDefault: true);
                  onChanged?.call(updatedLimit);
                  showEditor.value = false;
                },
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Widget for managing visa types
class _VisaTypesManager extends HookWidget {
  final CountryTimeLimitConfig? config;
  final ValueChanged<CountryTimeLimitConfig>? onConfigChanged;
  final String countryCode;
  final String countryName;

  const _VisaTypesManager({
    this.config,
    this.onConfigChanged,
    required this.countryCode,
    required this.countryName,
  });

  @override
  Widget build(BuildContext context) {
    final visaLimits = useState<List<VisaTimeLimit>>(
      config?.visaLimits ?? [],
    );

    void updateConfig() {
      final newConfig = (config ??
              CountryTimeLimitConfig(
                countryCode: countryCode,
                countryName: countryName,
                visaLimits: [],
                createdAt: DateTime.now(),
              ))
          .copyWith(
        visaLimits: visaLimits.value,
        updatedAt: DateTime.now(),
      );
      onConfigChanged?.call(newConfig);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Visa Types Configuration',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                visaLimits.value = [
                  ...visaLimits.value,
                  VisaTimeLimit(
                    visaType: VisaType.tourist,
                    maxStay: const TimeDuration(value: 90, unit: TimeUnit.days),
                    createdAt: DateTime.now(),
                  ),
                ];
                updateConfig();
              },
              icon: const Icon(Icons.add),
              label: const Text('Add Visa Type'),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...visaLimits.value.asMap().entries.map((entry) {
          final index = entry.key;
          final limit = entry.value;
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: VisaTimeLimitEditor(
              key: ValueKey(limit.visaType),
              initialLimit: limit,
              onChanged: (updatedLimit) {
                final newLimits = List<VisaTimeLimit>.from(visaLimits.value);
                newLimits[index] = updatedLimit;
                visaLimits.value = newLimits;
                updateConfig();
              },
              onRemove: () {
                visaLimits.value = visaLimits.value
                    .where((l) => l.visaType != limit.visaType)
                    .toList();
                updateConfig();
              },
            ),
          );
        }),
        if (visaLimits.value.isEmpty)
          const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No visa types configured.\nTap "Add Visa Type" to get started.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          ),
      ],
    );
  }
}

// Placeholder dialogs (would be implemented as separate files)
class _ExportDialog extends StatelessWidget {
  final TimeLimitManagementService service;

  const _ExportDialog({required this.service});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Export Configuration'),
      content: const Text('Export functionality would be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _HistoryDialog extends StatelessWidget {
  final TimeLimitManagementService service;
  final String countryCode;

  const _HistoryDialog({required this.service, required this.countryCode});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configuration History'),
      content: const Text('History functionality would be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}


class _TemplatesDialog extends StatelessWidget {
  final TimeLimitManagementService service;

  const _TemplatesDialog({required this.service});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Templates'),
      content: const Text('Templates functionality would be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}

class _StatisticsDialog extends StatelessWidget {
  final TimeLimitManagementService service;

  const _StatisticsDialog({required this.service});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Statistics'),
      content: const Text('Statistics functionality would be implemented here.'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    );
  }
}