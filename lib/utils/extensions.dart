import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';

extension ContextExt on WidgetRef {
  StorageNotifier get storage => read(storageNotifierProvider.notifier);
}

extension StringExt on String {
  /// Format npub for visual display with spaces
  /// Example: npub1abc123... becomes "npub1 abc12 3def4 56789 ..."
  String formatNpub() {
    if (!startsWith('npub1')) return this;
    
    if (length <= 10) return this;
    
    // Take first 5 chars (npub1), then add spaces every 5 characters
    final prefix = substring(0, 5); // "npub1"
    final remaining = substring(5);
    
    final chunks = <String>[];
    for (int i = 0; i < remaining.length; i += 5) {
      final end = (i + 5 < remaining.length) ? i + 5 : remaining.length;
      chunks.add(remaining.substring(i, end));
    }
    
    return '$prefix ${chunks.join(' ')}';
  }
}
