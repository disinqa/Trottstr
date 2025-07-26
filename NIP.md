# NIP-TROTTSTR: Country Stay Tracking for Tax Residency Compliance

`draft` `optional`

This NIP defines custom event kinds for tracking time spent in different countries to ensure tax residency compliance.

## Abstract

This NIP introduces four custom event kinds (30100-30103) to enable users to track their travel patterns, monitor tax residency thresholds, and receive warnings before exceeding tax residency limits in various countries. All events are encrypted and can be backed up across multiple relays for redundancy.

## Motivation

Digital nomads and frequent travelers need to track their time in different countries to avoid accidentally becoming tax residents. This requires:

1. **Accurate record keeping** of entry/exit dates and durations
2. **Tax rule awareness** for different countries and their thresholds
3. **Proactive warnings** before exceeding tax residency limits
4. **Secure backup** of travel data across multiple relays
5. **Future trip planning** that considers existing time spent

## Event Kinds

### Kind 30100: Country Entry Record

Records an entry into a specific country with entry/exit timestamps.

#### Tags

- `d` - Unique identifier for this entry (required)
- `country` - ISO 3166-1 alpha-2 country code (required)
- `entry_time` - Entry timestamp in milliseconds since epoch (required)
- `exit_time` - Exit timestamp in milliseconds since epoch (optional, omitted if still in country)
- `purpose` - Purpose of visit (e.g., "tourism", "business", "transit") (optional)
- `location` - Specific location details (e.g., "London Heathrow", "Berlin") (optional)
- `planned` - Set to "true" if this is a planned future entry (optional)
- `t` - Category tag set to "country-tracking" for efficient relay filtering

#### Content

Free-form notes about the entry (optional).

#### Example

```json
{
  "kind": 30100,
  "content": "Entered for business meetings with potential clients",
  "tags": [
    ["d", "2024-03-15-DE-entry"],
    ["country", "DE"],
    ["entry_time", "1710518400000"],
    ["exit_time", "1710691200000"],
    ["purpose", "business"],
    ["location", "Frankfurt Airport"],
    ["t", "country-tracking"]
  ],
  "created_at": 1710518400,
  "pubkey": "...",
  "id": "...",
  "sig": "..."
}
```

### Kind 30101: Country Tax Residency Rule

Defines tax residency rules for a specific country.

#### Tags

- `d` - Country code (ISO 3166-1 alpha-2) (required)
- `country` - Country code (ISO 3166-1 alpha-2) (required)
- `name` - Human-readable country name (required)
- `max_days` - Maximum days before becoming tax resident (default: 183)
- `rolling_period` - Period in days for calculation (default: 365)
- `warning_threshold` - Days before limit to show warning (default: 30)
- `custom` - Set to "true" if this is a user-defined rule (optional)
- `meta_*` - Additional metadata about the rule (optional)
- `t` - Category tag set to "tax-rules" for efficient relay filtering

#### Content

Detailed description of the tax residency rule and any special conditions.

#### Example

```json
{
  "kind": 30101,
  "content": "Germany: Tax residency triggered after 183 days in a calendar year, or if center of vital interests is in Germany.",
  "tags": [
    ["d", "DE"],
    ["country", "DE"],
    ["name", "Germany"],
    ["max_days", "183"],
    ["rolling_period", "365"],
    ["warning_threshold", "30"],
    ["meta_source", "German Tax Code AO §8"],
    ["t", "tax-rules"]
  ],
  "created_at": 1710518400,
  "pubkey": "...",
  "id": "...",
  "sig": "..."
}
```

### Kind 30102: Travel Warning

Generates warnings when approaching or exceeding tax residency thresholds.

#### Tags

- `d` - Unique identifier for this warning (required)
- `country` - ISO 3166-1 alpha-2 country code (required)
- `warning_type` - Type of warning: "approaching_limit", "exceeded_limit", "planned_exceedance", "rule_changed" (required)
- `days_remaining` - Days remaining before threshold (required)
- `current_days` - Current days spent in country (required)
- `max_days` - Maximum allowed days (required)
- `severity` - Warning severity: "low", "medium", "high", "critical" (optional, default: "medium")
- `acknowledged` - Set to "true" if user has acknowledged the warning (optional)
- `t` - Category tag set to "travel-warnings" for efficient relay filtering

#### Content

Human-readable warning message with specific details.

#### Example

