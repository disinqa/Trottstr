import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:models/models.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:trottstr/providers/auth_providers.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/widgets/expandable_country_list.dart';
import 'package:trottstr/utils/country_flags.dart';
import 'package:trottstr/utils/toast_utils.dart';
import 'package:trottstr/providers/country_tracking_providers.dart';
import 'package:trottstr/models/tax_residency_rule.dart';

class DashboardTab extends ConsumerWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(userProfileProvider);
    ref.watch(Signer.activePubkeyProvider);
    ref.read(countryTrackingServiceProvider);
    final currentYear = DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Welcome Section with Expandable Country List
          ExpandableCountryList(),

          const SizedBox(height: 24),

          // Tax Residency Warnings (if any)
          Consumer(
            builder: (context, ref, child) {
              final risksAsync = ref.watch(taxResidencyRisksProvider);

              return risksAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (error, stack) => const SizedBox.shrink(),
                data: (risks) {
                  final warningRisks = risks.values
                      .where(
                        (risk) =>
                            risk.riskLevel == RiskLevel.critical ||
                            risk.riskLevel == RiskLevel.exceeded,
                      )
                      .toList();

                  if (warningRisks.isNotEmpty) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Theme.of(context).colorScheme.error,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Tax Residency Alerts',
                              style: Theme.of(context).textTheme.titleMedium
                                  ?.copyWith(
                                    color: Theme.of(context).colorScheme.error,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        ...warningRisks.map(
                          (risk) => _buildWarningCard(context, risk),
                        ),
                        const SizedBox(height: 24),
                      ],
                    );
                  }
                  return const SizedBox.shrink();
                },
              );
            },
          ),

          // Quick Actions
          Text(
            'Quick Actions',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          // Dynamic Quick Actions based on current location
          Consumer(
            builder: (context, ref, child) {
              final locationAsync = ref.watch(currentLocationProvider);

              return locationAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) =>
                    const Center(child: Text('Error loading current location')),
                data: (currentLocation) {
                  print("currentLocation: $currentLocation");
                  final hasActiveLocation = currentLocation != null;

                  return GridView.count(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    children: [
                      _buildActionCard(
                        context,
                        icon: Icons.flight_land,
                        title: 'Record Entry',
                        subtitle: hasActiveLocation
                            ? 'Enter new country'
                            : 'Check in to country',
                        onTap: () => context.push('/record'),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.schedule,
                        title: 'Plan Stay',
                        subtitle: 'Schedule future visit',
                        onTap: () => context.push('/plan'),
                      ),
                      _buildActionCard(
                        context,
                        icon: Icons.analytics,
                        title: 'View Stats',
                        subtitle: 'See your progress',
                        onTap: () {
                          // Navigate to stats tab
                          DefaultTabController.of(context).animateTo(
                            2,
                          ); // Assuming stats is the 3rd tab (index 2)
                        },
                      ),
                      if (hasActiveLocation)
                        _buildActionCard(
                          context,
                          icon: Icons.flight_takeoff,
                          title: 'Clear Check-in',
                          subtitle: 'Exit from $currentLocation',
                          onTap: () => _showExitCountryDialog(
                            context,
                            ref,
                            currentLocation,
                          ),
                        )
                      else
                        _buildActionCard(
                          context,
                          icon: Icons.info_outline,
                          title: 'No Active Check-in',
                          subtitle: 'Record an entry to start tracking',
                          onTap: () => context.push('/record'),
                        ),
                    ],
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Current Year Overview
          Text(
            '$currentYear Overview',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          Consumer(
            builder: (context, ref, child) {
              final statsAsync = ref.watch(travelStatsProvider);

              return statsAsync.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('Error loading data: $error')),
                  ),
                ),
                data: (stats) {
                  return Column(
                    children: [
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Countries Visited',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${stats.countriesCount}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Travel Days',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${stats.totalDays}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Total Entries',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Text(
                                    '${stats.totalEntries}',
                                    style: Theme.of(context)
                                        .textTheme
                                        .headlineMedium
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                          fontWeight: FontWeight.bold,
                                        ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Current Status',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  Flexible(
                                    child: Text(
                                      stats.currentStatus.isEmpty
                                          ? 'No active check-in'
                                          : stats.currentStatus,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyLarge
                                          ?.copyWith(
                                            color: stats.currentStatus.isEmpty
                                                ? Theme.of(
                                                    context,
                                                  ).colorScheme.onSurfaceVariant
                                                : Theme.of(
                                                    context,
                                                  ).colorScheme.primary,
                                            fontWeight: FontWeight.w600,
                                          ),
                                      textAlign: TextAlign.end,
                                    ),
                                  ),
                                ],
                              ),
                              if (stats.countriesCount == 0) ...[
                                const SizedBox(height: 16),
                                const Divider(),
                                const SizedBox(height: 16),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Start tracking your travels to monitor tax residency limits',
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      if (stats.countriesCount > 0) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Country Breakdown',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 12),
                        Column(
                          children: stats.countryBreakdown
                              .map(
                                (summary) => _buildCountryRiskCard(
                                  context,
                                  summary.risk!,
                                ),
                              )
                              .toList(),
                        ),
                      ],
                    ],
                  );
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWarningCard(BuildContext context, TaxResidencyRisk risk) {
    return Card(
      color: risk.isExceeded
          ? Theme.of(context).colorScheme.errorContainer
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Row(
          children: [
            Icon(
              risk.isExceeded ? Icons.error : Icons.warning,
              color: risk.isExceeded
                  ? Theme.of(context).colorScheme.onErrorContainer
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    risk.countryName,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    risk.isExceeded
                        ? 'Tax residency threshold exceeded!'
                        : 'Close to tax residency threshold',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            Text(
              '${risk.currentDays}/${risk.threshold}',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryRiskCard(BuildContext context, TaxResidencyRisk risk) {
    Color riskColor;
    switch (risk.riskLevel) {
      case RiskLevel.low:
        riskColor = Colors.green;
        break;
      case RiskLevel.medium:
        riskColor = Colors.orange;
        break;
      case RiskLevel.high:
        riskColor = Colors.deepOrange;
        break;
      case RiskLevel.critical:
        riskColor = Colors.red;
        break;
      case RiskLevel.exceeded:
        riskColor = Colors.red.shade800;
        break;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Center(
                  child: Text(
                    CountryFlags.getFlagOptimized(risk.countryCode),
                    style: const TextStyle(fontSize: 28),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    risk.countryName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${risk.currentDays}/${risk.threshold}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: riskColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LinearProgressIndicator(
              value: (risk.currentDays / risk.threshold).clamp(0.0, 1.0),
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(riskColor),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '${risk.percentageUsed.toStringAsFixed(1)}% used',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                if (risk.daysRemaining > 0)
                  Text(
                    '${risk.daysRemaining} days remaining',
                    style: Theme.of(
                      context,
                    ).textTheme.bodySmall?.copyWith(color: riskColor),
                  )
                else
                  Text(
                    'Threshold exceeded',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: riskColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 32,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(height: 12),
              Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showExitCountryDialog(
    BuildContext context,
    WidgetRef ref,
    String countryCode,
  ) {
    showDialog(
      context: context,
      builder: (context) => _ExitCountryDialog(countryCode: countryCode),
    );
  }
}

/// Dialog for selecting an exit date from the current country
class _ExitCountryDialog extends HookConsumerWidget {
  final String countryCode;

  const _ExitCountryDialog({required this.countryCode});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedDate = useState<DateTime?>(null);
    final isProcessing = useState<bool>(false);

    // Get country information
    final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);
    final countryName = rule?.countryName ?? countryCode;

    return AlertDialog(
      title: Row(
        children: [
          Text(
            CountryFlags.getFlagOptimized(countryCode),
            style: const TextStyle(fontSize: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Clear Check-in from $countryName',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Select the date you left this country. This will clear your current check-in status.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Date selection
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.3),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Date Left Country',
                  style: Theme.of(context).textTheme.labelLarge,
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime(DateTime.now().year - 2),
                      lastDate: DateTime.now(),
                      helpText: 'Select departure date',
                    );
                    if (date != null) {
                      selectedDate.value = date;
                    }
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 16,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 12),
                        Text(
                          selectedDate.value != null
                              ? DateFormat(
                                  'MMM dd, yyyy',
                                ).format(selectedDate.value!)
                              : 'Tap to select date',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: selectedDate.value != null
                                    ? Theme.of(context).colorScheme.onSurface
                                    : Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (selectedDate.value != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(
                  context,
                ).colorScheme.primaryContainer.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'This will clear your current check-in from $countryName. You will not be tracked as being in any country until your next entry.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
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
      actions: [
        TextButton(
          onPressed: isProcessing.value
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: (selectedDate.value != null && !isProcessing.value)
              ? () => _processExit(
                  context,
                  ref,
                  selectedDate.value!,
                  countryCode,
                  isProcessing,
                )
              : null,
          child: isProcessing.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Clear Check-in'),
        ),
      ],
    );
  }

  Future<void> _processExit(
    BuildContext context,
    WidgetRef ref,
    DateTime exitDate,
    String countryCode,
    ValueNotifier<bool> isProcessing,
  ) async {
    isProcessing.value = true;

    try {
      final trackingService = ref.read(countryTrackingServiceProvider);

      // Use the improved manual exit functionality
      await trackingService.addManualExit(
        exitDate: exitDate,
        notes: 'Manual exit via dashboard',
      );

      // Invalidate providers to refresh the UI
      invalidateTrackingProviders(ref);

      if (context.mounted) {
        Navigator.of(context).pop();

        // Show success toast
        ToastUtils.showSuccess(
          'Successfully exited from ${DefaultTaxResidencyRules.getRuleForCountry(countryCode)?.countryName ?? countryCode} on ${DateFormat('MMM dd, yyyy').format(exitDate)}',
          title: 'Exit Recorded',
        );
      }
    } catch (e) {
      ToastUtils.showError(
        'Failed to record exit: ${e.toString()}',
        title: 'Exit Failed',
      );
    } finally {
      isProcessing.value = false;
    }
  }
}
