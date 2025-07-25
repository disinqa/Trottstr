import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_typeahead/flutter_typeahead.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/providers/country_tracking_providers.dart';
import 'package:trottstr/services/favorite_countries_service.dart';
import 'package:trottstr/utils/country_flags.dart';
import 'package:trottstr/widgets/edit_country_time_limit_dialog.dart';

/// Base class for search suggestions
abstract class SearchSuggestion {
  const SearchSuggestion();
}

/// Data class for country information
class CountryInfo extends SearchSuggestion {
  final String code;
  final String name;
  final String flag;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
  });

  @override
  String toString() => '$flag $name';
}

/// Section header for organizing suggestions
class SectionHeader extends SearchSuggestion {
  final String title;
  final IconData? icon;

  const SectionHeader({required this.title, this.icon});
}

/// Visual separator between sections
class SectionSeparator extends SearchSuggestion {
  const SectionSeparator();
}

/// Widget for selecting a country with search functionality
class CountrySelector extends HookConsumerWidget {
  final String? selectedCountryCode;
  final void Function(String countryCode, String countryName) onCountrySelected;
  final String? hintText;

  const CountrySelector({
    super.key,
    this.selectedCountryCode,
    required this.onCountrySelected,
    this.hintText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = useTextEditingController();
    final favoriteCountriesAsync = ref.watch(favoriteCountriesProvider);
    final favoriteService = ref.read(favoriteCountriesServiceProvider);

    // Create list of all countries with flags
    final countriesMap = DefaultTaxResidencyRules.getAllCountries();
    final allCountries = countriesMap.entries
        .map(
          (entry) => CountryInfo(
            code: entry.key,
            name: entry.value,
            flag: CountryFlags.getFlagOptimized(entry.key),
          ),
        )
        .toList();

    // Set initial value if selectedCountryCode is provided
    useEffect(() {
      if (selectedCountryCode != null) {
        final selectedCountry = allCountries.firstWhere(
          (country) => country.code == selectedCountryCode,
          orElse: () => CountryInfo(
            code: selectedCountryCode!,
            name: selectedCountryCode!,
            flag: CountryFlags.getFlagOptimized(selectedCountryCode!),
          ),
        );
        controller.text = selectedCountry.toString();
      }
      return null;
    }, [selectedCountryCode]);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Country', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12),

              // Recent countries section
              favoriteCountriesAsync.when(
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
                data: (favoriteCodes) {
                  if (favoriteCodes.isEmpty) return const SizedBox.shrink();

                  final favoriteCountries = favoriteCodes
                      .map(
                        (code) => allCountries.firstWhere(
                          (country) => country.code == code,
                          orElse: () => CountryInfo(
                            code: code,
                            name: code,
                            flag: CountryFlags.getFlagOptimized(code),
                          ),
                        ),
                      )
                      .toList();

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Favorites',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: favoriteCountries
                            .map(
                              (country) => _buildFavoriteCountryChip(
                                context,
                                country,
                                controller,
                                favoriteService,
                                ref,
                              ),
                            )
                            .toList(),
                      ),
                      const SizedBox(height: 16),
                    ],
                  );
                },
              ),

              // Search field
              TypeAheadField<SearchSuggestion>(
                controller: controller,
                suggestionsCallback: (pattern) {
                  final favoriteCodes =
                      favoriteCountriesAsync.asData?.value ?? <String>[];
                  return _buildSuggestions(
                    pattern,
                    allCountries,
                    favoriteCodes,
                  );
                },
                itemBuilder: (context, suggestion) {
                  return _buildSuggestionItem(context, suggestion, ref);
                },
                onSelected: (suggestion) {
                  if (suggestion is CountryInfo) {
                    controller.text = suggestion.toString();
                    onCountrySelected(suggestion.code, suggestion.name);
                    // Unfocus to close the dropdown immediately
                    FocusScope.of(context).unfocus();
                  }
                },
                hideOnEmpty: false,
                hideOnLoading: false,
                hideOnError: false,
                itemSeparatorBuilder: (context, index) =>
                    const SizedBox.shrink(),
                retainOnLoading: true,
                showOnFocus: true,
                hideOnUnfocus: true,
                builder: (context, controller, focusNode) {
                  return TextFormField(
                    controller: controller,
                    focusNode: focusNode,
                    decoration: InputDecoration(
                      labelText: hintText ?? 'Search countries...',
                      border: const OutlineInputBorder(),
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: controller.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                controller.clear();
                              },
                            )
                          : null,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please select a country';
                      }
                      return null;
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Helper method to build favorite country chips with heart icon
  Widget _buildFavoriteCountryChip(
    BuildContext context,
    CountryInfo country,
    TextEditingController controller,
    FavoriteCountriesService favoriteService,
    WidgetRef ref,
  ) {
    return _FavoriteChipWidget(
      country: country,
      controller: controller,
      favoriteService: favoriteService,
      ref: ref,
      onCountrySelected: onCountrySelected,
    );
  }

  /// Build intelligent suggestions based on search pattern
  List<SearchSuggestion> _buildSuggestions(
    String pattern,
    List<CountryInfo> allCountries,
    List<String> favoriteCodes,
  ) {
    final suggestions = <SearchSuggestion>[];
    final query = pattern.toLowerCase().trim();

    if (query.isEmpty) {
      // When no search query, show favorites first, then popular countries
      if (favoriteCodes.isNotEmpty) {
        final favoriteCountries = favoriteCodes
            .map(
              (code) => allCountries.firstWhere(
                (country) => country.code == code,
                orElse: () => CountryInfo(
                  code: code,
                  name: code,
                  flag: CountryFlags.getFlagOptimized(code),
                ),
              ),
            )
            .toList();

        suggestions.add(
          const SectionHeader(title: 'Favorites', icon: Icons.favorite),
        );
        suggestions.addAll(favoriteCountries);
        suggestions.add(const SectionSeparator());
      }

      // Show popular countries (excluding already shown favorites)
      final popularCountryCodes = [
        'US',
        'GB',
        'CA',
        'AU',
        'DE',
        'FR',
        'ES',
        'IT',
        'NL',
        'CH',
        'SG',
        'HK',
        'AE',
        'JP',
      ];
      final popularCountries = popularCountryCodes
          .where((code) => !favoriteCodes.contains(code))
          .map(
            (code) => allCountries.firstWhere(
              (country) => country.code == code,
              orElse: () => CountryInfo(
                code: code,
                name: code,
                flag: CountryFlags.getFlagOptimized(code),
              ),
            ),
          )
          .toList();

      if (popularCountries.isNotEmpty) {
        suggestions.add(
          const SectionHeader(title: 'Popular Countries', icon: Icons.star),
        );
        suggestions.addAll(popularCountries);
        suggestions.add(const SectionSeparator());
      }

      // Show all remaining countries (excluding favorites and popular countries)
      final remainingCountries = allCountries.where(
        (country) =>
            !favoriteCodes.contains(country.code) &&
            !popularCountryCodes.contains(country.code),
      );
      if (remainingCountries.isNotEmpty) {
        suggestions.add(
          const SectionHeader(title: 'All Countries', icon: Icons.public),
        );
        suggestions.addAll(remainingCountries);
      }
    } else {
      // When searching, organize results intelligently
      final exactMatches = <CountryInfo>[];
      final startsWith = <CountryInfo>[];
      final contains = <CountryInfo>[];
      final codeMatches = <CountryInfo>[];

      for (final country in allCountries) {
        final name = country.name.toLowerCase();
        final code = country.code.toLowerCase();

        if (name == query || code == query) {
          exactMatches.add(country);
        } else if (name.startsWith(query) || code.startsWith(query)) {
          startsWith.add(country);
        } else if (code.contains(query)) {
          codeMatches.add(country);
        } else if (name.contains(query)) {
          contains.add(country);
        }
      }

      // Add best matches section
      final bestMatches = [...exactMatches, ...startsWith, ...codeMatches];
      if (bestMatches.isNotEmpty) {
        suggestions.add(
          const SectionHeader(title: 'Best Matches', icon: Icons.search),
        );
        suggestions.addAll(bestMatches);
      }

      // Add other matches if any
      if (contains.isNotEmpty) {
        if (bestMatches.isNotEmpty) {
          suggestions.add(const SectionSeparator());
        }
        suggestions.add(
          const SectionHeader(title: 'Other Matches', icon: Icons.more_horiz),
        );
        suggestions.addAll(contains);
      }

      // Always show all countries below for browsing
      if (suggestions.isNotEmpty) {
        suggestions.add(const SectionSeparator());
      }
      suggestions.add(
        const SectionHeader(title: 'All Countries', icon: Icons.public),
      );
      suggestions.addAll(allCountries);
    }

    return suggestions;
  }

  /// Build suggestion item widget based on type
  Widget _buildSuggestionItem(
    BuildContext context,
    SearchSuggestion suggestion,
    WidgetRef ref,
  ) {
    bool isLoading = false;

    switch (suggestion) {
      case CountryInfo country:
        return Consumer(
          builder: (context, ref, child) {
            final favoriteService = ref.read(favoriteCountriesServiceProvider);
            final favoritesAsync = ref.watch(favoriteCountriesProvider);

            return favoritesAsync.when(
              loading: () => ListTile(
                leading: Text(
                  country.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(country.name),
                subtitle: Text(country.code),
              ),
              error: (_, __) => ListTile(
                leading: Text(
                  country.flag,
                  style: const TextStyle(fontSize: 24),
                ),
                title: Text(country.name),
                subtitle: Text(country.code),
              ),
              data: (favorites) {
                final isFavorite = favorites.contains(country.code);

                return StatefulBuilder(
                  builder: (context, setState) {
                    return Row(
                      children: [
                        // Country selection area - this will be handled by TypeAheadField onSelected
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              vertical: 12,
                              horizontal: 16,
                            ),
                            child: Row(
                              children: [
                                Text(
                                  country.flag,
                                  style: const TextStyle(fontSize: 24),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        country.name,
                                        style: Theme.of(
                                          context,
                                        ).textTheme.bodyLarge,
                                      ),
                                      Text(
                                        country.code,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        // Favorite button - prevents event propagation
                        AbsorbPointer(
                          absorbing: false,
                          child: GestureDetector(
                            onTap: isLoading
                                ? null
                                : () async {
                                    // This should prevent the TypeAheadField onSelected from firing
                                    setState(() {
                                      isLoading = true;
                                    });

                                    try {
                                      final result = await favoriteService
                                          .toggleFavoriteCountry(country.code);
                                      if (result.isSuccess) {
                                        ref.invalidate(
                                          favoriteCountriesProvider,
                                        );
                                        ref.invalidate(
                                          favoriteCountriesCountProvider,
                                        );
                                        ref.invalidate(
                                          canAddMoreFavoritesProvider,
                                        );
                                      } else {
                                        if (context.mounted) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(result.message),
                                            ),
                                          );
                                        }
                                      }
                                    } catch (e) {
                                      if (context.mounted) {
                                        ScaffoldMessenger.of(
                                          context,
                                        ).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Error updating favorite: $e',
                                            ),
                                          ),
                                        );
                                      }
                                    } finally {
                                      if (context.mounted) {
                                        setState(() {
                                          isLoading = false;
                                        });
                                      }
                                    }
                                  },
                            child: Container(
                              width: 56,
                              height: 56,
                              margin: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Theme.of(context).colorScheme.outline,
                                  width: 2,
                                ),
                                borderRadius: BorderRadius.circular(28),
                                color: isFavorite
                                    ? Colors.red.withValues(alpha: 0.1)
                                    : Colors.transparent,
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        width: 18,
                                        height: 18,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                Colors.grey,
                                              ),
                                        ),
                                      )
                                    : Icon(
                                        isFavorite
                                            ? Icons.favorite
                                            : Icons.favorite_border,
                                        color: isFavorite
                                            ? Colors.red
                                            : Colors.grey,
                                        size: 22,
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );

      case SectionHeader header:
        return IgnorePointer(
          child: Container(
            color: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            child: ListTile(
              leading: header.icon != null
                  ? Icon(
                      header.icon,
                      size: 20,
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : null,
              title: Text(
                header.title,
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              dense: true,
              enabled: false,
            ),
          ),
        );

      case SectionSeparator():
        return IgnorePointer(
          child: Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
            color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.3),
          ),
        );

      default:
        return const SizedBox.shrink();
    }
  }
}

/// Stateful widget for favorite country chip with proper loading state management
class _FavoriteChipWidget extends StatefulWidget {
  final CountryInfo country;
  final TextEditingController controller;
  final FavoriteCountriesService favoriteService;
  final WidgetRef ref;
  final void Function(String countryCode, String countryName) onCountrySelected;

  const _FavoriteChipWidget({
    required this.country,
    required this.controller,
    required this.favoriteService,
    required this.ref,
    required this.onCountrySelected,
  });

  @override
  State<_FavoriteChipWidget> createState() => _FavoriteChipWidgetState();
}

class _FavoriteChipWidgetState extends State<_FavoriteChipWidget> {
  bool _isLoading = false;

  Future<void> _handleRemoveFavorite() async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final result = await widget.favoriteService.removeFavoriteCountry(
        widget.country.code,
      );
      if (result.isSuccess) {
        // Refresh the favorites provider
        widget.ref.invalidate(favoriteCountriesProvider);
        widget.ref.invalidate(favoriteCountriesCountProvider);
        widget.ref.invalidate(canAddMoreFavoritesProvider);
      } else {
        // Show error message
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(result.message)));
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error removing favorite: $e')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Text(widget.country.flag, style: const TextStyle(fontSize: 16)),
      label: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(widget.country.name),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: _isLoading ? null : _handleRemoveFavorite,
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              switchInCurve: Curves.easeIn,
              switchOutCurve: Curves.easeOut,
              child: _isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.red),
                      ),
                    )
                  : const Icon(
                      key: ValueKey('heart'),
                      Icons.favorite,
                      size: 16,
                      color: Colors.red,
                    ),
            ),
          ),
        ],
      ),
      onPressed: () {
        widget.controller.text = widget.country.toString();
        widget.onCountrySelected(widget.country.code, widget.country.name);
      },
      backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      labelStyle: TextStyle(
        color: Theme.of(context).colorScheme.onPrimaryContainer,
      ),
    );
  }
}

