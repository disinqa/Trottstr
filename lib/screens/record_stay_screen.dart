import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:trottstr/widgets/country_selector.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/providers/optimized_tracking_providers.dart';

class RecordStayScreen extends HookConsumerWidget {
  const RecordStayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final formKey = useMemoized(() => GlobalKey<FormState>());
    final selectedCountryCode = useState<String?>(null);
    final selectedCountryName = useState<String?>(null);
    final selectedDate = useState<DateTime>(DateTime.now());
    final notesController = useTextEditingController();
    final locationController = useTextEditingController();
    final purposeController = useTextEditingController();
    final pickerFocusNode = useFocusNode();
    final trackingService = ref.read(countryTrackingServiceProvider);

    Future<void> saveCountryEntry() async {
      if (!formKey.currentState!.validate()) return;
      if (selectedCountryCode.value == null) return;
  
      try {
        // Use optimized provider for immediate UI updates
        await ref.read(optimizedTrackingProvider.notifier).recordEntryOptimistic(
          countryCode: selectedCountryCode.value!,
          entryDate: selectedDate.value,
          notes: notesController.text.trim().isNotEmpty
              ? notesController.text.trim()
              : null,
          location: locationController.text.trim().isNotEmpty
              ? locationController.text.trim()
              : null,
          purpose: purposeController.text.trim().isNotEmpty
              ? purposeController.text.trim()
              : null,
        );
  
        // Show success message and navigate back
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Country entry recorded successfully!'),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: 'View',
                textColor: Theme.of(context).colorScheme.onPrimary,
                onPressed: () {
                  // Navigate to tracking tab to see the update
                  context.pop();
                },
              ),
            ),
          );
          context.pop();
        }
      } catch (error) {
        // Show error message if optimistic update fails
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to save entry: ${error.toString()}'),
              backgroundColor: Theme.of(context).colorScheme.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Country Entry'),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('How to Record Entries'),
                  content: const Text(
                    'Record an entry whenever you arrive in a new country.\n\n'
                    'The app automatically calculates exit dates by using each new country entry as the exit date for your previous location.\n\n'
                    'Your most recent entry will remain as your current location until you record a new entry. This streamlined system eliminates the need to manually track exit dates.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Main scrollable content
          Expanded(
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Country Selection
                    CountrySelector(
                      focusNode: pickerFocusNode,
                      selectedCountryCode: selectedCountryCode.value,
                      onCountrySelected: (countryCode, countryName) {
                        selectedCountryCode.value = countryCode;
                        selectedCountryName.value = countryName;
                      },
                    ),
                    const SizedBox(height: 12),

                    // Country Info (if selected)
                    if (selectedCountryCode.value != null) ...[
                      CountryInfoCard(countryCode: selectedCountryCode.value!),
                      const SizedBox(height: 12),
                    ],

                    // Entry Date Selection - Compact Design
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Entry Date',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 8),
                            InkWell(
                              onTap: () async {
                                pickerFocusNode.unfocus();

                                final date = await showDatePicker(
                                  context: context,
                                  initialDate: selectedDate.value,
                                  firstDate: DateTime(2020),
                                  lastDate: DateTime.now().add(
                                    const Duration(days: 1),
                                  ),
                                );
                                if (date != null) {
                                  selectedDate.value = date;
                                }
                                if (context.mounted) {
                                  pickerFocusNode.unfocus();
                                }
                              },
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.outline,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.calendar_today,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.primary,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${selectedDate.value.day}/${selectedDate.value.month}/${selectedDate.value.year}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyMedium,
                                      ),
                                    ),
                                    Icon(
                                      Icons.edit,
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurfaceVariant,
                                      size: 18,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Optional Details - Progressive Disclosure
                    OptionalDetailsSection(
                      locationController: locationController,
                      purposeController: purposeController,
                      notesController: notesController,
                    ),

                    // Add some bottom padding for the sticky footer
                    const SizedBox(height: 80),
                  ],
                ),
              ),
            ),
          ),

          // Sticky Footer with Save Button
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              border: Border(
                top: BorderSide(
                  color: Theme.of(
                    context,
                  ).colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: SafeArea(
              top: false,
              child: AsyncButtonBuilder(
                onPressed: selectedCountryCode.value != null
                    ? saveCountryEntry
                    : null,
                builder: (context, child, callback, buttonState) {
                  return SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: buttonState.maybeWhen(
                        loading: () => null,
                        orElse: () => callback,
                      ),
                      child: buttonState.maybeWhen(
                        loading: () => const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                        orElse: () => child,
                      ),
                    ),
                  );
                },
                onError: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save entry')),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14.0),
                  child: Text('Record Entry', style: TextStyle(fontSize: 16)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Progressive disclosure widget for optional details
class OptionalDetailsSection extends StatefulWidget {
  final TextEditingController locationController;
  final TextEditingController purposeController;
  final TextEditingController notesController;

  const OptionalDetailsSection({
    super.key,
    required this.locationController,
    required this.purposeController,
    required this.notesController,
  });

  @override
  State<OptionalDetailsSection> createState() => _OptionalDetailsSectionState();
}

class _OptionalDetailsSectionState extends State<OptionalDetailsSection> {
  bool _isExpanded = false;
  bool _hasOptionalData = false;

  @override
  void initState() {
    super.initState();
    _checkForOptionalData();

    // Listen for changes to show/hide expansion indicator
    widget.locationController.addListener(_checkForOptionalData);
    widget.purposeController.addListener(_checkForOptionalData);
    widget.notesController.addListener(_checkForOptionalData);
  }

  @override
  void dispose() {
    widget.locationController.removeListener(_checkForOptionalData);
    widget.purposeController.removeListener(_checkForOptionalData);
    widget.notesController.removeListener(_checkForOptionalData);
    super.dispose();
  }

  void _checkForOptionalData() {
    final hasData =
        widget.locationController.text.isNotEmpty ||
        widget.purposeController.text.isNotEmpty ||
        widget.notesController.text.isNotEmpty;

    if (hasData != _hasOptionalData) {
      setState(() {
        _hasOptionalData = hasData;
        if (hasData && !_isExpanded) {
          _isExpanded = true;
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          // Header with expand/collapse
          InkWell(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline,
                    color: Theme.of(context).colorScheme.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Optional Details',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                  ),
                  if (_hasOptionalData) ...[
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
            ),
          ),

          // Expandable content
          if (_isExpanded) ...[
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              child: Column(
                children: [
                  // Horizontal layout for Location and Purpose
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: widget.locationController,
                          decoration: const InputDecoration(
                            labelText: 'Location',
                            hintText: 'Airport, city...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.location_on, size: 20),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextFormField(
                          controller: widget.purposeController,
                          decoration: const InputDecoration(
                            labelText: 'Purpose',
                            hintText: 'Tourism, business...',
                            border: OutlineInputBorder(),
                            prefixIcon: Icon(Icons.business_center, size: 20),
                            isDense: true,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                          ),
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // Notes field (full width, compact)
                  TextFormField(
                    controller: widget.notesController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      labelText: 'Notes',
                      hintText: 'Additional information...',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.note, size: 20),
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
