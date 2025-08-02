/// Real-world default tax residency limits for countries
/// Based on actual tax residency thresholds used by tax authorities
class CountryTaxDefaults {
  /// Default tax residency limits by country code
  /// Most countries use 183 days, but some have different thresholds
  static const Map<String, int> defaultLimits = {
    // Countries with 90-day thresholds
    'AE': 90,  // UAE - 90 days
    'MC': 90,  // Monaco - 90 days
    'SG': 90,  // Singapore - 90 days (for certain cases)
    
    // Countries with 120-day thresholds
    'MY': 120, // Malaysia - 120 days
    'TH': 120, // Thailand - 120 days
    
    // Countries with 180-day thresholds
    'AU': 180, // Australia - 180 days
    'NZ': 180, // New Zealand - 180 days
    'ZA': 180, // South Africa - 180 days
    'JP': 180, // Japan - 180 days (for certain cases)
    
    // Countries with specific thresholds
    'US': 183,  // United States - 183 days (substantial presence test)
    'GB': 183,  // United Kingdom - 183 days
    'CA': 183,  // Canada - 183 days
    'DE': 183,  // Germany - 183 days
    'FR': 183,  // France - 183 days
    'IT': 183,  // Italy - 183 days
    'ES': 183,  // Spain - 183 days
    'NL': 183,  // Netherlands - 183 days
    'CH': 183,  // Switzerland - 183 days
    'AT': 183,  // Austria - 183 days
    'BE': 183,  // Belgium - 183 days
    'PT': 183,  // Portugal - 183 days
    'IE': 183,  // Ireland - 183 days
    'LU': 183,  // Luxembourg - 183 days
    'SE': 183,  // Sweden - 183 days
    'NO': 183,  // Norway - 183 days
    'DK': 183,  // Denmark - 183 days
    'FI': 183,  // Finland - 183 days
    'IS': 183,  // Iceland - 183 days
    'PL': 183,  // Poland - 183 days
    'CZ': 183,  // Czech Republic - 183 days
    'SK': 183,  // Slovakia - 183 days
    'HU': 183,  // Hungary - 183 days
    'RO': 183,  // Romania - 183 days
    'BG': 183,  // Bulgaria - 183 days
    'HR': 183,  // Croatia - 183 days
    'SI': 183,  // Slovenia - 183 days
    'EE': 183,  // Estonia - 183 days
    'LV': 183,  // Latvia - 183 days
    'LT': 183,  // Lithuania - 183 days
    'KR': 183,  // South Korea - 183 days
    'CN': 183,  // China - 183 days
    'HK': 183,  // Hong Kong - 183 days
    'TW': 183,  // Taiwan - 183 days
    'IN': 183,  // India - 183 days
    'BR': 183,  // Brazil - 183 days
    'AR': 183,  // Argentina - 183 days
    'CL': 183,  // Chile - 183 days
    'CO': 183,  // Colombia - 183 days
    'PE': 183,  // Peru - 183 days
    'UY': 183,  // Uruguay - 183 days
    'CR': 183,  // Costa Rica - 183 days
    'PA': 183,  // Panama - 183 days
    'MX': 183,  // Mexico - 183 days
    'SA': 183,  // Saudi Arabia - 183 days
    'QA': 183,  // Qatar - 183 days
    'KW': 183,  // Kuwait - 183 days
    'BH': 183,  // Bahrain - 183 days
    'OM': 183,  // Oman - 183 days
    'IL': 183,  // Israel - 183 days
    'TR': 183,  // Turkey - 183 days
    'EG': 183,  // Egypt - 183 days
    'MA': 183,  // Morocco - 183 days
    'KE': 183,  // Kenya - 183 days
    'NG': 183,  // Nigeria - 183 days
    'GH': 183,  // Ghana - 183 days
    'RU': 183,  // Russia - 183 days
    'UA': 183,  // Ukraine - 183 days
    'BY': 183,  // Belarus - 183 days
    'RS': 183,  // Serbia - 183 days
    'BA': 183,  // Bosnia and Herzegovina - 183 days
    'ME': 183,  // Montenegro - 183 days
    'MK': 183,  // North Macedonia - 183 days
    'AL': 183,  // Albania - 183 days
    'GR': 183,  // Greece - 183 days
    'CY': 183,  // Cyprus - 183 days
    'MT': 183,  // Malta - 183 days
    'AD': 183,  // Andorra - 183 days
    'LI': 183,  // Liechtenstein - 183 days
    'SM': 183,  // San Marino - 183 days
    'VA': 183,  // Vatican City - 183 days
    'PH': 183,  // Philippines - 183 days
    'VN': 183,  // Vietnam - 183 days
    'ID': 183,  // Indonesia - 183 days
    
    // Additional countries with 183-day default (most common)
    'AF': 183, 'AG': 183, 'AI': 183, 'AM': 183, 'AO': 183, 'AQ': 183,
    'AS': 183, 'AW': 183, 'AX': 183, 'AZ': 183, 'BB': 183, 'BD': 183,
    'BF': 183, 'BI': 183, 'BJ': 183, 'BL': 183, 'BM': 183, 'BN': 183,
    'BO': 183, 'BQ': 183, 'BS': 183, 'BT': 183, 'BV': 183, 'BW': 183,
    'BZ': 183, 'CC': 183, 'CD': 183, 'CF': 183, 'CG': 183, 'CI': 183,
    'CK': 183, 'CM': 183, 'CU': 183, 'CV': 183, 'CW': 183, 'CX': 183,
    'DJ': 183, 'DM': 183, 'DO': 183, 'DZ': 183, 'EC': 183, 'EH': 183,
    'ER': 183, 'ET': 183, 'FJ': 183, 'FK': 183, 'FM': 183, 'FO': 183,
    'GA': 183, 'GD': 183, 'GE': 183, 'GF': 183, 'GG': 183, 'GI': 183,
    'GL': 183, 'GM': 183, 'GN': 183, 'GP': 183, 'GQ': 183, 'GS': 183,
    'GT': 183, 'GU': 183, 'GW': 183, 'GY': 183, 'HM': 183, 'HN': 183,
    'HT': 183, 'IC': 183, 'IM': 183, 'IO': 183, 'IQ': 183, 'IR': 183,
    'JE': 183, 'JM': 183, 'JO': 183, 'KG': 183, 'KH': 183, 'KI': 183,
    'KM': 183, 'KN': 183, 'KP': 183, 'KY': 183, 'KZ': 183, 'LA': 183,
    'LB': 183, 'LC': 183, 'LK': 183, 'LR': 183, 'LS': 183, 'LY': 183,
    'MD': 183, 'MF': 183, 'MG': 183, 'MH': 183, 'ML': 183, 'MM': 183,
    'MN': 183, 'MO': 183, 'MP': 183, 'MQ': 183, 'MR': 183, 'MS': 183,
    'MU': 183, 'MV': 183, 'MW': 183, 'MZ': 183, 'NA': 183, 'NC': 183,
    'NE': 183, 'NF': 183, 'NI': 183, 'NP': 183, 'NR': 183, 'NU': 183,
    'PF': 183, 'PG': 183, 'PK': 183, 'PM': 183, 'PN': 183,
    'PR': 183, 'PS': 183, 'PW': 183, 'PY': 183, 'RE': 183, 'RW': 183,
    'SB': 183, 'SC': 183, 'SD': 183, 'SH': 183, 'SJ': 183, 'SL': 183,
    'SN': 183, 'SO': 183, 'SR': 183, 'SS': 183, 'ST': 183, 'SV': 183,
    'SX': 183, 'SY': 183, 'SZ': 183, 'TC': 183, 'TD': 183, 'TF': 183,
    'TG': 183, 'TJ': 183, 'TK': 183, 'TL': 183, 'TM': 183, 'TN': 183,
    'TO': 183, 'TT': 183, 'TV': 183, 'TZ': 183, 'UG': 183, 'UM': 183,
    'UZ': 183, 'VC': 183, 'VE': 183, 'VG': 183, 'VI': 183, 'VU': 183,
    'WF': 183, 'WS': 183, 'XK': 183, 'YE': 183, 'YT': 183, 'ZM': 183,
    'ZW': 183, 'EU': 183, 'UN': 183,
  };

  /// Get the default tax residency limit for a country
  static int getDefaultLimit(String countryCode) {
    return defaultLimits[countryCode.toUpperCase()] ?? 183;
  }

  /// Check if a country has a non-standard default limit
  static bool hasCustomDefault(String countryCode) {
    final defaultLimit = getDefaultLimit(countryCode);
    return defaultLimit != 183;
  }

  /// Get all countries with non-standard defaults
  static Map<String, int> getNonStandardDefaults() {
    return Map.fromEntries(
      defaultLimits.entries.where((entry) => entry.value != 183),
    );
  }

  /// Get a human-readable description of the limit
  static String getLimitDescription(String countryCode, int limit) {
    final defaultLimit = getDefaultLimit(countryCode);
    if (limit == defaultLimit) {
      return hasCustomDefault(countryCode) 
          ? '$limit days (country default)'
          : '$limit days (standard default)';
    } else {
      return '$limit days (custom)';
    }
  }
}