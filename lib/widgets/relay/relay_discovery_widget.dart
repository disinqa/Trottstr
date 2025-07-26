import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/providers/relay_providers.dart';
import 'package:trottstr/services/relay_management_service.dart';

/// Widget for discovering new relays based on travel destinations and preferences
class RelayDiscoveryWidget extends HookConsumerWidget {
  const RelayDiscoveryWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final destinationsController = useTextEditingController();
    final maxResultsController = useTextEditingController(text: '20');
    final isDiscovering = useState(false);
    final discoveryResults = useState<List<RelayDiscoveryResult>>([]);
    final selectedResults = useState<Set<String>>({});

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Discovery form
        _buildDiscoveryForm(
          context,
          destinationsController,
          maxResultsController,
          isDiscovering,
          discoveryResults,
          ref,
        ),
        
        const SizedBox(height: 16),
        
        // Results
        Expanded(
          child: _buildDiscoveryResults(
            context,
            ref,
            discoveryResults.value,
            selectedResults,
            isDiscovering.value,
          ),
        ),
      ],
    );
  }

  Widget _buildDiscoveryForm(
    BuildContext context,
    TextEditingController destinationsController,
    TextEditingController maxResultsController,
    ValueNotifier<bool> isDiscovering,
    ValueNotifier<List<RelayDiscoveryResult>> discoveryResults,
    WidgetRef ref,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Discover Relays',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Find optimal relays based on your travel destinations',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            
            // Destinations input
            TextField(
              controller: destinationsController,
              decoration: InputDecoration(
                labelText: 'Travel Destinations',
                hintText: 'e.g., Germany, Japan, USA (optional)',
                helperText: 'Enter countries or regions you frequently visit',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.travel_explore),
              ),
            ),
            
            const SizedBox(height: 16),
            
            // Max results and discovery button
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextField(
                    controller: maxResultsController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Max Results',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  flex: 3,
                  child: FilledButton.icon(
                    onPressed: isDiscovering.value
                        ? null
                        : () => _performDiscovery(
                            context,
                            ref,
                            destinationsController.text,
                            maxResultsController.text,
                            isDiscovering,
                            discoveryResults,
                          ),
                    icon: isDiscovering.value
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.search),
                    label: Text(isDiscovering.value ? 'Discovering...' : 'Discover'),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Quick discovery buttons
            _buildQuickDiscoveryButtons(
              context,
              ref,
              maxResultsController.text,
              isDiscovering,
              discoveryResults,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickDiscoveryButtons(
    BuildContext context,
    WidgetRef ref,
    String maxResults,
    ValueNotifier<bool> isDiscovering,
    ValueNotifier<List<RelayDiscoveryResult>> discoveryResults,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Discovery',
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ActionChip(
              label: const Text('European Relays'),
              onPressed: isDiscovering.value
                  ? null
                  : () => _performDiscovery(
                      context,
                      ref,
                      'Germany, France, Netherlands, Switzerland',
                      maxResults,
                      isDiscovering,
                      discoveryResults,
                    ),
            ),
            ActionChip(
              label: const Text('Asian Relays'),
              onPressed: isDiscovering.value
                  ? null
                  : () => _performDiscovery(
                      context,
                      ref,
                      'Japan, Singapore, Hong Kong, South Korea',
                      maxResults,
                      isDiscovering,
                      discoveryResults,
                    ),
            ),
            ActionChip(
              label: const Text('American Relays'),
              onPressed: isDiscovering.value
                  ? null
                  : () => _performDiscovery(
                      context,
                      ref,
                      'USA, Canada, Brazil, Mexico',
                      maxResults,
                      isDiscovering,
                      discoveryResults,
                    ),
            ),
            ActionChip(
              label: const Text('Global Popular'),
              onPressed: isDiscovering.value
                  ? null
                  : () => _performDiscovery(
                      context,
                      ref,
                      '',
                      maxResults,
                      isDiscovering,
                      discoveryResults,
                    ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDiscoveryResults(
    BuildContext context,
    WidgetRef ref,
    List<RelayDiscoveryResult> results,
    ValueNotifier<Set<String>> selectedResults,
    bool isDiscovering,
  ) {
    if (isDiscovering) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Discovering relays...'),
          ],
        ),
      );
    }

    if (results.isEmpty) {
      return _buildEmptyResultsState(context);
    }

    return Column(
      children: [
        // Results header with selection actions
        _buildResultsHeader(context, ref, results, selectedResults),
        
        // Results list
        Expanded(
          child: ListView.builder(
            itemCount: results.length,
            itemBuilder: (context, index) {
              final result = results[index];
              return _buildDiscoveryResultCard(
                context,
                result,
                selectedResults.value.contains(result.url),
                (selected) => _toggleResultSelection(selectedResults, result.url, selected),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEmptyResultsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(height: 16),
          Text(
            'No Results Yet',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Start a discovery to find optimal relays',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsHeader(
    BuildContext context,
    WidgetRef ref,
    List<RelayDiscoveryResult> results,
    ValueNotifier<Set<String>> selectedResults,
  ) {
    final selectedCount = selectedResults.value.length;
    final hasSelection = selectedCount > 0;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Discovery Results',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    hasSelection
                        ? '$selectedCount of ${results.length} selected'
                        : '${results.length} relays found',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            
            if (hasSelection) ...[
              OutlinedButton.icon(
                onPressed: () => selectedResults.value = {},
                icon: const Icon(Icons.clear),
                label: const Text('Clear'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _addSelectedRelays(context, ref, results, selectedResults),
                icon: const Icon(Icons.add),
                label: Text('Add $selectedCount'),
              ),
            ] else ...[
              TextButton.icon(
                onPressed: () => _selectAllResults(selectedResults, results),
                icon: const Icon(Icons.select_all),
                label: const Text('Select All'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildDiscoveryResultCard(
    BuildContext context,
    RelayDiscoveryResult result,
    bool isSelected,
    Function(bool) onSelectionChanged,
  ) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: CheckboxListTile(
        value: isSelected,
        onChanged: (value) => onSelectionChanged(value ?? false),
        title: Text(
          result.name ?? _formatUrl(result.url),
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result.description != null) ...[
              Text(result.description!),
              const SizedBox(height: 4),
            ],
            Text(
              _formatUrl(result.url),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontFamily: 'monospace',
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                _buildScoreChip(context, result.score),
                if (result.latency != null) _buildLatencyChip(context, result.latency!),
                _buildReachabilityChip(context, result.isReachable),
              ],
            ),
          ],
        ),
        secondary: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              result.isReachable ? Icons.wifi : Icons.wifi_off,
              color: result.isReachable ? Colors.green : Colors.red,
            ),
            const SizedBox(height: 4),
            Text(
              '${(result.score * 100).toStringAsFixed(0)}%',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: _getScoreColor(result.score),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildScoreChip(BuildContext context, double score) {
    final color = _getScoreColor(score);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${(score * 100).toStringAsFixed(0)}%',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLatencyChip(BuildContext context, int latency) {
    final color = _getLatencyColor(latency);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.speed, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            '${latency}ms',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReachabilityChip(BuildContext context, bool isReachable) {
    final color = isReachable ? Colors.green : Colors.red;
    final text = isReachable ? 'Reachable' : 'Unreachable';
    final icon = isReachable ? Icons.check_circle : Icons.error;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _performDiscovery(
    BuildContext context,
    WidgetRef ref,
    String destinationsText,
    String maxResultsText,
    ValueNotifier<bool> isDiscovering,
    ValueNotifier<List<RelayDiscoveryResult>> discoveryResults,
  ) async {
    if (isDiscovering.value) return;

    isDiscovering.value = true;
    
    try {
      final destinations = destinationsText.isNotEmpty
          ? destinationsText.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList()
          : null;
      
      final maxResults = int.tryParse(maxResultsText) ?? 20;
      
      final service = ref.read(relayManagementServiceProvider);
      final results = await service.discoverRelays(
        destinations: destinations,
        maxResults: maxResults,
      );
      
      discoveryResults.value = results;
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Found ${results.length} relays'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Discovery failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      isDiscovering.value = false;
    }
  }

  void _toggleResultSelection(
    ValueNotifier<Set<String>> selectedResults,
    String url,
    bool selected,
  ) {
    final newSelection = Set<String>.from(selectedResults.value);
    if (selected) {
      newSelection.add(url);
    } else {
      newSelection.remove(url);
    }
    selectedResults.value = newSelection;
  }

  void _selectAllResults(
    ValueNotifier<Set<String>> selectedResults,
    List<RelayDiscoveryResult> results,
  ) {
    selectedResults.value = results.map((r) => r.url).toSet();
  }

  Future<void> _addSelectedRelays(
    BuildContext context,
    WidgetRef ref,
    List<RelayDiscoveryResult> results,
    ValueNotifier<Set<String>> selectedResults,
  ) async {
    final service = ref.read(relayManagementServiceProvider);
    final selectedUrls = selectedResults.value;
    
    try {
      for (final result in results) {
        if (selectedUrls.contains(result.url)) {
          final relay = RelayConfig(
            id: DateTime.now().millisecondsSinceEpoch.toString() + 
                 result.url.hashCode.toString(),
            url: result.url,
            name: result.name ?? _formatUrl(result.url),
            description: result.description ?? 'Discovered relay',
            latency: result.latency,
            metadata: result.metadata,
          );
          
          await service.addRelay(relay);
        }
      }
      
      selectedResults.value = {};
      
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Added ${selectedUrls.length} relays'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add relays: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatUrl(String url) {
    return url.replaceFirst('wss://', '').replaceFirst('ws://', '');
  }

  Color _getScoreColor(double score) {
    if (score >= 0.8) return Colors.green;
    if (score >= 0.6) return Colors.orange;
    if (score >= 0.4) return Colors.deepOrange;
    return Colors.red;
  }

  Color _getLatencyColor(int latency) {
    if (latency < 50) return Colors.green;
    if (latency < 100) return Colors.orange;
    return Colors.red;
  }
}