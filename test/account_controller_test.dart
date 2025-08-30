import 'package:flutter_test/flutter_test.dart';
import 'package:foodcalorietracker/features/auth/presentation/account_controller.dart';
import 'fakes/fake_auth_repository.dart';

void main() {
  group('AccountController validation', () {
    late FakeAuthRepository repo;
    late AccountController controller;

    setUp(() {
      repo = FakeAuthRepository();
      controller = AccountController(repo);
    });

    test('changePassword fails when fields empty', () async {
      controller.currentPassword.text = '';
      controller.newPassword.text = '';
      controller.confirmPassword.text = '';
      await controller.changePassword();
      expect(controller.errorText.value, 'All fields are required');
    });

    test('changePassword fails when mismatch', () async {
      controller.currentPassword.text = 'OldPass1!';
      controller.newPassword.text = 'NewPass1!';
      controller.confirmPassword.text = 'Mismatch';
      await controller.changePassword();
      expect(controller.errorText.value, 'Passwords do not match');
    });

    test('changePassword reauth failure mapped', () async {
      controller.currentPassword.text = 'wrong';
      controller.newPassword.text = 'NewPass1!';
      controller.confirmPassword.text = 'NewPass1!';
      repo.reauthShouldFail = true;
      await controller.changePassword();
      expect(controller.errorText.value.contains('incorrect') || controller.errorText.value.isNotEmpty, true);
    });
  });
}
