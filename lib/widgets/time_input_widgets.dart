import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:trottstr/models/time_limit_models.dart';

/// Widget for inputting time duration with flexible units
class TimeDurationInput extends HookWidget {
  final TimeDuration? initialValue;
  final ValueChanged<TimeDuration>? onChanged;
  final String? labelText;
  final String? helperText;
  final bool enabled;
  final String? errorText;
  final bool showConversion;
  final List<TimeUnit> allowedUnits;

  const TimeDurationInput({
    super.key,
    this.initialValue,
    this.onChanged,
    this.labelText,
    this.helperText,
    this.enabled = true,
    this.errorText,
    this.showConversion = true,
    this.allowedUnits = TimeUnit.values,
  });

  @override
  Widget build(BuildContext context) {
    final valueController = useTextEditingController();
    final selectedUnit = useState<TimeUnit>(
      initialValue?.unit ?? TimeUnit.days,
    );

    // Initialize controller with initial value
    useEffect(() {
      if (initialValue != null) {
        valueController.text = initialValue!.value.toString();
        selectedUnit.value = initialValue!.unit;
      }
      return null;
    }, [initialValue]);

    void notifyChange() {
      final value = int.tryParse(valueController.text);
      if (value != null && value > 0) {
        final duration = TimeDuration(value: value, unit: selectedUnit.value);
        onChanged?.call(duration);
      }
    }

    final currentDuration = useMemoized(() {
      final value = int.tryParse(valueController.text);
      if (value != null && value > 0) {
        return TimeDuration(value: value, unit: selectedUnit.value);
      }
      return null;
    }, [valueController.text, selectedUnit.value]);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            // Value input field
            Expanded(
              flex: 2,
              child: TextField(
                controller: valueController,
                enabled: enabled,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(4),
                ],
                decoration: InputDecoration(
                  labelText: labelText ?? 'Duration',
                  helperText: helperText,
                  errorText: errorText,
                  border: const OutlineInputBorder(),
                  prefixIcon: const Icon(Icons.schedule),
                ),
                onChanged: (_) => notifyChange(),
              ),
            ),
            
            const SizedBox(width: 12),
            
            // Unit selector
            Expanded(
              flex: 1,
              child: DropdownButtonFormField<TimeUnit>(
                value: selectedUnit.value,
                decoration: const InputDecoration(
                  labelText: 'Unit',
                  border: OutlineInputBorder(),
                ),
                items: allowedUnits.map((unit) {
                  return DropdownMenuItem<TimeUnit>(
                    value: unit,
                    child: Text(unit.pluralName),
                  );
                }).toList(),
                onChanged: enabled ? (unit) {
                  if (unit != null) {
                    selectedUnit.value = unit;
                    notifyChange();
                  }
                } : null,
              ),
            ),
          ],
        ),
        
        // Show conversion to days if enabled and has valid value
        if (showConversion && currentDuration != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                const SizedBox(width: 8),
                Text(
                  'Equivalent to ${currentDuration.totalDays} days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Widget for selecting visa type with icon and description
class VisaTypeSelector extends StatelessWidget {
  final VisaType? selectedType;
  final ValueChanged<VisaType>? onChanged;
  final String? labelText;
  final bool enabled;
  final List<VisaType> availableTypes;

  const VisaTypeSelector({
    super.key,
    this.selectedType,
    this.onChanged,
    this.labelText,
    this.enabled = true,
    this.availableTypes = VisaType.values,
  });

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<VisaType>(
      value: selectedType,
      decoration: InputDecoration(
        labelText: labelText ?? 'Visa Type',
        border: const OutlineInputBorder(),
        prefixIcon: selectedType != null 
          ? Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                selectedType!.icon,
                style: const TextStyle(fontSize: 20),
              ),
            )
          : const Icon(Icons.card_travel),
      ),
      items: availableTypes.map((visaType) {
        return DropdownMenuItem<VisaType>(
          value: visaType,
          child: Row(
            children: [
              Text(
                visaType.icon,
                style: const TextStyle(fontSize: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(visaType.displayName),
              ),
            ],
          ),
        );
      }).toList(),
      onChanged: enabled ? (VisaType? value) {
        if (value != null) {
          onChanged?.call(value);
        }
      } : null,
    );
  }
}

/// Compact widget for displaying and editing time duration
class CompactTimeDurationChip extends StatelessWidget {
  final TimeDuration duration;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;
  final bool isDefault;
  final Color? backgroundColor;

  const CompactTimeDurationChip({
    super.key,
    required this.duration,
    this.onTap,
    this.onDelete,
    this.isDefault = false,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    if (onDelete != null) {
      return Chip(
        backgroundColor: backgroundColor ??
          (isDefault
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              duration.displayString,
              style: TextStyle(
                color: isDefault
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
                fontWeight: isDefault ? FontWeight.w600 : null,
              ),
            ),
            if (isDefault) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DEFAULT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        deleteIcon: const Icon(Icons.close, size: 18),
        onDeleted: onDelete,
      );
    } else {
      return ActionChip(
        backgroundColor: backgroundColor ??
          (isDefault
            ? Theme.of(context).colorScheme.primaryContainer
            : Theme.of(context).colorScheme.surfaceContainerHighest),
        label: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              duration.displayString,
              style: TextStyle(
                color: isDefault
                  ? Theme.of(context).colorScheme.onPrimaryContainer
                  : Theme.of(context).colorScheme.onSurface,
                fontWeight: isDefault ? FontWeight.w600 : null,
              ),
            ),
            if (isDefault) ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'DEFAULT',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: Theme.of(context).colorScheme.onPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        onPressed: onTap,
      );
    }
  }
}

