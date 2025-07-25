import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/utils/country_flags.dart';

/// Enhanced modal showing detailed country breakdown with comprehensive information
class CountryBreakdownModal extends ConsumerWidget {
  final String countryCode;
  final String countryName;
  final TaxResidencyRisk risk;

  const CountryBreakdownModal({
    super.key,
    required this.countryCode,
    required this.countryName,
    required this.risk,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trackingService = ref.read(countryTrackingServiceProvider);

    return DraggableScrollableSheet(
      initialChildSize: 1,
      minChildSize: 0.50,
      maxChildSize: 1,
      builder: (context, scrollController) {
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: Row(
                children: [
                  // Country Flag
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
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          'Travel History & Analytics',
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
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Content
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Days Overview Card
                    _buildDaysOverviewCard(context),
                    const SizedBox(height: 24),

                    // Overstay Status Card
                    _buildOverstayStatusCard(context),
                    const SizedBox(height: 24),

                    // Tax Calculation Card
                    _buildTaxCalculationCard(context),
                    const SizedBox(height: 24),

                    // Entry/Exit History
                    _buildEntryExitHistory(context, trackingService),
                    const SizedBox(height: 24),

                    // Visa Status Card
                    _buildVisaStatusCard(context),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDaysOverviewCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Days Spent',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Circular Progress Indicator
            Center(
              child: SizedBox(
                width: 120,
                height: 120,
                child: Stack(
                  children: [
                    CircularProgressIndicator(
                      value: (risk.currentDays / risk.threshold).clamp(
                        0.0,
                        1.0,
                      ),
                      strokeWidth: 8,
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        _getRiskColor(context),
                      ),
                    ),
                    Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            '${risk.currentDays}',
                            style: Theme.of(context).textTheme.headlineMedium
                                ?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: _getRiskColor(context),
                                ),
                          ),
                          Text(
                            'of ${risk.threshold}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
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

            // Progress Details
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Percentage Used',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      '${risk.percentageUsed.toStringAsFixed(1)}%',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      'Days Remaining',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    Text(
                      risk.daysRemaining > 0 ? '${risk.daysRemaining}' : '0',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: risk.daysRemaining <= 0
                            ? Theme.of(context).colorScheme.error
                            : null,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOverstayStatusCard(BuildContext context) {
    final statusColor = _getRiskColor(context);
    final statusText = _getRiskStatusText();
    final statusIcon = _getRiskStatusIcon();

    return Card(
      color: risk.riskLevel == RiskLevel.exceeded
          ? Theme.of(context).colorScheme.errorContainer
          : risk.riskLevel == RiskLevel.critical
          ? Theme.of(context).colorScheme.surfaceContainerHighest
          : null,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 24),
                const SizedBox(width: 12),
                Text(
                  'Compliance Status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withOpacity(0.3)),
              ),
              child: Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      statusText,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (risk.rule?.description != null) ...[
              Text(
                'Tax Residency Rule',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              Text(
                risk.rule!.description,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (risk.rule?.additionalNotes != null) ...[
                const SizedBox(height: 8),
                Text(
                  risk.rule!.additionalNotes!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTaxCalculationCard(BuildContext context) {
    // Simulate tax calculation based on overstay duration
    final overstayDays = risk.currentDays > risk.threshold
        ? risk.currentDays - risk.threshold
        : 0;
    final estimatedTaxRate = _getEstimatedTaxRate();
    final estimatedTax = _calculateEstimatedTax(overstayDays, estimatedTaxRate);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.calculate,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Tax Implications',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            if (overstayDays > 0) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tax Resident Status Triggered',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You may be liable for local taxes on worldwide income.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              _buildTaxCalculationRow(
                context,
                'Excess Days',
                '$overstayDays days',
              ),
              _buildTaxCalculationRow(
                context,
                'Estimated Tax Rate',
                '${estimatedTaxRate.toStringAsFixed(1)}%',
              ),
              _buildTaxCalculationRow(
                context,
                'Potential Annual Tax',
                '\$${estimatedTax.toStringAsFixed(0)}',
              ),
            ] else ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.check_circle,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Currently within safe limits. No additional tax obligations.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(
                            context,
                          ).colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            Text(
              'Note: These are estimates for guidance only. Consult a tax professional for accurate advice.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTaxCalculationRow(
    BuildContext context,
    String label,
    String value,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: Theme.of(context).textTheme.bodyMedium),
          Text(
            value,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Widget _buildEntryExitHistory(
    BuildContext context,
    CountryTrackingService trackingService,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.history,
              color: Theme.of(context).colorScheme.primary,
              size: 24,
            ),
            const SizedBox(width: 12),
            Text(
              'Entry & Exit History',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 16),

        FutureBuilder<List<CountryEntry>>(
          future: trackingService.getCurrentYearEntries(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            final entries =
                snapshot.data
                    ?.where((e) => e.countryCode == countryCode)
                    .toList() ??
                [];

            if (entries.isEmpty) {
              return Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Center(
                    child: Text(
                      'No travel history recorded for this country.',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              );
            }

            return Card(
              child: Column(
                children: entries
                    .map((entry) => _buildHistoryItem(context, entry))
                    .toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildHistoryItem(BuildContext context, CountryEntry entry) {
    final dateFormat = DateFormat('MMM dd, yyyy');

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.flight_land,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        'Entered Country',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(dateFormat.format(entry.entryDate.toLocal())),
          if (entry.location != null) Text('Location: ${entry.location}'),
          if (entry.purpose != null) Text('Purpose: ${entry.purpose}'),
          if (entry.notes != null) Text('Notes: ${entry.notes}'),
        ],
      ),
      trailing: Text(
        dateFormat.format(entry.entryDate.toLocal()),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }

  Widget _buildVisaStatusCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.credit_card,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  'Visa Status',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Placeholder for visa information
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline,
                        color: Theme.of(context).colorScheme.primary,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Visa Information',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Visa tracking feature coming soon. This will include visa type, validity period, remaining days, and renewal reminders.',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
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

  Color _getRiskColor(BuildContext context) {
    switch (risk.riskLevel) {
      case RiskLevel.low:
        return Colors.green;
      case RiskLevel.medium:
        return Colors.orange;
      case RiskLevel.high:
        return Colors.deepOrange;
      case RiskLevel.critical:
        return Colors.red;
      case RiskLevel.exceeded:
        return Colors.red.shade800;
    }
  }

  String _getRiskStatusText() {
    switch (risk.riskLevel) {
      case RiskLevel.low:
        return 'Compliant - Well within limits';
      case RiskLevel.medium:
        return 'Moderate usage - Monitor carefully';
      case RiskLevel.high:
        return 'High usage - Approaching threshold';
      case RiskLevel.critical:
        return 'Critical - Very close to tax residency';
      case RiskLevel.exceeded:
        return 'Threshold exceeded - Tax resident status';
    }
  }

  IconData _getRiskStatusIcon() {
    switch (risk.riskLevel) {
      case RiskLevel.low:
        return Icons.check_circle;
      case RiskLevel.medium:
        return Icons.watch_later;
      case RiskLevel.high:
        return Icons.warning;
      case RiskLevel.critical:
        return Icons.error_outline;
      case RiskLevel.exceeded:
        return Icons.error;
    }
  }

  double _getEstimatedTaxRate() {
    // Simplified tax rate estimation based on country
    final taxRates = <String, double>{
      'US': 35.0,
      'GB': 45.0,
      'DE': 42.0,
      'FR': 45.0,
      'CA': 33.0,
      'AU': 37.0,
      'SG': 22.0,
      'HK': 17.0,
      'CH': 25.0,
      'NL': 37.0,
      'ES': 37.0,
      'IT': 38.0,
      'JP': 33.0,
      'KR': 24.0,
    };
    return taxRates[countryCode] ?? 25.0; // Default 25%
  }

  double _calculateEstimatedTax(int overstayDays, double taxRate) {
    // Simplified calculation: assume $100K income, proportional tax for overstay
    const assumedIncome = 100000.0;
    final proportionalIncome = (overstayDays / 365.0) * assumedIncome;
    return proportionalIncome * (taxRate / 100.0);
  }
}
