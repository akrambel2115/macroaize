import 'package:firebase_auth/firebase_auth.dart';
import 'package:foodcalorietracker/features/auth/domain/auth_failure.dart';
import 'package:foodcalorietracker/features/auth/domain/auth_repository.dart';

class FakeAuthRepository implements AuthRepository {
  bool reauthShouldFail = false;
  bool updateShouldFail = false;

  @override
  Future<AuthFailure?> reauthenticateWithPassword(String password) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (reauthShouldFail) return CredentialFailure('wrong-password', 'Incorrect');
    return null;
  }

  @override
  Future<AuthFailure?> updatePassword(String newPassword) async {
    await Future.delayed(const Duration(milliseconds: 10));
    if (updateShouldFail) return UnknownFailure('Update failed');
    return null;
  }

  // Unused members for tests - implement stubs
  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  @override
  Future<(User?, AuthFailure?)> signInWithEmail({required String email, required String password}) async => (null, null);

  @override
  Future<(User?, AuthFailure?)> registerWithEmail({required String email, required String password, required String firstName, required String lastName}) async => (null, null);

  @override
  Future<AuthFailure?> sendPasswordReset({required String email}) async => null;

  @override
  Future<(User?, AuthFailure?)> signInWithGoogle() async => (null, null);

  @override
  Future<(User?, AuthFailure?)> signInWithApple() async => (null, null);

  @override
  Future<AuthFailure?> linkWithApple() async => null;

  @override
  Future<AuthFailure?> updateDisplayName(String name) async => null;

  @override
  Future<List<String>> getLinkedProviders() async => [];

  @override
  Future<void> signOut() async {}
}
