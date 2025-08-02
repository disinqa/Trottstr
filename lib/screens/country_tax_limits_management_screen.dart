import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/utils/country_flags.dart';
import 'package:trottstr/utils/country_utils.dart';
import 'package:trottstr/utils/country_tax_defaults.dart';
import 'package:trottstr/providers/country_tax_limits_provider.dart';

/// Extension of CountryInfo with tax limit
class CountryInfoWithLimit extends CountryInfo {
  final int daysLimit;

  const CountryInfoWithLimit({
    required super.code,
    required super.name,
    required super.flag,
    required this.daysLimit,
  });
}

/// Comprehensive country tax limits management screen
class CountryTaxLimitsManagementScreen extends HookConsumerWidget {
  const CountryTaxLimitsManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userCustomLimits = ref.watch(
      countryTaxLimitsProvider,
    ); // Only user customizations
    final searchController = useTextEditingController();
    final searchQuery = useState<String>('');
    final tabController = useTabController(initialLength: 2);

    // Get all available countries from the comprehensive flag mapping
    final allCountries =
        CountryFlags.countryFlags.entries
            .where((entry) => entry.key.length == 2) // Only valid country codes
            .map(
              (entry) => CountryInfo(
                code: entry.key,
                flag: entry.value,
                name: _getCountryName(entry.key),
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    // Filter countries based on search
    final filteredCountries = allCountries.where((country) {
      final query = searchQuery.value.toLowerCase();
      return country.name.toLowerCase().contains(query) ||
          country.code.toLowerCase().contains(query);
    }).toList();

    // Get only user-configured countries (only those different from defaults)
    final provider = ref.read(countryTaxLimitsProvider.notifier);
    final customLimits = provider.getCustomLimits();
    final configuredCountries =
        customLimits.entries
            .map(
              (entry) => CountryInfoWithLimit(
                code: entry.key,
                flag: CountryFlags.getFlagOptimized(entry.key),
                name: _getCountryName(entry.key),
                daysLimit: entry.value,
              ),
            )
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name));

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Country Tax Limits'),
          backgroundColor: Theme.of(context).colorScheme.surface,
          foregroundColor: Theme.of(context).colorScheme.onSurface,
          elevation: 0,
          actions: [
            IconButton(
              onPressed: () => _showBulkActions(context, ref),
              icon: const Icon(Icons.more_vert),
              tooltip: 'Bulk actions',
            ),
          ],
          bottom: TabBar(
            controller: tabController,
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.settings, size: 20),
                    const SizedBox(width: 8),
                    Text('Configured (${configuredCountries.length})'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.public, size: 20),
                    const SizedBox(width: 8),
                    Text('All (${allCountries.length})'),
                  ],
                ),
              ),
            ],
          ),
        ),
        body: Column(
          children: [
            // Search bar
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search countries...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: searchQuery.value.isNotEmpty
                      ? IconButton(
                          onPressed: () {
                            searchController.clear();
                            searchQuery.value = '';
                          },
                          icon: const Icon(Icons.clear),
                        )
                      : null,
                  border: const OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (value) => searchQuery.value = value,
              ),
            ),

            // Tab content
            Expanded(
              child: TabBarView(
                controller: tabController,
                children: [
                  // Custom/Configured countries tab
                  _buildConfiguredCountriesTab(
                    context,
                    ref,
                    configuredCountries,
                    searchQuery.value,
                    tabController,
                  ),

                  // All countries tab
                  _buildAllCountriesTab(
                    context,
                    ref,
                    filteredCountries,
                    userCustomLimits,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfiguredCountriesTab(
    BuildContext context,
    WidgetRef ref,
    List<CountryInfoWithLimit> configuredCountries,
    String searchQuery,
    TabController tabController,
  ) {
    final filteredConfigured = configuredCountries.where((country) {
      final query = searchQuery.toLowerCase();
      return country.name.toLowerCase().contains(query) ||
          country.code.toLowerCase().contains(query);
    }).toList();

    if (filteredConfigured.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              searchQuery.isEmpty ? Icons.settings_outlined : Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              searchQuery.isEmpty
                  ? 'No custom limits set'
                  : 'No configured countries found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              searchQuery.isEmpty
                  ? 'Countries use their real-world defaults until you customize them'
                  : 'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            if (searchQuery.isEmpty) ...[
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => tabController.animateTo(1),
                icon: const Icon(Icons.add),
                label: const Text('Add Custom Limits'),
              ),
            ],
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredConfigured.length,
      itemBuilder: (context, index) {
        final country = filteredConfigured[index];
        final defaultLimit = CountryTaxDefaults.getDefaultLimit(country.code);
        final isCustom = country.daysLimit != defaultLimit;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Text(country.flag, style: const TextStyle(fontSize: 24)),
            ),
            title: Text(
              country.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${country.code} • ${country.daysLimit} days (custom)',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'Default: $defaultLimit days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  onPressed: () => _editCountryLimit(context, ref, country),
                  icon: const Icon(Icons.edit, size: 20),
                  tooltip: 'Edit limit',
                ),
                IconButton(
                  onPressed: () =>
                      _restoreCountryToDefault(context, ref, country),
                  icon: Icon(
                    Icons.restore,
                    size: 20,
                    color: Theme.of(context).colorScheme.secondary,
                  ),
                  tooltip: 'Restore to default',
                ),
              ],
            ),
            onTap: () => _editCountryLimit(context, ref, country),
          ),
        );
      },
    );
  }

  Widget _buildAllCountriesTab(
    BuildContext context,
    WidgetRef ref,
    List<CountryInfo> filteredCountries,
    Map<String, int> countryLimits,
  ) {
    if (filteredCountries.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 16),
            Text(
              'No countries found',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try a different search term',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(8),
      itemCount: filteredCountries.length,
      itemBuilder: (context, index) {
        final country = filteredCountries[index];
        final defaultLimit = CountryTaxDefaults.getDefaultLimit(country.code);
        final effectiveLimit = countryLimits[country.code] ?? defaultLimit;
        final isConfigured = countryLimits.containsKey(country.code);
        final isCustom = isConfigured && effectiveLimit != defaultLimit;

        return Card(
          margin: const EdgeInsets.symmetric(vertical: 4),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.transparent,
              child: Text(country.flag, style: const TextStyle(fontSize: 24)),
            ),
            title: Text(
              country.name,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${country.code} • $effectiveLimit days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isCustom
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Text(
                  isCustom
                      ? 'Custom limit (default: $defaultLimit days)'
                      : CountryTaxDefaults.hasCustomDefault(country.code)
                      ? 'Country default'
                      : 'Standard default',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isCustom
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isCustom)
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'CUSTOM',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                const SizedBox(width: 8),
                Icon(
                  isConfigured ? Icons.edit : Icons.add_circle_outline,
                  color: isConfigured
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 20,
                ),
              ],
            ),
            onTap: () => _addOrEditCountryLimit(
              context,
              ref,
              country,
              isConfigured ? effectiveLimit : null,
            ),
          ),
        );
      },
    );
  }

  void _addOrEditCountryLimit(
    BuildContext context,
    WidgetRef ref,
    CountryInfo country,
    int? currentLimit,
  ) {
    final defaultLimit = CountryTaxDefaults.getDefaultLimit(country.code);
    final daysController = TextEditingController(
      text: currentLimit?.toString() ?? defaultLimit.toString(),
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                currentLimit != null
                    ? 'Edit ${country.name} Limit'
                    : 'Set ${country.name} Limit',
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextFormField(
              controller: daysController,
              decoration: InputDecoration(
                border: const OutlineInputBorder(),
                labelText: 'Days Limit',
                hintText: defaultLimit.toString(),
                prefixIcon: const Icon(Icons.calendar_today),
                helperText: 'Default for ${country.name}: $defaultLimit days',
              ),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(3),
              ],
              autofocus: true,
            ),
            const SizedBox(height: 16),
            Text(
              'Country: ${country.name} (${country.code})',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final daysText = daysController.text.trim();
              final days = int.tryParse(daysText);

              if (days == null || days <= 0 || days > 365) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Please enter a valid number of days (1-365)',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
                return;
              }

              ref
                  .read(countryTaxLimitsProvider.notifier)
                  .setCountryLimit(country.code, days);

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    currentLimit != null
                        ? 'Updated ${country.name} limit to $days days'
                        : 'Set ${country.name} limit to $days days',
                  ),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editCountryLimit(
    BuildContext context,
    WidgetRef ref,
    CountryInfoWithLimit country,
  ) {
    final countryInfo = CountryInfo(
      code: country.code,
      name: country.name,
      flag: country.flag,
    );
    _addOrEditCountryLimit(context, ref, countryInfo, country.daysLimit);
  }

  void _restoreCountryToDefault(
    BuildContext context,
    WidgetRef ref,
    CountryInfoWithLimit country,
  ) {
    final defaultLimit = CountryTaxDefaults.getDefaultLimit(country.code);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Text(country.flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Expanded(child: Text('Restore ${country.name}')),
          ],
        ),
        content: Text(
          'Restore ${country.name} to its default limit?\n\n'
          'Current: ${country.daysLimit} days (custom)\n'
          'Default: $defaultLimit days\n\n'
          'This will remove your custom setting.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref
                  .read(countryTaxLimitsProvider.notifier)
                  .restoreCountryToDefault(country.code);

              Navigator.of(context).pop();

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Restored ${country.name} to default ($defaultLimit days)',
                  ),
                  backgroundColor: Theme.of(context).colorScheme.secondary,
                ),
              );
            },
            child: const Text('Restore'),
          ),
        ],
      ),
    );
  }

  void _showBulkActions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.restore),
              title: const Text('Reset to Defaults'),
              subtitle: const Text('Reset all countries to default limits'),
              onTap: () {
                Navigator.of(context).pop();
                _resetToDefaults(context, ref);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _resetToDefaults(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reset to Defaults'),
        content: const Text(
          'This will reset all country tax limits to the default configuration. '
          'All custom limits will be lost. Are you sure?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              ref.read(countryTaxLimitsProvider.notifier).resetToDefaults();
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset to default configuration')),
              );
            },
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
  }

  String _getCountryName(String countryCode) {
    // Use the existing country utils if available
    final existingCountry = CountryUtils.getCountryByCode(countryCode);
    if (existingCountry != null) {
      return existingCountry.name;
    }

    // Extended country name mapping for all countries
    const countryNames = {
      'AD': 'Andorra',
      'AE': 'United Arab Emirates',
      'AF': 'Afghanistan',
      'AG': 'Antigua and Barbuda',
      'AI': 'Anguilla',
      'AL': 'Albania',
      'AM': 'Armenia',
      'AO': 'Angola',
      'AQ': 'Antarctica',
      'AR': 'Argentina',
      'AS': 'American Samoa',
      'AT': 'Austria',
      'AU': 'Australia',
      'AW': 'Aruba',
      'AX': 'Åland Islands',
      'AZ': 'Azerbaijan',
      'BA': 'Bosnia and Herzegovina',
      'BB': 'Barbados',
      'BD': 'Bangladesh',
      'BE': 'Belgium',
      'BF': 'Burkina Faso',
      'BG': 'Bulgaria',
      'BH': 'Bahrain',
      'BI': 'Burundi',
      'BJ': 'Benin',
      'BL': 'Saint Barthélemy',
      'BM': 'Bermuda',
      'BN': 'Brunei',
      'BO': 'Bolivia',
      'BQ': 'Caribbean Netherlands',
      'BR': 'Brazil',
      'BS': 'Bahamas',
      'BT': 'Bhutan',
      'BV': 'Bouvet Island',
      'BW': 'Botswana',
      'BY': 'Belarus',
      'BZ': 'Belize',
      'CA': 'Canada',
      'CC': 'Cocos Islands',
      'CD': 'DR Congo',
      'CF': 'Central African Republic',
      'CG': 'Republic of the Congo',
      'CH': 'Switzerland',
      'CI': 'Côte d\'Ivoire',
      'CK': 'Cook Islands',
      'CL': 'Chile',
      'CM': 'Cameroon',
      'CN': 'China',
      'CO': 'Colombia',
      'CR': 'Costa Rica',
      'CU': 'Cuba',
      'CV': 'Cape Verde',
      'CW': 'Curaçao',
      'CX': 'Christmas Island',
      'CY': 'Cyprus',
      'CZ': 'Czech Republic',
      'DE': 'Germany',
      'DJ': 'Djibouti',
      'DK': 'Denmark',
      'DM': 'Dominica',
      'DO': 'Dominican Republic',
      'DZ': 'Algeria',
      'EC': 'Ecuador',
      'EE': 'Estonia',
      'EG': 'Egypt',
      'EH': 'Western Sahara',
      'ER': 'Eritrea',
      'ES': 'Spain',
      'ET': 'Ethiopia',
      'FI': 'Finland',
      'FJ': 'Fiji',
      'FK': 'Falkland Islands',
      'FM': 'Micronesia',
      'FO': 'Faroe Islands',
      'FR': 'France',
      'GA': 'Gabon',
      'GB': 'United Kingdom',
      'GD': 'Grenada',
      'GE': 'Georgia',
      'GF': 'French Guiana',
      'GG': 'Guernsey',
      'GH': 'Ghana',
      'GI': 'Gibraltar',
      'GL': 'Greenland',
      'GM': 'Gambia',
      'GN': 'Guinea',
      'GP': 'Guadeloupe',
      'GQ': 'Equatorial Guinea',
      'GR': 'Greece',
      'GS': 'South Georgia',
      'GT': 'Guatemala',
      'GU': 'Guam',
      'GW': 'Guinea-Bissau',
      'GY': 'Guyana',
      'HK': 'Hong Kong',
      'HM': 'Heard Island',
      'HN': 'Honduras',
      'HR': 'Croatia',
      'HT': 'Haiti',
      'HU': 'Hungary',
      'IC': 'Canary Islands',
      'ID': 'Indonesia',
      'IE': 'Ireland',
      'IL': 'Israel',
      'IM': 'Isle of Man',
      'IN': 'India',
      'IO': 'British Indian Ocean Territory',
      'IQ': 'Iraq',
      'IR': 'Iran',
      'IS': 'Iceland',
      'IT': 'Italy',
      'JE': 'Jersey',
      'JM': 'Jamaica',
      'JO': 'Jordan',
      'JP': 'Japan',
      'KE': 'Kenya',
      'KG': 'Kyrgyzstan',
      'KH': 'Cambodia',
      'KI': 'Kiribati',
      'KM': 'Comoros',
      'KN': 'Saint Kitts and Nevis',
      'KP': 'North Korea',
      'KR': 'South Korea',
      'KW': 'Kuwait',
      'KY': 'Cayman Islands',
      'KZ': 'Kazakhstan',
      'LA': 'Laos',
      'LB': 'Lebanon',
      'LC': 'Saint Lucia',
      'LI': 'Liechtenstein',
      'LK': 'Sri Lanka',
      'LR': 'Liberia',
      'LS': 'Lesotho',
      'LT': 'Lithuania',
      'LU': 'Luxembourg',
      'LV': 'Latvia',
      'LY': 'Libya',
      'MA': 'Morocco',
      'MC': 'Monaco',
      'MD': 'Moldova',
      'ME': 'Montenegro',
      'MF': 'Saint Martin',
      'MG': 'Madagascar',
      'MH': 'Marshall Islands',
      'MK': 'North Macedonia',
      'ML': 'Mali',
      'MM': 'Myanmar',
      'MN': 'Mongolia',
      'MO': 'Macao',
      'MP': 'Northern Mariana Islands',
      'MQ': 'Martinique',
      'MR': 'Mauritania',
      'MS': 'Montserrat',
      'MT': 'Malta',
      'MU': 'Mauritius',
      'MV': 'Maldives',
      'MW': 'Malawi',
      'MX': 'Mexico',
      'MY': 'Malaysia',
      'MZ': 'Mozambique',
      'NA': 'Namibia',
      'NC': 'New Caledonia',
      'NE': 'Niger',
      'NF': 'Norfolk Island',
      'NG': 'Nigeria',
      'NI': 'Nicaragua',
      'NL': 'Netherlands',
      'NO': 'Norway',
      'NP': 'Nepal',
      'NR': 'Nauru',
      'NU': 'Niue',
      'NZ': 'New Zealand',
      'OM': 'Oman',
      'PA': 'Panama',
      'PE': 'Peru',
      'PF': 'French Polynesia',
      'PG': 'Papua New Guinea',
      'PH': 'Philippines',
      'PK': 'Pakistan',
      'PL': 'Poland',
      'PM': 'Saint Pierre and Miquelon',
      'PN': 'Pitcairn',
      'PR': 'Puerto Rico',
      'PS': 'Palestine',
      'PT': 'Portugal',
      'PW': 'Palau',
      'PY': 'Paraguay',
      'QA': 'Qatar',
      'RE': 'Réunion',
      'RO': 'Romania',
      'RS': 'Serbia',
      'RU': 'Russia',
      'RW': 'Rwanda',
      'SA': 'Saudi Arabia',
      'SB': 'Solomon Islands',
      'SC': 'Seychelles',
      'SD': 'Sudan',
      'SE': 'Sweden',
      'SG': 'Singapore',
      'SH': 'Saint Helena',
      'SI': 'Slovenia',
      'SJ': 'Svalbard and Jan Mayen',
      'SK': 'Slovakia',
      'SL': 'Sierra Leone',
      'SM': 'San Marino',
      'SN': 'Senegal',
      'SO': 'Somalia',
      'SR': 'Suriname',
      'SS': 'South Sudan',
      'ST': 'São Tomé and Príncipe',
      'SV': 'El Salvador',
      'SX': 'Sint Maarten',
      'SY': 'Syria',
      'SZ': 'Eswatini',
      'TC': 'Turks and Caicos Islands',
      'TD': 'Chad',
      'TF': 'French Southern Territories',
      'TG': 'Togo',
      'TH': 'Thailand',
      'TJ': 'Tajikistan',
      'TK': 'Tokelau',
      'TL': 'Timor-Leste',
      'TM': 'Turkmenistan',
      'TN': 'Tunisia',
      'TO': 'Tonga',
      'TR': 'Turkey',
      'TT': 'Trinidad and Tobago',
      'TV': 'Tuvalu',
      'TW': 'Taiwan',
      'TZ': 'Tanzania',
      'UA': 'Ukraine',
      'UG': 'Uganda',
      'UM': 'U.S. Minor Outlying Islands',
      'US': 'United States',
      'UY': 'Uruguay',
      'UZ': 'Uzbekistan',
      'VA': 'Vatican City',
      'VC': 'Saint Vincent and the Grenadines',
      'VE': 'Venezuela',
      'VG': 'British Virgin Islands',
      'VI': 'U.S. Virgin Islands',
      'VN': 'Vietnam',
      'VU': 'Vanuatu',
      'WF': 'Wallis and Futuna',
      'WS': 'Samoa',
      'XK': 'Kosovo',
      'YE': 'Yemen',
      'YT': 'Mayotte',
      'ZA': 'South Africa',
      'ZM': 'Zambia',
      'ZW': 'Zimbabwe',
      'EU': 'European Union',
      'UN': 'United Nations',
    };

    return countryNames[countryCode.toUpperCase()] ?? countryCode;
  }
}
