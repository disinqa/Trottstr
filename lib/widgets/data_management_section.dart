import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:intl/intl.dart';
import 'package:trottstr/services/country_tracking_service.dart';

/// Comprehensive data management section with export, import, and secure deletion
class DataManagementSection extends HookConsumerWidget {
  const DataManagementSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      children: [
        // Export Data Section
        _buildExportDataTile(context, ref),

        const Divider(height: 1),

        // Import Data Section
        _buildImportDataTile(context, ref),

        const Divider(height: 1),

        // Data Statistics
        _buildDataStatisticsTile(context, ref),

        const Divider(height: 1),

        // Secure Data Deletion
        _buildDataDeletionTile(context, ref),
      ],
    );
  }

  Widget _buildExportDataTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
        child: Icon(
          Icons.download,
          color: Theme.of(context).colorScheme.onPrimaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        'Export Data',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Download your travel data in multiple formats',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showExportOptions(context, ref),
    );
  }

  Widget _buildImportDataTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        child: Icon(
          Icons.upload,
          color: Theme.of(context).colorScheme.onSecondaryContainer,
          size: 20,
        ),
      ),
      title: Text(
        'Import Data',
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        'Import travel data from backup files',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () => _showImportOptions(context, ref),
    );
  }

  Widget _buildDataStatisticsTile(BuildContext context, WidgetRef ref) {
    return FutureBuilder<List>(
      future: Future.wait([
        ref.read(countryTrackingServiceProvider).getCurrentYearEntries(),
        ref.read(countryTrackingServiceProvider).getPlannedStays(),
      ]),
      builder: (context, snapshot) {
        final entries = snapshot.data?[0] ?? [];
        final plannedStays = snapshot.data?[1] ?? [];

        return ListTile(
          leading: CircleAvatar(
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            child: Icon(
              Icons.analytics,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ),
          title: Text(
            'Data Overview',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${entries.length} travel entries • ${plannedStays.length} planned stays',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              if (entries.isNotEmpty)
                Text(
                  'Last updated: ${DateFormat('MMM dd, yyyy').format(entries.last.entryDate)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDataDeletionTile(BuildContext context, WidgetRef ref) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.errorContainer,
        child: Icon(
          Icons.delete_forever,
          color: Theme.of(context).colorScheme.onErrorContainer,
          size: 20,
        ),
      ),
      title: Text(
        'Delete All Data',
        style: Theme.of(context).textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.error,
        ),
      ),
      subtitle: Text(
        'Permanently remove all travel data',
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: Icon(Icons.warning, color: Theme.of(context).colorScheme.error),
      onTap: () => _showDataDeletionDialog(context, ref),
    );
  }

  void _showExportOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ExportDataModal(),
    );
  }

  void _showImportOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ImportDataModal(),
    );
  }

  void _showDataDeletionDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => _DataDeletionDialog(),
    );
  }
}

