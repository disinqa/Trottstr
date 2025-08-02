import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:trottstr/providers/country_tax_limits_provider.dart';

/// Widget for managing per-country tax residency limits
class CountryTaxLimitsSection extends HookConsumerWidget {
  const CountryTaxLimitsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final countryLimits = ref.watch(countryTaxLimitsProvider);

    return _buildOverviewTile(context, countryLimits);
  }

  Widget _buildOverviewTile(BuildContext context, Map<String, int> limits) {
    final customCount = limits.entries.where((e) => e.value != 183).length;
    final defaultCount = limits.length - customCount;

    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.public,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        'Country Tax Limits',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${limits.length} countries configured',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.arrow_forward_ios,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            size: 16,
          ),
        ],
      ),
      onTap: () => context.push('/country-tax-limits'),
    );
  }
}
