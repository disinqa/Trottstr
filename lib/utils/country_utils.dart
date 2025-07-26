/// Utility class for country-related operations
class CountryUtils {
  static const List<CountryInfo> _countries = [
    // Major Countries
    CountryInfo(code: 'US', name: 'United States', flag: '🇺🇸'),
    CountryInfo(code: 'GB', name: 'United Kingdom', flag: '🇬🇧'),
    CountryInfo(code: 'DE', name: 'Germany', flag: '🇩🇪'),
    CountryInfo(code: 'FR', name: 'France', flag: '🇫🇷'),
    CountryInfo(code: 'ES', name: 'Spain', flag: '🇪🇸'),
    CountryInfo(code: 'IT', name: 'Italy', flag: '🇮🇹'),
    CountryInfo(code: 'NL', name: 'Netherlands', flag: '🇳🇱'),
    CountryInfo(code: 'CH', name: 'Switzerland', flag: '🇨🇭'),
    CountryInfo(code: 'AT', name: 'Austria', flag: '🇦🇹'),
    CountryInfo(code: 'BE', name: 'Belgium', flag: '🇧🇪'),
    CountryInfo(code: 'PT', name: 'Portugal', flag: '🇵🇹'),
    CountryInfo(code: 'IE', name: 'Ireland', flag: '🇮🇪'),
    CountryInfo(code: 'LU', name: 'Luxembourg', flag: '🇱🇺'),
    
    // Nordic Countries
    CountryInfo(code: 'SE', name: 'Sweden', flag: '🇸🇪'),
    CountryInfo(code: 'NO', name: 'Norway', flag: '🇳🇴'),
    CountryInfo(code: 'DK', name: 'Denmark', flag: '🇩🇰'),
    CountryInfo(code: 'FI', name: 'Finland', flag: '🇫🇮'),
    CountryInfo(code: 'IS', name: 'Iceland', flag: '🇮🇸'),
    
    // Eastern Europe
    CountryInfo(code: 'PL', name: 'Poland', flag: '🇵🇱'),
    CountryInfo(code: 'CZ', name: 'Czech Republic', flag: '🇨🇿'),
    CountryInfo(code: 'SK', name: 'Slovakia', flag: '🇸🇰'),
    CountryInfo(code: 'HU', name: 'Hungary', flag: '🇭🇺'),
    CountryInfo(code: 'RO', name: 'Romania', flag: '🇷🇴'),
    CountryInfo(code: 'BG', name: 'Bulgaria', flag: '🇧🇬'),
    CountryInfo(code: 'HR', name: 'Croatia', flag: '🇭🇷'),
    CountryInfo(code: 'SI', name: 'Slovenia', flag: '🇸🇮'),
    CountryInfo(code: 'EE', name: 'Estonia', flag: '🇪🇪'),
    CountryInfo(code: 'LV', name: 'Latvia', flag: '🇱🇻'),
    CountryInfo(code: 'LT', name: 'Lithuania', flag: '🇱🇹'),
    
    // Asia Pacific
    CountryInfo(code: 'JP', name: 'Japan', flag: '🇯🇵'),
    CountryInfo(code: 'KR', name: 'South Korea', flag: '🇰🇷'),
    CountryInfo(code: 'CN', name: 'China', flag: '🇨🇳'),
    CountryInfo(code: 'SG', name: 'Singapore', flag: '🇸🇬'),
    CountryInfo(code: 'HK', name: 'Hong Kong', flag: '🇭🇰'),
    CountryInfo(code: 'TW', name: 'Taiwan', flag: '🇹🇼'),
    CountryInfo(code: 'TH', name: 'Thailand', flag: '🇹🇭'),
    CountryInfo(code: 'MY', name: 'Malaysia', flag: '🇲🇾'),
    CountryInfo(code: 'PH', name: 'Philippines', flag: '🇵🇭'),
    CountryInfo(code: 'VN', name: 'Vietnam', flag: '🇻🇳'),
    CountryInfo(code: 'ID', name: 'Indonesia', flag: '🇮🇩'),
    CountryInfo(code: 'AU', name: 'Australia', flag: '🇦🇺'),
    CountryInfo(code: 'NZ', name: 'New Zealand', flag: '🇳🇿'),
    CountryInfo(code: 'IN', name: 'India', flag: '🇮🇳'),
    
    // Americas
    CountryInfo(code: 'CA', name: 'Canada', flag: '🇨🇦'),
    CountryInfo(code: 'MX', name: 'Mexico', flag: '🇲🇽'),
    CountryInfo(code: 'BR', name: 'Brazil', flag: '🇧🇷'),
    CountryInfo(code: 'AR', name: 'Argentina', flag: '🇦🇷'),
    CountryInfo(code: 'CL', name: 'Chile', flag: '🇨🇱'),
    CountryInfo(code: 'CO', name: 'Colombia', flag: '🇨🇴'),
    CountryInfo(code: 'PE', name: 'Peru', flag: '🇵🇪'),
    CountryInfo(code: 'UY', name: 'Uruguay', flag: '🇺🇾'),
    CountryInfo(code: 'CR', name: 'Costa Rica', flag: '🇨🇷'),
    CountryInfo(code: 'PA', name: 'Panama', flag: '🇵🇦'),
    
    // Middle East & Africa
    CountryInfo(code: 'AE', name: 'UAE', flag: '🇦🇪'),
    CountryInfo(code: 'SA', name: 'Saudi Arabia', flag: '🇸🇦'),
    CountryInfo(code: 'QA', name: 'Qatar', flag: '🇶🇦'),
    CountryInfo(code: 'KW', name: 'Kuwait', flag: '🇰🇼'),
    CountryInfo(code: 'BH', name: 'Bahrain', flag: '🇧🇭'),
    CountryInfo(code: 'OM', name: 'Oman', flag: '🇴🇲'),
    CountryInfo(code: 'IL', name: 'Israel', flag: '🇮🇱'),
    CountryInfo(code: 'TR', name: 'Turkey', flag: '🇹🇷'),
    CountryInfo(code: 'ZA', name: 'South Africa', flag: '🇿🇦'),
    CountryInfo(code: 'EG', name: 'Egypt', flag: '🇪🇬'),
    CountryInfo(code: 'MA', name: 'Morocco', flag: '🇲🇦'),
    CountryInfo(code: 'KE', name: 'Kenya', flag: '🇰🇪'),
    CountryInfo(code: 'NG', name: 'Nigeria', flag: '🇳🇬'),
    CountryInfo(code: 'GH', name: 'Ghana', flag: '🇬🇭'),
    
    // Other European
    CountryInfo(code: 'RU', name: 'Russia', flag: '🇷🇺'),
    CountryInfo(code: 'UA', name: 'Ukraine', flag: '🇺🇦'),
    CountryInfo(code: 'BY', name: 'Belarus', flag: '🇧🇾'),
    CountryInfo(code: 'RS', name: 'Serbia', flag: '🇷🇸'),
    CountryInfo(code: 'BA', name: 'Bosnia and Herzegovina', flag: '🇧🇦'),
    CountryInfo(code: 'ME', name: 'Montenegro', flag: '🇲🇪'),
    CountryInfo(code: 'MK', name: 'North Macedonia', flag: '🇲🇰'),
    CountryInfo(code: 'AL', name: 'Albania', flag: '🇦🇱'),
    CountryInfo(code: 'GR', name: 'Greece', flag: '🇬🇷'),
    CountryInfo(code: 'CY', name: 'Cyprus', flag: '🇨🇾'),
    CountryInfo(code: 'MT', name: 'Malta', flag: '🇲🇹'),
    
    // Other Popular
    CountryInfo(code: 'AD', name: 'Andorra', flag: '🇦🇩'),
    CountryInfo(code: 'MC', name: 'Monaco', flag: '🇲🇨'),
    CountryInfo(code: 'LI', name: 'Liechtenstein', flag: '🇱🇮'),
    CountryInfo(code: 'SM', name: 'San Marino', flag: '🇸🇲'),
    CountryInfo(code: 'VA', name: 'Vatican City', flag: '🇻🇦'),
  ];

