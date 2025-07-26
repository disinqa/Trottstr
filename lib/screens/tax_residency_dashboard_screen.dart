import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/providers/tax_residency_providers.dart';
import 'package:trottstr/services/tax_residency_service.dart';
import 'package:trottstr/screens/country_entry_screen.dart';

/// Tax residency dashboard screen showing overview and warnings
class TaxResidencyDashboardScreen extends ConsumerWidget {
  const TaxResidencyDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tax Residency Dashboard'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          invalidateTaxResidencyProviders(ref);
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildOverviewCard(context, ref),
              const SizedBox(height: 16),
              _buildCountriesAtRiskCard(context, ref),
              const SizedBox(height: 16),
              _buildHighUsageCountriesCard(context, ref),
              const SizedBox(height: 16),
              _buildTravelSummaryCard(context, ref),
              const SizedBox(height: 16),
              _buildQuickActionsCard(context, ref),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CountryEntryScreen(),
            ),
          );
        },
        icon: const Icon(Icons.add_location),
        label: const Text('Add Entry'),
      ),
    );
  }

  Widget _buildOverviewCard(BuildContext context, WidgetRef ref) {
    final summaryAsync = ref.watch(taxResidencySummaryProvider);
    final riskAssessmentAsync = ref.watch(overallRiskAssessmentProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.dashboard,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Overview',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            summaryAsync.when(
              data: (summary) => Column(
                children: [
                  _buildOverviewRow(
                    context,
                    'Countries Visited',
                    '${summary.totalCountries}',
                    Icons.public,
                  ),
                  _buildOverviewRow(
                    context,
                    'Days Traveled',
                    '${summary.totalDaysTraveled}',
                    Icons.flight_takeoff,
                  ),
                  _buildOverviewRow(
                    context,
                    'Countries at Risk',
                    '${summary.countriesAtRisk}',
                    Icons.warning,
                    isWarning: summary.countriesAtRisk > 0,
                  ),
                  _buildOverviewRow(
                    context,
                    'Countries Over Limit',
                    '${summary.countriesOverLimit}',
                    Icons.error,
                    isError: summary.countriesOverLimit > 0,
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
            const SizedBox(height: 16),
            riskAssessmentAsync.when(
              data: (assessment) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _getRiskColor(assessment, context),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      _getRiskIcon(assessment),
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        assessment,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const LinearProgressIndicator(),
              error: (error, stack) => const SizedBox(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverviewRow(
    BuildContext context,
    String label,
    String value,
    IconData icon, {
    bool isWarning = false,
    bool isError = false,
  }) {
    Color? color;
    if (isError) {
      color = Theme.of(context).colorScheme.error;
    } else if (isWarning) {
      color = Theme.of(context).colorScheme.tertiary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCountriesAtRiskCard(BuildContext context, WidgetRef ref) {
    final countriesAtRiskAsync = ref.watch(countriesAtRiskProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
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
                  'Countries at Risk',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            countriesAtRiskAsync.when(
              data: (countries) {
                if (countries.isEmpty) {
                  return Row(
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      const Text('No countries at risk'),
                    ],
                  );
                }
                
                return Column(
                  children: countries.map((status) => 
                    _buildCountryRiskTile(context, status)
                  ).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCountryRiskTile(BuildContext context, TaxResidencyStatus status) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Color(int.parse(status.riskLevel.colorHex.substring(1), radix: 16) + 0xFF000000),
          child: Text(
            status.countryCode,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(status.rule.countryName),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              status.isOverLimit
                  ? 'Exceeded by ${-status.daysRemaining} days'
                  : '${status.daysRemaining} days remaining',
            ),
            LinearProgressIndicator(
              value: status.usagePercentage.clamp(0.0, 1.0),
              backgroundColor: Colors.grey[300],
              valueColor: AlwaysStoppedAnimation<Color>(
                Color(int.parse(status.riskLevel.colorHex.substring(1), radix: 16) + 0xFF000000),
              ),
            ),
          ],
        ),
        trailing: Text(
          '${status.totalDaysIncludingPlanned}/${status.rule.maxDays}',
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildHighUsageCountriesCard(BuildContext context, WidgetRef ref) {
    final highUsageAsync = ref.watch(highestUsageCountriesProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.trending_up,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Highest Usage Countries',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            highUsageAsync.when(
              data: (countries) {
                if (countries.isEmpty) {
                  return const Text('No travel data available');
                }
                
                return Column(
                  children: countries.map((status) => 
                    _buildUsageTile(context, status)
                  ).toList(),
                );
              },
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsageTile(BuildContext context, TaxResidencyStatus status) {
    final percentage = (status.usagePercentage * 100).toInt();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            child: Text(
              status.countryCode,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(status.rule.countryName),
                LinearProgressIndicator(
                  value: status.usagePercentage.clamp(0.0, 1.0),
                  backgroundColor: Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation<Color>(
                    _getUsageColor(status.usagePercentage, context),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '$percentage%',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTravelSummaryCard(BuildContext context, WidgetRef ref) {
    final totalDaysAsync = ref.watch(totalDaysTraveledProvider);
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.analytics,
                  color: Theme.of(context).colorScheme.primary,
                ),
                const SizedBox(width: 8),
                Text(
                  'Travel Summary ${DateTime.now().year}',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ],
            ),
            const SizedBox(height: 16),
            totalDaysAsync.when(
              data: (totalDays) => Column(
                children: [
                  _buildSummaryRow(
                    context,
                    'Total Days Traveled',
                    '$totalDays days',
                    Icons.calendar_today,
                  ),
                  _buildSummaryRow(
                    context,
                    'Days Remaining in Year',
                    '${365 - DateTime.now().dayOfYear} days',
                    Icons.access_time,
                  ),
                  _buildSummaryRow(
                    context,
                    'Travel Intensity',
                    '${(totalDays / DateTime.now().dayOfYear * 100).toInt()}%',
                    Icons.speed,
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (error, stack) => Text('Error: $error'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryRow(
    BuildContext context,
    String label,
    String value,
    IconData icon,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsCard(BuildContext context, WidgetRef ref) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Quick Actions',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const CountryEntryScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add_location),
                  label: const Text('Record Entry'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to planned trips screen
                  },
                  icon: const Icon(Icons.event),
                  label: const Text('Plan Trip'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to backup settings
                  },
                  icon: const Icon(Icons.backup),
                  label: const Text('Backup'),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // Navigate to settings
                  },
                  icon: const Icon(Icons.settings),
                  label: const Text('Settings'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _getRiskColor(String assessment, BuildContext context) {
    if (assessment.toLowerCase().contains('critical')) {
      return Theme.of(context).colorScheme.error;
    } else if (assessment.toLowerCase().contains('warning')) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }

  IconData _getRiskIcon(String assessment) {
    if (assessment.toLowerCase().contains('critical')) {
      return Icons.error;
    } else if (assessment.toLowerCase().contains('warning')) {
      return Icons.warning;
    } else {
      return Icons.check_circle;
    }
  }

  Color _getUsageColor(double percentage, BuildContext context) {
    if (percentage > 0.8) {
      return Theme.of(context).colorScheme.error;
    } else if (percentage > 0.6) {
      return Colors.orange;
    } else {
      return Theme.of(context).colorScheme.primary;
    }
  }
}

/// Extension to get day of year
extension DateTimeExtension on DateTime {
  int get dayOfYear {
    final firstDayOfYear = DateTime(year, 1, 1);
    return difference(firstDayOfYear).inDays + 1;
  }
}