/// Widget for editing visa time limits with optional rolling period
class VisaTimeLimitEditor extends HookWidget {
  final VisaTimeLimit? initialLimit;
  final ValueChanged<VisaTimeLimit>? onChanged;
  final VoidCallback? onRemove;
  final bool showRemoveButton;

  const VisaTimeLimitEditor({
    super.key,
    this.initialLimit,
    this.onChanged,
    this.onRemove,
    this.showRemoveButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final selectedVisaType = useState<VisaType?>(initialLimit?.visaType);
    final maxStayDuration = useState<TimeDuration?>(initialLimit?.maxStay);
    final hasPeriod = useState<bool>(initialLimit?.perPeriod != null);
    final periodDuration = useState<TimeDuration?>(initialLimit?.perPeriod);
    final descriptionController = useTextEditingController(
      text: initialLimit?.description ?? '',
    );

    void notifyChange() {
      if (selectedVisaType.value != null && maxStayDuration.value != null) {
        final limit = VisaTimeLimit(
          visaType: selectedVisaType.value!,
          maxStay: maxStayDuration.value!,
          perPeriod: hasPeriod.value ? periodDuration.value : null,
          description: descriptionController.text.trim().isEmpty 
            ? null 
            : descriptionController.text.trim(),
          createdAt: initialLimit?.createdAt ?? DateTime.now(),
          updatedAt: DateTime.now(),
        );
        onChanged?.call(limit);
      }
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with visa type and remove button
            Row(
              children: [
                Expanded(
                  child: VisaTypeSelector(
                    selectedType: selectedVisaType.value,
                    onChanged: (type) {
                      selectedVisaType.value = type;
                      notifyChange();
                    },
                  ),
                ),
                if (showRemoveButton) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                    tooltip: 'Remove visa type',
                  ),
                ],
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Maximum stay duration
            TimeDurationInput(
              initialValue: maxStayDuration.value,
              labelText: 'Maximum Stay',
              helperText: 'Maximum allowed stay duration',
              onChanged: (duration) {
                maxStayDuration.value = duration;
                notifyChange();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Rolling period toggle
            CheckboxListTile(
              title: const Text('Has rolling period restriction'),
              subtitle: const Text('e.g., 90 days per 180 days'),
              value: hasPeriod.value,
              onChanged: (value) {
                hasPeriod.value = value ?? false;
                if (!hasPeriod.value) {
                  periodDuration.value = null;
                }
                notifyChange();
              },
              contentPadding: EdgeInsets.zero,
            ),
            
            // Period duration (if enabled)
            if (hasPeriod.value) ...[
              const SizedBox(height: 16),
              TimeDurationInput(
                initialValue: periodDuration.value,
                labelText: 'Per Period',
                helperText: 'The period in which the maximum stay applies',
                onChanged: (duration) {
                  periodDuration.value = duration;
                  notifyChange();
                },
              ),
            ],
            
            const SizedBox(height: 16),
            
            // Description/notes
            TextField(
              controller: descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                helperText: 'Additional notes about this visa type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.notes),
              ),
              onChanged: (_) => notifyChange(),
            ),
            
            // Preview of the limit
            if (selectedVisaType.value != null && maxStayDuration.value != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedVisaType.value!.icon,
                      style: const TextStyle(fontSize: 20),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selectedVisaType.value!.displayName,
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          Text(
                            hasPeriod.value && periodDuration.value != null
                              ? '${maxStayDuration.value!.displayString} per ${periodDuration.value!.displayString}'
                              : maxStayDuration.value!.displayString,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Quick time duration picker with preset options
class QuickDurationPicker extends StatelessWidget {
  final TimeDuration? selectedDuration;
  final ValueChanged<TimeDuration>? onChanged;
  final List<TimeDuration> presetDurations;

  const QuickDurationPicker({
    super.key,
    this.selectedDuration,
    this.onChanged,
    this.presetDurations = const [
      TimeDuration(value: 30, unit: TimeUnit.days),
      TimeDuration(value: 60, unit: TimeUnit.days),
      TimeDuration(value: 90, unit: TimeUnit.days),
      TimeDuration(value: 6, unit: TimeUnit.months),
      TimeDuration(value: 1, unit: TimeUnit.years),
    ],
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Select',
          style: Theme.of(context).textTheme.labelMedium,
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: presetDurations.map((duration) {
            final isSelected = selectedDuration == duration;
            return FilterChip(
              label: Text(duration.displayString),
              selected: isSelected,
              onSelected: (_) => onChanged?.call(duration),
              selectedColor: Theme.of(context).colorScheme.primaryContainer,
              checkmarkColor: Theme.of(context).colorScheme.onPrimaryContainer,
            );
          }).toList(),
        ),
      ],
    );
  }
}

/// Widget for displaying time duration with conversion info
class TimeDurationDisplay extends StatelessWidget {
  final TimeDuration duration;
  final bool showConversion;
  final bool showIcon;
  final TextStyle? textStyle;

  const TimeDurationDisplay({
    super.key,
    required this.duration,
    this.showConversion = true,
    this.showIcon = true,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (showIcon) ...[
          const Icon(Icons.schedule, size: 16),
          const SizedBox(width: 4),
        ],
        Text(
          duration.displayString,
          style: textStyle ?? Theme.of(context).textTheme.bodyMedium,
        ),
        if (showConversion && duration.unit != TimeUnit.days) ...[
          Text(
            ' (${duration.totalDays} days)',
            style: (textStyle ?? Theme.of(context).textTheme.bodyMedium)?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ],
    );
  }
}