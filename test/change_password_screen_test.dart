import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:foodcalorietracker/features/auth/presentation/account_controller.dart';
import 'fakes/fake_auth_repository.dart';
import 'package:foodcalorietracker/screens/AccountDetails/change_password_screen.dart';

void main() {
  testWidgets('ChangePasswordScreen renders and validates', (tester) async {
    final repo = FakeAuthRepository();
    final controller = AccountController(repo);

  await tester.pumpWidget(GetMaterialApp(home: ChangePasswordScreen(controller: controller)));
  await tester.pumpAndSettle();

    // Verify fields present
    expect(find.byType(TextFormField), findsNWidgets(3));

    // Enter passwords
    await tester.enterText(find.byType(TextFormField).at(0), 'OldPass1!');
    await tester.enterText(find.byType(TextFormField).at(1), 'NewPass1!');
    await tester.enterText(find.byType(TextFormField).at(2), 'NewPass1!');

    await tester.pump();

  // Try to tap the Change Password button specifically (TextButton in UI)
  final changeButton = find.widgetWithText(TextButton, 'Change Password');
  expect(changeButton, findsOneWidget);
  await tester.tap(changeButton);
  await tester.pumpAndSettle(const Duration(seconds: 1));

  // There should be two 'Change Password' Text widgets (AppBar title + button label)
  expect(find.text('Change Password'), findsNWidgets(2));
  });
}
