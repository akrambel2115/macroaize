import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'fakes/fake_auth_repository.dart';
import 'package:foodcalorietracker/features/auth/presentation/account_controller.dart';
import 'package:foodcalorietracker/screens/AccountDetails/change_password_screen.dart';

/// A simple widget that increments [counter] every time it is built.
class RebuildCounter extends StatelessWidget {
  final ValueNotifier<int> counter;
  final Widget child;
  const RebuildCounter({required this.counter, required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    counter.value = counter.value + 1;
    return child;
  }
}

void main() {
  testWidgets('ChangePasswordScreen rebuild benchmark (typing)', (tester) async {
    final repo = FakeAuthRepository();
    final controller = AccountController(repo);
    final rebuildCounter = ValueNotifier<int>(0);

    await tester.pumpWidget(GetMaterialApp(
      home: RebuildCounter(
        counter: rebuildCounter,
        child: ChangePasswordScreen(controller: controller),
      ),
    ));

    // Ensure initial build settles
    await tester.pumpAndSettle();

    // Reset counter after initial rendering
    rebuildCounter.value = 0;

    // Simulate typing into each of the three fields repeatedly
    for (var i = 0; i < 6; i++) {
      await tester.enterText(find.byType(TextFormField).at(0), 'OldPass$i!A');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextFormField).at(1), 'NewPass$i!A');
      await tester.pump(const Duration(milliseconds: 50));
      await tester.enterText(find.byType(TextFormField).at(2), 'NewPass$i!A');
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Allow any remaining microtasks
    await tester.pumpAndSettle(const Duration(milliseconds: 200));

    final count = rebuildCounter.value;
  // Expect rebuilds to stay within a reasonable budget.
  // Tightened threshold to catch regressions.
  expect(count < 120, true, reason: 'Rebuilds too high: $count');
  });
}
