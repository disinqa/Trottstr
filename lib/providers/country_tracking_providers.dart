import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/services/favorite_countries_service.dart';
import 'package:trottstr/services/custom_country_settings_service.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/models/custom_country_settings.dart';

/// Provider for current year country entries
final currentYearEntriesProvider = FutureProvider<List<CountryEntry>>((
  ref,
) async {
  final service = ref.read(countryTrackingServiceProvider);
  return service.getCurrentYearEntries();
});

/// Provider for days per country calculation
final daysPerCountryProvider = FutureProvider<Map<String, int>>((ref) async {
  final service = ref.read(countryTrackingServiceProvider);
  return service.calculateDaysPerCountry();
});

/// Provider for tax residency risks
final taxResidencyRisksProvider = FutureProvider<Map<String, TaxResidencyRisk>>(
  (ref) async {
    final service = ref.read(countryTrackingServiceProvider);
    return service.calculateTaxResidencyRisks();
  },
);

/// Provider for current location
final currentLocationProvider = FutureProvider<String?>((ref) async {
  final service = ref.read(countryTrackingServiceProvider);
  return service.getCurrentLocation();
});

/// Provider for planned stays
final plannedStaysProvider = FutureProvider<List<PlannedStay>>((ref) async {
  final service = ref.read(countryTrackingServiceProvider);
  return service.getPlannedStays();
});

/// Provider for recently used countries
final recentlyUsedCountriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(countryTrackingServiceProvider);
  final entries = await service.getCurrentYearEntries();

  // Get unique country codes from recent entries, sorted by most recent
  final recentCountries = <String>[];
  final seen = <String>{};

  // Sort entries by entry date (most recent first)
  entries.sort((a, b) => b.entryDate.compareTo(a.entryDate));

  for (final entry in entries) {
    if (!seen.contains(entry.countryCode)) {
      recentCountries.add(entry.countryCode);
      seen.add(entry.countryCode);
    }
    // Limit to 5 most recent countries
    if (recentCountries.length >= 5) break;
  }

  return recentCountries;
});

/// Provider for favorite countries
final favoriteCountriesProvider = FutureProvider<List<String>>((ref) async {
  final service = ref.read(favoriteCountriesServiceProvider);
  return service.getFavoriteCountries();
});

/// Provider to check if a specific country is a favorite
final isFavoriteCountryProvider = FutureProvider.family<bool, String>((ref, countryCode) async {
  final service = ref.read(favoriteCountriesServiceProvider);
  return service.isFavoriteCountry(countryCode);
});

/// Provider for favorite countries count
final favoriteCountriesCountProvider = FutureProvider<int>((ref) async {
  final service = ref.read(favoriteCountriesServiceProvider);
  return service.getFavoriteCount();
});

/// Provider to check if more favorites can be added
final canAddMoreFavoritesProvider = FutureProvider<bool>((ref) async {
  final service = ref.read(favoriteCountriesServiceProvider);
  return service.canAddMoreFavorites();
});

/// Provider for custom country settings
final customCountrySettingsProvider = FutureProvider<List<CustomCountrySettings>>((ref) async {
  final service = ref.read(customCountrySettingsServiceProvider);
  return service.getCustomCountrySettings();
});

/// Provider for custom settings for a specific country
final customSettingsForCountryProvider = FutureProvider.family<CustomCountrySettings?, String>((ref, countryCode) async {
  final service = ref.read(customCountrySettingsServiceProvider);
  return service.getCustomSettingsForCountry(countryCode);
});

/// Provider to check if a country has custom settings
final hasCustomSettingsProvider = FutureProvider.family<bool, String>((ref, countryCode) async {
  final service = ref.read(customCountrySettingsServiceProvider);
  return service.hasCustomSettings(countryCode);
});

/// Provider for effective time limit for a country (custom or default)
final effectiveTimeLimitProvider = FutureProvider.family<int, String>((ref, countryCode) async {
  final service = ref.read(customCountrySettingsServiceProvider);
  return service.getEffectiveTimeLimit(countryCode);
});

/// Provider for custom settings as a map
final customSettingsMapProvider = FutureProvider<Map<String, CustomCountrySettings>>((ref) async {
  final service = ref.read(customCountrySettingsServiceProvider);
  return service.getCustomSettingsMap();
});

/// Provider for current year entries with exit information
final currentYearEntriesWithExitProvider =
    FutureProvider<List<CountryEntryWithExit>>((ref) async {
      final service = ref.read(countryTrackingServiceProvider);
      return service.getCurrentYearEntriesWithExitInfo();
    });

/// Provider for complete travel history with exit information
final completeHistoryProvider = FutureProvider<List<CountryEntryWithExit>>((
  ref,
) async {
  final service = ref.read(countryTrackingServiceProvider);
  return service.getCompleteHistory();
});

/// Provider for travel statistics
final travelStatsProvider = FutureProvider<TravelStats>((ref) async {
  final service = ref.read(countryTrackingServiceProvider);
  final daysPerCountry = await service.calculateDaysPerCountry();
  final risks = await service.calculateTaxResidencyRisks();
  final history = await service.getCompleteHistory();

  return TravelStats.fromData(daysPerCountry, risks, history);
});

