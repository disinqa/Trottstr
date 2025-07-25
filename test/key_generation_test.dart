import 'package:flutter_test/flutter_test.dart';
import 'package:trottstr/utils/key_generator.dart';

void main() {
  group('KeyGenerator', () {
    test('should generate valid keypairs', () {
      final keyPair = KeyGenerator.generateKeyPair();

      // Check that keys are generated
      expect(keyPair.privateKeyHex, isNotEmpty);
      expect(keyPair.publicKeyHex, isNotEmpty);
      expect(keyPair.nsec, isNotEmpty);
      expect(keyPair.npub, isNotEmpty);

      // Check proper format
      expect(
        keyPair.privateKeyHex.length,
        equals(64),
      ); // 32 bytes = 64 hex chars
      expect(
        keyPair.publicKeyHex.length,
        equals(64),
      ); // 32 bytes = 64 hex chars
      expect(keyPair.nsec.startsWith('nsec1'), isTrue);
      expect(keyPair.npub.startsWith('npub1'), isTrue);

      // Check that keys are different from each other
      expect(keyPair.privateKeyHex, isNot(equals(keyPair.publicKeyHex)));
      expect(keyPair.nsec, isNot(equals(keyPair.npub)));

      // Keys generated successfully - no need to print in production
    });

    test('should generate different keys on each call', () {
      final keyPair1 = KeyGenerator.generateKeyPair();
      final keyPair2 = KeyGenerator.generateKeyPair();

      expect(keyPair1.privateKeyHex, isNot(equals(keyPair2.privateKeyHex)));
      expect(keyPair1.publicKeyHex, isNot(equals(keyPair2.publicKeyHex)));
      expect(keyPair1.nsec, isNot(equals(keyPair2.nsec)));
      expect(keyPair1.npub, isNot(equals(keyPair2.npub)));
    });
  });
}