  /// Get all available countries
  static List<CountryInfo> getAllCountries() {
    final sorted = List<CountryInfo>.from(_countries);
    sorted.sort((a, b) => a.name.compareTo(b.name));
    return sorted;
  }

  /// Get country by code
  static CountryInfo? getCountryByCode(String code) {
    try {
      return _countries.firstWhere((country) => country.code == code);
    } catch (e) {
      return null;
    }
  }

  /// Get country name by code
  static String getCountryName(String code) {
    final country = getCountryByCode(code);
    return country?.name ?? code;
  }

  /// Get country flag by code
  static String getCountryFlag(String code) {
    final country = getCountryByCode(code);
    return country?.flag ?? '🌍';
  }

  /// Search countries by name or code
  static List<CountryInfo> searchCountries(String query) {
    if (query.isEmpty) return getAllCountries();
    
    final lowerQuery = query.toLowerCase();
    return _countries
        .where((country) =>
            country.name.toLowerCase().contains(lowerQuery) ||
            country.code.toLowerCase().contains(lowerQuery))
        .toList()
      ..sort((a, b) => a.name.compareTo(b.name));
  }

  /// Get most commonly used countries (for quick selection)
  static List<CountryInfo> getPopularCountries() {
    const popularCodes = [
      'US', 'GB', 'DE', 'FR', 'ES', 'IT', 'NL', 'CH', 'AT', 'BE',
      'PT', 'SE', 'NO', 'DK', 'FI', 'SG', 'HK', 'AU', 'CA', 'AE',
    ];
    
    return popularCodes
        .map((code) => getCountryByCode(code))
        .where((country) => country != null)
        .cast<CountryInfo>()
        .toList();
  }

  /// Validate country code
  static bool isValidCountryCode(String code) {
    return getCountryByCode(code) != null;
  }
}

/// Country information model
class CountryInfo {
  final String code;
  final String name;
  final String flag;

  const CountryInfo({
    required this.code,
    required this.name,
    required this.flag,
  });

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CountryInfo && other.code == code;
  }

  @override
  int get hashCode => code.hashCode;

  @override
  String toString() => '$flag $name ($code)';
}