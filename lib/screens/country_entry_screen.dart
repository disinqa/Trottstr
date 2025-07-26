import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/providers/country_tracking_providers.dart';
import 'package:trottstr/utils/country_utils.dart';
import 'package:trottstr/models/country_stay.dart';

/// Screen for recording country entry/exit
class CountryEntryScreen extends HookConsumerWidget {
  const CountryEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCountry = useState<String?>(null);
    final entryDate = useState<DateTime>(DateTime.now());
    final exitDate = useState<DateTime?>(null);
    final location = useState<String>('');
    final purpose = useState<String>('');
    final notes = useState<String>('');
    final isPlanned = useState<bool>(false);
    final isProcessing = useState<bool>(false);

    final locationController = useTextEditingController();
    final purposeController = useTextEditingController();
    final notesController = useTextEditingController();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Record Country Entry'),
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Entry Type Toggle
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Entry Type',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(
                          value: false,
                          label: Text('Actual Entry'),
                          icon: Icon(Icons.flight_land),
                        ),
                        ButtonSegment(
                          value: true,
                          label: Text('Planned Trip'),
                          icon: Icon(Icons.event),
                        ),
                      ],
                      selected: {isPlanned.value},
                      onSelectionChanged: (Set<bool> selection) {
                        isPlanned.value = selection.first;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Country Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Country',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<String>(
                      value: selectedCountry.value,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: 'Select a country',
                        prefixIcon: Icon(Icons.public),
                      ),
                      items: CountryUtils.getAllCountries()
                          .map((country) => DropdownMenuItem(
                                value: country.code,
                                child: Row(
                                  children: [
                                    Text(
                                      country.flag,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(country.name),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        selectedCountry.value = value;
                      },
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please select a country';
                        }
                        return null;
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Date Selection
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Dates',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Entry Date
                    Row(
                      children: [
                        const Icon(Icons.login),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPlanned.value ? 'Start Date' : 'Entry Date',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                '${entryDate.value.day}/${entryDate.value.month}/${entryDate.value.year}',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: entryDate.value,
                              firstDate: DateTime(2020),
                              lastDate: DateTime(2030),
                            );
                            if (date != null) {
                              entryDate.value = date;
                            }
                          },
                          child: const Text('Change'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Exit Date (optional)
                    Row(
                      children: [
                        const Icon(Icons.logout),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isPlanned.value ? 'End Date' : 'Exit Date (Optional)',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              Text(
                                exitDate.value != null
                                    ? '${exitDate.value!.day}/${exitDate.value!.month}/${exitDate.value!.year}'
                                    : 'Not set (currently here)',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () async {
                            final date = await showDatePicker(
                              context: context,
                              initialDate: exitDate.value ?? DateTime.now(),
                              firstDate: entryDate.value,
                              lastDate: DateTime(2030),
                            );
                            exitDate.value = date;
                          },
                          child: Text(exitDate.value != null ? 'Change' : 'Set'),
                        ),
                      ],
                    ),
                    if (exitDate.value != null) ...[
                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: () {
                          exitDate.value = null;
                        },
                        child: const Text('Clear Exit Date'),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Additional Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Additional Details',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 16),
                    
                    // Location
                    TextFormField(
                      controller: locationController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Location (Optional)',
                        hintText: 'e.g., London Heathrow, Berlin',
                        prefixIcon: Icon(Icons.location_on),
                      ),
                      onChanged: (value) => location.value = value,
                    ),
                    const SizedBox(height: 16),
                    
                    // Purpose
                    TextFormField(
                      controller: purposeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Purpose (Optional)',
                        hintText: 'e.g., Tourism, Business, Transit',
                        prefixIcon: Icon(Icons.work),
                      ),
                      onChanged: (value) => purpose.value = value,
                    ),
                    const SizedBox(height: 16),
                    
                    // Notes
                    TextFormField(
                      controller: notesController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        labelText: 'Notes (Optional)',
                        hintText: 'Any additional notes about this entry',
                        prefixIcon: Icon(Icons.note),
                      ),
                      maxLines: 3,
                      onChanged: (value) => notes.value = value,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Duration Preview
            if (selectedCountry.value != null) ...[
              Card(
                color: Theme.of(context).colorScheme.primaryContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.info,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Duration Preview',
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _calculateDurationText(entryDate.value, exitDate.value),
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Submit Button
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: isProcessing.value || selectedCountry.value == null
                    ? null
                    : () async {
                        await _submitEntry(
                          context,
                          ref,
                          isProcessing,
                          selectedCountry.value!,
                          entryDate.value,
                          exitDate.value,
                          location.value,
                          purpose.value,
                          notes.value,
                          isPlanned.value,
                        );
                      },
                icon: isProcessing.value
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.save),
                label: Text(isProcessing.value ? 'Saving...' : 'Save Entry'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _calculateDurationText(DateTime entry, DateTime? exit) {
    final endDate = exit ?? DateTime.now();
    final duration = endDate.difference(entry).inDays + 1;
    
    if (exit != null) {
      return 'Duration: $duration days';
    } else {
      return 'Current stay: $duration days (ongoing)';
    }
  }

  Future<void> _submitEntry(
    BuildContext context,
    WidgetRef ref,
    ValueNotifier<bool> isProcessing,
    String countryCode,
    DateTime entryDate,
    DateTime? exitDate,
    String location,
    String purpose,
    String notes,
    bool isPlanned,
  ) async {
    if (isProcessing.value) return;

    isProcessing.value = true;

    try {
      final service = ref.read(countryTrackingServiceProvider);
      
      // Generate unique ID
      final id = DateTime.now().millisecondsSinceEpoch.toString();
      
      // Create country entry
      final entry = CountryEntry(
        id: id,
        countryCode: countryCode,
        entryDate: entryDate,
        exitDate: exitDate,
        notes: notes.isEmpty ? null : notes,
        location: location.isEmpty ? null : location,
        purpose: purpose.isEmpty ? null : purpose,
      );

      if (isPlanned) {
        // For planned entries, create a planned stay instead
        if (exitDate == null) {
          throw Exception('End date is required for planned trips');
        }
        
        final plannedStay = PlannedStay(
          id: id,
          countryCode: countryCode,
          startDate: entryDate,
          endDate: exitDate,
          purpose: purpose.isEmpty ? null : purpose,
          notes: notes.isEmpty ? null : notes,
        );
        
        await service.addPlannedStay(plannedStay);
      } else {
        await service.addCountryEntry(entry);
      }

      // Invalidate providers to refresh data
      invalidateTrackingProviders(ref);

      if (!context.mounted) return;

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isPlanned ? 'Planned trip saved successfully!' : 'Country entry saved successfully!',
          ),
          backgroundColor: Theme.of(context).colorScheme.primary,
        ),
      );

      // Go back
      Navigator.of(context).pop();

    } catch (e) {
      if (!context.mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error saving entry: $e'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    } finally {
      isProcessing.value = false;
    }
  }
}