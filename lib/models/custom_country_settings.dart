/// Model for custom country time limit settings
class CustomCountrySettings {
  final String countryCode;
  final String countryName;
  final int customDaysThreshold;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? notes;

  const CustomCountrySettings({
    required this.countryCode,
    required this.countryName,
    required this.customDaysThreshold,
    required this.createdAt,
    this.updatedAt,
    this.notes,
  });

  /// Convert to JSON for storage
  Map<String, dynamic> toJson() => {
        'countryCode': countryCode,
        'countryName': countryName,
        'customDaysThreshold': customDaysThreshold,
        'createdAt': createdAt.toIso8601String(),
        if (updatedAt != null) 'updatedAt': updatedAt!.toIso8601String(),
        if (notes != null) 'notes': notes,
      };

  /// Create from JSON
  factory CustomCountrySettings.fromJson(Map<String, dynamic> json) =>
      CustomCountrySettings(
        countryCode: json['countryCode'],
        countryName: json['countryName'],
        customDaysThreshold: json['customDaysThreshold'],
        createdAt: DateTime.parse(json['createdAt']),
        updatedAt: json['updatedAt'] != null 
            ? DateTime.parse(json['updatedAt']) 
            : null,
        notes: json['notes'],
      );

  /// Create a copy with updated values
  CustomCountrySettings copyWith({
    String? countryCode,
    String? countryName,
    int? customDaysThreshold,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? notes,
  }) =>
      CustomCountrySettings(
        countryCode: countryCode ?? this.countryCode,
        countryName: countryName ?? this.countryName,
        customDaysThreshold: customDaysThreshold ?? this.customDaysThreshold,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        notes: notes ?? this.notes,
      );

  @override
  String toString() => '$countryName: $customDaysThreshold days (custom)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CustomCountrySettings &&
          runtimeType == other.runtimeType &&
          countryCode == other.countryCode;

  @override
  int get hashCode => countryCode.hashCode;
}

/// Result enum for custom country settings operations
enum CustomCountrySettingsResult {
  success,
  notFound,
  error,
}

/// Extension to get user-friendly messages for results
extension CustomCountrySettingsResultExtension on CustomCountrySettingsResult {
  String get message {
    switch (this) {
      case CustomCountrySettingsResult.success:
        return 'Settings updated successfully';
      case CustomCountrySettingsResult.notFound:
        return 'Country settings not found';
      case CustomCountrySettingsResult.error:
        return 'An error occurred while updating settings';
    }
  }

  bool get isSuccess => this == CustomCountrySettingsResult.success;
}