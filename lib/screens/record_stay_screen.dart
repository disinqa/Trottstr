import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:trottstr/widgets/country_selector.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/providers/country_tracking_providers.dart';

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

    final trackingService = ref.read(countryTrackingServiceProvider);

    Future<void> saveCountryEntry() async {
      if (!formKey.currentState!.validate()) return;
      if (selectedCountryCode.value == null) return;

      await trackingService.recordCountryEntry(
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

      // Invalidate providers to trigger UI updates
      invalidateTrackingProviders(ref);
      invalidatePlannedStaysProvider(ref);

      // Show success message and navigate back
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Country entry recorded successfully!')),
        );
        context.pop();
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
                    'The app automatically calculates when you exited the previous country based on your next entry.\n\n'
                    'This helps track your total days in each country for tax residency purposes.',
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
      body: Form(
        key: formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Country Selection
              CountrySelector(
                selectedCountryCode: selectedCountryCode.value,
                onCountrySelected: (countryCode, countryName) {
                  selectedCountryCode.value = countryCode;
                  selectedCountryName.value = countryName;
                },
              ),
              const SizedBox(height: 16),

              // Country Info (if selected)
              if (selectedCountryCode.value != null) ...[
                CountryInfoCard(countryCode: selectedCountryCode.value!),
                const SizedBox(height: 16),
              ],

              // Entry Date Selection
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Entry Date',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      InkWell(
                        onTap: () async {
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
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.outline,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  '${selectedDate.value.day}/${selectedDate.value.month}/${selectedDate.value.year}',
                                  style: Theme.of(context).textTheme.bodyLarge,
                                ),
                              ),
                              Icon(
                                Icons.edit,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Optional Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Optional Details',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 16),

                      // Location
                      TextFormField(
                        controller: locationController,
                        decoration: const InputDecoration(
                          labelText: 'Location',
                          hintText: 'Airport, city, border crossing...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.location_on),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Purpose
                      TextFormField(
                        controller: purposeController,
                        decoration: const InputDecoration(
                          labelText: 'Purpose of Visit',
                          hintText: 'Tourism, business, family visit...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.business_center),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Notes
                      TextFormField(
                        controller: notesController,
                        maxLines: 3,
                        decoration: const InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Additional information...',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.note),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Save Button
              AsyncButtonBuilder(
                onPressed: selectedCountryCode.value != null
                    ? saveCountryEntry
                    : null,
                builder: (context, child, callback, buttonState) {
                  return FilledButton(
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
                  );
                },
                onError: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Failed to save entry')),
                  );
                },
                child: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0),
                  child: Text('Record Entry', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
