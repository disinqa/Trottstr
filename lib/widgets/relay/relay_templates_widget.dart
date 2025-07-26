import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:trottstr/models/relay_models.dart';
import 'package:trottstr/providers/relay_providers.dart';
import 'package:trottstr/services/relay_management_service.dart';

/// Widget for managing relay templates
class RelayTemplatesWidget extends HookConsumerWidget {
  const RelayTemplatesWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 2);

    return Column(
      children: [
        // Tab bar
        TabBar(
          controller: tabController,
          tabs: const [
            Tab(text: 'Built-in Templates'),
            Tab(text: 'Custom Templates'),
          ],
        ),
        
        // Tab views
        Expanded(
          child: TabBarView(
            controller: tabController,
            children: const [
              _BuiltInTemplatesTab(),
              _CustomTemplatesTab(),
            ],
          ),
        ),
      ],
    );
  }
}

/// Tab showing built-in templates
class _BuiltInTemplatesTab extends ConsumerWidget {
  const _BuiltInTemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final builtInTemplates = ref.watch(builtInTemplatesProvider);

    if (builtInTemplates.isEmpty) {
      return _buildEmptyState(
        context,
        icon: Icons.library_books_outlined,
        title: 'No Built-in Templates',
        subtitle: 'Built-in templates will be loaded automatically',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: builtInTemplates.length,
      itemBuilder: (context, index) {
        final template = builtInTemplates[index];
        return _buildTemplateCard(context, ref, template, isBuiltIn: true);
      },
    );
  }
}

/// Tab showing custom templates
class _CustomTemplatesTab extends ConsumerWidget {
  const _CustomTemplatesTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customTemplates = ref.watch(customTemplatesProvider);

    return Column(
      children: [
        // Add template button
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => _showCreateTemplateDialog(context, ref),
              icon: const Icon(Icons.add),
              label: const Text('Create Template'),
            ),
          ),
        ),
        
        // Templates list
        Expanded(
          child: customTemplates.isEmpty
              ? _buildEmptyState(
                  context,
                  icon: Icons.bookmark_border,
                  title: 'No Custom Templates',
                  subtitle: 'Create templates to save your relay configurations',
                  action: FilledButton.icon(
                    onPressed: () => _showCreateTemplateDialog(context, ref),
                    icon: const Icon(Icons.add),
                    label: const Text('Create Template'),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: customTemplates.length,
                  itemBuilder: (context, index) {
                    final template = customTemplates[index];
                    return _buildTemplateCard(context, ref, template, isBuiltIn: false);
                  },
                ),
        ),
      ],
    );
  }
}

Widget _buildEmptyState(
  BuildContext context, {
  required IconData icon,
  required String title,
  required String subtitle,
  Widget? action,
}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          icon,
          size: 64,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
        const SizedBox(height: 16),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        if (action != null) ...[
          const SizedBox(height: 24),
          action,
        ],
      ],
    ),
  );
}

