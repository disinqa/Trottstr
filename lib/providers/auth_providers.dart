import 'package:amber_signer/amber_signer.dart';
import 'package:flutter/foundation.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:models/models.dart';
import 'package:trottstr/services/auth_persistence_service.dart';

/// Provider for Amber signer instance
final amberSignerProvider = Provider<AmberSigner>((ref) => AmberSigner(ref));

/// Provider for private key signer (when using nsec)
final privateKeySignerProvider = StateProvider<Bip340PrivateKeySigner?>(
  (ref) => null,
);

/// Provider for storing the original nsec string
final nsecProvider = StateProvider<String?>((ref) => null);

/// Authentication service provider
final authServiceProvider = Provider<AuthService>((ref) => AuthService(ref));

/// Authentication service class that handles sign in/out operations
class AuthService {
  final Ref _ref;

  AuthService(this._ref);

  /// Sign in with Amber signer
  Future<void> signInWithAmber() async {
    try {
      final amberSigner = _ref.read(amberSignerProvider);
      await amberSigner.signIn();

      // Clear any existing private key signer
      _ref.read(privateKeySignerProvider.notifier).state = null;

      // Save auth method for persistence
      await AuthPersistenceService.saveAuthMethod(
        AuthPersistenceService.authMethodAmber,
      );

      debugPrint('Successfully signed in with Amber');
    } catch (e) {
      debugPrint('Failed to sign in with Amber: $e');
      rethrow;
    }
  }

  /// Sign in with private key (nsec)
  Future<void> signInWithNsec(String nsec) async {
    try {
      // Validate nsec format
      if (!nsec.startsWith('nsec1') || nsec.length < 50) {
        throw Exception('Invalid private key format');
      }

      // Decode and validate the nsec using real bech32 decoding
      String privateKeyHex;
      try {
        privateKeyHex = nsec.decodeShareable();
      } catch (e) {
        throw Exception('Invalid nsec format: $e');
      }

      // Create a real Bip340PrivateKeySigner instance
      final signer = Bip340PrivateKeySigner(privateKeyHex, _ref);
      await signer.signIn();

      // Store the signer and original nsec, clear amber signer
      _ref.read(privateKeySignerProvider.notifier).state = signer;
      _ref.read(nsecProvider.notifier).state = nsec;
      await _ref.read(amberSignerProvider).signOut();

      // Save auth method and nsec for persistence
      await AuthPersistenceService.saveAuthMethod(
        AuthPersistenceService.authMethodNsec,
      );
      await AuthPersistenceService.saveNsec(nsec);

      debugPrint('Successfully signed in with private key');
    } catch (e) {
      debugPrint('Failed to sign in with private key: $e');
      rethrow;
    }
  }

  /// Sign out from current signer
  Future<void> signOut() async {
    try {
      // Sign out from amber
      await _ref.read(amberSignerProvider).signOut();

      // Sign out from private key signer if it exists
      final privateKeySigner = _ref.read(privateKeySignerProvider);
      if (privateKeySigner != null) {
        await privateKeySigner.signOut();
        _ref.read(privateKeySignerProvider.notifier).state = null;
        _ref.read(nsecProvider.notifier).state = null;
      }

      // Clear persisted auth state
      await AuthPersistenceService.clearAuthState();

      debugPrint('Successfully signed out');
    } catch (e) {
      debugPrint('Failed to sign out: $e');
      rethrow;
    }
  }

  /// Attempt auto sign-in (for app startup)
  Future<void> attemptAutoSignIn() async {
    try {
      // Check if there's a saved auth method
      final savedAuthMethod = await AuthPersistenceService.getAuthMethod();

      if (savedAuthMethod == null) {
        debugPrint('No saved auth method found');
        return;
      }

      switch (savedAuthMethod) {
        case AuthPersistenceService.authMethodAmber:
          // Try amber auto sign-in
          await _ref.read(amberSignerProvider).attemptAutoSignIn();
          debugPrint('Auto sign-in with Amber successful');
          break;

        case AuthPersistenceService.authMethodNsec:
          // Try nsec auto sign-in
          final savedNsec = await AuthPersistenceService.getNsec();
          if (savedNsec != null) {
            await signInWithNsec(savedNsec);
            debugPrint('Auto sign-in with nsec successful');
          } else {
            debugPrint('No saved nsec found, clearing invalid auth state');
            await AuthPersistenceService.clearAuthState();
          }
          break;

        default:
          debugPrint('Unknown auth method: $savedAuthMethod');
          await AuthPersistenceService.clearAuthState();
      }
    } catch (e) {
      debugPrint('Auto sign-in failed: $e');
      // If auto sign-in fails, clear the potentially corrupted auth state
      try {
        await AuthPersistenceService.clearAuthState();
        debugPrint('Cleared potentially corrupted auth state');
      } catch (clearError) {
        debugPrint('Failed to clear auth state: $clearError');
      }
    }
  }
}

/// Enhanced profile provider that handles null profiles gracefully
final userProfileProvider = Provider<Profile?>((ref) {
  final pubkey = ref.watch(Signer.activePubkeyProvider);
  if (pubkey == null) return null;

  final remoteProfile = ref.watch(
    Signer.activeProfileProvider(RemoteSource(group: 'default')),
  );

  // Return the remote profile (which might be null for new users)
  return remoteProfile;
});