```json
{
  "kind": 30102,
  "content": "Warning: You have spent 150 days in Germany this year. You have 33 days remaining before reaching the 183-day tax residency threshold.",
  "tags": [
    ["d", "2024-warning-DE-approaching"],
    ["country", "DE"],
    ["warning_type", "approaching_limit"],
    ["days_remaining", "33"],
    ["current_days", "150"],
    ["max_days", "183"],
    ["severity", "high"],
    ["t", "travel-warnings"]
  ],
  "created_at": 1710518400,
  "pubkey": "...",
  "id": "...",
  "sig": "..."
}
```

### Kind 30103: Backup Configuration

Stores encrypted backup configuration for multi-relay data redundancy.

#### Tags

- `d` - Unique identifier for this configuration (required)
- `name` - Configuration name (required)
- `backup_relays` - Comma-separated list of backup relay URLs (required)
- `frequency` - Backup frequency: "manual", "hourly", "daily", "weekly", "monthly" (optional, default: "daily")
- `enabled` - Set to "false" to disable backup (optional, default: enabled)
- `last_backup` - Timestamp of last successful backup in milliseconds (optional)
- `encryption` - Encryption type: "nip44", "nip04", "custom" (optional, default: "nip44")
- `t` - Category tag set to "backup-config" for efficient relay filtering

#### Content

JSON configuration details for backup settings (encrypted).

#### Example

```json
{
  "kind": 30103,
  "content": "{\"compress\": true, \"verification\": true, \"retention_days\": 365}",
  "tags": [
    ["d", "primary-backup"],
    ["name", "Primary Backup Configuration"],
    ["backup_relays", "wss://relay1.example.com,wss://relay2.example.com,wss://relay3.example.com"],
    ["frequency", "daily"],
    ["encryption", "nip44"],
    ["last_backup", "1710518400000"],
    ["t", "backup-config"]
  ],
  "created_at": 1710518400,
  "pubkey": "...",
  "id": "...",
  "sig": "..."
}
```

## Security Considerations

### Encryption

All events contain sensitive travel and tax information and SHOULD be encrypted using NIP-44 encryption before publishing to relays. The events can optionally include an additional encryption layer with a user-defined passphrase for enhanced security.

### Privacy

- Events SHOULD be published to relays that the user trusts with their travel data
- Consider using multiple backup relays in different jurisdictions for redundancy
- The `alt` tag SHOULD be included for NIP-31 compliance with a generic description

### Data Integrity

- Critical events (country entries, tax rules) SHOULD be backed up to multiple relays
- Implement verification mechanisms to ensure backup integrity
- Consider using relay-specific signatures for tamper detection

## Implementation Notes

### Tax Year Calculations

Implementations SHOULD support both calendar year and tax year calculations, as different countries may have different tax year periods (e.g., UK tax year runs April 6 to April 5).

### Time Zone Handling

Entry and exit times SHOULD be stored in UTC to avoid time zone confusion. User interfaces MAY display times in local time zones for user convenience.

### Country Code Validation

Implementations SHOULD validate country codes against the ISO 3166-1 alpha-2 standard and provide fallback handling for invalid or deprecated codes.

### Rule Updates

Tax rules can change over time. Implementations SHOULD version control rule changes and notify users when rules affecting their travel plans are updated.

## Example Use Cases

1. **Digital Nomad Tracking**: A digital nomad can record entries/exits as they travel, receive warnings before becoming tax resident anywhere, and plan future trips accordingly.

2. **Business Traveler Compliance**: A consultant can track business trips across multiple countries and ensure they don't accidentally trigger tax residency in client countries.

3. **Backup and Recovery**: Users can backup their travel data across multiple relays and recover their complete travel history from any of them.

4. **Future Trip Planning**: Users can plan future trips and see warnings if those trips would cause them to exceed tax residency thresholds.

## Client Implementation Recommendations

### User Interface

- Provide a simple country entry/exit interface with date/time pickers
- Display visual warnings with clear risk levels (low, medium, high, critical)
- Show country-specific tax residency status with days remaining
- Include a calendar view showing travel history and planned trips

### Automation

- Support automatic backup scheduling across multiple relays
- Implement smart warnings that consider planned future travel
- Provide export functionality for tax compliance documentation

### Data Validation

- Validate that exit times are after entry times
- Warn users about overlapping entries (being in two countries simultaneously)
- Implement data consistency checks across backup relays

## Backward Compatibility

These event kinds are new and do not conflict with existing NIPs. Clients that don't support these kinds will simply ignore them.

## Reference Implementation

A reference implementation of this NIP is available in the Trottstr application, which demonstrates all event kinds and provides a complete country stay tracking solution with multi-relay encrypted backup.

## Authors

This NIP was developed as part of the Trottstr (Country Stay Tracker) application for tax residency compliance.

## Copyright

This NIP is released under the Creative Commons Attribution 4.0 International License.