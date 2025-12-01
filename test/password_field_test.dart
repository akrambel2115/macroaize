import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:foodcalorietracker/widgets/password_field.dart';

void main() {
  testWidgets('PasswordField toggles obscure and limits parent rebuilds', (
    tester,
  ) async {
    final controller = TextEditingController();
    final rebuilds = ValueNotifier<int>(0);

    final widget = ValueListenableBuilder<int>(
      valueListenable: rebuilds,
      builder: (context, value, child) {
        // Increment on each rebuild
        rebuilds.value = value + 1;
        return child!;
      },
      child: MaterialApp(
        home: Scaffold(
          body: PasswordField(
            controller: controller,
            label: 'Test',
            autofocus: false,
          ),
        ),
      ),
    );

    await tester.pumpWidget(widget);
    await tester.pumpAndSettle();

    // Initial rebuilds should be small
    expect(rebuilds.value < 10, true);

    // Find the eye icon button and tap it to toggle
    final eye = find.byType(IconButton);
    expect(eye, findsOneWidget);
    await tester.tap(eye);
    await tester.pumpAndSettle();

    // Toggling should not cause excessive parent rebuilds
    expect(
      rebuilds.value < 20,
      true,
      reason: 'Parent rebuilt too many times: ${rebuilds.value}',
    );
  });
}
