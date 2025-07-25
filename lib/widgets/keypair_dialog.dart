import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:trottstr/utils/key_generator.dart';

class KeypairDialog extends StatelessWidget {
  final KeyPair keyPair;
  final VoidCallback onSecuredAndContinue;

  const KeypairDialog({
    super.key,
    required this.keyPair,
    required this.onSecuredAndContinue,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          Icon(Icons.key, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('Keypair'),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Warning message
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Save these keys safely! You cannot recover them if lost.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action buttons
            OutlinedButton.icon(
              onPressed: () => _copyKeys(context),
              icon: const Icon(Icons.copy, size: 18),
              label: const Text('Copy'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _downloadKeys(context),
              icon: const Icon(Icons.download, size: 18),
              label: const Text('Download'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            Navigator.of(context).pop();
            onSecuredAndContinue();
          },
          child: const Text('Secured Keys, Continue'),
        ),
      ],
    );
  }

  void _copyKeys(BuildContext context) {
    final keysText = keyPair.nsec;

    Clipboard.setData(ClipboardData(text: keysText));

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Keys copied to clipboard'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Future<void> _downloadKeys(BuildContext context) async {
    try {
      // Request storage permission
      final permission = await Permission.storage.request();
      if (!permission.isGranted) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Storage permission is required to download keys'),
            ),
          );
        }
        return;
      }

      // Create the keys content
      final keysContent =
          'trottstr KEYPAIR\n'
          'Generated: ${DateTime.now().toIso8601String()}\n\n'
          'Private Key (nsec):\n${keyPair.nsec}\n\n'
          'Public Key (npub):\n${keyPair.npub}\n\n'
          'WARNING: Keep your private key secret and secure!\n'
          'Never share your private key with anyone.\n'
          'Your public key can be shared freely.';

      // Get the downloads directory
      Directory? directory;
      if (Platform.isAndroid) {
        directory = Directory('/storage/emulated/0/Download');
        if (!await directory.exists()) {
          directory = await getExternalStorageDirectory();
        }
      } else {
        directory = await getApplicationDocumentsDirectory();
      }

      if (directory == null) {
        throw Exception('Could not access storage directory');
      }

      // Create the file
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = 'trottstr_keypair_$timestamp.txt';
      final file = File('${directory.path}/$fileName');

      await file.writeAsString(keysContent);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Keys saved to: ${file.path}'),
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to download keys: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    }
  }
}