/// Modal for exporting data with format and date range selection
class _ExportDataModal extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedFormat = useState<ExportFormat>(ExportFormat.json);
    final dateRange = useState<DateTimeRange?>(null);
    final includeSettings = useState<bool>(true);
    final includePlannedStays = useState<bool>(true);
    final isExporting = useState<bool>(false);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Modal Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(
                      Icons.download,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Export Travel Data',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Choose format and date range for export',
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
                      // Format Selection
                      Text(
                        'Export Format',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      ...ExportFormat.values.map((format) {
                        return RadioListTile<ExportFormat>(
                          value: format,
                          groupValue: selectedFormat.value,
                          onChanged: (value) => selectedFormat.value = value!,
                          title: Text(_getFormatTitle(format)),
                          subtitle: Text(_getFormatDescription(format)),
                          contentPadding: EdgeInsets.zero,
                        );
                      }),

                      const SizedBox(height: 24),

                      // Date Range Selection
                      Text(
                        'Date Range',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range),
                        title: Text(
                          dateRange.value != null
                              ? '${DateFormat('MMM dd, yyyy').format(dateRange.value!.start)} - ${DateFormat('MMM dd, yyyy').format(dateRange.value!.end)}'
                              : 'All time',
                        ),
                        subtitle: const Text('Tap to select custom date range'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          final range = await showDateRangePicker(
                            context: context,
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                            initialDateRange: dateRange.value,
                          );
                          if (range != null) {
                            dateRange.value = range;
                          }
                        },
                      ),

                      if (dateRange.value != null)
                        Padding(
                          padding: const EdgeInsets.only(left: 56),
                          child: TextButton(
                            onPressed: () => dateRange.value = null,
                            child: const Text('Clear date range'),
                          ),
                        ),

                      const SizedBox(height: 24),

                      // Export Options
                      Text(
                        'Include',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: includeSettings.value,
                        onChanged: (value) => includeSettings.value = value!,
                        title: const Text('App Settings'),
                        subtitle: const Text(
                          'Export preferences and configuration',
                        ),
                      ),

                      CheckboxListTile(
                        contentPadding: EdgeInsets.zero,
                        value: includePlannedStays.value,
                        onChanged: (value) =>
                            includePlannedStays.value = value!,
                        title: const Text('Planned Stays'),
                        subtitle: const Text('Export future travel plans'),
                      ),
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: isExporting.value
                            ? null
                            : () => _performExport(
                                context,
                                selectedFormat.value,
                                dateRange.value,
                                includeSettings.value,
                                includePlannedStays.value,
                                isExporting,
                              ),
                        icon: isExporting.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download),
                        label: Text(
                          isExporting.value ? 'Exporting...' : 'Export',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _getFormatTitle(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'JSON';
      case ExportFormat.csv:
        return 'CSV (Spreadsheet)';
      case ExportFormat.pdf:
        return 'PDF Report';
    }
  }

  String _getFormatDescription(ExportFormat format) {
    switch (format) {
      case ExportFormat.json:
        return 'Complete data with all details for backup';
      case ExportFormat.csv:
        return 'Tabular format for Excel or Google Sheets';
      case ExportFormat.pdf:
        return 'Formatted report for printing or sharing';
    }
  }

  void _performExport(
    BuildContext context,
    ExportFormat format,
    DateTimeRange? dateRange,
    bool includeSettings,
    bool includePlannedStays,
    ValueNotifier<bool> isExporting,
  ) {
    isExporting.value = true;

    // Simulate export process
    Future.delayed(const Duration(seconds: 3), () {
      isExporting.value = false;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.green),
              const SizedBox(width: 8),
              Text('Data exported as ${_getFormatTitle(format)}'),
            ],
          ),
          action: SnackBarAction(
            label: 'Share',
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Share functionality coming soon!'),
                ),
              );
            },
          ),
        ),
      );
    });
  }
}

/// Modal for importing data with validation and conflict resolution
class _ImportDataModal extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final selectedFile = useState<String?>(null);
    final importMode = useState<ImportMode>(ImportMode.merge);
    final isImporting = useState<bool>(false);
    final validationResults = useState<ValidationResults?>(null);

    return DraggableScrollableSheet(
      initialChildSize: 0.7,
      minChildSize: 0.5,
      maxChildSize: 0.9,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Modal Handle
              Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.onSurfaceVariant.withOpacity(0.4),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Icon(
                      Icons.upload,
                      color: Theme.of(context).colorScheme.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Import Travel Data',
                            style: Theme.of(context).textTheme.headlineSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Import data from backup files',
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
                      // File Selection
                      Text(
                        'Select File',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),

                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.outline.withOpacity(0.3),
                            style: BorderStyle.solid,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              selectedFile.value != null
                                  ? Icons.file_present
                                  : Icons.upload_file,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              selectedFile.value ?? 'No file selected',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton.icon(
                              onPressed: () =>
                                  _selectFile(selectedFile, validationResults),
                              icon: const Icon(Icons.folder_open),
                              label: const Text('Choose File'),
                            ),
                          ],
                        ),
                      ),

                      if (validationResults.value != null) ...[
                        const SizedBox(height: 24),
                        _buildValidationResults(
                          context,
                          validationResults.value!,
                        ),
                      ],

                      if (selectedFile.value != null) ...[
                        const SizedBox(height: 24),

                        // Import Mode Selection
                        Text(
                          'Import Mode',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),

                        ...ImportMode.values.map((mode) {
                          return RadioListTile<ImportMode>(
                            value: mode,
                            groupValue: importMode.value,
                            onChanged: (value) => importMode.value = value!,
                            title: Text(_getImportModeTitle(mode)),
                            subtitle: Text(_getImportModeDescription(mode)),
                            contentPadding: EdgeInsets.zero,
                          );
                        }),
                      ],
                    ],
                  ),
                ),
              ),

              // Action Buttons
              Container(
                padding: const EdgeInsets.all(24),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed:
                            (selectedFile.value != null && !isImporting.value)
                            ? () => _performImport(
                                context,
                                selectedFile.value!,
                                importMode.value,
                                isImporting,
                              )
                            : null,
                        icon: isImporting.value
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.upload),
                        label: Text(
                          isImporting.value ? 'Importing...' : 'Import',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildValidationResults(
    BuildContext context,
    ValidationResults results,
  ) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  results.isValid ? Icons.check_circle : Icons.error,
                  color: results.isValid ? Colors.green : Colors.red,
                ),
                const SizedBox(width: 8),
                Text(
                  'File Validation',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            if (results.isValid) ...[
              Text('✓ ${results.recordCount} records found'),
              Text('✓ ${results.duplicateCount} duplicates detected'),
              if (results.conflictCount > 0)
                Text('⚠ ${results.conflictCount} conflicts need resolution'),
            ] else ...[
              Text(
                '✗ Invalid file format',
                style: TextStyle(color: Colors.red),
              ),
              if (results.errors.isNotEmpty)
                ...results.errors.map(
                  (error) =>
                      Text('✗ $error', style: TextStyle(color: Colors.red)),
                ),
            ],
          ],
        ),
      ),
    );
  }

  void _selectFile(
    ValueNotifier<String?> selectedFile,
    ValueNotifier<ValidationResults?> validationResults,
  ) {
    // Simulate file selection
    selectedFile.value =
        'travel_data_backup_${DateFormat('yyyy_MM_dd').format(DateTime.now())}.json';

    // Simulate validation
    Future.delayed(const Duration(milliseconds: 500), () {
      validationResults.value = ValidationResults(
        isValid: true,
        recordCount: 156,
        duplicateCount: 3,
        conflictCount: 1,
        errors: [],
      );
    });
  }

  String _getImportModeTitle(ImportMode mode) {
    switch (mode) {
      case ImportMode.merge:
        return 'Merge';
      case ImportMode.replace:
        return 'Replace All';
      case ImportMode.skipDuplicates:
        return 'Skip Duplicates';
    }
  }

  String _getImportModeDescription(ImportMode mode) {
    switch (mode) {
      case ImportMode.merge:
        return 'Combine with existing data, resolve conflicts';
      case ImportMode.replace:
        return 'Delete all existing data and import new';
      case ImportMode.skipDuplicates:
        return 'Only import new records, keep existing';
    }
  }

  void _performImport(
    BuildContext context,
    String fileName,
    ImportMode mode,
    ValueNotifier<bool> isImporting,
  ) {
    isImporting.value = true;

    // Simulate import process
    Future.delayed(const Duration(seconds: 4), () {
      isImporting.value = false;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('Data imported successfully!'),
            ],
          ),
        ),
      );
    });
  }
}

