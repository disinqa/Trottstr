import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:go_router/go_router.dart';
import 'package:trottstr/providers/auth_providers.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/widgets/expandable_country_list.dart';
import 'package:trottstr/utils/country_flags.dart';
import 'package:trottstr/providers/optimized_tracking_providers.dart';

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
              final risks = ref.watch(optimizedTaxResidencyRisksProvider);
              final trackingState = ref.watch(optimizedTrackingProvider);

              // Show loading only on initial load, not during optimistic updates
              if (trackingState is TrackingDataLoading) {
                return const SizedBox.shrink();
              }

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
              final currentLocation = ref.watch(
                optimizedCurrentLocationProvider,
              );
              final trackingState = ref.watch(optimizedTrackingProvider);

              // Show loading only on initial load
              if (trackingState is TrackingDataLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              final hasActiveLocation = currentLocation != null;

              return GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.2,
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
                ],
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
              final stats = ref.watch(optimizedTravelStatsProvider);
              final trackingState = ref.watch(optimizedTrackingProvider);
              final isOptimistic = ref.watch(isOptimisticProvider);

              // Show loading only on initial load
              if (trackingState is TrackingDataLoading) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              if (trackingState is TrackingDataError) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(
                      child: Text('Error loading data: ${trackingState.error}'),
                    ),
                  ),
                );
              }

              if (stats == null) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: Text('No data available')),
                  ),
                );
              }

              return Column(
                children: [
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          // Show optimistic update indicator
                          if (isOptimistic) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  SizedBox(
                                    width: 12,
                                    height: 12,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                        Theme.of(context).colorScheme.primary,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Syncing...',
                                    style: Theme.of(context)
                                        .textTheme
                                        .labelSmall
                                        ?.copyWith(
                                          color: Theme.of(
                                            context,
                                          ).colorScheme.primary,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Countries Visited',
                                style: Theme.of(context).textTheme.titleMedium,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Travel Days',
                                style: Theme.of(context).textTheme.titleMedium,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Total Entries',
                                style: Theme.of(context).textTheme.titleMedium,
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
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Current Status',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                              Flexible(
                                child: Text(
                                  stats.currentStatus.isEmpty
                                      ? 'No active check-in'
                                      : stats.currentStatus,
                                  style: Theme.of(context).textTheme.bodyLarge
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
                                  color: Theme.of(context).colorScheme.primary,
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
                            (summary) => summary.risk != null
                                ? buildCountryRiskCard(context, summary.risk!)
                                : const SizedBox.shrink(),
                          )
                          .toList(),
                    ),
                  ],
                ],
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
}

Widget buildCountryRiskCard(BuildContext context, TaxResidencyRisk risk) {
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
