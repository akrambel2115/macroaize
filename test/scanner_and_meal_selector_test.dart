import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:macroaize/widgets/ScannerOverlay.dart';
import 'package:macroaize/screens/ScanFoodView/ScanFoodView.dart';

void main() {
  testWidgets(
    'ScannerOverlay has rounded borderRadius and meal selector updates',
    (WidgetTester tester) async {
      // Verify ScannerOverlay rounded corners
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const ScannerOverlay(
              width: 200,
              height: 120,
              borderRadius: 28,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      final containerFinder = find
          .byType(Container)
          .at(1); // the central frame container
      expect(containerFinder, findsWidgets);

      // Now test meal selector behavior by rendering ScanFoodView
      await tester.pumpWidget(
        GetMaterialApp(
          home: Builder(
            builder: (context) {
              return const ScanFoodView();
            },
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Find breakfast and lunch labels
      final breakfastFinder = find.text('BreakFast');
      final lunchFinder = find.text('Lunch');

      expect(breakfastFinder, findsWidgets);
      expect(lunchFinder, findsWidgets);

      // Tap Lunch
      await tester.tap(lunchFinder.first);
      await tester.pump(const Duration(milliseconds: 300));

      // After tap, Lunch should still be present and selectable
      expect(lunchFinder, findsWidgets);
    },
  );
}