Widget _buildTemplateCard(
  BuildContext context,
  WidgetRef ref,
  RelayTemplate template, {
  required bool isBuiltIn,
}) {
  return Card(
    margin: const EdgeInsets.only(bottom: 12),
    child: Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              CircleAvatar(
                backgroundColor: isBuiltIn
                    ? Colors.blue.withOpacity(0.1)
                    : Colors.purple.withOpacity(0.1),
                child: Icon(
                  isBuiltIn ? Icons.verified : Icons.bookmark,
                  color: isBuiltIn ? Colors.blue : Colors.purple,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            template.name,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isBuiltIn)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.blue.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'BUILT-IN',
                              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                color: Colors.blue,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                    Text(
                      template.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                onSelected: (value) => _handleTemplateAction(context, ref, template, value),
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'apply',
                    child: ListTile(
                      leading: Icon(Icons.play_arrow),
                      title: Text('Apply Template'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'apply_replace',
                    child: ListTile(
                      leading: Icon(Icons.swap_horiz),
                      title: Text('Replace All Relays'),
                      dense: true,
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'view',
                    child: ListTile(
                      leading: Icon(Icons.visibility),
                      title: Text('View Details'),
                      dense: true,
                    ),
                  ),
                  if (!isBuiltIn) ...[
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'edit',
                      child: ListTile(
                        leading: Icon(Icons.edit),
                        title: Text('Edit'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: ListTile(
                        leading: Icon(Icons.copy),
                        title: Text('Duplicate'),
                        dense: true,
                      ),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem(
                      value: 'delete',
                      child: ListTile(
                        leading: Icon(Icons.delete, color: Colors.red),
                        title: Text('Delete', style: TextStyle(color: Colors.red)),
                        dense: true,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          // Template details
          _buildTemplateDetails(context, template),
          
          const SizedBox(height: 12),
          
          // Action buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => _applyTemplate(context, ref, template, false),
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Add Relays'),
              ),
              const SizedBox(width: 8),
              FilledButton.icon(
                onPressed: () => _showApplyTemplateDialog(context, ref, template),
                icon: const Icon(Icons.play_arrow, size: 16),
                label: const Text('Apply'),
              ),
            ],
          ),
        ],
      ),
    ),
  );
}

Widget _buildTemplateDetails(BuildContext context, RelayTemplate template) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      // Relay count and metadata
      Row(
        children: [
          Icon(
            Icons.dns,
            size: 16,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          const SizedBox(width: 4),
          Text(
            '${template.relays.length} relays',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(width: 16),
          if (template.createdAt != null) ...[
            Icon(
              Icons.schedule,
              size: 16,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 4),
            Text(
              _formatDate(template.createdAt!),
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
      
      const SizedBox(height: 8),
      
      // Relay preview
      if (template.relays.isNotEmpty) ...[
        Text(
          'Relays:',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Wrap(
          spacing: 4,
          runSpacing: 4,
          children: template.relays.take(3).map((relay) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                relay.name,
                style: Theme.of(context).textTheme.labelSmall,
              ),
            );
          }).toList()
            ..addAll(template.relays.length > 3
                ? [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Text(
                        '+${template.relays.length - 3} more',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ]
                : []),
        ),
      ],
    ],
  );
}

void _handleTemplateAction(
  BuildContext context,
  WidgetRef ref,
  RelayTemplate template,
  String action,
) {
  switch (action) {
    case 'apply':
      _applyTemplate(context, ref, template, false);
      break;
    case 'apply_replace':
      _applyTemplate(context, ref, template, true);
      break;
    case 'view':
      _showTemplateDetails(context, template);
      break;
    case 'edit':
      _showEditTemplateDialog(context, ref, template);
      break;
    case 'duplicate':
      _duplicateTemplate(context, ref, template);
      break;
    case 'delete':
      _showDeleteTemplateDialog(context, ref, template);
      break;
  }
}

Future<void> _applyTemplate(
  BuildContext context,
  WidgetRef ref,
  RelayTemplate template,
  bool replaceExisting,
) async {
  try {
    final service = ref.read(relayManagementServiceProvider);
    await service.applyTemplate(template.id, replaceExisting: replaceExisting);
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            replaceExisting
                ? 'Template applied, all relays replaced'
                : 'Template applied, relays added',
          ),
        ),
      );
    }
  } catch (e) {
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to apply template: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

void _showApplyTemplateDialog(
  BuildContext context,
  WidgetRef ref,
  RelayTemplate template,
) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('Apply "${template.name}"'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('This template contains ${template.relays.length} relays.'),
          const SizedBox(height: 16),
          const Text('How would you like to apply it?'),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        OutlinedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _applyTemplate(context, ref, template, false);
          },
          child: const Text('Add to existing'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            _applyTemplate(context, ref, template, true);
          },
          child: const Text('Replace all'),
        ),
      ],
    ),
  );
}

void _showTemplateDetails(BuildContext context, RelayTemplate template) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(template.name),
      content: SizedBox(
        width: 400,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(template.description),
              const SizedBox(height: 16),
              Text(
                'Relays (${template.relays.length}):',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...template.relays.map((relay) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    const Icon(Icons.dns, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            relay.name,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          Text(
                            relay.url,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Close'),
        ),
      ],
    ),
  );
}

void _showCreateTemplateDialog(BuildContext context, WidgetRef ref) {
  // TODO: Implement create template dialog
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Create template feature coming soon!')),
  );
}

void _showEditTemplateDialog(BuildContext context, WidgetRef ref, RelayTemplate template) {
  // TODO: Implement edit template dialog
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Edit template feature coming soon!')),
  );
}

void _duplicateTemplate(BuildContext context, WidgetRef ref, RelayTemplate template) {
  // TODO: Implement duplicate template
  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(content: Text('Duplicate template feature coming soon!')),
  );
}

void _showDeleteTemplateDialog(BuildContext context, WidgetRef ref, RelayTemplate template) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Delete Template'),
      content: Text('Are you sure you want to delete "${template.name}"?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // TODO: Implement delete template
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Delete template feature coming soon!')),
            );
          },
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Delete'),
        ),
      ],
    ),
  );
}

String _formatDate(DateTime date) {
  return '${date.day}/${date.month}/${date.year}';
}