import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:trottstr/widgets/country_selector.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/providers/country_tracking_providers.dart';

class PlanStayScreen extends HookConsumerWidget {
  const PlanStayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final selectedCountryCode = useState<String?>(null);
    final selectedCountryName = useState<String?>(null);
    final startDate = useState<DateTime>(DateTime.now());
    final endDate = useState<DateTime>(
      DateTime.now().add(const Duration(days: 7)),
    );
    final purposeController = useTextEditingController();
    final notesController = useTextEditingController();

    final trackingService = ref.read(countryTrackingServiceProvider);

    // Calculate days between dates
    final daysCount = endDate.value.difference(startDate.value).inDays + 1;

    Future<void> savePlannedStay() async {
      if (!formKey.currentState!.validate()) return;
      if (selectedCountryCode.value == null) return;
      if (endDate.value.isBefore(startDate.value)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('End date must be after start date')),
        );
        return;
      }

      final plannedStay = PlannedStay(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        countryCode: selectedCountryCode.value!,
        startDate: startDate.value,
        endDate: endDate.value,
        purpose: purposeController.text.trim().isNotEmpty
            ? purposeController.text.trim()
            : null,
        notes: notesController.text.trim().isNotEmpty
            ? notesController.text.trim()
            : null,
      );

      await trackingService.addPlannedStay(plannedStay);

      // Invalidate providers to trigger UI updates
      invalidatePlannedStaysProvider(ref);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Planned stay saved successfully!')),
        );
        context.pop();
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Plan Future Stay'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Planning Future Stays'),
                  content: const Text(
                    'Plan your future trips to see how they will impact your tax residency status.\n\n'
                    'Planned days are counted toward your annual limits to help you stay within safe thresholds.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Country Selection
              CountrySelector(
                selectedCountryCode: selectedCountryCode.value,
                onCountrySelected: (countryCode, countryName) {
                  selectedCountryCode.value = countryCode;
                  selectedCountryName.value = countryName;
                },
                hintText: 'Select destination country',
              ),
              const SizedBox(height: 16),

              // Country Info (if selected)
              if (selectedCountryCode.value != null) ...[
                CountryInfoCard(countryCode: selectedCountryCode.value!),
                const SizedBox(height: 16),
              ],

              // Date Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Stay Duration',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Start Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: startDate.value,
                            firstDate: DateTime.now(),
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 2),
                            ),
                          );
                          if (date != null) {
                            startDate.value = date;
                            // Ensure end date is not before start date
                            if (endDate.value.isBefore(date)) {
                              endDate.value = date.add(const Duration(days: 1));
                            }
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flight_land,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Start Date',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      '${startDate.value.day}/${startDate.value.month}/${startDate.value.year}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.edit,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // End Date
                      InkWell(
                        onTap: () async {
                          final date = await showDatePicker(
                            context: context,
                            initialDate: endDate.value,
                            firstDate: startDate.value,
                            lastDate: DateTime.now().add(
                              const Duration(days: 365 * 2),
                            ),
                          );
                          if (date != null) {
                            endDate.value = date;
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.flight_takeoff,
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'End Date',
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodySmall
                                          ?.copyWith(
                                            color: Theme.of(
                                              context,
                                            ).colorScheme.onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      '${endDate.value.day}/${endDate.value.month}/${endDate.value.year}',
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodyLarge,
                                    ),
                                  ],
                                ),
                              ),
                              Icon(
                                Icons.edit,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Duration summary
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Theme.of(
                            context,
                          ).colorScheme.primaryContainer.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.schedule,
                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Duration: $daysCount days',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Optional Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optional Details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Purpose
                      TextFormField(
                        controller: purposeController,
                        decoration: const InputDecoration(
                          labelText: 'Purpose of Visit',
                          hintText: 'Tourism, business, family visit...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_center),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Additional information about this trip...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Tax Impact Preview (if country selected)
              if (selectedCountryCode.value != null) ...[
                FutureBuilder<TaxResidencyRisk?>(
                  future: _calculateImpact(
                    trackingService,
                    selectedCountryCode.value!,
                    daysCount,
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.hasData && snapshot.data != null) {
                      final risk = snapshot.data!;
                      return Card(
                        color:
                            risk.riskLevel == RiskLevel.critical ||
                                risk.riskLevel == RiskLevel.exceeded
                            ? Theme.of(
                                context,
                              ).colorScheme.errorContainer.withOpacity(0.5)
                            : null,
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(
                                    Icons.analytics,
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Tax Impact Preview',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'After this planned stay:',
                                style: Theme.of(context).textTheme.bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Total days in ${risk.countryName}:'),
                                  Text(
                                    '${risk.currentDays}/${risk.threshold}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: risk.isExceeded
                                              ? Colors.red
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 4),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text('Threshold usage:'),
                                  Text(
                                    '${risk.percentageUsed.toStringAsFixed(1)}%',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                          color: risk.percentageUsed >= 90
                                              ? Colors.red
                                              : risk.percentageUsed >= 75
                                              ? Colors.orange
                                              : null,
                                        ),
                                  ),
                                ],
                              ),
                              if (risk.isExceeded) ...[
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.red.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Row(
                                    children: [
                                      const Icon(
                                        Icons.warning,
                                        color: Colors.red,
                                        size: 16,
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          'Warning: This stay would exceed tax residency threshold!',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodySmall
                                              ?.copyWith(
                                                color: Colors.red,
                                                fontWeight: FontWeight.bold,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      );
                    }
                    return const SizedBox.shrink();
                  },
                ),
                const SizedBox(height: 16),
              ],

              // Save Button
              AsyncButtonBuilder(
                onPressed: selectedCountryCode.value != null
                    ? savePlannedStay
                    : null,
                builder: (context, child, callback, buttonState) {
                  return FilledButton(
                    onPressed: buttonState.maybeWhen(
                      loading: () => null,
                      orElse: () => callback,
                    ),
                    child: buttonState.maybeWhen(
                      loading: () => const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      orElse: () => child,
                    ),
                  );
                },
                onError: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Failed to save planned stay'),
                    ),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    'Save Planned Stay',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<TaxResidencyRisk?> _calculateImpact(
    CountryTrackingService service,
    String countryCode,
    int plannedDays,
  ) async {
    try {
      final currentRisks = await service.calculateTaxResidencyRisks();
      final currentRisk = currentRisks[countryCode];
      final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);

      if (rule == null) return null;

      final currentDays = currentRisk?.currentDays ?? 0;
      final newTotalDays = currentDays + plannedDays;

      return TaxResidencyRisk(
        countryCode: countryCode,
        countryName: rule.countryName,
        currentDays: newTotalDays,
        threshold: rule.daysThreshold,
        rule: rule,
      );
    } catch (e) {
      return null;
    }
  }
}
