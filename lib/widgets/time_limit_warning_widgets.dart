import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/providers/time_limit_providers.dart';
import 'package:trottstr/utils/country_flags.dart';

/// Widget for displaying time limit warnings as a banner
class TimeLimitWarningBanner extends ConsumerWidget {
  final String countryCode;
  final bool showDismiss;
  final VoidCallback? onDismiss;
  final VoidCallback? onTap;

  const TimeLimitWarningBanner({
    super.key,
    required this.countryCode,
    this.showDismiss = true,
    this.onDismiss,
    this.onTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warnings = ref.watch(timeLimitWarningsProvider);
    final warning = warnings[countryCode];

    if (warning == null) {
      return const SizedBox.shrink();
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _getWarningColor(warning.severity),
              width: 2,
            ),
          ),
          child: Row(
            children: [
              // Country flag and icon
              Column(
                children: [
                  Text(
                    CountryFlags.getFlagOptimized(countryCode),
                    style: const TextStyle(fontSize: 24),
                  ),
                  const SizedBox(height: 4),
                  Icon(
                    _getWarningIcon(warning.severity),
                    color: _getWarningColor(warning.severity),
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(width: 12),

              // Warning content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            warning.countryName,
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (warning.isCurrentLocation)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.blue,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              'CURRENT',
                              style: Theme.of(context).textTheme.labelSmall
                                  ?.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      warning.message,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: _getWarningColor(warning.severity),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    TimeLimitProgressBar(
                      current: warning.daysSpent,
                      maximum: warning.maxDays,
                      color: _getWarningColor(warning.severity),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${warning.daysSpent}/${warning.maxDays} days (${warning.percentageUsed.toStringAsFixed(1)}%)',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),

              // Dismiss button
              if (showDismiss)
                IconButton(
                  onPressed: onDismiss,
                  icon: const Icon(Icons.close),
                  iconSize: 20,
                ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getWarningColor(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.low:
        return Colors.green;
      case WarningSeverity.medium:
        return Colors.orange;
      case WarningSeverity.high:
        return Colors.deepOrange;
      case WarningSeverity.critical:
        return Colors.red;
      case WarningSeverity.exceeded:
        return Colors.purple;
    }
  }

  IconData _getWarningIcon(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.low:
        return Icons.info;
      case WarningSeverity.medium:
        return Icons.warning;
      case WarningSeverity.high:
        return Icons.warning;
      case WarningSeverity.critical:
        return Icons.error;
      case WarningSeverity.exceeded:
        return Icons.block;
    }
  }
}

/// Compact warning indicator for use in lists or smaller spaces
class CompactTimeLimitIndicator extends ConsumerWidget {
  final String countryCode;
  final bool showText;

  const CompactTimeLimitIndicator({
    super.key,
    required this.countryCode,
    this.showText = true,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warnings = ref.watch(timeLimitWarningsProvider);
    final warning = warnings[countryCode];

    if (warning == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: _getWarningColor(warning.severity).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _getWarningColor(warning.severity), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getWarningIcon(warning.severity),
            size: 16,
            color: _getWarningColor(warning.severity),
          ),
          if (showText) ...[
            const SizedBox(width: 4),
            Text(
              '${warning.daysRemaining}d',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: _getWarningColor(warning.severity),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Color _getWarningColor(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.low:
        return Colors.green;
      case WarningSeverity.medium:
        return Colors.orange;
      case WarningSeverity.high:
        return Colors.deepOrange;
      case WarningSeverity.critical:
        return Colors.red;
      case WarningSeverity.exceeded:
        return Colors.purple;
    }
  }

  IconData _getWarningIcon(WarningSeverity severity) {
    switch (severity) {
      case WarningSeverity.low:
        return Icons.info;
      case WarningSeverity.medium:
        return Icons.warning;
      case WarningSeverity.high:
        return Icons.warning;
      case WarningSeverity.critical:
        return Icons.error;
      case WarningSeverity.exceeded:
        return Icons.block;
    }
  }
}

/// Progress bar showing time limit usage
class TimeLimitProgressBar extends StatelessWidget {
  final int current;
  final int maximum;
  final Color? color;
  final double height;

  const TimeLimitProgressBar({
    super.key,
    required this.current,
    required this.maximum,
    this.color,
    this.height = 8,
  });

  @override
  Widget build(BuildContext context) {
    final progress = (current / maximum).clamp(0.0, 1.0);
    final effectiveColor = color ?? Theme.of(context).colorScheme.primary;

    return Container(
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(height / 2),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: FractionallySizedBox(
        alignment: Alignment.centerLeft,
        widthFactor: progress,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(height / 2),
            color: effectiveColor,
          ),
        ),
      ),
    );
  }
}

/// Current location status widget for dashboard
class CurrentLocationStatusWidget extends ConsumerWidget {
  final VoidCallback? onTap;

  const CurrentLocationStatusWidget({super.key, this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentStatus = ref.watch(currentLocationTimeLimitProvider);

    if (currentStatus == null) {
      return const SizedBox.shrink();
    }

    final hasWarning = currentStatus.hasWarning;
    final isExceeded = currentStatus.isExceeded;
    final isApproaching = currentStatus.isApproachingLimit;

    Color statusColor;
    IconData statusIcon;
    String statusText;

    if (isExceeded) {
      statusColor = Colors.red;
      statusIcon = Icons.error;
      statusText = 'Limit Exceeded';
    } else if (isApproaching) {
      statusColor = Colors.orange;
      statusIcon = Icons.warning;
      statusText = 'Approaching Limit';
    } else if (hasWarning) {
      statusColor = Colors.blue;
      statusIcon = Icons.info;
      statusText = 'Time Tracking';
    } else {
      statusColor = Colors.green;
      statusIcon = Icons.check_circle;
      statusText = 'Within Limits';
    }

    return Card(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 24),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Current Location',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  Text(
                    CountryFlags.getFlagOptimized(currentStatus.countryCode),
                    style: const TextStyle(fontSize: 24),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          statusText,
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(
                                color: statusColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${currentStatus.daysSpent} days spent',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  if (currentStatus.warning != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: statusColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${currentStatus.warning!.daysRemaining}d left',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: statusColor,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                ],
              ),
              if (currentStatus.warning != null) ...[
                const SizedBox(height: 8),
                TimeLimitProgressBar(
                  current: currentStatus.warning!.daysSpent,
                  maximum: currentStatus.warning!.maxDays,
                  color: statusColor,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget showing all active warnings
class AllWarningsOverview extends ConsumerWidget {
  final VoidCallback? onWarningTap;

  const AllWarningsOverview({super.key, this.onWarningTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warnings = ref.watch(timeLimitWarningsProvider);
    final stats = ref.watch(timeLimitStatisticsProvider);

    if (warnings.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'No time limit warnings',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.green,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final criticalWarnings = warnings.values
        .where(
          (w) =>
              w.severity == WarningSeverity.critical ||
              w.severity == WarningSeverity.exceeded,
        )
        .toList();
    final highWarnings = warnings.values
        .where((w) => w.severity == WarningSeverity.high)
        .toList();
    final otherWarnings = warnings.values
        .where(
          (w) =>
              w.severity == WarningSeverity.medium ||
              w.severity == WarningSeverity.low,
        )
        .toList();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  criticalWarnings.isNotEmpty ? Icons.error : Icons.warning,
                  color: criticalWarnings.isNotEmpty
                      ? Colors.red
                      : Colors.orange,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Time Limit Warnings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${warnings.length}',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Critical warnings
            if (criticalWarnings.isNotEmpty) ...[
              _buildWarningSection(
                context,
                'Critical',
                criticalWarnings,
                Colors.red,
                Icons.error,
              ),
              const SizedBox(height: 8),
            ],

            // High warnings
            if (highWarnings.isNotEmpty) ...[
              _buildWarningSection(
                context,
                'High Priority',
                highWarnings,
                Colors.deepOrange,
                Icons.warning,
              ),
              const SizedBox(height: 8),
            ],

            // Other warnings
            if (otherWarnings.isNotEmpty) ...[
              _buildWarningSection(
                context,
                'Other',
                otherWarnings,
                Colors.orange,
                Icons.info,
              ),
            ],

            // Statistics summary
            const SizedBox(height: 12),
            stats.when(
              data: (statistics) => Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Countries Configured',
                        '${statistics.totalConfigurations}',
                      ),
                    ),
                    Container(
                      width: 1,
                      height: 32,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    Expanded(
                      child: _buildStatItem(
                        context,
                        'Countries with Time',
                        '${statistics.countriesWithTimeSpent}',
                      ),
                    ),
                  ],
                ),
              ),
              loading: () => const SizedBox.shrink(),
              error: (_, __) => const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWarningSection(
    BuildContext context,
    String title,
    List<TimeLimitWarning> warnings,
    Color color,
    IconData icon,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 6),
            Text(
              '$title (${warnings.length})',
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: warnings
              .map(
                (warning) => Chip(
                  avatar: Text(
                    CountryFlags.getFlagOptimized(warning.countryCode),
                    style: const TextStyle(fontSize: 14),
                  ),
                  label: Text(
                    '${warning.countryCode}: ${warning.daysRemaining}d',
                    style: TextStyle(
                      fontSize: 12,
                      color: color,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  backgroundColor: color.withValues(alpha: 0.1),
                  side: BorderSide(color: color, width: 1),
                ),
              )
              .toList(),
        ),
      ],
    );
  }

  Widget _buildStatItem(BuildContext context, String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall,
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}

/// Floating action button with warning indicator
class TimeLimitFAB extends ConsumerWidget {
  final VoidCallback? onPressed;

  const TimeLimitFAB({super.key, this.onPressed});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final warnings = ref.watch(timeLimitWarningsProvider);
    final hasWarnings = warnings.isNotEmpty;
    final hasCritical = warnings.values.any(
      (w) =>
          w.severity == WarningSeverity.critical ||
          w.severity == WarningSeverity.exceeded,
    );

    return Stack(
      children: [
        FloatingActionButton(
          onPressed: onPressed,
          backgroundColor: hasCritical
              ? Colors.red
              : hasWarnings
              ? Colors.orange
              : null,
          child: Icon(
            hasWarnings ? Icons.warning : Icons.schedule,
            color: hasWarnings ? Colors.white : null,
          ),
        ),
        if (hasWarnings)
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                '${warnings.length}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
