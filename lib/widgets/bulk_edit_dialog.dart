import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/time_limit_models.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/services/time_limit_management_service.dart';
import 'package:trottstr/widgets/country_selector.dart';
import 'package:trottstr/widgets/time_input_widgets.dart';
import 'package:trottstr/utils/country_flags.dart';

/// Dialog for bulk editing time limits across multiple countries
class BulkEditDialog extends HookConsumerWidget {
  final TimeLimitManagementService service;

  const BulkEditDialog({
    super.key,
    required this.service,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCountries = useState<List<String>>([]);
    final selectedTemplate = useState<String?>(null);
    final customLimits = useState<List<VisaTimeLimit>>([]);
    final notes = useTextEditingController();
    final isLoading = useState<bool>(false);
    final currentStep = useState<int>(0);
    final stepController = usePageController();

    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.edit_note,
                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Bulk Edit Time Limits',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                  ),
                ],
              ),
            ),

            // Progress indicator
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                children: [
                  for (int i = 0; i < 3; i++) ...[
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: currentStep.value >= i
                            ? Theme.of(context).colorScheme.primary
                            : Theme.of(context).colorScheme.outline,
                      ),
                      child: Center(
                        child: Text(
                          '${i + 1}',
                          style: TextStyle(
                            color: currentStep.value >= i
                                ? Theme.of(context).colorScheme.onPrimary
                                : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    if (i < 2)
                      Expanded(
                        child: Container(
                          height: 2,
                          color: currentStep.value > i
                              ? Theme.of(context).colorScheme.primary
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                  ],
                ],
              ),
            ),

            // Content
            Expanded(
              child: PageView(
                controller: stepController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _buildCountrySelectionStep(context, selectedCountries),
                  _buildConfigurationStep(
                    context,
                    ref,
                    selectedTemplate,
                    customLimits,
                    notes,
                  ),
                  _buildConfirmationStep(
                    context,
                    selectedCountries.value,
                    selectedTemplate.value,
                    customLimits.value,
                    notes.text,
                  ),
                ],
              ),
            ),

            // Navigation buttons
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).colorScheme.outline,
                    width: 0.5,
                  ),
                ),
              ),
              child: Row(
                children: [
                  if (currentStep.value > 0)
                    TextButton(
                      onPressed: isLoading.value
                          ? null
                          : () {
                              currentStep.value--;
                              stepController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            },
                      child: const Text('Back'),
                    ),
                  const Spacer(),
                  if (currentStep.value < 2)
                    FilledButton(
                      onPressed: _canProceed(currentStep.value, selectedCountries.value, customLimits.value)
                          ? () {
                              currentStep.value++;
                              stepController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeInOut,
                              );
                            }
                          : null,
                      child: const Text('Next'),
                    )
                  else
                    FilledButton(
                      onPressed: isLoading.value
                          ? null
                          : () => _executeBulkEdit(
                                context,
                                service,
                                selectedCountries.value,
                                selectedTemplate.value,
                                customLimits.value,
                                notes.text.trim(),
                                isLoading,
                              ),
                      child: isLoading.value
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Apply Changes'),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountrySelectionStep(
    BuildContext context,
    ValueNotifier<List<String>> selectedCountries,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 1: Select Countries',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose the countries you want to apply time limits to:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: _CountryMultiSelector(
              selectedCountries: selectedCountries.value,
              onSelectionChanged: (countries) {
                selectedCountries.value = countries;
              },
            ),
          ),
          if (selectedCountries.value.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${selectedCountries.value.length} countries selected',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildConfigurationStep(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<String?> selectedTemplate,
    ValueNotifier<List<VisaTimeLimit>> customLimits,
    TextEditingController notes,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 2: Configure Time Limits',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Choose how to configure the time limits:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _TemplateSelector(
                    service: service,
                    selectedTemplate: selectedTemplate.value,
                    onTemplateSelected: (templateId) {
                      selectedTemplate.value = templateId;
                      // Clear custom limits when template is selected
                      if (templateId != null) {
                        customLimits.value = [];
                      }
                    },
                  ),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                  Text(
                    'OR create custom configuration:',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 16),
                  _CustomLimitsEditor(
                    limits: customLimits.value,
                    onLimitsChanged: (limits) {
                      customLimits.value = limits;
                      // Clear template selection when custom limits are set
                      if (limits.isNotEmpty) {
                        selectedTemplate.value = null;
                      }
                    },
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: notes,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Notes (optional)',
                      helperText: 'Add any notes about this bulk update',
                      border: OutlineInputBorder(),
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

  Widget _buildConfirmationStep(
    BuildContext context,
    List<String> selectedCountries,
    String? selectedTemplate,
    List<VisaTimeLimit> customLimits,
    String notes,
  ) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Step 3: Confirm Changes',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Review the changes that will be applied:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 16),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Countries summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Countries (${selectedCountries.length})',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: selectedCountries.map((code) {
                              final name = DefaultTaxResidencyRules.getRuleForCountry(code)?.countryName ?? code;
                              return Chip(
                                avatar: Text(CountryFlags.getFlagOptimized(code)),
                                label: Text(name),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Configuration summary
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Configuration',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          const SizedBox(height: 8),
                          if (selectedTemplate != null)
                            ListTile(
                              leading: const Icon(Icons.category),
                              title: Text('Template: $selectedTemplate'),
                              contentPadding: EdgeInsets.zero,
                            )
                          else if (customLimits.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('Custom visa limits:'),
                                const SizedBox(height: 8),
                                ...customLimits.map((limit) => ListTile(
                                      leading: Text(
                                        limit.visaType.icon,
                                        style: const TextStyle(fontSize: 20),
                                      ),
                                      title: Text(limit.visaType.displayName),
                                      subtitle: Text(limit.limitDescription),
                                      contentPadding: EdgeInsets.zero,
                                    )),
                              ],
                            )
                          else
                            const Text('No configuration selected'),
                          if (notes.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Text('Notes: $notes'),
                          ],
                        ],
                      ),
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

  bool _canProceed(int step, List<String> countries, List<VisaTimeLimit> limits) {
    switch (step) {
      case 0:
        return countries.isNotEmpty;
      case 1:
        return limits.isNotEmpty; // Either template or custom limits
      default:
        return true;
    }
  }

  Future<void> _executeBulkEdit(
    BuildContext context,
    TimeLimitManagementService service,
    List<String> countryCodes,
    String? templateId,
    List<VisaTimeLimit> customLimits,
    String notes,
    ValueNotifier<bool> isLoading,
  ) async {
    isLoading.value = true;
    
    try {
      Map<String, bool> results;
      
      if (templateId != null) {
        // Apply template
        results = await service.applyTemplateToCountries(
          templateId: templateId,
          countryCodes: countryCodes,
          additionalNotes: notes.isEmpty ? null : notes,
        );
      } else {
        // Apply custom limits
        results = await service.bulkUpdateCountries(
          countryCodes: countryCodes,
          visaLimits: customLimits,
          notes: notes.isEmpty ? null : notes,
        );
      }

      final successCount = results.values.where((success) => success).length;
      final failureCount = results.length - successCount;

      if (context.mounted) {
        Navigator.of(context).pop();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              failureCount == 0
                  ? 'Successfully updated $successCount countries'
                  : 'Updated $successCount countries, $failureCount failed',
            ),
            backgroundColor: failureCount == 0 ? Colors.green : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error during bulk update: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isLoading.value = false;
    }
  }
}

