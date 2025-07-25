import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:async_button_builder/async_button_builder.dart';
import 'package:go_router/go_router.dart';
import 'package:trottstr/providers/auth_providers.dart';
import 'package:trottstr/utils/key_generator.dart';
import 'package:trottstr/widgets/keypair_dialog.dart';

class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tabController = useTabController(initialLength: 3);
    final nsecController = useTextEditingController();
    final isNsecValid = useState(false);
    final generatedKeyPair = useState<KeyPair?>(null);
    final isNsecVisible = useState(false);

    // Watch authentication state
    ref.watch(userProfileProvider);
    ref.watch(Signer.activePubkeyProvider);

    // Validate nsec as user types
    useEffect(() {
      void validateNsec() {
        final text = nsecController.text.trim();
        if (text.isEmpty) {
          isNsecValid.value = false;
          return;
        }

        try {
          // Use real bech32 decoding to validate the nsec
          text.decodeShareable();
          isNsecValid.value = text.startsWith('nsec1') && text.length > 50;
        } catch (e) {
          isNsecValid.value = false;
        }
      }

      nsecController.addListener(validateNsec);
      return () => nsecController.removeListener(validateNsec);
    }, [nsecController]);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sign In'),
        bottom: TabBar(
          controller: tabController,
          tabs: const [
            Tab(icon: Icon(Icons.key), text: 'Private Key'),
            Tab(icon: Icon(Icons.security), text: 'Amber Signer'),
            Tab(icon: Icon(Icons.qr_code), text: 'QR Code'),
          ],
        ),
      ),
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: TabBarView(
          controller: tabController,
          children: [
            // Private Key Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Sign in with Private Key',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Enter your existing nsec private key to sign in, or generate a new keypair to create an account',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Private key input
                    TextField(
                      controller: nsecController,
                      obscureText: !isNsecVisible.value,
                      decoration: InputDecoration(
                        labelText: 'Private Key (nsec...)',
                        hintText: 'Enter your existing nsec private key',
                        border: const OutlineInputBorder(),
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (isNsecValid.value)
                              Icon(
                                Icons.check,
                                color: Theme.of(context).colorScheme.primary,
                              ),
                            IconButton(
                              icon: Icon(
                                isNsecVisible.value
                                    ? Icons.visibility_off
                                    : Icons.visibility,
                              ),
                              onPressed: () {
                                isNsecVisible.value = !isNsecVisible.value;
                              },
                            ),
                          ],
                        ),
                      ),
                      maxLines: 1,
                      onChanged: (value) {
                        if (generatedKeyPair.value != null &&
                            value != generatedKeyPair.value!.nsec) {
                          generatedKeyPair.value = null;
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Generate new key button
                    OutlinedButton.icon(
                      onPressed: () {
                        // Generate real keypair and immediately show popup
                        final keyPair = KeyGenerator.generateKeyPair();
                        generatedKeyPair.value = keyPair;

                        // Show the keypair dialog immediately
                        showDialog(
                          context: context,
                          builder: (context) => KeypairDialog(
                            keyPair: keyPair,
                            onSecuredAndContinue: () async {
                              // Sign in with the generated keypair
                              await ref
                                  .read(authServiceProvider)
                                  .signInWithNsec(keyPair.nsec);

                              // Navigate to home after successful sign-in
                              if (context.mounted) {
                                context.go('/home');
                              }
                            },
                          ),
                        );
                      },
                      icon: const Icon(Icons.auto_awesome),
                      label: const Text('Generate New Keypair'),
                    ),
                    const SizedBox(height: 24),

                    // Sign in button
                    AsyncButtonBuilder(
                      onPressed: isNsecValid.value
                          ? () async {
                              await ref
                                  .read(authServiceProvider)
                                  .signInWithNsec(nsecController.text.trim());

                              // Navigate to home after successful sign-in
                              if (context.mounted) {
                                context.go('/home');
                              }
                            }
                          : null,
                      builder: (context, child, callback, buttonState) {
                        return FilledButton(
                          onPressed: buttonState.maybeWhen(
                            loading: () => null,
                            orElse: () => callback,
                          ),
                          child: buttonState.maybeWhen(
                            loading: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            orElse: () => child,
                          ),
                        );
                      },
                      onError: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Failed to sign in with private key'),
                          ),
                        );
                      },
                      child: const Text('Sign In'),
                    ),
                  ],
                ),
              ),
            ),

            // Amber Signer Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Sign in with Amber',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Use the Amber app to securely sign in without exposing your private key',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          children: [
                            Icon(
                              Icons.security,
                              size: 48,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Secure Signing',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Amber keeps your private keys secure on your device and signs events without exposing them.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    AsyncButtonBuilder(
                      child: const Text('Sign in with Amber'),
                      onPressed: () async {
                        await ref.read(authServiceProvider).signInWithAmber();

                        // Navigate to home after successful sign-in
                        if (context.mounted) {
                          context.go('/home');
                        }
                      },
                      builder: (context, child, callback, buttonState) {
                        return FilledButton.icon(
                          onPressed: buttonState.maybeWhen(
                            loading: () => null,
                            orElse: () => callback,
                          ),
                          icon: buttonState.maybeWhen(
                            loading: () => const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            orElse: () => const Icon(Icons.security),
                          ),
                          label: child,
                        );
                      },
                      onError: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Failed to sign in with Amber. Make sure the app is installed.',
                            ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),

                    TextButton(
                      onPressed: () {
                        // TODO: Show instructions for installing Amber
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text('Install Amber'),
                            content: const Text(
                              'Amber is a Nostr signing app that keeps your private keys secure.\n\n'
                              'Download it from the Google Play Store or F-Droid.',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('OK'),
                              ),
                            ],
                          ),
                        );
                      },
                      child: const Text('Don\'t have Amber? Learn more'),
                    ),
                  ],
                ),
              ),
            ),

            // QR Code Tab
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    Text(
                      'Scan QR Code',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Scan a QR code containing your nsec private key',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 24),

                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.qr_code_scanner,
                              size: 64,
                              color: Theme.of(context).colorScheme.primary,
                            ),
                            const SizedBox(height: 24),
                            Text(
                              'QR Code Scanner',
                              style: Theme.of(context).textTheme.titleLarge,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Tap the button below to open the camera and scan a QR code containing your nsec.',
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 24),

                            FilledButton.icon(
                              onPressed: () {
                                // TODO: Implement QR scanner
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('QR Scanner coming soon!'),
                                  ),
                                );
                              },
                              icon: const Icon(Icons.camera_alt),
                              label: const Text('Open Camera'),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Card(
                      color: Theme.of(context).colorScheme.errorContainer,
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Row(
                          children: [
                            Icon(
                              Icons.warning,
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Never share QR codes containing your private key with anyone!',
                                style: Theme.of(context).textTheme.bodySmall
                                    ?.copyWith(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onErrorContainer,
                                    ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
