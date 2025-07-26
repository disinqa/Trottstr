import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/providers/relay_providers.dart';

/// Widget for filtering and sorting relay list
class RelayFilterWidget extends HookConsumerWidget {
  const RelayFilterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final searchController = useTextEditingController();
    final filter = ref.watch(relayFilterProvider);
    final isExpanded = useState(false);

    // Update search when controller changes
    useEffect(() {
      void onChanged() {
        final newFilter = filter.copyWith(searchQuery: searchController.text);
        ref.read(relayFilterProvider.notifier).state = newFilter;
      }

      searchController.addListener(onChanged);
      return () => searchController.removeListener(onChanged);
    }, [searchController]);

    return Card(
      margin: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Search bar with expand button
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: searchController,
                    decoration: InputDecoration(
                      hintText: 'Search relays...',
                      prefixIcon: const Icon(Icons.search),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Theme.of(
                        context,
                      ).colorScheme.surfaceContainerHighest,
                      suffixIcon: searchController.text.isNotEmpty
                          ? IconButton(
                              onPressed: () {
                                searchController.clear();
                              },
                              icon: const Icon(Icons.clear),
                            )
                          : null,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () => isExpanded.value = !isExpanded.value,
                  icon: Icon(isExpanded.value ? Icons.expand_less : Icons.tune),
                  tooltip: isExpanded.value ? 'Hide filters' : 'Show filters',
                ),
              ],
            ),
          ),

          // Expandable filter options
          if (isExpanded.value) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Status filter
                  _buildStatusFilter(context, ref, filter),
                  const SizedBox(height: 16),

                  // Enabled filter
                  _buildEnabledFilter(context, ref, filter),
                  const SizedBox(height: 16),

                  // Sort options
                  _buildSortOptions(context, ref, filter),
                  const SizedBox(height: 16),

                  // Quick filter chips
                  _buildQuickFilters(context, ref, filter),
                  const SizedBox(height: 16),

                  // Actions
                  _buildFilterActions(context, ref),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStatusFilter(
    BuildContext context,
    WidgetRef ref,
    RelayFilter filter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Status',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: filter.status == null,
              onSelected: (selected) {
                if (selected) {
                  final newFilter = filter.copyWith(status: null);
                  ref.read(relayFilterProvider.notifier).state = newFilter;
                }
              },
            ),
            ...RelayStatus.values.map(
              (status) => FilterChip(
                label: Text(_getStatusLabel(status)),
                selected: filter.status == status,
                onSelected: (selected) {
                  final newFilter = filter.copyWith(
                    status: selected ? status : null,
                  );
                  ref.read(relayFilterProvider.notifier).state = newFilter;
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildEnabledFilter(
    BuildContext context,
    WidgetRef ref,
    RelayFilter filter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'State',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            FilterChip(
              label: const Text('All'),
              selected: filter.enabledOnly == null,
              onSelected: (selected) {
                if (selected) {
                  final newFilter = filter.copyWith(enabledOnly: null);
                  ref.read(relayFilterProvider.notifier).state = newFilter;
                }
              },
            ),
            FilterChip(
              label: const Text('Enabled'),
              selected: filter.enabledOnly == true,
              onSelected: (selected) {
                final newFilter = filter.copyWith(
                  enabledOnly: selected ? true : null,
                );
                ref.read(relayFilterProvider.notifier).state = newFilter;
              },
            ),
            FilterChip(
              label: const Text('Disabled'),
              selected: filter.enabledOnly == false,
              onSelected: (selected) {
                final newFilter = filter.copyWith(
                  enabledOnly: selected ? false : null,
                );
                ref.read(relayFilterProvider.notifier).state = newFilter;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSortOptions(
    BuildContext context,
    WidgetRef ref,
    RelayFilter filter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Sort by',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<RelaySortBy>(
                value: filter.sortBy,
                decoration: InputDecoration(
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                ),
                items: RelaySortBy.values
                    .map(
                      (sortBy) => DropdownMenuItem(
                        value: sortBy,
                        child: Text(_getSortLabel(sortBy)),
                      ),
                    )
                    .toList(),
                onChanged: (value) {
                  if (value != null) {
                    final newFilter = filter.copyWith(sortBy: value);
                    ref.read(relayFilterProvider.notifier).state = newFilter;
                  }
                },
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              onPressed: () {
                final newFilter = filter.copyWith(
                  sortDescending: !filter.sortDescending,
                );
                ref.read(relayFilterProvider.notifier).state = newFilter;
              },
              icon: Icon(
                filter.sortDescending
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
              ),
              tooltip: filter.sortDescending ? 'Descending' : 'Ascending',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickFilters(
    BuildContext context,
    WidgetRef ref,
    RelayFilter filter,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick filters',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text('Connected only'),
              onPressed: () {
                final newFilter = RelayFilter(
                  status: RelayStatus.connected,
                  enabledOnly: true,
                  sortBy: RelaySortBy.latency,
                );
                ref.read(relayFilterProvider.notifier).state = newFilter;
              },
            ),
            ActionChip(
              label: const Text('High priority'),
              onPressed: () {
                final newFilter = RelayFilter(
                  enabledOnly: true,
                  sortBy: RelaySortBy.priority,
                );
                ref.read(relayFilterProvider.notifier).state = newFilter;
              },
            ),
            ActionChip(
              label: const Text('Low latency'),
              onPressed: () {
                final newFilter = RelayFilter(
                  status: RelayStatus.connected,
                  sortBy: RelaySortBy.latency,
                );
                ref.read(relayFilterProvider.notifier).state = newFilter;
              },
            ),
            ActionChip(
              label: const Text('Errors'),
              onPressed: () {
                final newFilter = RelayFilter(
                  status: RelayStatus.error,
                  sortBy: RelaySortBy.lastConnected,
                  sortDescending: true,
                );
                ref.read(relayFilterProvider.notifier).state = newFilter;
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFilterActions(BuildContext context, WidgetRef ref) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: () {
            ref.read(relayFilterProvider.notifier).state = const RelayFilter();
          },
          icon: const Icon(Icons.clear),
          label: const Text('Clear filters'),
        ),
        const Spacer(),
        OutlinedButton.icon(
          onPressed: () => _showFilterPresets(context, ref),
          icon: const Icon(Icons.bookmark),
          label: const Text('Presets'),
        ),
      ],
    );
  }

  void _showFilterPresets(BuildContext context, WidgetRef ref) {
    final presets = [
      ('Default', const RelayFilter()),
      (
        'Connected',
        const RelayFilter(
          status: RelayStatus.connected,
          enabledOnly: true,
          sortBy: RelaySortBy.latency,
        ),
      ),
      (
        'High Priority',
        const RelayFilter(enabledOnly: true, sortBy: RelaySortBy.priority),
      ),
      (
        'Health Issues',
        const RelayFilter(
          status: RelayStatus.error,
          sortBy: RelaySortBy.health,
        ),
      ),
      (
        'Recently Connected',
        const RelayFilter(
          sortBy: RelaySortBy.lastConnected,
          sortDescending: true,
        ),
      ),
    ];

    showModalBottomSheet(
      context: context,
      builder: (context) => Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Filter Presets',
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
          ...presets.map(
            (preset) => ListTile(
              title: Text(preset.$1),
              onTap: () {
                ref.read(relayFilterProvider.notifier).state = preset.$2;
                Navigator.of(context).pop();
              },
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  String _getStatusLabel(RelayStatus status) {
    switch (status) {
      case RelayStatus.connected:
        return 'Connected';
      case RelayStatus.connecting:
        return 'Connecting';
      case RelayStatus.disconnected:
        return 'Disconnected';
      case RelayStatus.error:
        return 'Error';
      case RelayStatus.testing:
        return 'Testing';
    }
  }

  String _getSortLabel(RelaySortBy sortBy) {
    switch (sortBy) {
      case RelaySortBy.name:
        return 'Name';
      case RelaySortBy.priority:
        return 'Priority';
      case RelaySortBy.latency:
        return 'Latency';
      case RelaySortBy.health:
        return 'Health';
      case RelaySortBy.status:
        return 'Status';
      case RelaySortBy.lastConnected:
        return 'Last Connected';
    }
  }
}