/// Widget for selecting multiple countries
class _CountryMultiSelector extends HookWidget {
  final List<String> selectedCountries;
  final ValueChanged<List<String>> onSelectionChanged;

  const _CountryMultiSelector({
    required this.selectedCountries,
    required this.onSelectionChanged,
  });

  @override
  Widget build(BuildContext context) {
    final searchController = useTextEditingController();
    final searchQuery = useState<String>('');

    // Get all countries
    final allCountries = DefaultTaxResidencyRules.getAllCountries();
    final filteredCountries = useMemoized(() {
      if (searchQuery.value.isEmpty) return allCountries;
      
      return Map.fromEntries(
        allCountries.entries.where((entry) =>
          entry.key.toLowerCase().contains(searchQuery.value.toLowerCase()) ||
          entry.value.toLowerCase().contains(searchQuery.value.toLowerCase()),
        ),
      );
    }, [searchQuery.value]);

    return Column(
      children: [
        TextField(
          controller: searchController,
          decoration: const InputDecoration(
            labelText: 'Search countries',
            prefixIcon: Icon(Icons.search),
            border: OutlineInputBorder(),
          ),
          onChanged: (value) => searchQuery.value = value,
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            TextButton(
              onPressed: () => onSelectionChanged(filteredCountries.keys.toList()),
              child: const Text('Select All'),
            ),
            TextButton(
              onPressed: () => onSelectionChanged([]),
              child: const Text('Clear All'),
            ),
            const Spacer(),
            Text('${selectedCountries.length} selected'),
          ],
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ListView.builder(
            itemCount: filteredCountries.length,
            itemBuilder: (context, index) {
              final entry = filteredCountries.entries.elementAt(index);
              final code = entry.key;
              final name = entry.value;
              final isSelected = selectedCountries.contains(code);

              return CheckboxListTile(
                secondary: Text(
                  CountryFlags.getFlagOptimized(code),
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(name),
                subtitle: Text(code),
                value: isSelected,
                onChanged: (selected) {
                  final newSelection = List<String>.from(selectedCountries);
                  if (selected == true) {
                    newSelection.add(code);
                  } else {
                    newSelection.remove(code);
                  }
                  onSelectionChanged(newSelection);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// Widget for selecting templates
class _TemplateSelector extends HookConsumerWidget {
  final TimeLimitManagementService service;
  final String? selectedTemplate;
  final ValueChanged<String?> onTemplateSelected;

  const _TemplateSelector({
    required this.service,
    this.selectedTemplate,
    required this.onTemplateSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final templatesAsync = useFuture(useMemoized(() => service.getAllTemplates()));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Use Template',
          style: Theme.of(context).textTheme.titleSmall,
        ),
        const SizedBox(height: 8),
        if (templatesAsync.connectionState == ConnectionState.waiting)
          const Center(child: CircularProgressIndicator())
        else if (templatesAsync.hasError)
          Text('Error loading templates: ${templatesAsync.error}')
        else if (!templatesAsync.hasData || templatesAsync.data!.isEmpty)
          const Text('No templates available')
        else
          Column(
            children: templatesAsync.data!.map((template) {
              final isSelected = selectedTemplate == template.id;
              return Card(
                elevation: isSelected ? 4 : 1,
                color: isSelected
                    ? Theme.of(context).colorScheme.primaryContainer
                    : null,
                child: ListTile(
                  leading: Icon(
                    Icons.category,
                    color: isSelected
                        ? Theme.of(context).colorScheme.onPrimaryContainer
                        : null,
                  ),
                  title: Text(
                    template.name,
                    style: isSelected
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                            fontWeight: FontWeight.w600,
                          )
                        : null,
                  ),
                  subtitle: Text(
                    template.description,
                    style: isSelected
                        ? TextStyle(
                            color: Theme.of(context).colorScheme.onPrimaryContainer,
                          )
                        : null,
                  ),
                  trailing: Radio<String>(
                    value: template.id,
                    groupValue: selectedTemplate,
                    onChanged: onTemplateSelected,
                  ),
                  onTap: () => onTemplateSelected(
                    isSelected ? null : template.id,
                  ),
                ),
              );
            }).toList(),
          ),
      ],
    );
  }
}

/// Widget for editing custom limits
class _CustomLimitsEditor extends HookWidget {
  final List<VisaTimeLimit> limits;
  final ValueChanged<List<VisaTimeLimit>> onLimitsChanged;

  const _CustomLimitsEditor({
    required this.limits,
    required this.onLimitsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Custom Visa Limits',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
            FilledButton.icon(
              onPressed: () {
                final newLimits = List<VisaTimeLimit>.from(limits);
                newLimits.add(VisaTimeLimit(
                  visaType: VisaType.tourist,
                  maxStay: const TimeDuration(value: 90, unit: TimeUnit.days),
                  createdAt: DateTime.now(),
                ));
                onLimitsChanged(newLimits);
              },
              icon: const Icon(Icons.add),
              label: const Text('Add'),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (limits.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(color: Theme.of(context).colorScheme.outline),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Center(
              child: Text(
                'No custom limits defined.\nTap "Add" to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            ),
          )
        else
          ...limits.asMap().entries.map((entry) {
            final index = entry.key;
            final limit = entry.value;
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: VisaTimeLimitEditor(
                key: ValueKey('${limit.visaType}_$index'),
                initialLimit: limit,
                onChanged: (updatedLimit) {
                  final newLimits = List<VisaTimeLimit>.from(limits);
                  newLimits[index] = updatedLimit;
                  onLimitsChanged(newLimits);
                },
                onRemove: () {
                  final newLimits = List<VisaTimeLimit>.from(limits);
                  newLimits.removeAt(index);
                  onLimitsChanged(newLimits);
                },
              ),
            );
          }),
      ],
    );
  }
}