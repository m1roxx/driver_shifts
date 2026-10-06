import 'package:driver_shifts/src/features/shift_diary/presentation/screens/shift_diary_screen.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/day_reports.dart';
import '../helpers/fake_trips_repository.dart';
import '../helpers/pump_app.dart';

void main() {
  testWidgets('opens today on the day screen in Russian', (tester) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    final context = tester.element(find.byType(ShiftDiaryScreen));
    expect(Localizations.localeOf(context), const Locale('ru'));
    expect(MaterialLocalizations.of(context).okButtonLabel, 'ОК');
    expect(CupertinoLocalizations.of(context).todayLabel, 'Сегодня');
    expect(find.text('Дневник смен'), findsOneWidget);
    expect(repository.requestedDays, [oct1]);
  });

  for (final brightness in Brightness.values) {
    testWidgets('follows the ${brightness.name} system theme', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearAllTestValues);

      await pumpApp(tester, FakeTripsRepository.withReports({}));
      await tester.pumpAndSettle();

      final theme = Theme.of(tester.element(find.byType(ShiftDiaryScreen)));
      expect(theme.colorScheme.brightness, brightness);
    });
  }
}
