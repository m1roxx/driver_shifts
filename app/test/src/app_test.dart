import 'package:driver_shifts/src/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('follows the ${brightness.name} system theme at 200% text '
        'on a small phone', (tester) async {
      tester.view
        ..physicalSize = const Size(360, 640)
        ..devicePixelRatio = 1;
      tester.platformDispatcher
        ..platformBrightnessTestValue = brightness
        ..textScaleFactorTestValue = 2;
      addTearDown(tester.view.reset);
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await tester.pumpWidget(const DriverShiftsApp());

      final theme = Theme.of(tester.element(find.byType(Scaffold)));
      expect(theme.colorScheme.brightness, brightness);
      expect(find.text('Дневник смен'), findsOneWidget);
    });
  }
}
