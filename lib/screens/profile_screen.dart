import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:trottstr/providers/auth_providers.dart';
import 'package:trottstr/widgets/common/profile_avatar.dart';
import 'package:trottstr/utils/extensions.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _showNsec = false;

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider);
    final pubkey = ref.watch(Signer.activePubkeyProvider);
    final privateKeySigner = ref.watch(privateKeySignerProvider);
    final nsec = ref.watch(nsecProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                context.go('/auth');
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  ProfileAvatar(profile: profile, radius: 50),
                  const SizedBox(height: 16),
                  Text(
                    profile?.nameOrNpub ?? 'Unknown User',
                    style: Theme.of(context).textTheme.headlineSmall,
                    textAlign: TextAlign.center,
                  ),
                  if (profile?.about != null && profile!.about!.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      profile.about!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 32),

            // User Metadata Section
            Text(
              'Profile Information',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // npub (Public Key)
            _buildInfoCard(
              context,
              title: 'Public Key (npub)',
              value:
                  pubkey?.encodeShareable(type: 'npub').formatNpub() ??
                  'Not available',
              copyable: true,
              monospace: true,
            ),

            const SizedBox(height: 12),

            // nsec (Private Key) - only if using private key signer
            if (privateKeySigner != null && nsec != null)
              _buildPrivateKeyCard(context, nsec: nsec),

            const SizedBox(height: 12),

            // Profile metadata
            if (profile?.website != null && profile!.website!.isNotEmpty)
              _buildInfoCard(
                context,
                title: 'Website',
                value: profile.website!,
                copyable: true,
              ),

            if (profile?.nip05 != null && profile!.nip05!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                title: 'NIP-05 Identifier',
                value: profile.nip05!,
                copyable: true,
              ),
            ],

            if (profile?.lud16 != null && profile!.lud16!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoCard(
                context,
                title: 'Lightning Address',
                value: profile.lud16!,
                copyable: true,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateKeyCard(BuildContext context, {required String nsec}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Private Key (nsec)',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_showNsec)
                      IconButton(
                        icon: Icon(
                          Icons.copy,
                          size: 20,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                        onPressed: () => _copyToClipboard(context, nsec),
                        tooltip: 'Copy private key',
                      ),
                    IconButton(
                      icon: Icon(
                        _showNsec ? Icons.visibility_off : Icons.visibility,
                        size: 20,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      onPressed: () {
                        setState(() {
                          _showNsec = !_showNsec;
                        });
                      },
                      tooltip: _showNsec
                          ? 'Hide private key'
                          : 'Show private key',
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              _showNsec ? nsec : '•' * 60,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontFamily: 'monospace',
                fontSize: 13,
              ),
            ),
            if (!_showNsec) ...[
              const SizedBox(height: 8),
              Text(
                'Tap the eye icon to reveal',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            if (_showNsec) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning,
                      size: 16,
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Keep this private! Never share with anyone.',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context, {
    required String title,
    required String value,
    bool copyable = false,
    bool monospace = false,
    bool sensitive = false,
    VoidCallback? onTap,
  }) {
    return Card(
      child: InkWell(
        onTap:
            onTap ?? (copyable ? () => _copyToClipboard(context, value) : null),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (sensitive)
                    Icon(
                      _showNsec ? Icons.visibility_off : Icons.visibility,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )
                  else if (copyable)
                    Icon(
                      Icons.copy,
                      size: 20,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontFamily: monospace ? 'monospace' : null,
                  fontSize: monospace ? 13 : null,
                ),
              ),
              if (sensitive && !_showNsec) ...[
                const SizedBox(height: 8),
                Text(
                  'Tap to reveal',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  void _copyToClipboard(BuildContext context, String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }
}
