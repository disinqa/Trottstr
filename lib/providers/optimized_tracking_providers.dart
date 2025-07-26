import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/country_tracking_service.dart';
import 'package:trottstr/models/country_stay.dart';
import 'package:trottstr/providers/country_tracking_providers.dart';

/// Optimized state notifier for real-time tracking data
class TrackingDataNotifier extends StateNotifier<TrackingDataState> {
  final CountryTrackingService _service;
  final Ref _ref;

  TrackingDataNotifier(this._service, this._ref) : super(const TrackingDataState.loading()) {
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    try {
      final entries = await _service.getAllEntries();
      final currentLocation = await _service.getCurrentLocation();
      final risks = await _service.calculateTaxResidencyRisks();
      final plannedStays = await _service.getPlannedStays();

      state = TrackingDataState.loaded(
        entries: entries,
        currentLocation: currentLocation,
        risks: risks,
        plannedStays: plannedStays,
        lastUpdated: DateTime.now(),
      );
    } catch (error, stackTrace) {
      state = TrackingDataState.error(error, stackTrace);
    }
  }

  /// Add entry with optimistic update
  Future<void> addEntryOptimistic(CountryEntry entry) async {
    if (state is! TrackingDataLoaded) return;

    final currentState = state as TrackingDataLoaded;
    
    // 1. Immediate UI update (optimistic)
    final optimisticEntries = [...currentState.entries, entry];
    optimisticEntries.sort((a, b) => a.entryDate.compareTo(b.entryDate));
    
    // Update current location if this is a new current entry
    String? newCurrentLocation = currentState.currentLocation;
    if (entry.exitDate == null) {
      newCurrentLocation = entry.countryCode;
    }

    // Show immediate UI update
    state = currentState.copyWith(
      entries: optimisticEntries,
      currentLocation: newCurrentLocation,
      isOptimistic: true,
      lastUpdated: DateTime.now(),
    );

    try {
      // 2. Background persistence
      await _service.addCountryEntry(entry);
      
      // 3. Full refresh after persistence (but UI already updated)
      await _refreshFromStorage();
    } catch (error) {
      // 4. Rollback on error
      state = currentState.copyWith(
        error: error,
        lastUpdated: DateTime.now(),
      );
      rethrow;
    }
  }

  /// Record entry with optimistic updates for exit dates
  Future<void> recordEntryOptimistic({
    required String countryCode,
    DateTime? entryDate,
    String? notes,
    String? location,
    String? purpose,
  }) async {
    if (state is! TrackingDataLoaded) return;

    final currentState = state as TrackingDataLoaded;
    final newEntryDate = entryDate ?? DateTime.now();
    final upperCountryCode = countryCode.toUpperCase();

    // Find current entries (without exit dates)
    final currentEntries = currentState.entries
        .where((entry) => entry.exitDate == null)
        .toList();

    // Create optimistic updates
    final updatedEntries = [...currentState.entries];
    
    // Auto-exit current entries
    for (final currentEntry in currentEntries) {
      final exitDate = DateTime(
        newEntryDate.year,
        newEntryDate.month,
        newEntryDate.day,
      );
      
      final updatedEntry = currentEntry.addExit(exitDate);
      final entryIndex = updatedEntries.indexWhere((e) => e.id == currentEntry.id);
      if (entryIndex != -1) {
        updatedEntries[entryIndex] = updatedEntry;
      }
    }

    // Add new entry
    final newEntry = CountryEntry(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      countryCode: upperCountryCode,
      entryDate: newEntryDate,
      notes: notes,
      location: location,
      purpose: purpose,
    );

    updatedEntries.add(newEntry);
    updatedEntries.sort((a, b) => a.entryDate.compareTo(b.entryDate));

    // 1. Immediate UI update
    state = currentState.copyWith(
      entries: updatedEntries,
      currentLocation: upperCountryCode,
      isOptimistic: true,
      lastUpdated: DateTime.now(),
    );

    try {
      // 2. Background persistence
      await _service.recordCountryEntry(
        countryCode: countryCode,
        entryDate: entryDate,
        notes: notes,
        location: location,
        purpose: purpose,
      );
      
      // 3. Refresh and recalculate after persistence
      await _refreshFromStorage();
    } catch (error) {
      // 4. Rollback on error
      state = currentState.copyWith(
        error: error,
        lastUpdated: DateTime.now(),
      );
      rethrow;
    }
  }

  /// Refresh data from storage
  Future<void> refresh() async {
    await _refreshFromStorage();
  }

  Future<void> _refreshFromStorage() async {
    try {
      final entries = await _service.getAllEntries();
      final currentLocation = await _service.getCurrentLocation();
      final risks = await _service.calculateTaxResidencyRisks();
      final plannedStays = await _service.getPlannedStays();

      state = TrackingDataState.loaded(
        entries: entries,
        currentLocation: currentLocation,
        risks: risks,
        plannedStays: plannedStays,
        lastUpdated: DateTime.now(),
      );
    } catch (error, stackTrace) {
      if (state is TrackingDataLoaded) {
        final currentState = state as TrackingDataLoaded;
        state = currentState.copyWith(error: error);
      } else {
        state = TrackingDataState.error(error, stackTrace);
      }
    }
  }
}

/// Immutable state for tracking data
sealed class TrackingDataState {
  const TrackingDataState();

