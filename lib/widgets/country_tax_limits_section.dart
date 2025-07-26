import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/utils/country_flags.dart';
import 'package:trottstr/providers/country_tax_limits_provider.dart';

/// Widget for managing per-country tax residency limits
class CountryTaxLimitsSection extends HookConsumerWidget {
  const CountryTaxLimitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryLimits = ref.watch(countryTaxLimitsProvider);
    final countryLimitsNotifier = ref.read(countryTaxLimitsProvider.notifier);
    final isExpanded = useState<bool>(false);

    return Column(
      children: [
        // Overview tile
        _buildOverviewTile(context, countryLimits, isExpanded),
        
        if (isExpanded.value) ...[
          const Divider(height: 1),
          
          // Add new country section
          _buildAddCountrySection(context, ref),
          
          const Divider(height: 1),
          
          // Countries list
          if (countryLimits.isNotEmpty) ...[
            _buildCountriesList(context, countryLimits, ref),
          ],
        ],
      ],
    );
  }

  Widget _buildOverviewTile(
    BuildContext context,
    Map<String, int> limits,
    ValueNotifier<bool> isExpanded,
  ) {
    final customCount = limits.entries.where((e) => e.value != 183).length;
    final defaultCount = limits.length - customCount;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.public,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        'Country Tax Limits',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${limits.length} countries configured',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (customCount > 0) ...[
            const SizedBox(height: 2),
            Text(
              '$customCount custom limits, $defaultCount default (183 days)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ],
      ),
      trailing: Icon(
        isExpanded.value ? Icons.expand_less : Icons.expand_more,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
      onTap: () => isExpanded.value = !isExpanded.value,
    );
  }

  Widget _buildAddCountrySection(
    BuildContext context,
    WidgetRef ref,
  ) {
    final countryController = useTextEditingController();
    final daysController = useTextEditingController(text: '183');

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.add_location,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Add Country Limit',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: [
              // Country code input
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: countryController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Country Code',
                    hintText: 'e.g., US, DE, FR',
                    prefixIcon: Icon(Icons.flag),
                    isDense: true,
                  ),
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    LengthLimitingTextInputFormatter(2),
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z]')),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              
              // Days limit input
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: daysController,
                  decoration: const InputDecoration(
                    border: OutlineInputBorder(),
                    labelText: 'Days Limit',
                    hintText: '183',
                    prefixIcon: Icon(Icons.calendar_today),
                    isDense: true,
                  ),
                  keyboardType: TextInputType.number,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(3),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              
              // Add button
              IconButton(
                onPressed: () => _addCountryLimit(
                  context,
                  countryController,
                  daysController,
                  ref,
                ),
                icon: const Icon(Icons.add),
                tooltip: 'Add country',
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          Text(
            'Enter the 2-letter country code and maximum days before tax residency',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountriesList(
    BuildContext context,
    Map<String, int> countryLimits,
    WidgetRef ref,
  ) {
    final sortedEntries = countryLimits.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(
                Icons.list,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Configured Countries',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        ...sortedEntries.map((entry) {
          final countryCode = entry.key;
          final daysLimit = entry.value;
          final isCustom = daysLimit != 183;
          
          return ListTile(
            dense: true,
            leading: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  CountryFlags.getFlagOptimized(countryCode),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 8),
                Text(
                  countryCode,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontFamily: 'monospace',
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            title: Text(
              '$daysLimit days',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: isCustom 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurface,
                fontWeight: isCustom ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            subtitle: Text(
              isCustom ? 'Custom limit' : 'Default limit',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: isCustom 
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Edit button
                IconButton(
                  onPressed: () => _editCountryLimit(
                    context,
                    countryCode,
                    daysLimit,
                    ref,
                  ),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit limit',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
                // Remove button
                IconButton(
                  onPressed: () => _removeCountryLimit(
                    context,
                    countryCode,
                    ref,
                  ),
                  icon: const Icon(Icons.remove_circle, size: 20),
                  tooltip: 'Remove country',
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  void _addCountryLimit(
    BuildContext context,
    TextEditingController countryController,
    TextEditingController daysController,
    WidgetRef ref,
  ) {
    final countryCode = countryController.text.trim().toUpperCase();
    final daysText = daysController.text.trim();

    if (countryCode.length != 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid 2-letter country code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final days = int.tryParse(daysText);
    if (days == null || days <= 0 || days > 365) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid number of days (1-365)'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final currentLimits = ref.read(countryTaxLimitsProvider);
    if (currentLimits.containsKey(countryCode)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$countryCode is already configured'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Add the country using the provider
    ref.read(countryTaxLimitsProvider.notifier).setCountryLimit(countryCode, days);

    // Clear the form
    countryController.clear();
    daysController.text = '183';

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Added $countryCode with $days days limit'),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }

  void _editCountryLimit(
    BuildContext context,
    String countryCode,
    int currentLimit,
    WidgetRef ref,
  ) {
    final daysController = TextEditingController(text: currentLimit.toString());

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(CountryFlags.getFlagOptimized(countryCode)),
            const SizedBox(width: 8),
            Text('Edit $countryCode Limit'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              controller: daysController,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Days Limit',
                hintText: '183',
                prefixIcon: Icon(Icons.calendar_today),
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'Maximum days before becoming tax resident in $countryCode',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final daysText = daysController.text.trim();
              final days = int.tryParse(daysText);
              
              if (days == null || days <= 0 || days > 365) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Please enter a valid number of days (1-365)'),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              // Update the limit using the provider
              ref.read(countryTaxLimitsProvider.notifier).setCountryLimit(countryCode, days);

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Updated $countryCode limit to $days days'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _removeCountryLimit(
    BuildContext context,
    String countryCode,
    WidgetRef ref,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Remove $countryCode'),
        content: Text(
          'Are you sure you want to remove the tax limit configuration for $countryCode?\n\n'
          'The default 183-day limit will be used for this country.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              // Remove the country using the provider
              ref.read(countryTaxLimitsProvider.notifier).removeCountryLimit(countryCode);

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Removed $countryCode configuration'),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            child: const Text('Remove'),
          ),
        ],
      ),
    );
  }
}