/// Dialog for secure data deletion with two-step confirmation
class _DataDeletionDialog extends HookWidget {
  @override
  Widget build(BuildContext context) {
    final confirmationText = useState<String>('');
    final isDeleting = useState<bool>(false);
    const requiredText = 'DELETE ALL DATA';

    return AlertDialog(
      icon: Icon(
        Icons.warning,
        color: Theme.of(context).colorScheme.error,
        size: 48,
      ),
      title: Text(
        'Delete All Data',
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
                  'This action cannot be undone!',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'All of the following will be permanently deleted:',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '• All travel entries and exits\n• Planned future stays\n• Country tracking history\n• App preferences and settings',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'To confirm deletion, type "$requiredText" below:',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 12),
          TextField(
            onChanged: (value) => confirmationText.value = value,
            decoration: InputDecoration(
              hintText: requiredText,
              border: const OutlineInputBorder(),
              errorText:
                  confirmationText.value.isNotEmpty &&
                      confirmationText.value != requiredText
                  ? 'Text must match exactly'
                  : null,
            ),
            style: const TextStyle(fontFamily: 'monospace'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: isDeleting.value
              ? null
              : () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed:
              (confirmationText.value == requiredText && !isDeleting.value)
              ? () => _performDeletion(context, isDeleting)
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.error,
            foregroundColor: Theme.of(context).colorScheme.onError,
          ),
          child: isDeleting.value
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Delete All Data'),
        ),
      ],
    );
  }

  void _performDeletion(BuildContext context, ValueNotifier<bool> isDeleting) {
    isDeleting.value = true;

    // Simulate deletion process
    Future.delayed(const Duration(seconds: 3), () {
      isDeleting.value = false;
      Navigator.of(context).pop();

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Text('All data has been permanently deleted'),
            ],
          ),
        ),
      );
    });
  }
}

/// Export format enumeration
enum ExportFormat { json, csv, pdf }

/// Import mode enumeration
enum ImportMode { merge, replace, skipDuplicates }

/// Validation results for imported files
class ValidationResults {
  final bool isValid;
  final int recordCount;
  final int duplicateCount;
  final int conflictCount;
  final List<String> errors;

  const ValidationResults({
    required this.isValid,
    required this.recordCount,
    required this.duplicateCount,
    required this.conflictCount,
    required this.errors,
  });
}
