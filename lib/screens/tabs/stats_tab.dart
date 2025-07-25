import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/providers/country_tracking_providers.dart';
import 'package:trottstr/utils/country_flags.dart';

class StatsTab extends ConsumerWidget {
  const StatsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingService = ref.read(countryTrackingServiceProvider);
    final currentYear = DateTime.now().year;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Travel Statistics',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 16),

          // Year Summary Card using new provider
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
                    child: Center(child: Text('Error loading stats: $error')),
                  ),
                ),
                data: (stats) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$currentYear Summary',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                context,
                                title: 'Countries',
                                value: '${stats.countriesCount}',
                                icon: Icons.public,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                title: 'Total Days',
                                value: '${stats.totalDays}',
                                icon: Icons.today,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildStatItem(
                                context,
                                title: 'Total Entries',
                                value: '${stats.totalEntries}',
                                icon: Icons.flight_land,
                              ),
                            ),
                            Expanded(
                              child: _buildStatItem(
                                context,
                                title: 'Longest Stay',
                                value: '${stats.longestStayDays} days',
                                icon: Icons.schedule,
                              ),
                            ),
                          ],
                        ),
                        if (stats.currentStatus.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  stats.currentStatus,
                                  style: Theme.of(context).textTheme.titleMedium
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.primary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Country Breakdown
          Text(
            'Country Breakdown',
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
                  if (stats.countryBreakdown.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Icon(
                                  Icons.pie_chart,
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'No data available',
                                  style: Theme.of(
                                    context,
                                  ).textTheme.titleMedium,
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Start tracking your travels to see detailed statistics about your time in each country.',
                              style: Theme.of(context).textTheme.bodyMedium
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return Column(
                    children: stats.countryBreakdown.map((summary) {
                      final percentage = stats.totalDays > 0
                          ? (summary.days / stats.totalDays * 100)
                          : 0.0;
                      return _buildCountryStatsCard(
                        context,
                        summary,
                        percentage,
                      );
                    }).toList(),
                  );
                },
              );
            },
          ),

          const SizedBox(height: 24),

          // Tax Residency Alerts
          Text(
            'Tax Residency Alerts',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          FutureBuilder<Map<String, TaxResidencyRisk>>(
            future: trackingService.calculateTaxResidencyRisks(),
            builder: (context, snapshot) {
              if (!snapshot.hasData) {
                return const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                );
              }

              final risks = snapshot.data!.values;
              final alerts = risks
                  .where(
                    (risk) =>
                        risk.riskLevel == RiskLevel.critical ||
                        risk.riskLevel == RiskLevel.exceeded ||
                        risk.isCloseToThreshold,
                  )
                  .toList();

              if (alerts.isEmpty) {
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: Colors.green),
                            const SizedBox(width: 8),
                            Text(
                              'No active warnings',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'You\'re currently within safe limits for all countries. Keep tracking to stay informed!',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: alerts
                    .map((risk) => _buildAlertCard(context, risk))
                    .toList(),
              );
            },
          ),

          const SizedBox(height: 24),

          // Travel Calendar
          Text(
            'Travel Calendar',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),

          Consumer(
            builder: (context, ref, child) {
              final historyAsync = ref.watch(completeHistoryProvider);

              return historyAsync.when(
                loading: () => const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16.0),
                    child: Center(child: CircularProgressIndicator()),
                  ),
                ),
                error: (error, stack) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Center(child: Text('Error loading history: $error')),
                  ),
                ),
                data: (history) => Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recent Activity',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 16),
                        if (history.isEmpty)
                          Text(
                            'No travel activity recorded yet.',
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          )
                        else
                          Column(
                            children: history
                                .take(5)
                                .map(
                                  (entryWithExit) => _buildCalendarEntry(
                                    context,
                                    entryWithExit.entry,
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          Icon(icon, color: Theme.of(context).colorScheme.primary, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: valueColor ?? Theme.of(context).colorScheme.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCountryStatsCard(
    BuildContext context,
    CountryDaysSummary summary,
    double percentage,
  ) {
    final rule = DefaultTaxResidencyRules.getRuleForCountry(
      summary.countryCode,
    );
    final countryName = rule?.countryName ?? summary.countryCode;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  CountryFlags.getFlagOptimized(summary.countryCode),
                  style: const TextStyle(fontSize: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    countryName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${summary.days} days',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${percentage.toStringAsFixed(1)}% of total',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  flex: percentage.round().clamp(1, 100),
                  child: Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                if (percentage < 100)
                  Expanded(
                    flex: (100 - percentage).round().clamp(1, 100),
                    child: Container(
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
              ],
            ),
            if (summary.risk != null) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Tax residency: ${summary.risk!.currentDays}/${summary.risk!.threshold} days',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    '${summary.risk!.percentageUsed.toStringAsFixed(1)}% used',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: _getRiskColor(summary.risk!.riskLevel.name),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAlertCard(BuildContext context, TaxResidencyRisk risk) {
    IconData icon;
    Color color;
    String message;

    if (risk.isExceeded) {
      icon = Icons.error;
      color = Colors.red;
      message = 'Tax residency threshold exceeded!';
    } else if (risk.riskLevel == RiskLevel.critical) {
      icon = Icons.warning;
      color = Colors.orange;
      message = 'Critical: Very close to tax residency limit';
    } else {
      icon = Icons.info;
      color = Colors.blue;
      message = 'Approaching tax residency threshold';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: color.withOpacity(0.1),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    risk.countryName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(message, style: Theme.of(context).textTheme.bodyMedium),
                  Text(
                    '${risk.currentDays}/${risk.threshold} days (${risk.percentageUsed.toStringAsFixed(1)}%)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalendarEntry(BuildContext context, CountryEntry entry) {
    final rule = DefaultTaxResidencyRules.getRuleForCountry(entry.countryCode);
    final countryName = rule?.countryName ?? entry.countryCode;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: Colors.green,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Entered $countryName',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            _formatDate(entry.entryDate),
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  Color _getRiskColor(String riskLevel) {
    switch (riskLevel.toLowerCase()) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.orange;
      case 'high':
        return Colors.deepOrange;
      case 'critical':
        return Colors.red;
      case 'exceeded':
        return Colors.red.shade800;
      default:
        return Colors.green;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return 'Today';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} days ago';
    } else {
      return '${date.day}/${date.month}';
    }
  }
}
