import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/models/custom_country_settings.dart';
import 'package:trottstr/models/tax_residency_rule.dart';
import 'package:trottstr/services/custom_country_settings_service.dart';

void main() {
  group('CustomCountrySettings', () {
    test('should create custom country settings correctly', () {
      final now = DateTime.now();
      final settings = CustomCountrySettings(
        countryCode: 'US',
        countryName: 'United States',
        customDaysThreshold: 120,
        createdAt: now,
        notes: 'Personal limit for tax planning',
      );

      expect(settings.countryCode, 'US');
      expect(settings.countryName, 'United States');
      expect(settings.customDaysThreshold, 120);
      expect(settings.createdAt, now);
      expect(settings.notes, 'Personal limit for tax planning');
      expect(settings.updatedAt, null);
    });

    test('should convert to and from JSON correctly', () {
      final now = DateTime.now();
      final settings = CustomCountrySettings(
        countryCode: 'GB',
        countryName: 'United Kingdom',
        customDaysThreshold: 60,
        createdAt: now,
        updatedAt: now.add(const Duration(days: 1)),
        notes: 'Brexit considerations',
      );

      final json = settings.toJson();
      final restored = CustomCountrySettings.fromJson(json);

      expect(restored.countryCode, settings.countryCode);
      expect(restored.countryName, settings.countryName);
      expect(restored.customDaysThreshold, settings.customDaysThreshold);
      expect(restored.createdAt, settings.createdAt);
      expect(restored.updatedAt, settings.updatedAt);
      expect(restored.notes, settings.notes);
    });

    test('should handle copyWith correctly', () {
      final now = DateTime.now();
      final original = CustomCountrySettings(
        countryCode: 'DE',
        countryName: 'Germany',
        customDaysThreshold: 90,
        createdAt: now,
      );

      final updated = original.copyWith(
        customDaysThreshold: 75,
        updatedAt: now.add(const Duration(hours: 1)),
        notes: 'Updated for personal planning',
      );

      expect(updated.countryCode, original.countryCode);
      expect(updated.countryName, original.countryName);
      expect(updated.customDaysThreshold, 75);
      expect(updated.createdAt, original.createdAt);
      expect(updated.updatedAt, now.add(const Duration(hours: 1)));
      expect(updated.notes, 'Updated for personal planning');
    });

    test('should handle equality correctly', () {
      final now = DateTime.now();
      final settings1 = CustomCountrySettings(
        countryCode: 'FR',
        countryName: 'France',
        customDaysThreshold: 80,
        createdAt: now,
      );

      final settings2 = CustomCountrySettings(
        countryCode: 'FR',
        countryName: 'France',
        customDaysThreshold: 90, // Different threshold
        createdAt: now.add(const Duration(days: 1)), // Different date
      );

      final settings3 = CustomCountrySettings(
        countryCode: 'IT',
        countryName: 'Italy',
        customDaysThreshold: 80,
        createdAt: now,
      );

      expect(settings1, settings2); // Same country code
      expect(settings1, isNot(settings3)); // Different country code
    });
  });

  group('CustomCountrySettingsResult', () {
    test('should provide correct messages', () {
      expect(CustomCountrySettingsResult.success.message, 'Settings updated successfully');
      expect(CustomCountrySettingsResult.notFound.message, 'Country settings not found');
      expect(CustomCountrySettingsResult.error.message, 'An error occurred while updating settings');
    });

    test('should identify success correctly', () {
      expect(CustomCountrySettingsResult.success.isSuccess, true);
      expect(CustomCountrySettingsResult.notFound.isSuccess, false);
      expect(CustomCountrySettingsResult.error.isSuccess, false);
    });
  });

  group('Default Tax Residency Rules Integration', () {
    test('should get correct default thresholds', () {
      expect(DefaultTaxResidencyRules.getRuleForCountry('US')?.daysThreshold, 183);
      expect(DefaultTaxResidencyRules.getRuleForCountry('GB')?.daysThreshold, 90);
      expect(DefaultTaxResidencyRules.getRuleForCountry('SG')?.daysThreshold, 30);
      expect(DefaultTaxResidencyRules.getRuleForCountry('UNKNOWN'), null);
    });

    test('should provide default threshold for unknown countries', () {
      expect(DefaultTaxResidencyRules.defaultThreshold, 90);
    });

    test('should have comprehensive country coverage', () {
      final allCountries = DefaultTaxResidencyRules.getAllCountries();
      expect(allCountries.isNotEmpty, true);
      expect(allCountries['US'], 'United States');
      expect(allCountries['GB'], 'United Kingdom');
      expect(allCountries['DE'], 'Germany');
    });
  });

  group('Real World Scenarios', () {
    test('US tax residency planning scenario', () {
      final now = DateTime.now();
      
      // Default US rule is 183 days
      final defaultRule = DefaultTaxResidencyRules.getRuleForCountry('US');
      expect(defaultRule?.daysThreshold, 183);
      
      // User wants to be more conservative and sets 150 days
      final customSettings = CustomCountrySettings(
        countryCode: 'US',
        countryName: 'United States',
        customDaysThreshold: 150,
        createdAt: now,
        notes: 'Conservative limit to avoid substantial presence test complications',
      );
      
      expect(customSettings.customDaysThreshold, 150);
      expect(customSettings.customDaysThreshold < defaultRule!.daysThreshold, true);
    });

    test('Schengen area planning scenario', () {
      final now = DateTime.now();
      
      // Multiple Schengen countries with same default (90 days)
      final countries = ['DE', 'FR', 'ES', 'IT', 'NL'];
      for (final countryCode in countries) {
        final rule = DefaultTaxResidencyRules.getRuleForCountry(countryCode);
        expect(rule?.daysThreshold, 90);
      }
      
      // User wants to track combined Schengen time more conservatively
      final customGermany = CustomCountrySettings(
        countryCode: 'DE',
        countryName: 'Germany',
        customDaysThreshold: 30,
        createdAt: now,
        notes: 'Part of 90-day Schengen strategy - allocating 30 days to Germany',
      );
      
      expect(customGermany.customDaysThreshold, 30);
    });

    test('Digital nomad scenario with multiple countries', () {
      final now = DateTime.now();
      
      // Common nomad destinations with custom limits
      final nomadSettings = [
        CustomCountrySettings(
          countryCode: 'TH',
          countryName: 'Thailand',
          customDaysThreshold: 25,
          createdAt: now,
          notes: 'Tourist visa limit, want buffer before extension',
        ),
        CustomCountrySettings(
          countryCode: 'SG',
          countryName: 'Singapore',
          customDaysThreshold: 25,
          createdAt: now,
          notes: 'Conservative limit for visa-free stay',
        ),
        CustomCountrySettings(
          countryCode: 'MY',
          countryName: 'Malaysia',
          customDaysThreshold: 150,
          createdAt: now,
          notes: 'Tax residency threshold is 182 days',
        ),
      ];
      
      for (final settings in nomadSettings) {
        expect(settings.customDaysThreshold > 0, true);
        expect(settings.notes?.isNotEmpty, true);
      }
    });
  });
}