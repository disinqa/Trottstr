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
      body: Column(
        children: [
          // Main scrollable content
          Expanded(
            child: Form(
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
                    const SizedBox(height: 12),

                    // Country Info (if selected)
                    if (selectedCountryCode.value != null) ...[
                      CountryInfoCard(countryCode: selectedCountryCode.value!),
                      const SizedBox(height: 12),
                    ],

                    // Date Selection - Compact Design
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Stay Duration',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 12),

                            // Start Date - Compact
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flight_land,
                                      color: Theme.of(context).colorScheme.primary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'Start Date',
                                            style: Theme.of(context).textTheme.labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                          Text(
                                            '${startDate.value.day}/${startDate.value.month}/${startDate.value.year}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit_outlined,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // End Date - Compact
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
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(context).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.flight_takeoff,
                                      color: Theme.of(context).colorScheme.secondary,
                                      size: 18,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            'End Date',
                                            style: Theme.of(context).textTheme.labelSmall
                                                ?.copyWith(
                                                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                                                ),
                                          ),
                                          Text(
                                            '${endDate.value.day}/${endDate.value.month}/${endDate.value.year}',
                                            style: Theme.of(context).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit_outlined,
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                      size: 16,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // Duration summary - Compact
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.schedule,
                                    color: Theme.of(context).colorScheme.onPrimaryContainer,
                                    size: 18,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Duration: $daysCount days',
                                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional Details - Progressive Disclosure
                    PlanOptionalDetailsSection(
                      purposeController: purposeController,
                      notesController: notesController,
                    ),

                    // Tax Impact Preview (if country selected) - Compact
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
                              color: risk.riskLevel == RiskLevel.critical ||
                                      risk.riskLevel == RiskLevel.exceeded
                                  ? Theme.of(context).colorScheme.errorContainer.withValues(alpha: 0.5)
                                  : null,
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          Icons.analytics,
                                          color: Theme.of(context).colorScheme.primary,
                                          size: 18,
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          'Tax Impact Preview',
                                          style: Theme.of(context).textTheme.titleSmall
                                              ?.copyWith(fontWeight: FontWeight.w600),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Total days:', style: Theme.of(context).textTheme.bodySmall),
                                        Text(
                                          '${risk.currentDays}/${risk.threshold}',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                            fontWeight: FontWeight.bold,
                                            color: risk.isExceeded ? Colors.red : null,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 2),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text('Usage:', style: Theme.of(context).textTheme.bodySmall),
                                        Text(
                                          '${risk.percentageUsed.toStringAsFixed(1)}%',
                                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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
                                      const SizedBox(height: 6),
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: Colors.red.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.warning, color: Colors.red, size: 14),
                                            const SizedBox(width: 6),
                                            Expanded(
                                              child: Text(
                                                'Warning: Would exceed threshold!',
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
                    ],

                    // Add some bottom padding for the sticky footer
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Footer with Save Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: AsyncButtonBuilder(
                onPressed: selectedCountryCode.value != null ? savePlannedStay : null,
                builder: (context, child, callback, buttonState) {
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
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
                    ),
                  );
                },
                onError: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save planned stay')),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('Save Planned Stay', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
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

/// Progressive disclosure widget for optional details in plan stay
class PlanOptionalDetailsSection extends StatefulWidget {
  final TextEditingController purposeController;
  final TextEditingController notesController;

  const PlanOptionalDetailsSection({
    super.key,
    required this.purposeController,
    required this.notesController,
  });

  @override
  State<PlanOptionalDetailsSection> createState() => _PlanOptionalDetailsSectionState();
}

class _PlanOptionalDetailsSectionState extends State<PlanOptionalDetailsSection> {
  bool _isExpanded = false;
  bool _hasOptionalData = false;

  @override
  void initState() {
    super.initState();
    _checkForOptionalData();

    // Listen for changes to show/hide expansion indicator
    widget.purposeController.addListener(_checkForOptionalData);
    widget.notesController.addListener(_checkForOptionalData);
  }

  @override
  void dispose() {
    widget.purposeController.removeListener(_checkForOptionalData);
    widget.notesController.removeListener(_checkForOptionalData);
    super.dispose();
  }

  void _checkForOptionalData() {
    final hasData = widget.purposeController.text.isNotEmpty ||
        widget.notesController.text.isNotEmpty;

    if (hasData != _hasOptionalData) {
      setState(() {
        _hasOptionalData = hasData;
        if (hasData && !_isExpanded) {
          _isExpanded = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Optional Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (_hasOptionalData) ...[
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  // Purpose field
                  TextFormField(
                    controller: widget.purposeController,
                    decoration: const InputDecoration(
                      labelText: 'Purpose of Visit',
                      hintText: 'Tourism, business, family...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.business_center, size: 18),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 8),

                  // Notes field (compact)
                  TextFormField(
                    controller: widget.notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Additional information...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note, size: 18),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
