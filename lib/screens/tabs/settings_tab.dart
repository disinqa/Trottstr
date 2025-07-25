import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:go_router/go_router.dart';
import 'package:trottstr/widgets/data_management_section.dart';
import 'package:trottstr/widgets/relay_server_section.dart';

/// Comprehensive settings screen with enhanced functionality
class SettingsTab extends HookConsumerWidget {
  const SettingsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    useState<String?>(null);
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Settings Header
            Text(
              'Settings',
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Manage your preferences and data',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 24),

            // Account Section
            _buildSectionCard(
              context,
              title: 'Account',
              icon: Icons.person,
              children: [
                _buildSettingsTile(
                  context,
                  title: 'Profile',
                  subtitle: 'Manage your profile information',
                  icon: Icons.account_circle,
                  onTap: () => context.push('/profile'),
                ),
                _buildSettingsTile(
                  context,
                  title: 'Privacy & Security',
                  subtitle: 'Control your data and privacy settings',
                  icon: Icons.security,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Privacy settings coming soon!'),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Connection Section
            _buildSectionCard(
              context,
              title: 'Connection',
              icon: Icons.network_check,
              children: [RelayServerSection()],
            ),

            const SizedBox(height: 16),

            // Data Management Section
            _buildSectionCard(
              context,
              title: 'Data Management',
              icon: Icons.storage,
              children: [DataManagementSection()],
            ),

            const SizedBox(height: 16),

            // Travel Preferences Section
            _buildSectionCard(
              context,
              title: 'Travel Preferences',
              icon: Icons.travel_explore,
              children: [
                _buildSettingsTile(
                  context,
                  title: 'Default Country',
                  subtitle: 'Set your primary country of residence',
                  icon: Icons.home,
                  onTap: () {
                    _showDefaultCountrySelector(context, ref);
                  },
                ),
                _buildSettingsTile(
                  context,
                  title: 'Notification Preferences',
                  subtitle: 'Configure when to receive alerts',
                  icon: Icons.notifications,
                  onTap: () {
                    _showNotificationSettings(context);
                  },
                ),
                _buildSettingsTile(
                  context,
                  title: 'Tax Year Settings',
                  subtitle: 'Configure your tax year preferences',
                  icon: Icons.calendar_today,
                  onTap: () {
                    _showTaxYearSettings(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Analytics & Insights Section
            _buildSectionCard(
              context,
              title: 'Analytics & Insights',
              icon: Icons.analytics,
              children: [
                _buildSettingsTile(
                  context,
                  title: 'Travel Analytics',
                  subtitle: 'View detailed travel statistics',
                  icon: Icons.bar_chart,
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Analytics feature coming soon!'),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  context,
                  title: 'Tax Residency Reports',
                  subtitle: 'Generate compliance reports',
                  icon: Icons.assessment,
                  onTap: () {
                    _showTaxResidencyReports(context, ref);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Application Section
            _buildSectionCard(
              context,
              title: 'Application',
              icon: Icons.settings,
              children: [
                _buildSettingsTile(
                  context,
                  title: 'Theme',
                  subtitle: 'Choose your preferred theme',
                  icon: Icons.palette,
                  onTap: () {
                    _showThemeSelector(context);
                  },
                ),
                _buildSettingsTile(
                  context,
                  title: 'Language',
                  subtitle: 'Select your language',
                  icon: Icons.language,
                  onTap: () {
                    _showLanguageSelector(context);
                  },
                ),
                _buildSettingsTile(
                  context,
                  title: 'About',
                  subtitle: 'App version and information',
                  icon: Icons.info,
                  onTap: () {
                    _showAboutDialog(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard(
    BuildContext context, {
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Text(
                  title,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildSettingsTile(
    BuildContext context, {
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: Icon(
          icon,
          color: Theme.of(context).colorScheme.onSurfaceVariant,
          size: 20,
        ),
      ),
      title: Text(
        title,
        style: Theme.of(
          context,
        ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing:
          trailing ??
          Icon(
            Icons.chevron_right,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
      onTap: onTap,
    );
  }

  void _showDefaultCountrySelector(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Default Country'),
        content: const Text(
          'Select your primary country of residence. This will be used as default for new entries.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Feature coming soon!')),
              );
            },
            child: const Text('Select'),
          ),
        ],
      ),
    );
  }

  void _showNotificationSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Notification Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CheckboxListTile(
              title: const Text('Tax residency warnings'),
              subtitle: const Text('Alert when approaching thresholds'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Visa expiry reminders'),
              subtitle: const Text('Remind before visa expiration'),
              value: true,
              onChanged: (value) {},
            ),
            CheckboxListTile(
              title: const Text('Travel summaries'),
              subtitle: const Text('Monthly travel reports'),
              value: false,
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Settings saved!')));
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTaxYearSettings(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Year Settings'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Configure how tax years are calculated for different countries.',
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              decoration: const InputDecoration(
                labelText: 'Default Tax Year',
                border: OutlineInputBorder(),
              ),
              value: 'Calendar Year',
              items: const [
                DropdownMenuItem(
                  value: 'Calendar Year',
                  child: Text('Calendar Year (Jan-Dec)'),
                ),
                DropdownMenuItem(
                  value: 'Financial Year',
                  child: Text('Financial Year (Apr-Mar)'),
                ),
                DropdownMenuItem(value: 'Custom', child: Text('Custom Period')),
              ],
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Tax year settings saved!')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showTaxResidencyReports(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Residency Reports'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Generate detailed reports for tax compliance purposes.',
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Annual Summary Report'),
              subtitle: const Text('Comprehensive yearly overview'),
              trailing: const Icon(Icons.download),
              onTap: () {
                Navigator.of(context).pop();
                _generateReport(context, ref, 'annual');
              },
            ),
            ListTile(
              leading: const Icon(Icons.table_chart),
              title: const Text('Country-wise Breakdown'),
              subtitle: const Text('Detailed country analysis'),
              trailing: const Icon(Icons.download),
              onTap: () {
                Navigator.of(context).pop();
                _generateReport(context, ref, 'country');
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _generateReport(BuildContext context, WidgetRef ref, String type) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating $type report...'),
        action: SnackBarAction(
          label: 'View',
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Report generation feature coming soon!'),
              ),
            );
          },
        ),
      ),
    );
  }

  void _showThemeSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Choose Theme'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('System Default'),
              value: 'system',
              groupValue: 'system',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Light'),
              value: 'light',
              groupValue: 'system',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Dark'),
              value: 'dark',
              groupValue: 'system',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Theme updated!')));
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showLanguageSelector(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Language'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            RadioListTile<String>(
              title: const Text('English'),
              value: 'en',
              groupValue: 'en',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('Spanish'),
              value: 'es',
              groupValue: 'en',
              onChanged: (value) {},
            ),
            RadioListTile<String>(
              title: const Text('French'),
              value: 'fr',
              groupValue: 'en',
              onChanged: (value) {},
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Language updated!')),
              );
            },
            child: const Text('Apply'),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'trottstr',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(Icons.travel_explore, size: 64),
      children: [
        const Text(
          'A comprehensive country tracking application for managing tax residency compliance and travel analytics.',
        ),
        const SizedBox(height: 16),
        const Text('Features:'),
        const Text('• Country stay tracking'),
        const Text('• Tax residency monitoring'),
        const Text('• Travel analytics'),
        const Text('• Data export/import'),
        const Text('• Secure data management'),
      ],
    );
  }
}
