import 'package:flutter_test/flutter_test.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:trottstr/services/encryption_service.dart';

void main() {
  group('EncryptionService', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test(
      'should handle encryption gracefully when user not signed in',
      () async {
        final encryptionService = container.read(encryptionServiceProvider);

        expect(encryptionService.canEncrypt(), false);

        const testData = 'test travel data';
        final result = await encryptionService.safeEncryptData(testData);

        // Should fallback to plaintext when not signed in
        expect(result, equals(testData));
      },
    );

    test(
      'should handle decryption gracefully when user not signed in',
      () async {
        final encryptionService = container.read(encryptionServiceProvider);

        const testData = 'test travel data';
        final result = await encryptionService.safeDecryptData(testData);

        // Should return plaintext when not signed in
        expect(result, equals(testData));
      },
    );

    test('should handle empty content gracefully', () async {
      final encryptionService = container.read(encryptionServiceProvider);

      const emptyData = '';
      final encryptResult = await encryptionService.safeEncryptData(emptyData);
      final decryptResult = await encryptionService.safeDecryptData(emptyData);

      expect(encryptResult, equals(emptyData));
      expect(decryptResult, equals(emptyData));
    });
  });
}
