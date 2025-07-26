import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';

/// Theme mode options
enum AppThemeMode {
  system,
  light,
  dark,
}

extension AppThemeModeExtension on AppThemeMode {
  String get displayName {
    switch (this) {
      case AppThemeMode.system:
        return 'System Default';
      case AppThemeMode.light:
        return 'Light';
      case AppThemeMode.dark:
        return 'Dark';
    }
  }

  IconData get icon {
    switch (this) {
      case AppThemeMode.system:
        return Icons.brightness_auto;
      case AppThemeMode.light:
        return Icons.brightness_high;
      case AppThemeMode.dark:
        return Icons.brightness_2;
    }
  }

  ThemeMode get themeMode {
    switch (this) {
      case AppThemeMode.system:
        return ThemeMode.system;
      case AppThemeMode.light:
        return ThemeMode.light;
      case AppThemeMode.dark:
        return ThemeMode.dark;
    }
  }
}

/// Theme provider that manages theme mode persistence
class ThemeNotifier extends StateNotifier<AppThemeMode> {
  final Ref _ref;
  static const String _storageKey = 'app_theme_mode';

  ThemeNotifier(this._ref) : super(AppThemeMode.system) {
    _loadThemeMode();
  }

  /// Load theme mode from storage
  Future<void> _loadThemeMode() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) {
        return; // Keep default system theme
      }

      final pubkey = signer.pubkey;
      final customDataList = await _ref.storage.query(
        RequestFilter<CustomData>(
          authors: {pubkey},
          tags: {
            '#d': {_storageKey},
          },
          limit: 1,
        ).toRequest(),
      );

      if (customDataList.isEmpty) {
        return; // Keep default system theme
      }

      final latestData = customDataList.first;
      final content = latestData.content;

      if (content.isEmpty) {
        return; // Keep default system theme
      }

      try {
        final Map<String, dynamic> jsonData = json.decode(content);
        final themeModeName = jsonData['theme_mode'] as String?;
        
        if (themeModeName != null) {
          final themeMode = AppThemeMode.values.firstWhere(
            (mode) => mode.name == themeModeName,
            orElse: () => AppThemeMode.system,
          );
          state = themeMode;
        }
      } catch (e) {
        debugPrint('Error parsing theme mode: $e');
      }
    } catch (e) {
      debugPrint('Error loading theme mode: $e');
    }
  }

  /// Save theme mode to storage
  Future<void> _saveThemeMode() async {
    try {
      final signer = _ref.read(Signer.activeSignerProvider);
      if (signer == null) {
        throw Exception('User not signed in');
      }

      final jsonString = json.encode({
        'theme_mode': state.name,
        'updated_at': DateTime.now().toIso8601String(),
      });

      final customData = PartialCustomData(
        identifier: _storageKey,
        content: jsonString,
      );
      final signedData = await customData.signWith(signer);

      await _ref.storage.save({signedData});
      await _ref.storage.publish({signedData});
    } catch (e) {
      debugPrint('Error saving theme mode: $e');
      rethrow;
    }
  }

  /// Set theme mode
  Future<void> setThemeMode(AppThemeMode themeMode) async {
    state = themeMode;
    await _saveThemeMode();
  }

  /// Get current ThemeMode for MaterialApp
  ThemeMode get themeMode => state.themeMode;
}

/// Provider for theme mode
final themeProvider = StateNotifierProvider<ThemeNotifier, AppThemeMode>(
  (ref) => ThemeNotifier(ref),
);

/// Provider for getting current ThemeMode
final themeModeProvider = Provider<ThemeMode>((ref) {
  final themeMode = ref.watch(themeProvider);
  return themeMode.themeMode;
});

/// Provider for checking if current theme is dark
final isDarkThemeProvider = Provider<bool>((ref) {
  final themeMode = ref.watch(themeProvider);
  switch (themeMode) {
    case AppThemeMode.dark:
      return true;
    case AppThemeMode.light:
      return false;
    case AppThemeMode.system:
      // This will be handled by the system, but we can provide a default
      return false;
  }
});