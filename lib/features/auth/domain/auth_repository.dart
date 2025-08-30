import 'package:firebase_auth/firebase_auth.dart';
import 'auth_failure.dart';

abstract class AuthRepository {
  Stream<User?> authStateChanges();

  Future<(User?, AuthFailure?)> signInWithEmail({required String email, required String password});
  Future<(User?, AuthFailure?)> registerWithEmail({required String email, required String password, required String firstName, required String lastName});
  Future<AuthFailure?> sendPasswordReset({required String email});

  Future<(User?, AuthFailure?)> signInWithGoogle();
  Future<(User?, AuthFailure?)> signInWithApple();
  Future<AuthFailure?> linkWithApple();
  Future<AuthFailure?> updateDisplayName(String name);
  Future<AuthFailure?> reauthenticateWithPassword(String password);
  Future<AuthFailure?> updatePassword(String newPassword);
  Future<List<String>> getLinkedProviders();

  Future<void> signOut();
}