  const factory TrackingDataState.loading() = TrackingDataLoading;
  const factory TrackingDataState.loaded({
    required List<CountryEntry> entries,
    required String? currentLocation,
    required Map<String, TaxResidencyRisk> risks,
    required List<PlannedStay> plannedStays,
    required DateTime lastUpdated,
    bool isOptimistic,
    Object? error,
  }) = TrackingDataLoaded;
  const factory TrackingDataState.error(Object error, StackTrace stackTrace) = TrackingDataError;
}

class TrackingDataLoading extends TrackingDataState {
  const TrackingDataLoading();
}

class TrackingDataLoaded extends TrackingDataState {
  final List<CountryEntry> entries;
  final String? currentLocation;
  final Map<String, TaxResidencyRisk> risks;
  final List<PlannedStay> plannedStays;
  final DateTime lastUpdated;
  final bool isOptimistic;
  final Object? error;

  const TrackingDataLoaded({
    required this.entries,
    required this.currentLocation,
    required this.risks,
    required this.plannedStays,
    required this.lastUpdated,
    this.isOptimistic = false,
    this.error,
  });

  /// Current year entries
  List<CountryEntry> get currentYearEntries {
    final currentYear = DateTime.now().year;
    return entries
        .where((entry) => entry.entryDate.year == currentYear)
        .toList()
      ..sort((a, b) => a.entryDate.compareTo(b.entryDate));
  }

  /// Entries with exit information
  List<CountryEntryWithExit> get entriesWithExit {
    return entries.map((entry) => CountryEntryWithExit(entry: entry)).toList();
  }

  /// Current year entries with exit information
  List<CountryEntryWithExit> get currentYearEntriesWithExit {
    final currentYear = DateTime.now().year;
    return entriesWithExit
        .where((entryWithExit) => entryWithExit.entry.entryDate.year == currentYear)
        .toList();
  }

  /// Calculate days per country
  Map<String, int> get daysPerCountry {
    final Map<String, int> daysPerCountry = <String, int>{};

    for (final entry in entries) {
      final country = entry.countryCode;
      final daysStayed = entry.daysStayed;
      daysPerCountry[country] = (daysPerCountry[country] ?? 0) + daysStayed;
    }

    // Add planned stays
    final currentYear = DateTime.now().year;
    final yearStart = DateTime(currentYear, 1, 1);
    final yearEnd = DateTime(currentYear, 12, 31, 23, 59, 59);

    for (final stay in plannedStays) {
      if (stay.endDate.isBefore(yearStart) || stay.startDate.isAfter(yearEnd)) {
        continue;
      }

      final effectiveStart = stay.startDate.isBefore(yearStart)
          ? yearStart
          : stay.startDate;
      final effectiveEnd = stay.endDate.isAfter(yearEnd)
          ? yearEnd
          : stay.endDate;

      final days = effectiveEnd.difference(effectiveStart).inDays + 1;
      daysPerCountry[stay.countryCode] =
          (daysPerCountry[stay.countryCode] ?? 0) + days;
    }

    return daysPerCountry;
  }

  /// Travel statistics
  TravelStats get travelStats {
    return TravelStats.fromData(daysPerCountry, risks, entriesWithExit);
  }

  TrackingDataLoaded copyWith({
    List<CountryEntry>? entries,
    String? currentLocation,
    Map<String, TaxResidencyRisk>? risks,
    List<PlannedStay>? plannedStays,
    DateTime? lastUpdated,
    bool? isOptimistic,
    Object? error,
  }) {
    return TrackingDataLoaded(
      entries: entries ?? this.entries,
      currentLocation: currentLocation ?? this.currentLocation,
      risks: risks ?? this.risks,
      plannedStays: plannedStays ?? this.plannedStays,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      isOptimistic: isOptimistic ?? this.isOptimistic,
      error: error ?? this.error,
    );
  }
}

class TrackingDataError extends TrackingDataState {
  final Object error;
  final StackTrace stackTrace;

  const TrackingDataError(this.error, this.stackTrace);
}

/// Main optimized tracking provider
final optimizedTrackingProvider = StateNotifierProvider<TrackingDataNotifier, TrackingDataState>((ref) {
  final service = ref.read(countryTrackingServiceProvider);
  return TrackingDataNotifier(service, ref);
});

/// Derived providers for specific data
final optimizedCurrentYearEntriesProvider = Provider<List<CountryEntry>>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.currentYearEntries : [];
});

final optimizedCurrentLocationProvider = Provider<String?>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.currentLocation : null;
});

final optimizedTaxResidencyRisksProvider = Provider<Map<String, TaxResidencyRisk>>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.risks : {};
});

final optimizedTravelStatsProvider = Provider<TravelStats?>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.travelStats : null;
});

final optimizedDaysPerCountryProvider = Provider<Map<String, int>>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.daysPerCountry : {};
});

final optimizedCompleteHistoryProvider = Provider<List<CountryEntryWithExit>>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.entriesWithExit : [];
});

final optimizedPlannedStaysProvider = Provider<List<PlannedStay>>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.plannedStays : [];
});

/// Helper to check if data is optimistic (showing immediate updates)
final isOptimisticProvider = Provider<bool>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.isOptimistic : false;
});

/// Helper to get last update time
final lastUpdatedProvider = Provider<DateTime?>((ref) {
  final state = ref.watch(optimizedTrackingProvider);
  return state is TrackingDataLoaded ? state.lastUpdated : null;
});