/// Auto-refresh provider that watches for changes and invalidates others
final autoRefreshProvider = StreamProvider<void>((ref) async* {
  // Create a stream that emits every 30 seconds to keep data fresh
  while (true) {
    await Future.delayed(const Duration(seconds: 30));

    // Invalidate all tracking providers to refresh data
    ref.invalidate(currentYearEntriesProvider);
    ref.invalidate(daysPerCountryProvider);
    ref.invalidate(taxResidencyRisksProvider);
    ref.invalidate(currentLocationProvider);
    ref.invalidate(recentlyUsedCountriesProvider);
    ref.invalidate(currentYearEntriesWithExitProvider);
    ref.invalidate(completeHistoryProvider);
    ref.invalidate(travelStatsProvider);
    ref.invalidate(favoriteCountriesProvider);
    ref.invalidate(favoriteCountriesCountProvider);
    ref.invalidate(canAddMoreFavoritesProvider);
    ref.invalidate(customCountrySettingsProvider);
    ref.invalidate(customSettingsMapProvider);

    yield null;
  }
});

/// Function to invalidate all providers when data changes
void invalidateTrackingProviders(WidgetRef ref) {
  ref.invalidate(currentYearEntriesProvider);
  ref.invalidate(daysPerCountryProvider);
  ref.invalidate(taxResidencyRisksProvider);
  ref.invalidate(currentLocationProvider);
  ref.invalidate(recentlyUsedCountriesProvider);
  ref.invalidate(currentYearEntriesWithExitProvider);
  ref.invalidate(completeHistoryProvider);
  ref.invalidate(travelStatsProvider);
  ref.invalidate(favoriteCountriesProvider);
  ref.invalidate(favoriteCountriesCountProvider);
  ref.invalidate(canAddMoreFavoritesProvider);
  ref.invalidate(customCountrySettingsProvider);
  ref.invalidate(customSettingsMapProvider);
}

/// Function to invalidate favorite countries providers
void invalidateFavoriteCountriesProviders(WidgetRef ref) {
  ref.invalidate(favoriteCountriesProvider);
  ref.invalidate(favoriteCountriesCountProvider);
  ref.invalidate(canAddMoreFavoritesProvider);
}

/// Function to invalidate planned stays provider
void invalidatePlannedStaysProvider(WidgetRef ref) {
  ref.invalidate(plannedStaysProvider);
  // Also invalidate other providers since planned stays affect calculations
  ref.invalidate(daysPerCountryProvider);
  ref.invalidate(taxResidencyRisksProvider);
  ref.invalidate(travelStatsProvider);
}

/// Function to invalidate custom country settings providers
void invalidateCustomCountrySettingsProviders(WidgetRef ref) {
  ref.invalidate(customCountrySettingsProvider);
  ref.invalidate(customSettingsMapProvider);
  // Also invalidate providers that depend on custom settings
  ref.invalidate(taxResidencyRisksProvider);
  ref.invalidate(travelStatsProvider);
}

/// Data class for travel statistics
class TravelStats {
  final int totalDays;
  final int countriesCount;
  final int totalEntries;
  final int longestStayDays;
  final String longestStayCountry;
  final String currentStatus;
  final List<CountryDaysSummary> countryBreakdown;

  const TravelStats({
    required this.totalDays,
    required this.countriesCount,
    required this.totalEntries,
    required this.longestStayDays,
    required this.longestStayCountry,
    required this.currentStatus,
    required this.countryBreakdown,
  });

  factory TravelStats.fromData(
    Map<String, int> daysPerCountry,
    Map<String, TaxResidencyRisk> risks,
    List<CountryEntryWithExit> history,
  ) {
    final totalDays = daysPerCountry.values.fold(0, (sum, days) => sum + days);
    final countriesCount = daysPerCountry.keys.length;
    final totalEntries = history.length;

    int longestStayDays = 0;
    String longestStayCountry = '';

    for (final entry in daysPerCountry.entries) {
      if (entry.value > longestStayDays) {
        longestStayDays = entry.value;
        longestStayCountry = entry.key;
      }
    }

    // Find entries that are currently active (no exit date)
    final currentEntries = history
        .where((entry) => entry.isCurrentLocation)
        .toList();
    final currentLocation = currentEntries.isNotEmpty
        ? currentEntries.last.entry.countryCode
        : null;

    final currentStatus = currentLocation != null
        ? 'Currently in $currentLocation'
        : '';

    final countryBreakdown =
        daysPerCountry.entries
            .map(
              (entry) => CountryDaysSummary(
                countryCode: entry.key,
                days: entry.value,
                risk: risks[entry.key],
              ),
            )
            .toList()
          ..sort((a, b) => b.days.compareTo(a.days));

    return TravelStats(
      totalDays: totalDays,
      countriesCount: countriesCount,
      totalEntries: totalEntries,
      longestStayDays: longestStayDays,
      longestStayCountry: longestStayCountry,
      currentStatus: currentStatus,
      countryBreakdown: countryBreakdown,
    );
  }
}

/// Summary of days spent in a country
class CountryDaysSummary {
  final String countryCode;
  final int days;
  final TaxResidencyRisk? risk;

  const CountryDaysSummary({
    required this.countryCode,
    required this.days,
    this.risk,
  });
}
