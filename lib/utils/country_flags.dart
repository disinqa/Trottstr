import 'package:flutter/material.dart';

/// Utility functions for displaying country flags
class CountryFlags {
  /// Convert country code to flag emoji
  static String getFlag(String countryCode) {
    if (countryCode.length != 2) return '🏳️'; // Default flag for invalid codes
    
    final upperCode = countryCode.toUpperCase();
    
    // Convert country code to flag emoji using Unicode regional indicator symbols
    final flag = String.fromCharCodes([
      0x1F1E6 - 1 + upperCode.codeUnitAt(0),
      0x1F1E6 - 1 + upperCode.codeUnitAt(1),
    ]);
    
    return flag;
  }

  /// Get country flag with fallback text
  static String getFlagWithFallback(String countryCode) {
    try {
      return getFlag(countryCode);
    } catch (e) {
      return countryCode; // Fallback to country code if flag fails
    }
  }

  /// Widget that displays country flag with proper sizing
  static Widget flagWidget(String countryCode, {double? size}) {
    return Text(
      getFlag(countryCode),
      style: TextStyle(
        fontSize: size ?? 24,
        fontFamily: 'Noto Color Emoji', // Use color emoji font if available
      ),
    );
  }

  /// Some country codes have special handling
  static String getSpecialFlag(String countryCode) {
    switch (countryCode.toUpperCase()) {
      case 'UK':
      case 'GB':
        return getFlag('GB'); // United Kingdom
      case 'EU':
        return '🇪🇺'; // European Union (not a country but useful)
      case 'AN':
        return '🇳🇱'; // Netherlands Antilles -> Netherlands
      case 'YU':
        return '🏳️'; // Former Yugoslavia
      case 'SU':
        return '🏳️'; // Former Soviet Union
      default:
        return getFlag(countryCode);
    }
  }

  /// Check if country code is valid (2 letters)
  static bool isValidCountryCode(String countryCode) {
    return countryCode.length == 2 && RegExp(r'^[A-Za-z]{2}$').hasMatch(countryCode);
  }

