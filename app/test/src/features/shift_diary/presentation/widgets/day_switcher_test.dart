import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';

void main() {
  testWidgets('names other days by weekday and adds the year of another '
      'year', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: GlobalMaterialLocalizations.delegates,
        supportedLocales: const [Locale('ru')],
        home: Scaffold(
          body: Column(
            children: [
              DaySwitcher(
                date: DateTime.utc(2026, 9, 29),
                today: oct1,
                onChanged: (_) {},
              ),
              DaySwitcher(
                date: DateTime.utc(2025, 12, 31),
                today: oct1,
                onChanged: (_) {},
              ),
            ],
          ),
        ),
      ),
    );

    expect(find.text('Вторник, 29 сентября'), findsOneWidget);
    expect(find.text('Среда, 31 декабря 2025\u202Fг.'), findsOneWidget);
  });
}
