import 'dart:io';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:crypto/crypto.dart';
import 'package:get/get.dart';
import 'package:macroaize/shared/services/revenuecat_service.dart';

import '../../../shared/services/email_verification_guard.dart';
import '../../../shared/services/firebase_messaging_service.dart';
import '../domain/auth_failure.dart';
import '../domain/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuth _auth;
  final GoogleSignIn _google;

  FirebaseAuthRepository({FirebaseAuth? auth, GoogleSignIn? google})
    : _auth = auth ?? FirebaseAuth.instance,
      _google = google ?? GoogleSignIn(
        scopes: ['email'],

        clientId: Platform.isIOS
            ? '582471032450-ek1mh77ula8jd013uv0t5f3oeksvberc.apps.googleusercontent.com'
            : null,
      );

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<(User?, AuthFailure?)> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final cred = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return (cred.user, null);
    } on FirebaseAuthException catch (e) {
      return (null, CredentialFailure(e.code, e.message ?? ''));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(User?, AuthFailure?)> registerWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      final cred = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      await cred.user?.updateDisplayName('$firstName $lastName');
      if (cred.user != null) {
        await cred.user!.sendEmailVerification();
      }

      return (cred.user, null);
    } on FirebaseAuthException catch (e) {
      return (null, CredentialFailure(e.code, e.message ?? ''));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<AuthFailure?> sendPasswordReset({required String email}) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return null;
    } on FirebaseAuthException catch (e) {
      return CredentialFailure(e.code, e.message ?? '');
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  @override
  Future<(User?, AuthFailure?)> signInWithGoogle() async {
    try {
      final account = await _google.signIn();
      if (account == null) {
        return (null, CredentialFailure('canceled', 'Canceled'));
      }
      final auth = await account.authentication;
      final oauthCred = GoogleAuthProvider.credential(
        idToken: auth.idToken,
        accessToken: auth.accessToken,
      );
      final res = await _auth.signInWithCredential(oauthCred);
      final user = res.user;
  // ensure displayName is set
      if (user != null &&
          (user.displayName == null || user.displayName!.trim().isEmpty)) {
        final g = await _google.signInSilently();
        final given = g?.displayName;
        if (given != null && given.trim().isNotEmpty) {
          await user.updateDisplayName(given.trim());
        }
      }
      return (user, null);
    } on FirebaseAuthException catch (e) {
      return (null, CredentialFailure(e.code, e.message ?? ''));
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(User?, AuthFailure?)> signInWithApple() async {
    try {
      if (!Platform.isIOS) {
        return (
          null,
          CredentialFailure(
            'unsupported-platform',
            'Apple Sign-In is only available on iOS',
          ),
        );
      }

  // create a secure random nonce and its SHA256 hash
      final rawNonce = _generateNonce(32);
      final hashedNonce = _sha256ofString(rawNonce);

  // request email/fullName scopes on first sign-in
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );

      final idToken = credential.identityToken;
      if (idToken == null) {
        return (
          null,
          const CredentialFailure(
            'apple-no-token',
            'Apple did not return an identity token. Please try again.',
          ),
        );
      }

      // create OAuth credential for Firebase including the raw nonce
      // The authorizationCode must be passed as accessToken for Firebase
      // to validate the Apple credential correctly on iOS.
      final oauth = OAuthProvider('apple.com').credential(
        idToken: idToken,
        rawNonce: rawNonce,
        accessToken: credential.authorizationCode,
      );

  // sign-in with Firebase
      final res = await _auth.signInWithCredential(oauth);
      final user = res.user;

  // update display name if provided
      final fullName =
          [
            credential.givenName,
            credential.familyName,
          ].where((e) => (e ?? '').trim().isNotEmpty).join(' ').trim();
      if (user != null &&
          fullName.isNotEmpty &&
          (user.displayName == null || user.displayName!.isEmpty)) {
        await user.updateDisplayName(fullName);
      }

      return (user, null);
    } on SignInWithAppleAuthorizationException catch (e) {
      // map Apple errors to auth failures
      final code = switch (e.code) {
        AuthorizationErrorCode.canceled => 'canceled',
        AuthorizationErrorCode.failed => 'failed',
        AuthorizationErrorCode.invalidResponse => 'invalid-response',
        AuthorizationErrorCode.notHandled => 'not-handled',
        AuthorizationErrorCode.notInteractive => 'not-interactive',
        _ => 'unknown',
      };
      if (kDebugMode) {
        print('[AppleSignIn] AuthorizationException – code: $code, '
            'message: ${e.message}');
      }
      return (null, CredentialFailure(code, e.message));
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[AppleSignIn] FirebaseAuthException – code: ${e.code}, '
            'message: ${e.message}');
      }
      return (null, CredentialFailure(e.code, e.message ?? ''));
    } catch (e, st) {
      if (kDebugMode) {
        print('[AppleSignIn] Unknown error (${e.runtimeType}): $e');
        print('[AppleSignIn] Stack trace: $st');
      }
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<void> signOut() async {
  // get current user ID before signing out
    final currentUserId = _auth.currentUser?.uid;

  // reset email verification skip flag for this user on logout
    final guard = EmailVerificationGuard();
    await guard.resetSkipFlag(currentUserId);

    // remove FCM token from Firestore before signing out
    try {
      if (Get.isRegistered<FirebaseMessagingService>()) {
        final fcmService = Get.find<FirebaseMessagingService>();
        await fcmService.removeTokenFromFirestore();
      }
    } catch (_) {
      // Continue if FCM service fails - don't block logout
    }

    try {
      await _google.signOut();
    } catch (_) {}

    // detach RevenueCat app user to avoid entitlement transfer on next login
    try {
      await RevenueCatService().logOut();
    } catch (_) {}

    await _auth.signOut();
  }

  // Secure nonce helpers
  String _generateNonce([int length = 32]) {
    const charset =
        '0123456789ABCDEFGHIJKLMNOPQRSTUVXYZabcdefghijklmnopqrstuvwxyz-._';
    final random = Random.secure();
    final values = List<int>.generate(
      length,
      (_) => random.nextInt(charset.length),
    );
    return values.map((i) => charset[i]).join();
  }

  String _sha256ofString(String input) {
    final bytes = utf8.encode(input);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  @override
  Future<AuthFailure?> linkWithApple() async {
    try {
      if (!Platform.isIOS) {
        return CredentialFailure(
          'unsupported-platform',
          'Apple Sign-In is only available on iOS',
        );
      }

      final user = _auth.currentUser;
      if (user == null) {
        return CredentialFailure(
          'not-authenticated',
          'No current user to link',
        );
      }

      final rawNonce = _generateNonce(32);
      final hashedNonce = _sha256ofString(rawNonce);
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
        nonce: hashedNonce,
      );
      final linkIdToken = credential.identityToken;
      if (linkIdToken == null) {
        return const CredentialFailure(
          'apple-no-token',
          'Apple did not return an identity token. Please try again.',
        );
      }
      final oauth = OAuthProvider(
        'apple.com',
      ).credential(
        idToken: linkIdToken,
        rawNonce: rawNonce,
        accessToken: credential.authorizationCode,
      );
      await user.linkWithCredential(oauth);
      return null;
    } on FirebaseAuthException catch (e) {
      if (kDebugMode) {
        print('[AppleLink] FirebaseAuthException – code: ${e.code}, '
            'message: ${e.message}');
      }
      return CredentialFailure(e.code, e.message ?? '');
    } on SignInWithAppleAuthorizationException catch (e) {
      final code = switch (e.code) {
        AuthorizationErrorCode.canceled => 'canceled',
        AuthorizationErrorCode.failed => 'failed',
        AuthorizationErrorCode.invalidResponse => 'invalid-response',
        AuthorizationErrorCode.notHandled => 'not-handled',
        AuthorizationErrorCode.notInteractive => 'not-interactive',
        _ => 'unknown',
      };
      if (kDebugMode) {
        print('[AppleLink] AuthorizationException – code: $code, '
            'message: ${e.message}');
      }
      return CredentialFailure(code, e.message);
    } catch (e, st) {
      if (kDebugMode) {
        print('[AppleLink] Unknown error (${e.runtimeType}): $e');
        print('[AppleLink] Stack trace: $st');
      }
      return UnknownFailure(e.toString());
    }
  }

  @override
  Future<AuthFailure?> updateDisplayName(String name) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return CredentialFailure('not-authenticated', 'Not authenticated');
      }
      await user.updateDisplayName(name);
      await user.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return CredentialFailure(e.code, e.message ?? '');
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  @override
  Future<AuthFailure?> reauthenticateWithPassword(String password) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return CredentialFailure('not-authenticated', 'Not authenticated');
      }
      final email = user.email;
      if (email == null) {
        return CredentialFailure('no-email', 'No email available');
      }
      final cred = EmailAuthProvider.credential(
        email: email,
        password: password,
      );
      await user.reauthenticateWithCredential(cred);
      return null;
    } on FirebaseAuthException catch (e) {
      return CredentialFailure(e.code, e.message ?? '');
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  @override
  Future<AuthFailure?> updatePassword(String newPassword) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return CredentialFailure('not-authenticated', 'Not authenticated');
      }
      await user.updatePassword(newPassword);
      await user.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return CredentialFailure(e.code, e.message ?? '');
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  @override
  Future<List<String>> getLinkedProviders() async {
    final user = _auth.currentUser;
    if (user == null) return [];
    return user.providerData.map((p) => p.providerId).toList();
  }

  @override
  Future<AuthFailure?> sendEmailVerification() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return CredentialFailure('not-authenticated', 'No current user');
      }
      if (user.emailVerified) {
        return null; // Already verified
      }
      await user.sendEmailVerification();
      return null;
    } on FirebaseAuthException catch (e) {
      return CredentialFailure(e.code, e.message ?? '');
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }

  @override
  Future<bool> isEmailVerified() async {
    final user = _auth.currentUser;
    return user?.emailVerified ?? false;
  }

  @override
  Future<AuthFailure?> reloadUser() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        return CredentialFailure('not-authenticated', 'No current user');
      }
      await user.reload();
      return null;
    } on FirebaseAuthException catch (e) {
      return CredentialFailure(e.code, e.message ?? '');
    } catch (e) {
      return UnknownFailure(e.toString());
    }
  }
}