/// Widget for displaying country information with tax residency rules
class CountryInfoCard extends HookConsumerWidget {
  final String countryCode;
  final TaxResidencyRule? rule;

  const CountryInfoCard({super.key, required this.countryCode, this.rule});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rule =
        this.rule ?? DefaultTaxResidencyRules.getRuleForCountry(countryCode);
    final customSettingsAsync = ref.watch(
      customSettingsForCountryProvider(countryCode),
    );
    final effectiveTimeLimitAsync = ref.watch(
      effectiveTimeLimitProvider(countryCode),
    );

    if (rule == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    CountryFlags.getFlagOptimized(countryCode),
                    style: const TextStyle(fontSize: 32),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      countryCode,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  IconButton(
                    onPressed: () {
                      showEditCountryTimeLimitDialog(
                        context: context,
                        countryCode: countryCode,
                        countryName: countryCode,
                      );
                    },
                    icon: const Icon(Icons.edit),
                    tooltip: 'Edit time limit',
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                'Tax residency information not available for this country. Default threshold of ${DefaultTaxResidencyRules.defaultThreshold} days will be used.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  CountryFlags.getFlagOptimized(rule.countryCode),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    rule.countryName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                IconButton(
                  onPressed: () {
                    showEditCountryTimeLimitDialog(
                      context: context,
                      countryCode: countryCode,
                      countryName: rule.countryName,
                    );
                  },
                  icon: customSettingsAsync.when(
                    loading: () => const Icon(Icons.edit),
                    error: (_, __) => const Icon(Icons.edit),
                    data: (customSettings) => Icon(
                      customSettings != null ? Icons.edit : Icons.edit_outlined,
                      color: customSettings != null
                          ? Theme.of(context).colorScheme.primary
                          : null,
                    ),
                  ),
                  tooltip: 'Edit time limit',
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Time limit row with custom/default indicator
            effectiveTimeLimitAsync.when(
              loading: () => Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  const Text('Loading...'),
                ],
              ),
              error: (_, __) => Row(
                children: [
                  Icon(
                    Icons.access_time,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${rule.daysThreshold} days',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'tax residency threshold',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              data: (effectiveLimit) {
                return customSettingsAsync.when(
                  loading: () => Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$effectiveLimit days',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'tax residency threshold',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  error: (_, __) => Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$effectiveLimit days',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Theme.of(context).colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'tax residency threshold',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  data: (customSettings) {
                    final isCustom = customSettings != null;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 16,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$effectiveLimit days',
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'tax residency threshold',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            if (isCustom) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Theme.of(context).colorScheme.primary,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'CUSTOM',
                                  style: Theme.of(context).textTheme.labelSmall
                                      ?.copyWith(
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onPrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (isCustom &&
                            effectiveLimit != rule.daysThreshold) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Default: ${rule.daysThreshold} days',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ],
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 8),
            Text(
              rule.description,
              style: Theme.of(context).textTheme.bodyMedium,
            ),

            // Show custom notes if available
            customSettingsAsync.whenOrNull(
                  data: (customSettings) {
                    if (customSettings?.notes != null &&
                        customSettings!.notes!.isNotEmpty) {
                      return Column(
                        children: [
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Theme.of(context)
                                  .colorScheme
                                  .primaryContainer
                                  .withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Icon(
                                  Icons.note,
                                  size: 16,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Custom Notes:',
                                        style: Theme.of(context)
                                            .textTheme
                                            .labelSmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.primary,
                                              fontWeight: FontWeight.w600,
                                            ),
                                      ),
                                      const SizedBox(height: 2),
                                      Text(
                                        customSettings.notes!,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodySmall
                                            ?.copyWith(
                                              color: Theme.of(
                                                context,
                                              ).colorScheme.onPrimaryContainer,
                                            ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }
                    return null;
                  },
                ) ??
                const SizedBox.shrink(),

            if (rule.additionalNotes != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(
                    context,
                  ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 16,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        rule.additionalNotes!,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
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
