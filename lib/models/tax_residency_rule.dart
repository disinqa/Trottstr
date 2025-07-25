/// Represents tax residency rules for a specific country
class TaxResidencyRule {
  final String countryCode;
  final String countryName;
  final int daysThreshold;
  final String description;
  final String? additionalNotes;
  final List<String>? exceptions;

  const TaxResidencyRule({
    required this.countryCode,
    required this.countryName,
    required this.daysThreshold,
    required this.description,
    this.additionalNotes,
    this.exceptions,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
    'countryCode': countryCode,
    'countryName': countryName,
    'daysThreshold': daysThreshold,
    'description': description,
    if (additionalNotes != null) 'additionalNotes': additionalNotes,
    if (exceptions != null) 'exceptions': exceptions,
  };

  /// Create from JSON
  factory TaxResidencyRule.fromJson(Map<String, dynamic> json) =>
      TaxResidencyRule(
        countryCode: json['countryCode'],
        countryName: json['countryName'],
        daysThreshold: json['daysThreshold'],
        description: json['description'],
        additionalNotes: json['additionalNotes'],
        exceptions: json['exceptions']?.cast<String>(),
      );

  @override
  String toString() => '$countryName: $daysThreshold days';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TaxResidencyRule &&
          runtimeType == other.runtimeType &&
          countryCode == other.countryCode;

  @override
  int get hashCode => countryCode.hashCode;
}

/// Default tax residency rules for common countries
class DefaultTaxResidencyRules {
  static const List<TaxResidencyRule> rules = [
    TaxResidencyRule(
      countryCode: 'US',
      countryName: 'United States',
      daysThreshold: 183,
      description: 'Substantial presence test - 183 days in current year',
      additionalNotes: 'Complex calculation involving 3-year lookback period',
    ),
    TaxResidencyRule(
      countryCode: 'GB',
      countryName: 'United Kingdom',
      daysThreshold: 90,
      description: 'Visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Post-Brexit rules for most non-UK nationals',
    ),
    TaxResidencyRule(
      countryCode: 'DE',
      countryName: 'Germany',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'FR',
      countryName: 'France',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'CA',
      countryName: 'Canada',
      daysThreshold: 183,
      description: 'Deemed resident if present for 183+ days',
      additionalNotes:
          'May be resident with fewer days if having residential ties',
    ),
    TaxResidencyRule(
      countryCode: 'AU',
      countryName: 'Australia',
      daysThreshold: 183,
      description: 'Resident if present for 183+ days',
      additionalNotes: 'Unless usual place of abode is outside Australia',
    ),
    TaxResidencyRule(
      countryCode: 'SG',
      countryName: 'Singapore',
      daysThreshold: 30,
      description: 'Tourist visa exemption of 30 days',
      additionalNotes: 'For most passport holders; 90 days for some countries',
    ),
    TaxResidencyRule(
      countryCode: 'HK',
      countryName: 'Hong Kong',
      daysThreshold: 90,
      description: 'Visitor limit of 90 days visa-free',
      additionalNotes: 'For most passport holders; 180 days for some',
    ),
    TaxResidencyRule(
      countryCode: 'AE',
      countryName: 'United Arab Emirates',
      daysThreshold: 30,
      description: 'Tourist visa exemption of 30 days',
      additionalNotes: 'For most passport holders; 90 days for some countries',
    ),
    TaxResidencyRule(
      countryCode: 'CH',
      countryName: 'Switzerland',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU/EFTA visitors',
    ),
    TaxResidencyRule(
      countryCode: 'NL',
      countryName: 'Netherlands',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'ES',
      countryName: 'Spain',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'IT',
      countryName: 'Italy',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'PT',
      countryName: 'Portugal',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'JP',
      countryName: 'Japan',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days visa-free',
      additionalNotes: 'For most passport holders; extensions possible',
    ),
    TaxResidencyRule(
      countryCode: 'KR',
      countryName: 'South Korea',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days visa-free',
      additionalNotes: 'For most passport holders; K-ETA required for some',
    ),
    TaxResidencyRule(
      countryCode: 'TH',
      countryName: 'Thailand',
      daysThreshold: 30,
      description: 'Tourist visa exemption of 30 days',
      additionalNotes: 'Can be extended; tourist visa allows 60 days',
    ),
    TaxResidencyRule(
      countryCode: 'MY',
      countryName: 'Malaysia',
      daysThreshold: 182,
      description: 'Tax resident if present for 182+ days',
      additionalNotes: 'Or 90+ days for two consecutive years',
    ),
    TaxResidencyRule(
      countryCode: 'ID',
      countryName: 'Indonesia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a 12-month period',
    ),
    TaxResidencyRule(
      countryCode: 'PH',
      countryName: 'Philippines',
      daysThreshold: 180,
      description: 'Tax resident if present for 180+ days',
      additionalNotes: 'In any calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'MX',
      countryName: 'Mexico',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'Or if having center of vital interests in Mexico',
    ),
    TaxResidencyRule(
      countryCode: 'BR',
      countryName: 'Brazil',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a 12-month period, consecutive or not',
    ),
    TaxResidencyRule(
      countryCode: 'AR',
      countryName: 'Argentina',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'Per calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'CL',
      countryName: 'Chile',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In any calendar year within an 18-month period',
    ),
    TaxResidencyRule(
      countryCode: 'ZA',
      countryName: 'South Africa',
      daysThreshold: 91,
      description: 'Ordinarily resident test or physical presence test',
      additionalNotes:
          '91+ days in current year AND 915+ days in preceding 5 years',
    ),
    TaxResidencyRule(
      countryCode: 'EG',
      countryName: 'Egypt',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a tax year',
    ),
    TaxResidencyRule(
      countryCode: 'IN',
      countryName: 'India',
      daysThreshold: 182,
      description: 'Tax resident if present for 182+ days',
      additionalNotes: 'Or 60+ days if Indian citizen/PIO with income >15 lakh',
    ),
    TaxResidencyRule(
      countryCode: 'CN',
      countryName: 'China',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'RU',
      countryName: 'Russia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'VN',
      countryName: 'Vietnam',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'TR',
      countryName: 'Turkey',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'GR',
      countryName: 'Greece',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'Or if having center of vital interests in Greece',
    ),
    TaxResidencyRule(
      countryCode: 'CY',
      countryName: 'Cyprus',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In any calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'MT',
      countryName: 'Malta',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In any calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'EE',
      countryName: 'Estonia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'LV',
      countryName: 'Latvia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'LT',
      countryName: 'Lithuania',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'PL',
      countryName: 'Poland',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'Or if having center of vital interests in Poland',
    ),
    TaxResidencyRule(
      countryCode: 'CZ',
      countryName: 'Czech Republic',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'HU',
      countryName: 'Hungary',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'RO',
      countryName: 'Romania',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'BG',
      countryName: 'Bulgaria',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'HR',
      countryName: 'Croatia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'SI',
      countryName: 'Slovenia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'SK',
      countryName: 'Slovakia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'BE',
      countryName: 'Belgium',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'AT',
      countryName: 'Austria',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'NO',
      countryName: 'Norway',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU/EEA visitors',
    ),
    TaxResidencyRule(
      countryCode: 'SE',
      countryName: 'Sweden',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'DK',
      countryName: 'Denmark',
      daysThreshold: 90,
      description: 'Tourist/visitor limit of 90 days in any 180-day period',
      additionalNotes: 'Schengen area rules apply for non-EU visitors',
    ),
    TaxResidencyRule(
      countryCode: 'FI',
      countryName: 'Finland',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'IS',
      countryName: 'Iceland',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'IE',
      countryName: 'Ireland',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a tax year',
    ),
    TaxResidencyRule(
      countryCode: 'LU',
      countryName: 'Luxembourg',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'MC',
      countryName: 'Monaco',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'No personal income tax for residents',
    ),
    TaxResidencyRule(
      countryCode: 'AD',
      countryName: 'Andorra',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'Low tax rates for residents',
    ),
    TaxResidencyRule(
      countryCode: 'LI',
      countryName: 'Liechtenstein',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'SM',
      countryName: 'San Marino',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'VA',
      countryName: 'Vatican City',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'Special tax arrangements',
    ),
    TaxResidencyRule(
      countryCode: 'GI',
      countryName: 'Gibraltar',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a tax year',
    ),
    TaxResidencyRule(
      countryCode: 'IM',
      countryName: 'Isle of Man',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a tax year',
    ),
    TaxResidencyRule(
      countryCode: 'JE',
      countryName: 'Jersey',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'GG',
      countryName: 'Guernsey',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'NZ',
      countryName: 'New Zealand',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In any 12-month period',
    ),
    TaxResidencyRule(
      countryCode: 'IL',
      countryName: 'Israel',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a tax year',
    ),
    TaxResidencyRule(
      countryCode: 'JO',
      countryName: 'Jordan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'LB',
      countryName: 'Lebanon',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'QA',
      countryName: 'Qatar',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'No personal income tax',
    ),
    TaxResidencyRule(
      countryCode: 'KW',
      countryName: 'Kuwait',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'No personal income tax',
    ),
    TaxResidencyRule(
      countryCode: 'BH',
      countryName: 'Bahrain',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'No personal income tax',
    ),
    TaxResidencyRule(
      countryCode: 'OM',
      countryName: 'Oman',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'No personal income tax',
    ),
    TaxResidencyRule(
      countryCode: 'SA',
      countryName: 'Saudi Arabia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'No personal income tax',
    ),
    TaxResidencyRule(
      countryCode: 'LK',
      countryName: 'Sri Lanka',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a year of assessment',
    ),
    TaxResidencyRule(
      countryCode: 'BD',
      countryName: 'Bangladesh',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In an income year',
    ),
    TaxResidencyRule(
      countryCode: 'PK',
      countryName: 'Pakistan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a tax year',
    ),
    TaxResidencyRule(
      countryCode: 'NP',
      countryName: 'Nepal',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a fiscal year',
    ),
    TaxResidencyRule(
      countryCode: 'MM',
      countryName: 'Myanmar',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a tax year',
    ),
    TaxResidencyRule(
      countryCode: 'KH',
      countryName: 'Cambodia',
      daysThreshold: 182,
      description: 'Tax resident if present for 182+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'LA',
      countryName: 'Laos',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'BN',
      countryName: 'Brunei',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'No personal income tax',
    ),
    TaxResidencyRule(
      countryCode: 'MV',
      countryName: 'Maldives',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'No personal income tax',
    ),
    TaxResidencyRule(
      countryCode: 'TW',
      countryName: 'Taiwan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'MO',
      countryName: 'Macau',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'GE',
      countryName: 'Georgia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In any consecutive 12-month period',
    ),
    TaxResidencyRule(
      countryCode: 'AM',
      countryName: 'Armenia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'AZ',
      countryName: 'Azerbaijan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'KZ',
      countryName: 'Kazakhstan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'UZ',
      countryName: 'Uzbekistan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'KG',
      countryName: 'Kyrgyzstan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'TJ',
      countryName: 'Tajikistan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'TM',
      countryName: 'Turkmenistan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'MN',
      countryName: 'Mongolia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'AF',
      countryName: 'Afghanistan',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a solar year',
    ),
    TaxResidencyRule(
      countryCode: 'IR',
      countryName: 'Iran',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'IQ',
      countryName: 'Iraq',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'SY',
      countryName: 'Syria',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'YE',
      countryName: 'Yemen',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'UY',
      countryName: 'Uruguay',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'PY',
      countryName: 'Paraguay',
      daysThreshold: 120,
      description: 'Tax resident if present for 120+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'BO',
      countryName: 'Bolivia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'PE',
      countryName: 'Peru',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'EC',
      countryName: 'Ecuador',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'CO',
      countryName: 'Colombia',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'VE',
      countryName: 'Venezuela',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'GY',
      countryName: 'Guyana',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'SR',
      countryName: 'Suriname',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'In a calendar year',
    ),
    TaxResidencyRule(
      countryCode: 'GF',
      countryName: 'French Guiana',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'French tax rules apply',
    ),
    TaxResidencyRule(
      countryCode: 'FK',
      countryName: 'Falkland Islands',
      daysThreshold: 183,
      description: 'Tax resident if present for 183+ days',
      additionalNotes: 'UK tax rules may apply',
    ),
  ];

  /// Get rule for a specific country
  static TaxResidencyRule? getRuleForCountry(String countryCode) {
    try {
      return rules.firstWhere(
        (rule) => rule.countryCode == countryCode.toUpperCase(),
      );
    } catch (e) {
      return null;
    }
  }

  /// Get all available country codes
  static List<String> getAllCountryCodes() {
    return rules.map((rule) => rule.countryCode).toList();
  }

  /// Get all available countries with names
  static Map<String, String> getAllCountries() {
    return {for (final rule in rules) rule.countryCode: rule.countryName};
  }

  /// Default threshold for unknown countries
  static const int defaultThreshold = 90;
}
