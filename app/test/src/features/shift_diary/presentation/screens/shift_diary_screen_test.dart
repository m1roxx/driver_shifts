import 'dart:async';

import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_skeleton.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/failure_banner.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/summary_card.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/semantics.dart';

FakeTripsRepository _answering(List<Result<DayReport>> responses) =>
    FakeTripsRepository((_) async => responses.removeAt(0));

final Finder _todayButton = find.widgetWithText(TextButton, 'Сегодня');

final Finder _addTripButton = find.widgetWithText(
  FilledButton,
  'Добавить поездку',
);

Color? _addTripBarDivider(WidgetTester tester) {
  final bar = tester.widget<DecoratedBox>(
    find.ancestor(of: _addTripButton, matching: find.byType(DecoratedBox)).last,
  );
  return (bar.decoration as BoxDecoration).border?.top.color;
}

Future<void> _pullToRefresh(WidgetTester tester) async {
  await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('shows the server summary and the trips of today', (
    tester,
  ) async {
    await pumpApp(
      tester,
      FakeTripsRepository.withReports({oct1: taskExampleReport}),
    );
    await tester.pumpAndSettle();

    expect(find.text('Сегодня, 1 октября'), findsOneWidget);
    expect(find.text('3\u00A0315\u00A0₸'), findsOneWidget);
    expect(find.bySemanticsLabel('На руки 3\u00A0315 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Поездки 2'), findsOneWidget);
    expect(find.bySemanticsLabel('Выручка 3\u00A0900 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Комиссия 585 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Наличные 1\u00A0500 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Карта 2\u00A0400 тенге'), findsOneWidget);

    expect(find.text('08:10\u00A0– 08:32'), findsOneWidget);
    expect(find.text('09:05\u00A0– 09:20'), findsOneWidget);
    expect(
      find.bySemanticsLabel('с 08:10 до 08:32\nКарта\n2\u00A0400 тенге'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('с 09:05 до 09:20\nНаличные\n1\u00A0500 тенге'),
      findsOneWidget,
    );
  });

  testWidgets('adds trips from a bar at the bottom, divided from the list '
      'only while trips are under it', (tester) async {
    await pumpApp(tester, FakeTripsRepository.withReports({oct1: longReport}));
    await tester.pumpAndSettle();
    final colors = Theme.of(tester.element(_addTripButton)).colorScheme;
    final lastTrip = find.text('19:10\u00A0– 19:40');

    expect(find.byType(FloatingActionButton), findsNothing);
    expect(_addTripButton.hitTestable(), findsOneWidget);
    expect(_addTripBarDivider(tester), colors.outlineVariant);

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -3000));
    await tester.pumpAndSettle();

    expect(_addTripBarDivider(tester), Colors.transparent);
    expect(
      tester.getRect(_addTripButton).top - tester.getRect(lastTrip).bottom,
      greaterThanOrEqualTo(16),
    );
  });

  testWidgets('switches days with the arrows and a swipe, and «Сегодня» '
      'returns to today', (tester) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
      oct2: oct2Report,
    });
    final haptics = <Object?>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      SystemChannels.platform,
      (call) async {
        if (call.method == 'HapticFeedback.vibrate') {
          haptics.add(call.arguments);
        }
        return null;
      },
    );
    addTearDown(
      () => tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        SystemChannels.platform,
        null,
      ),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    expect(_todayButton.hitTestable(), findsNothing);

    await tester.tap(find.byTooltip('Следующий день'));
    await tester.pumpAndSettle();
    expect(find.text('Завтра, 2 октября'), findsOneWidget);
    expect(find.bySemanticsLabel('На руки 7\u00A0259 тенге'), findsOneWidget);
    expect(find.text('00:30\u00A0– 00:55'), findsOneWidget);
    expect(find.text('23:50\u00A0– 00:20'), findsOneWidget);

    await tester.fling(find.byType(SummaryCard), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Сегодня, 1 октября'), findsOneWidget);

    await tester.tap(find.byTooltip('Предыдущий день'));
    await tester.pumpAndSettle();
    expect(find.text('Вчера, 30 сентября'), findsOneWidget);
    expect(find.text('В этот день поездок нет'), findsOneWidget);

    await tester.fling(find.byType(SummaryCard), const Offset(-300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Сегодня, 1 октября'), findsOneWidget);

    await tester.tap(find.byTooltip('Предыдущий день'));
    await tester.pumpAndSettle();
    await tester.tap(_todayButton);
    await tester.pumpAndSettle();

    expect(find.text('Сегодня, 1 октября'), findsOneWidget);
    expect(_todayButton.hitTestable(), findsNothing);
    expect(repository.requestedDays, [
      oct1,
      oct2,
      oct1,
      sep30,
      oct1,
      sep30,
      oct1,
    ]);
    expect(haptics, List.filled(6, 'HapticFeedbackType.selectionClick'));
  });

  testWidgets('picks a day in the Russian Material date picker', (
    tester,
  ) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
      oct2: oct2Report,
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Выбрать дату'));
    await tester.pumpAndSettle();
    expect(find.text('Выберите дату'), findsOneWidget);
    final dialog = tester.widget<DatePickerDialog>(
      find.byType(DatePickerDialog),
    );
    expect(
      (dialog.firstDate, dialog.lastDate),
      (DateTime(2000), DateTime(2100, 12, 31)),
    );
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('2'),
      ),
    );
    await tester.tap(find.text('ОК'));
    await tester.pumpAndSettle();

    expect(find.text('Завтра, 2 октября'), findsOneWidget);
    expect(repository.requestedDays, [oct1, oct2]);
  });

  testWidgets('picks a day in a Cupertino picker sheet on iOS', (tester) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Выбрать дату'));
    await tester.pumpAndSettle();
    final picker = tester.widget<CupertinoDatePicker>(
      find.byType(CupertinoDatePicker),
    );
    expect(picker.mode, CupertinoDatePickerMode.date);
    expect(
      (picker.minimumDate, picker.maximumDate),
      (DateTime(2000), DateTime(2100, 12, 31)),
    );
    expect((picker.minimumYear, picker.maximumYear), (2000, 2100));
    expect(find.text('октября'), findsWidgets);
    picker.onDateTimeChanged(DateTime(2026, 9, 30));
    await tester.tap(find.text('Готово'));
    await tester.pumpAndSettle();

    expect(find.text('Вчера, 30 сентября'), findsOneWidget);
    expect(repository.requestedDays, [oct1, sep30]);
  }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));

  testWidgets('shows a skeleton until the day loads', (tester) async {
    final response = Completer<Result<DayReport>>();
    await pumpApp(tester, FakeTripsRepository((_) => response.future));
    await tester.pumpAndSettle();

    expect(find.byType(DaySkeleton), findsOneWidget);
    expect(find.bySemanticsLabel('Загрузка поездок'), findsOneWidget);
    expect(find.byType(SummaryCard), findsNothing);

    response.complete(Result.success(taskExampleReport));
    await tester.pumpAndSettle();

    expect(find.byType(DaySkeleton), findsNothing);
    expect(find.byType(SummaryCard), findsOneWidget);
  });

  testWidgets('offers a retry when the day does not load', (tester) async {
    final repository = _answering([
      const Result.error(Failure.connection()),
      Result.success(taskExampleReport),
    ]);
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text(const Failure.connection().message), findsOneWidget);
    expect(find.byType(SummaryCard), findsNothing);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryCard), findsOneWidget);
    expect(repository.requestedDays, [oct1, oct1]);
  });

  testWidgets('keeps the day on screen when a pull-to-refresh fails and '
      'retries from the banner', (tester) async {
    final repository = _answering([
      Result.success(taskExampleReport),
      const Result.error(Failure.timeout()),
      Result.success(taskExampleReport),
    ]);
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await _pullToRefresh(tester);

    expect(find.text(const Failure.timeout().message), findsOneWidget);
    expect(find.bySemanticsLabel('На руки 3\u00A0315 тенге'), findsOneWidget);

    await tester.tap(find.widgetWithText(TextButton, 'Повторить'));
    await tester.pumpAndSettle();

    expect(find.byType(FailureBanner), findsNothing);
    expect(find.byType(SummaryCard), findsOneWidget);
    expect(repository.requestedDays, [oct1, oct1, oct1]);
  });

  testWidgets('hides a refresh error once another day is chosen', (
    tester,
  ) async {
    await pumpApp(
      tester,
      _answering([
        Result.success(taskExampleReport),
        const Result.error(Failure.timeout()),
        Result.success(oct2Report),
      ]),
    );
    await tester.pumpAndSettle();
    await _pullToRefresh(tester);
    expect(find.byType(FailureBanner), findsOneWidget);

    await tester.tap(find.byTooltip('Следующий день'));
    await tester.pumpAndSettle();

    expect(find.byType(FailureBanner), findsNothing);
    expect(find.text('Завтра, 2 октября'), findsOneWidget);
  });

  testWidgets('screen readers hear failures and the new day without moving '
      'focus', (tester) async {
    await pumpApp(
      tester,
      _answering([
        const Result.error(Failure.connection()),
        Result.success(taskExampleReport),
        const Result.error(Failure.timeout()),
        Result.success(oct2Report),
      ]),
    );
    await tester.pumpAndSettle();
    expect(
      inLiveRegion(tester, find.text(const Failure.connection().message)),
      isTrue,
    );

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    await _pullToRefresh(tester);
    expect(
      inLiveRegion(tester, find.text(const Failure.timeout().message)),
      isTrue,
    );

    await tester.tap(find.byTooltip('Следующий день'));
    await tester.pump();
    expect(inLiveRegion(tester, find.text('Завтра, 2 октября')), isTrue);
  });

  group('after midnight in Almaty', () {
    final beforeMidnight = DateTime.utc(2026, 10, 1, 18, 50);

    testWidgets('today moves on when the app comes back from the '
        'background', (tester) async {
      var now = beforeMidnight;
      final repository = FakeTripsRepository.withReports({
        oct1: taskExampleReport,
        oct2: oct2Report,
      });
      await pumpApp(tester, repository, now: () => now);
      await tester.pumpAndSettle();
      expect(find.text('Сегодня, 1 октября'), findsOneWidget);

      now = DateTime.utc(2026, 10, 2, 3);
      for (final state in [
        AppLifecycleState.inactive,
        AppLifecycleState.hidden,
        AppLifecycleState.paused,
        AppLifecycleState.hidden,
        AppLifecycleState.inactive,
        AppLifecycleState.resumed,
      ]) {
        tester.binding.handleAppLifecycleStateChanged(state);
      }
      await tester.pumpAndSettle();

      expect(find.text('Вчера, 1 октября'), findsOneWidget);
      expect(_todayButton.hitTestable(), findsOneWidget);

      await tester.tap(_todayButton);
      await tester.pumpAndSettle();

      expect(find.text('Сегодня, 2 октября'), findsOneWidget);
      expect(repository.requestedDays, [oct1, oct2]);
    });

    testWidgets('today moves on at midnight while the screen is open', (
      tester,
    ) async {
      var now = beforeMidnight;
      await pumpApp(
        tester,
        FakeTripsRepository.withReports({oct1: taskExampleReport}),
        now: () => now,
      );
      await tester.pumpAndSettle();

      now = DateTime.utc(2026, 10, 1, 19, 0, 1);
      await tester.pump(const Duration(minutes: 10));

      expect(find.text('Вчера, 1 октября'), findsOneWidget);
      expect(_todayButton.hitTestable(), findsOneWidget);
    });
  });

  for (final brightness in Brightness.values) {
    group('at 200% text in the ${brightness.name} theme on a small phone', () {
      testWidgets('a day with trips', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          FakeTripsRepository.withReports({oct1: taskExampleReport}),
        );
        await tester.pumpAndSettle();

        final theme = Theme.of(tester.element(find.byType(SummaryCard)));
        expect(theme.colorScheme.brightness, brightness);
        expect(find.text('3\u00A0315\u00A0₸'), findsOneWidget);
        await tester.scrollUntilVisible(find.text('09:05\u00A0– 09:20'), 100);
        expect(
          find.bySemanticsLabel('с 09:05 до 09:20\nНаличные\n1\u00A0500 тенге'),
          findsOneWidget,
        );
      });

      testWidgets('loading', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          FakeTripsRepository((_) => Completer<Result<DayReport>>().future),
        );
        await tester.pumpAndSettle();

        expect(find.byType(DaySkeleton), findsOneWidget);
      });

      testWidgets('an empty day', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(tester, FakeTripsRepository.withReports({}));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('В этот день поездок нет'),
          100,
        );
      });

      testWidgets('an error', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          FakeTripsRepository(
            (_) async => const Result.error(Failure.timeout()),
          ),
        );
        await tester.pumpAndSettle();

        expect(find.text(const Failure.timeout().message), findsOneWidget);
        expect(find.text('Повторить'), findsOneWidget);
      });

      testWidgets('a failed refresh', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          _answering([
            Result.success(taskExampleReport),
            const Result.error(Failure.timeout()),
          ]),
        );
        await tester.pumpAndSettle();
        await _pullToRefresh(tester);

        expect(find.text(const Failure.timeout().message), findsOneWidget);
      });

      testWidgets(
        'the date picker',
        (tester) async {
          useSmallPhone(tester, brightness: brightness, textScale: 2);
          await pumpApp(
            tester,
            FakeTripsRepository.withReports({oct1: taskExampleReport}),
          );
          await tester.pumpAndSettle();

          await tester.tap(find.byTooltip('Выбрать дату'));
          await tester.pumpAndSettle();

          if (defaultTargetPlatform == TargetPlatform.iOS) {
            expect(find.byType(CupertinoDatePicker), findsOneWidget);
          } else {
            final calendar = tester.element(find.byType(DatePickerDialog));
            expect(MediaQuery.textScalerOf(calendar).scale(10), 13);
          }
        },
        variant: const TargetPlatformVariant({
          TargetPlatform.android,
          TargetPlatform.iOS,
        }),
      );
    });
  }
}
