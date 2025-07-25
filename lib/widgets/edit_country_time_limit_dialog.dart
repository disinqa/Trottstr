import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/custom_country_settings.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/providers/country_tracking_providers.dart';
import 'package:trottstr/services/custom_country_settings_service.dart';
import 'package:trottstr/utils/country_flags.dart';

/// Dialog for editing custom time limits for a country
class EditCountryTimeLimitDialog extends HookConsumerWidget {
  final String countryCode;
  final String countryName;

  const EditCountryTimeLimitDialog({
    super.key,
    required this.countryCode,
    required this.countryName,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customSettingsService = ref.read(customCountrySettingsServiceProvider);
    final customSettingsAsync = ref.watch(customSettingsForCountryProvider(countryCode));
    final effectiveTimeLimitAsync = ref.watch(effectiveTimeLimitProvider(countryCode));
    
    final daysController = useTextEditingController();
    final notesController = useTextEditingController();
    final isLoading = useState(false);
    
    // Get default rule for reference
    final defaultRule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);
    final defaultThreshold = defaultRule?.daysThreshold ?? DefaultTaxResidencyRules.defaultThreshold;

    // Initialize controllers with current values
    useEffect(() {
      customSettingsAsync.whenData((customSettings) {
        if (customSettings != null) {
          daysController.text = customSettings.customDaysThreshold.toString();
          notesController.text = customSettings.notes ?? '';
        } else {
          // Use default threshold as starting point
          daysController.text = defaultThreshold.toString();
          notesController.text = '';
        }
      });
      return null;
    }, [customSettingsAsync]);

    return AlertDialog(
      title: Row(
        children: [
          Text(
            CountryFlags.getFlagOptimized(countryCode),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Edit Time Limit',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  countryName,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Current settings info
            customSettingsAsync.when(
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
              data: (customSettings) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            customSettings != null ? Icons.edit : Icons.info_outline,
                            size: 16,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            customSettings != null ? 'Current: Custom limit' : 'Current: Default limit',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      effectiveTimeLimitAsync.when(
                        loading: () => const Text('Loading...'),
                        error: (_, __) => Text('$defaultThreshold days'),
                        data: (effectiveLimit) => Text('$effectiveLimit days'),
                      ),
                      if (defaultRule != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Default: $defaultThreshold days',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          defaultRule.description,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 16),
            
            // Days input
            TextField(
              controller: daysController,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              decoration: const InputDecoration(
                labelText: 'Custom Time Limit (days)',
                border: OutlineInputBorder(),
                helperText: 'Maximum days allowed to stay in this country',
                prefixIcon: Icon(Icons.schedule),
              ),
            ),
            const SizedBox(height: 16),
            
            // Notes input
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                border: OutlineInputBorder(),
                helperText: 'Add any personal notes about this limit',
                prefixIcon: Icon(Icons.notes),
              ),
            ),
          ],
        ),
      ),
      actions: [
        // Remove custom settings button (if custom settings exist)
        ...customSettingsAsync.when(
          loading: () => <Widget>[],
          error: (_, __) => <Widget>[],
          data: (customSettings) {
            if (customSettings == null) return <Widget>[];
            
            return <Widget>[
              TextButton(
                onPressed: isLoading.value ? null : () async {
                  isLoading.value = true;
                  try {
                    final result = await customSettingsService.removeCustomSettings(countryCode);
                    if (result.isSuccess) {
                      // Refresh providers
                      ref.invalidate(customSettingsForCountryProvider(countryCode));
                      ref.invalidate(effectiveTimeLimitProvider(countryCode));
                      invalidateCustomCountrySettingsProviders(ref);
                      
                      if (context.mounted) {
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Reverted to default limit')),
                        );
                      }
                    } else {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(result.message)),
                        );
                      }
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Error: $e')),
                      );
                    }
                  } finally {
                    isLoading.value = false;
                  }
                },
                child: const Text('Remove Custom'),
              ),
            ];
          },
        ),
        
        // Cancel button
        TextButton(
          onPressed: isLoading.value ? null : () {
            Navigator.of(context).pop();
          },
          child: const Text('Cancel'),
        ),
        
        // Save button
        FilledButton(
          onPressed: isLoading.value ? null : () async {
            final daysText = daysController.text.trim();
            if (daysText.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter the number of days')),
              );
              return;
            }
            
            final days = int.tryParse(daysText);
            if (days == null || days <= 0) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Please enter a valid number of days')),
              );
              return;
            }
            
            if (days > 999) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Maximum 999 days allowed')),
              );
              return;
            }
            
            isLoading.value = true;
            try {
              final result = await customSettingsService.setCustomTimeLimit(
                countryCode: countryCode,
                countryName: countryName,
                daysThreshold: days,
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
              
              if (result.isSuccess) {
                // Refresh providers
                ref.invalidate(customSettingsForCountryProvider(countryCode));
                ref.invalidate(effectiveTimeLimitProvider(countryCode));
                invalidateCustomCountrySettingsProviders(ref);
                
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Custom time limit saved')),
                  );
                }
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(result.message)),
                  );
                }
              }
            } catch (e) {
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            } finally {
              isLoading.value = false;
            }
          },
          child: isLoading.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Save'),
        ),
      ],
    );
  }
}

/// Helper function to show the edit country time limit dialog
Future<void> showEditCountryTimeLimitDialog({
  required BuildContext context,
  required String countryCode,
  required String countryName,
}) async {
  await showDialog<void>(
    context: context,
    builder: (context) => EditCountryTimeLimitDialog(
      countryCode: countryCode,
      countryName: countryName,
    ),
  );
}