  /// Comprehensive country flag mappings using emoji
  static const Map<String, String> countryFlags = {
    // Popular countries
    'US': '🇺🇸', 'GB': '🇬🇧', 'CA': '🇨🇦', 'AU': '🇦🇺', 'DE': '🇩🇪',
    'FR': '🇫🇷', 'IT': '🇮🇹', 'ES': '🇪🇸', 'CH': '🇨🇭', 'JP': '🇯🇵',
    'KR': '🇰🇷', 'CN': '🇨🇳', 'IN': '🇮🇳', 'BR': '🇧🇷', 'MX': '🇲🇽',
    'RU': '🇷🇺', 'TH': '🇹🇭', 'SG': '🇸🇬', 'MY': '🇲🇾', 'ID': '🇮🇩',
    'PH': '🇵🇭', 'VN': '🇻🇳', 'AE': '🇦🇪', 'SA': '🇸🇦', 'EG': '🇪🇬',
    'ZA': '🇿🇦', 'NG': '🇳🇬', 'KE': '🇰🇪', 'GH': '🇬🇭',
    
    // All other countries A-Z
    'AD': '🇦🇩', 'AF': '🇦🇫', 'AG': '🇦🇬', 'AI': '🇦🇮', 'AL': '🇦🇱',
    'AM': '🇦🇲', 'AO': '🇦🇴', 'AQ': '🇦🇶', 'AR': '🇦🇷', 'AS': '🇦🇸',
    'AT': '🇦🇹', 'AW': '🇦🇼', 'AX': '🇦🇽', 'AZ': '🇦🇿', 'BA': '🇧🇦',
    'BB': '🇧🇧', 'BD': '🇧🇩', 'BE': '🇧🇪', 'BF': '🇧🇫', 'BG': '🇧🇬',
    'BH': '🇧🇭', 'BI': '🇧🇮', 'BJ': '🇧🇯', 'BL': '🇧🇱', 'BM': '🇧🇲',
    'BN': '🇧🇳', 'BO': '🇧🇴', 'BQ': '🇧🇶', 'BS': '🇧🇸', 'BT': '🇧🇹',
    'BV': '🇧🇻', 'BW': '🇧🇼', 'BY': '🇧🇾', 'BZ': '🇧🇿', 'CC': '🇨🇨',
    'CD': '🇨🇩', 'CF': '🇨🇫', 'CG': '🇨🇬', 'CI': '🇨🇮', 'CK': '🇨🇰',
    'CL': '🇨🇱', 'CM': '🇨🇲', 'CO': '🇨🇴', 'CR': '🇨🇷', 'CU': '🇨🇺',
    'CV': '🇨🇻', 'CW': '🇨🇼', 'CX': '🇨🇽', 'CY': '🇨🇾', 'CZ': '🇨🇿',
    'DJ': '🇩🇯', 'DK': '🇩🇰', 'DM': '🇩🇲', 'DO': '🇩🇴', 'DZ': '🇩🇿',
    'EC': '🇪🇨', 'EE': '🇪🇪', 'EH': '🇪🇭', 'ER': '🇪🇷', 'ET': '🇪🇹',
    'FI': '🇫🇮', 'FJ': '🇫🇯', 'FK': '🇫🇰', 'FM': '🇫🇲', 'FO': '🇫🇴',
    'GA': '🇬🇦', 'GD': '🇬🇩', 'GE': '🇬🇪', 'GF': '🇬🇫', 'GG': '🇬🇬',
    'GI': '🇬🇮', 'GL': '🇬🇱', 'GM': '🇬🇲', 'GN': '🇬🇳', 'GP': '🇬🇵',
    'GQ': '🇬🇶', 'GR': '🇬🇷', 'GS': '🇬🇸', 'GT': '🇬🇹', 'GU': '🇬🇺',
    'GW': '🇬🇼', 'GY': '🇬🇾', 'HK': '🇭🇰', 'HM': '🇭🇲', 'HN': '🇭🇳',
    'HR': '🇭🇷', 'HT': '🇭🇹', 'HU': '🇭🇺', 'IC': '🇮🇨', 'IE': '🇮🇪',
    'IL': '🇮🇱', 'IM': '🇮🇲', 'IO': '🇮🇴', 'IQ': '🇮🇶', 'IR': '🇮🇷',
    'IS': '🇮🇸', 'JE': '🇯🇪', 'JM': '🇯🇲', 'JO': '🇯🇴', 'KG': '🇰🇬',
    'KH': '🇰🇭', 'KI': '🇰🇮', 'KM': '🇰🇲', 'KN': '🇰🇳', 'KP': '🇰🇵',
    'KW': '🇰🇼', 'KY': '🇰🇾', 'KZ': '🇰🇿', 'LA': '🇱🇦', 'LB': '🇱🇧',
    'LC': '🇱🇨', 'LI': '🇱🇮', 'LK': '🇱🇰', 'LR': '🇱🇷', 'LS': '🇱🇸',
    'LT': '🇱🇹', 'LU': '🇱🇺', 'LV': '🇱🇻', 'LY': '🇱🇾', 'MA': '🇲🇦',
    'MC': '🇲🇨', 'MD': '🇲🇩', 'ME': '🇲🇪', 'MF': '🇲🇫', 'MG': '🇲🇬',
    'MH': '🇲🇭', 'MK': '🇲🇰', 'ML': '🇲🇱', 'MM': '🇲🇲', 'MN': '🇲🇳',
    'MO': '🇲🇴', 'MP': '🇲🇵', 'MQ': '🇲🇶', 'MR': '🇲🇷', 'MS': '🇲🇸',
    'MT': '🇲🇹', 'MU': '🇲🇺', 'MV': '🇲🇻', 'MW': '🇲🇼', 'MZ': '🇲🇿',
    'NA': '🇳🇦', 'NC': '🇳🇨', 'NE': '🇳🇪', 'NF': '🇳🇫', 'NI': '🇳🇮',
    'NL': '🇳🇱', 'NO': '🇳🇴', 'NP': '🇳🇵', 'NR': '🇳🇷', 'NU': '🇳🇺',
    'NZ': '🇳🇿', 'OM': '🇴🇲', 'PA': '🇵🇦', 'PE': '🇵🇪', 'PF': '🇵🇫',
    'PG': '🇵🇬', 'PK': '🇵🇰', 'PL': '🇵🇱', 'PM': '🇵🇲', 'PN': '🇵🇳',
    'PR': '🇵🇷', 'PS': '🇵🇸', 'PT': '🇵🇹', 'PW': '🇵🇼', 'PY': '🇵🇾',
    'QA': '🇶🇦', 'RE': '🇷🇪', 'RO': '🇷🇴', 'RS': '🇷🇸', 'RW': '🇷🇼',
    'SB': '🇸🇧', 'SC': '🇸🇨', 'SD': '🇸🇩', 'SE': '🇸🇪', 'SH': '🇸🇭',
    'SI': '🇸🇮', 'SJ': '🇸🇯', 'SK': '🇸🇰', 'SL': '🇸🇱', 'SM': '🇸🇲',
    'SN': '🇸🇳', 'SO': '🇸🇴', 'SR': '🇸🇷', 'SS': '🇸🇸', 'ST': '🇸🇹',
    'SV': '🇸🇻', 'SX': '🇸🇽', 'SY': '🇸🇾', 'SZ': '🇸🇿', 'TC': '🇹🇨',
    'TD': '🇹🇩', 'TF': '🇹🇫', 'TG': '🇹🇬', 'TJ': '🇹🇯', 'TK': '🇹🇰',
    'TL': '🇹🇱', 'TM': '🇹🇲', 'TN': '🇹🇳', 'TO': '🇹🇴', 'TR': '🇹🇷',
    'TT': '🇹🇹', 'TV': '🇹🇻', 'TW': '🇹🇼', 'TZ': '🇹🇿', 'UA': '🇺🇦',
    'UG': '🇺🇬', 'UM': '🇺🇲', 'UY': '🇺🇾', 'UZ': '🇺🇿', 'VA': '🇻🇦',
    'VC': '🇻🇨', 'VE': '🇻🇪', 'VG': '🇻🇬', 'VI': '🇻🇮', 'VU': '🇻🇺',
    'WF': '🇼🇫', 'WS': '🇼🇸', 'XK': '🇽🇰', 'YE': '🇾🇪', 'YT': '🇾🇹',
    'ZM': '🇿🇲', 'ZW': '🇿🇼',
    
    // Special territories and regions
    'EU': '🇪🇺', // European Union
    'UN': '🇺🇳', // United Nations
  };

  /// Get flag with comprehensive emoji mapping
  static String getFlagOptimized(String countryCode) {
    final upperCode = countryCode.toUpperCase();
    
    // Use comprehensive emoji mapping (guaranteed to work well)
    if (countryFlags.containsKey(upperCode)) {
      return countryFlags[upperCode]!;
    }
    
    // Fall back to generated flag for any missing codes
    return getFlag(upperCode);
  }
}