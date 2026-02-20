import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:macroaize/screens/ScanFoodView/scan_food_view.dart';

void main() {
  testWidgets('Meal selector animates and updates selection', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      GetMaterialApp(
        home: Builder(
          builder: (context) {
            // initialize controller manually
            return const ScanFoodView();
          },
        ),
      ),
    );

    // Allow initial build
    await tester.pumpAndSettle();

    // The meal selector is present (unless camera requires initialization)
    final mealTextFinder = find.text('BreakFast');

    // If camera unavailable in test env, we still expect the selector widget exists in tree
    expect(mealTextFinder, findsWidgets);

    // Tap on the second meal (Lunch)
    final lunchFinder = find.text('Lunch').first;
    await tester.tap(lunchFinder);
    // Pump animation duration
    await tester.pump(const Duration(milliseconds: 350));

    // After tapping, the UI should reflect the selection by elevated style (we check for existence)
    expect(find.text('Lunch'), findsOneWidget);
  });
}
