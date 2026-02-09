import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:macroaize/widgets/ScannerOverlay.dart';

void main() {
  testWidgets('ScannerOverlay has rounded border radius', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: const ScannerOverlay(width: 200, height: 150, borderRadius: 30),
        ),
      ),
    );

    // Find a Container that has BoxDecoration with BorderRadius
    final containerFinder = find.byType(Container);
    expect(containerFinder, findsWidgets);

    // Verify that there exists a ClipRRect (from the overlay) with our radius
    final clipFinder = find.byType(ClipRRect);
    expect(clipFinder, findsOneWidget);

    final ClipRRect clip = tester.widget<ClipRRect>(clipFinder);
    expect(clip.borderRadius is BorderRadius, true);
    final br = clip.borderRadius as BorderRadius;
    expect(br.topLeft.x, 30.0);
  });
}
