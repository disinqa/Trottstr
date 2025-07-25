import 'package:models/models.dart';

class KeyGenerator {
  /// Generates a new Nostr keypair with nsec and npub using real cryptography
  static KeyPair generateKeyPair() {
    // Generate a cryptographically secure private key using models package
    final privateKeyHex = Utils.generateRandomHex64();
    
    // Derive the corresponding public key using secp256k1 cryptography
    final publicKeyHex = Utils.derivePublicKey(privateKeyHex);
    
    // Encode to proper bech32 format using models package
    final nsec = privateKeyHex.encodeShareable(type: 'nsec');
    final npub = publicKeyHex.encodeShareable(type: 'npub');
    
    return KeyPair(
      privateKeyHex: privateKeyHex,
      publicKeyHex: publicKeyHex,
      nsec: nsec,
      npub: npub,
    );
  }
}

class KeyPair {
  final String privateKeyHex;
  final String publicKeyHex;
  final String nsec;
  final String npub;
  
  const KeyPair({
    required this.privateKeyHex,
    required this.publicKeyHex,
    required this.nsec,
    required this.npub,
  });
}