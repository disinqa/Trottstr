import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/widgets/country_breakdown_modal.dart';
import 'package:trottstr/utils/country_flags.dart';
import 'package:trottstr/providers/optimized_tracking_providers.dart';

/// Expandable widget showing chronological history of visited countries
class ExpandableCountryList extends ConsumerStatefulWidget {
  final VoidCallback? onCountrySelected;

  const ExpandableCountryList({super.key, this.onCountrySelected});

  @override
  ConsumerState<ExpandableCountryList> createState() =>
      _ExpandableCountryListState();
}

class _ExpandableCountryListState extends ConsumerState<ExpandableCountryList>
    with TickerProviderStateMixin {
  bool _isExpanded = false;
  late AnimationController _animationController;
  late Animation<double> _expandAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _toggleExpansion() {
    setState(() {
      _isExpanded = !_isExpanded;
      if (_isExpanded) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final trackingService = ref.read(countryTrackingServiceProvider);
    final entries = ref.watch(optimizedCurrentYearEntriesProvider);
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
          child: Center(child: Text('Error loading data: ${trackingState.error}')),
        ),
      );
    }

    final countryHistory = _buildCountryHistory(entries);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Header with current country and optimistic indicator
          _buildHeader(context, countryHistory, isOptimistic),

          // Expandable list
          AnimatedBuilder(
            animation: _expandAnimation,
            builder: (context, child) {
              return ClipRect(
                child: Align(
                  alignment: Alignment.topCenter,
                  heightFactor: _expandAnimation.value,
                  child: child,
                ),
              );
            },
            child: _buildExpandableContent(
              context,
              countryHistory,
              trackingService,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(
    BuildContext context,
    List<CountryVisitInfo> countryHistory,
    bool isOptimistic,
  ) {
    final currentCountry =
        countryHistory.isNotEmpty && countryHistory.first.isCurrentLocation
        ? countryHistory.first
        : null;

    // If no current location, don't show current location section at all
    if (currentCountry == null) {
      return InkWell(
        onTap: _toggleExpansion,
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              // Travel history icon
              Container(
                width: 64,
                height: 40,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(
                      context,
                    ).colorScheme.outline.withOpacity(0.2),
                  ),
                ),
                child: Icon(
                  Icons.history,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(width: 16),

              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'No Active Check-in',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      countryHistory.isNotEmpty
                          ? 'Tap to view ${countryHistory.length} countries visited'
                          : 'Record an entry to start tracking',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Expand/collapse indicator
              AnimatedRotation(
                turns: _isExpanded ? 0.5 : 0.0,
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  Icons.keyboard_arrow_down,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return InkWell(
      onTap: _toggleExpansion,
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Row(
          children: [
            // Country flag
            Text(
              CountryFlags.getFlagOptimized(currentCountry.countryCode),
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Current Location',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (isOptimistic) ...[
                        const SizedBox(width: 8),
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
                      ],
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    currentCountry.countryName,
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Since ${DateFormat('MMM dd').format(currentCountry.lastEntry)}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),

            // Expand/collapse indicator
            AnimatedRotation(
              turns: _isExpanded ? 0.5 : 0.0,
              duration: const Duration(milliseconds: 300),
              child: Icon(
                Icons.keyboard_arrow_down,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpandableContent(
    BuildContext context,
    List<CountryVisitInfo> countryHistory,
    CountryTrackingService trackingService,
  ) {
    if (countryHistory.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            const Divider(height: 1),
            const SizedBox(height: 20),
            Icon(
              Icons.travel_explore,
              size: 48,
              color: Theme.of(
                context,
              ).colorScheme.onSurfaceVariant.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No Travel History',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Start recording your travels to see your country history here.',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        const Divider(height: 1),

        // History header
        Padding(
          padding: const EdgeInsets.all(20.0),
          child: Row(
            children: [
              Icon(
                Icons.history,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Travel History (${countryHistory.length} countries)',
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
            ],
          ),
        ),

        // Country list
        Consumer(
          builder: (context, ref, child) {
            final risks = ref.watch(optimizedTaxResidencyRisksProvider);
            final trackingState = ref.watch(optimizedTrackingProvider);

            // Show loading only on initial load
            if (trackingState is TrackingDataLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: countryHistory.length,
              separatorBuilder: (context, index) =>
                  const Divider(height: 1, indent: 72),
              itemBuilder: (context, index) {
                final country = countryHistory[index];
                final risk = risks[country.countryCode];

                return _buildCountryListItem(context, country, risk);
              },
            );
          },
        ),

        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildCountryListItem(
    BuildContext context,
    CountryVisitInfo country,
    TaxResidencyRisk? risk,
  ) {
    final statusColor = risk != null
        ? _getRiskColor(context, risk.riskLevel)
        : null;
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      leading: Text(
        CountryFlags.getFlagOptimized(country.countryCode),
        style: const TextStyle(fontSize: 28),
      ),
      title: Text(
        country.countryName,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Last visit: ${DateFormat('MMM dd, yyyy').format(country.lastEntry)}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          if (risk != null) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: statusColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${risk.currentDays}/${risk.threshold} days (${risk.percentageUsed.toStringAsFixed(0)}%)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (risk != null && risk.riskLevel.index >= RiskLevel.high.index)
            Icon(Icons.warning, color: statusColor, size: 20),
          const SizedBox(width: 8),
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ],
      ),
      onTap: () {
        if (risk != null) {
          _showCountryBreakdown(context, country, risk);
        }
        widget.onCountrySelected?.call();
      },
    );
  }

  void _showCountryBreakdown(
    BuildContext context,
    CountryVisitInfo country,
    TaxResidencyRisk risk,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (context) => CountryBreakdownModal(
        countryCode: country.countryCode,
        countryName: country.countryName,
        risk: risk,
      ),
    );
  }

  List<CountryVisitInfo> _buildCountryHistory(List<CountryEntry> entries) {
    final Map<String, CountryVisitInfo> countryMap = {};

    // Group entries by country and find last entry date
    for (final entry in entries) {
      final existing = countryMap[entry.countryCode];
      if (existing == null || entry.entryDate.isAfter(existing.lastEntry)) {
        countryMap[entry.countryCode] = CountryVisitInfo(
          countryCode: entry.countryCode,
          countryName: _getCountryName(entry.countryCode),
          lastEntry: entry.entryDate,
          isCurrentLocation: false, // Will be set below
        );
      }
    }

    // Determine current location (entry without exit date)
    String? currentLocationCode;
    final currentEntries = entries
        .where((entry) => entry.exitDate == null)
        .toList();
    if (currentEntries.isNotEmpty) {
      // Sort by entry date and get the most recent one without exit date
      currentEntries.sort((a, b) => b.entryDate.compareTo(a.entryDate));
      currentLocationCode = currentEntries.first.countryCode;
    }

    // Update the country map with current location info
    for (final key in countryMap.keys) {
      final info = countryMap[key]!;
      countryMap[key] = CountryVisitInfo(
        countryCode: info.countryCode,
        countryName: info.countryName,
        lastEntry: info.lastEntry,
        isCurrentLocation: key == currentLocationCode,
      );
    }

    // Sort by last entry date (most recent first)
    final sortedCountries = countryMap.values.toList()
      ..sort((a, b) => b.lastEntry.compareTo(a.lastEntry));

    return sortedCountries;
  }

  String _getCountryName(String countryCode) {
    final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);
    return rule?.countryName ?? countryCode;
  }

  Color _getRiskColor(BuildContext context, RiskLevel riskLevel) {
    switch (riskLevel) {
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
}

/// Information about a country visit
class CountryVisitInfo {
  final String countryCode;
  final String countryName;
  final DateTime lastEntry;
  final bool isCurrentLocation;

  const CountryVisitInfo({
    required this.countryCode,
    required this.countryName,
    required this.lastEntry,
    required this.isCurrentLocation,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CountryVisitInfo &&
          runtimeType == other.runtimeType &&
          countryCode == other.countryCode;

  @override
  int get hashCode => countryCode.hashCode;
}
