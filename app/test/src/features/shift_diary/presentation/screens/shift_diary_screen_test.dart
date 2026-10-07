import 'dart:async';

import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_pages.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_report_view.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_skeleton.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/failure_banner.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/summary_card.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/trip_tile.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_list.dart';
import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/semantics.dart';

FakeTripsRepository _answering(List<Result<DayReport>> responses) =>
    FakeTripsRepository(
      (_) async =>
          responses.length > 1 ? responses.removeAt(0) : responses.single,
    );

const Failure _unexpected = Failure.unexpected();

const Failure _notFound = Failure.badResponse(statusCode: 404);

const String _serverWaking =
    'Сервер просыпается после простоя — это занимает до минуты';

final Finder _todayButton = find.widgetWithText(TextButton, 'Сегодня');

final Finder _goToTodayButton = find.widgetWithText(
  FilledButton,
  'Перейти к сегодня',
);

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

void _expectWordsWhole(WidgetTester tester, Finder within) {
  final texts = find.descendant(of: within, matching: find.byType(RichText));
  expect(texts, findsWidgets);
  for (final element in texts.evaluate()) {
    final paragraph = element.renderObject! as RenderParagraph;
    expect(
      paragraph.size.width,
      greaterThanOrEqualTo(
        paragraph.getMinIntrinsicWidth(double.infinity) - 0.5,
      ),
      reason: '«${paragraph.text.toPlainText()}» breaks inside a word',
    );
  }
}

void _expectWholeOnOneLine(WidgetTester tester, String amount) {
  final texts = find.text(amount);
  expect(texts, findsWidgets);
  for (var i = 0; i < texts.evaluate().length; i++) {
    _expectWholeInCard(tester, texts.at(i), amount);
  }
}

void _expectWholeInCard(WidgetTester tester, Finder text, String amount) {
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: text, matching: find.byType(RichText)),
  );
  expect(
    paragraph.size.width,
    moreOrLessEquals(paragraph.getMaxIntrinsicWidth(double.infinity)),
    reason: '$amount is cut off',
  );
  final card = tester.getRect(
    find
        .ancestor(
          of: text,
          matching: find.byWidgetPredicate((w) => w is Card || w is TripTile),
        )
        .first,
  );
  final rect = tester.getRect(text);
  expect(
    rect.left >= card.left && rect.right <= card.right,
    isTrue,
    reason: '$amount $rect sticks out of the card $card',
  );
}

void _expectSummaryOrder(WidgetTester tester, {required bool sideBySide}) {
  Rect rectOf(String label) => tester.getRect(find.bySemanticsLabel(label));
  final net = rectOf('На руки 3\u00A0315 тенге, 2\u00A0поездки');
  final revenue = rectOf('Выручка 3\u00A0900 тенге');
  final cash = rectOf('Наличные 1\u00A0500 тенге');
  final card = rectOf('Карта 2\u00A0400 тенге');
  final commission = rectOf('Комиссия 585 тенге');

  expect(net.bottom, lessThanOrEqualTo(revenue.top));
  expect(revenue.bottom, lessThanOrEqualTo(cash.top));
  if (sideBySide) {
    expect(card.top, cash.top);
    expect(card.left, greaterThanOrEqualTo(cash.right));
  } else {
    expect(cash.bottom, lessThanOrEqualTo(card.top));
  }
  expect(card.bottom, lessThanOrEqualTo(commission.top));
}

Future<void> _turnPages(WidgetTester tester) async {
  await tester.pump();
  await tester.pump(const Duration(seconds: 1));
}

Future<void> _pullToRefresh(WidgetTester tester, {bool settle = true}) async {
  await tester.fling(find.byType(CustomScrollView), const Offset(0, 300), 1000);
  if (settle) {
    await tester.pumpAndSettle();
  } else {
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }
}

Future<void> _waitPastSlowLoad(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 3));
  await tester.pump(const Duration(milliseconds: 300));
}

Future<void> _waitOutRetries(WidgetTester tester) async {
  await tester.pump(const Duration(seconds: 95));
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
    expect(
      find.bySemanticsLabel('На руки 3\u00A0315 тенге, 2\u00A0поездки'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Выручка 3\u00A0900 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Комиссия 585 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Наличные 1\u00A0500 тенге'), findsOneWidget);
    expect(find.bySemanticsLabel('Карта 2\u00A0400 тенге'), findsOneWidget);
    _expectSummaryOrder(tester, sideBySide: true);

    expect(find.text('08:10\u00A0– 08:32'), findsOneWidget);
    expect(find.text('Карта\u00A0·'), findsOneWidget);
    expect(find.text('комиссия 360\u00A0₸'), findsOneWidget);
    expect(find.text('2\u00A0400\u00A0₸'), findsNWidgets(2));
    await tester.scrollUntilVisible(
      find.text('09:05\u00A0– 09:20'),
      100,
      scrollable: dayList,
    );
    expect(find.text('Наличные\u00A0·'), findsOneWidget);
    expect(find.text('комиссия 225\u00A0₸'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'С 08:10 до 08:32, карта, 2\u00A0400 тенге, комиссия 360 тенге',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'С 09:05 до 09:20, наличные, 1\u00A0500 тенге, комиссия 225 тенге',
      ),
      findsOneWidget,
    );
    expect(find.text('+1 день'), findsNothing);
    expect(
      tester.getSemantics(find.text('Поездки')),
      isSemantics(label: 'Поездки', isHeader: true),
    );
  });

  testWidgets('marks a trip that ends after midnight in Almaty with «+1 день» '
      'and says so', (tester) async {
    await pumpApp(
      tester,
      FakeTripsRepository.withReports({oct2: oct2Report}),
      now: () => DateTime.utc(2026, 10, 2, 6),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('00:30\u00A0– 00:55'),
      100,
      scrollable: dayList,
    );
    await tester.scrollUntilVisible(
      find.text('23:50\u00A0– 00:20'),
      100,
      scrollable: dayList,
    );

    expect(find.text('+1 день'), findsOneWidget);
    expect(
      find.descendant(
        of: find.ancestor(
          of: find.text('23:50\u00A0– 00:20'),
          matching: find.byType(Wrap),
        ),
        matching: find.text('+1 день'),
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'С 23:50 до 00:20 следующего дня, карта, 4\u00A0600 тенге, '
        'комиссия 690 тенге',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'С 00:30 до 00:55, наличные, 2\u00A0700 тенге, комиссия 405 тенге',
      ),
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
    expect(
      find.bySemanticsLabel('На руки 7\u00A0259 тенге, 3\u00A0поездки'),
      findsOneWidget,
    );

    await tester.fling(find.byType(SummaryCard), const Offset(300, 0), 1000);
    await tester.pumpAndSettle();
    expect(find.text('Сегодня, 1 октября'), findsOneWidget);

    await tester.tap(find.byTooltip('Предыдущий день'));
    await tester.pumpAndSettle();
    expect(find.text('Вчера, 30 сентября'), findsOneWidget);
    expect(find.text('В этот день поездок нет'), findsOneWidget);
    expect(find.byType(SummaryCard), findsNothing);

    await tester.fling(
      find.text('В этот день поездок нет'),
      const Offset(-300, 0),
      1000,
    );
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

  testWidgets('a swipe drags the next day in beside the current one and '
      'loads it only once the page settles', (tester) async {
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
      oct2: oct2Report,
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    final summary = find.byType(SummaryCard);
    final left = tester.getTopLeft(summary).dx;
    final width = tester.getSize(find.byType(DayPages)).width;

    final peek = await tester.startGesture(tester.getCenter(summary));
    await peek.moveBy(const Offset(-40, 0));
    await peek.moveBy(const Offset(-100, 0));
    await tester.pump();
    expect(tester.getTopLeft(summary).dx, lessThan(left - 80));
    expect(
      tester.getTopLeft(find.byType(DaySkeleton)).dx,
      moreOrLessEquals(
        tester.getTopLeft(find.byType(DayReportView)).dx + width,
      ),
      reason: 'the next day is right beside the current one',
    );
    await peek.up();
    await tester.pumpAndSettle();
    expect(tester.getTopLeft(summary).dx, left);
    expect(find.text('Сегодня, 1 октября'), findsOneWidget);
    expect(repository.requestedDays, [oct1]);

    final swipe = await tester.startGesture(tester.getCenter(summary));
    await swipe.moveBy(const Offset(-40, 0));
    await swipe.moveBy(Offset(-width * 0.6, 0));
    await tester.pump();
    expect(
      find.text('Завтра, 2 октября'),
      findsOneWidget,
      reason: 'the title follows the page that takes most of the screen',
    );
    await tester.pump(const Duration(seconds: 1));
    expect(repository.requestedDays, [
      oct1,
    ], reason: 'the day loads when the page settles, not while it is dragged');
    await swipe.up();
    await tester.pumpAndSettle();

    expect(find.text('Завтра, 2 октября'), findsOneWidget);
    expect(
      find.bySemanticsLabel('На руки 7\u00A0259 тенге, 3\u00A0поездки'),
      findsOneWidget,
    );
    expect(repository.requestedDays, [oct1, oct2]);
  });

  testWidgets('flipping through days faster than they load shows only the '
      'day the pages stop on', (tester) async {
    final oct3 = DateTime.utc(2026, 10, 3);
    final oct2Response = Completer<Result<DayReport>>();
    final repository = FakeTripsRepository(
      (date) => date == oct2
          ? oct2Response.future
          : Future.value(
              Result.success(
                date == oct1 ? taskExampleReport : emptyReport(date),
              ),
            ),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    final pages = find.byType(DayPages);

    await tester.fling(pages, const Offset(-500, 0), 1000);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    expect(find.text('Завтра, 2 октября'), findsOneWidget);
    await tester.fling(pages, const Offset(-500, 0), 1000);
    await _turnPages(tester);
    expect(find.text('Суббота, 3 октября'), findsOneWidget);
    expect(repository.requestedDays, [oct1, oct3]);

    await tester.fling(pages, const Offset(300, 0), 1000);
    await _turnPages(tester);
    expect(repository.requestedDays, [oct1, oct3, oct2]);
    await tester.fling(pages, const Offset(300, 0), 1000);
    await _turnPages(tester);
    oct2Response.complete(Result.success(oct2Report));
    await _turnPages(tester);

    expect(find.text('Сегодня, 1 октября'), findsOneWidget);
    expect(
      find.bySemanticsLabel('На руки 3\u00A0315 тенге, 2\u00A0поездки'),
      findsOneWidget,
    );
    expect(find.byType(SummaryCard), findsOneWidget);
    expect(repository.requestedDays, [oct1, oct3, oct2, oct1]);
  });

  for (final reduced in [false, true]) {
    final mode = reduced
        ? 'switch the day at once when animations are off'
        : 'turn the page the way a swipe does';
    testWidgets('the arrows $mode', (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          FakeAccessibilityFeatures(disableAnimations: reduced);
      addTearDown(
        tester.platformDispatcher.clearAccessibilityFeaturesTestValue,
      );
      final repository = FakeTripsRepository.withReports({
        oct1: taskExampleReport,
        oct2: oct2Report,
      });
      await pumpApp(tester, repository);
      await tester.pumpAndSettle();
      final today = find.bySemanticsLabel(
        'На руки 3\u00A0315 тенге, 2\u00A0поездки',
      );
      final left = tester.getTopLeft(today).dx;

      await tester.tap(find.byTooltip('Следующий день'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('Завтра, 2 октября'), findsOneWidget);
      if (reduced) {
        expect(today, findsNothing);
        expect(repository.requestedDays, [oct1, oct2]);
      } else {
        expect(
          tester.getTopLeft(today).dx,
          lessThan(left),
          reason: 'today leaves to the left',
        );
        expect(
          tester.getTopLeft(find.byType(DaySkeleton)).dx,
          inExclusiveRange(left, tester.getSize(find.byType(DayPages)).width),
          reason: 'tomorrow comes from the right',
        );
        expect(repository.requestedDays, [oct1]);
      }

      await tester.pumpAndSettle();
      expect(
        find.bySemanticsLabel('На руки 7\u00A0259 тенге, 3\u00A0поездки'),
        findsOneWidget,
      );
      expect(repository.requestedDays, [oct1, oct2]);
    });
  }

  testWidgets('a far day from the calendar slides in beside the current one, '
      'without the days in between', (tester) async {
    final oct5 = DateTime.utc(2026, 10, 5);
    final repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
    });
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    final today = find.byType(SummaryCard);
    final left = tester.getTopLeft(today).dx;

    await tester.tap(find.byTooltip('Выбрать дату'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(DatePickerDialog),
        matching: find.text('5'),
      ),
    );
    await tester.tap(find.text('ОК'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Понедельник, 5 октября'), findsOneWidget);
    expect(tester.getTopLeft(today).dx, lessThan(left));
    expect(repository.requestedDays, [oct1]);

    await tester.pumpAndSettle();
    expect(find.text('В этот день поездок нет'), findsOneWidget);
    expect(repository.requestedDays, [oct1, oct5]);
  });

  for (final (name, back) in [
    ('the previous day', 'Предыдущий день'),
    ('today', 'Сегодня'),
  ]) {
    testWidgets('going back to $name while the page is still turning shows '
        'it again without a key clash', (tester) async {
      final repository = FakeTripsRepository(
        (date) => date == oct1
            ? Future.value(Result.success(taskExampleReport))
            : Completer<Result<DayReport>>().future,
      );
      await pumpApp(tester, repository);
      await tester.pumpAndSettle();
      final summary = find.byType(SummaryCard);
      final left = tester.getTopLeft(summary).dx;

      if (back == 'Сегодня') {
        await tester.tap(find.byTooltip('Выбрать дату'));
        await tester.pumpAndSettle();
        await tester.tap(
          find.descendant(
            of: find.byType(DatePickerDialog),
            matching: find.text('5'),
          ),
        );
        await tester.tap(find.text('ОК'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 200));
        await tester.tap(_todayButton);
      } else {
        await tester.tap(find.byTooltip('Следующий день'));
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 60));
        await tester.tap(find.byTooltip(back));
      }
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 60));

      expect(tester.takeException(), isNull);
      expect(find.text('Сегодня, 1 октября'), findsOneWidget);
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      expect(summary, findsOneWidget);
      expect(tester.getTopLeft(summary).dx, left);
      expect(repository.requestedDays, [oct1]);
    });
  }

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

  testWidgets('shows a skeleton when the day takes longer than 300 ms to '
      'load', (tester) async {
    final response = Completer<Result<DayReport>>();
    await pumpApp(tester, FakeTripsRepository((_) => response.future));
    await tester.pump(const Duration(milliseconds: 299));

    expect(find.bySemanticsLabel('Загрузка поездок'), findsNothing);

    await tester.pump(const Duration(milliseconds: 1));

    expect(find.byType(DaySkeleton), findsOneWidget);
    expect(find.bySemanticsLabel('Загрузка поездок'), findsOneWidget);
    expect(
      inLiveRegion(tester, find.bySemanticsLabel('Загрузка поездок')),
      isTrue,
    );
    expect(find.byType(SummaryCard), findsNothing);
    expect(_addTripButton.hitTestable(), findsOneWidget);
    final pulse = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(DaySkeleton),
        matching: find.byType(FadeTransition),
      ),
    );
    await tester.pump(const Duration(milliseconds: 450));
    expect(pulse.opacity.value, lessThan(1));

    response.complete(Result.success(taskExampleReport));
    await tester.pumpAndSettle();

    expect(find.byType(DaySkeleton), findsNothing);
    expect(find.byType(SummaryCard), findsOneWidget);
  });

  testWidgets('the skeleton holds still when animations are off', (
    tester,
  ) async {
    tester.platformDispatcher.accessibilityFeaturesTestValue =
        const FakeAccessibilityFeatures(disableAnimations: true);
    addTearDown(tester.platformDispatcher.clearAccessibilityFeaturesTestValue);
    await pumpApp(
      tester,
      FakeTripsRepository((_) => Completer<Result<DayReport>>().future),
    );
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 450));

    final pulse = tester.widget<FadeTransition>(
      find.descendant(
        of: find.byType(DaySkeleton),
        matching: find.byType(FadeTransition),
      ),
    );
    expect(pulse.opacity.value, 1);
  });

  testWidgets('explains a slow load after 3 s and keeps retrying until the '
      'server answers', (tester) async {
    final repository = _answering([
      const Result.error(Failure.connection()),
      const Result.error(Failure.badResponse(statusCode: 503)),
      Result.success(taskExampleReport),
    ]);
    await pumpApp(tester, repository);
    await tester.pump(const Duration(milliseconds: 2900));

    expect(find.byType(DaySkeleton), findsOneWidget);
    expect(find.text(_serverWaking), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text(_serverWaking), findsOneWidget);
    expect(find.bySemanticsLabel(_serverWaking), findsOneWidget);
    expect(inLiveRegion(tester, find.bySemanticsLabel(_serverWaking)), isTrue);
    expect(find.bySemanticsLabel('Загрузка поездок'), findsOneWidget);
    expect(find.text('Не удалось загрузить поездки'), findsNothing);

    await tester.pump(const Duration(seconds: 7));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryCard), findsOneWidget);
    expect(find.text(_serverWaking), findsNothing);
    expect(repository.requestedDays, [oct1, oct1, oct1]);
  });

  testWidgets('offers a retry once the server has not answered for 90 s', (
    tester,
  ) async {
    var online = false;
    final repository = FakeTripsRepository(
      (_) async => online
          ? Result.success(taskExampleReport)
          : const Result.error(Failure.connection()),
    );
    await pumpApp(tester, repository);
    await tester.pump(const Duration(seconds: 89));

    expect(find.text(_serverWaking), findsOneWidget);
    expect(find.text('Не удалось загрузить поездки'), findsNothing);

    await _waitOutRetries(tester);

    expect(find.text(_serverWaking), findsNothing);
    expect(find.text('Не удалось загрузить поездки'), findsOneWidget);
    expect(find.text(const Failure.connection().message), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        'Не удалось загрузить поездки. ${const Failure.connection().message}',
      ),
      findsOneWidget,
    );
    expect(find.byType(SummaryCard), findsNothing);
    final requests = repository.requestedDays.length;

    online = true;
    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();

    expect(find.byType(SummaryCard), findsOneWidget);
    expect(repository.requestedDays, hasLength(requests + 1));
  });

  testWidgets('shows a failure that a retry would not fix at once', (
    tester,
  ) async {
    final repository = _answering([const Result.error(_notFound)]);
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    expect(find.text('Не удалось загрузить поездки'), findsOneWidget);
    expect(find.text(_notFound.message), findsOneWidget);
    expect(repository.requestedDays, [oct1]);
  });

  testWidgets('a slow refresh explains itself above the day', (tester) async {
    final refresh = Completer<Result<DayReport>>();
    final responses = [
      Future.value(Result.success(taskExampleReport)),
      refresh.future,
    ];
    await pumpApp(tester, FakeTripsRepository((_) => responses.removeAt(0)));
    await tester.pumpAndSettle();

    await _pullToRefresh(tester, settle: false);
    await _waitPastSlowLoad(tester);

    expect(find.text(_serverWaking), findsOneWidget);
    expect(
      tester.getRect(find.text(_serverWaking)).bottom,
      lessThan(tester.getRect(find.byType(SummaryCard)).top),
    );

    refresh.complete(Result.success(taskExampleReport));
    await tester.pumpAndSettle();

    expect(find.text(_serverWaking), findsNothing);
  });

  testWidgets('keeps the day on screen when a pull-to-refresh fails and '
      'retries from the banner', (tester) async {
    final repository = _answering([
      Result.success(taskExampleReport),
      const Result.error(_unexpected),
      Result.success(taskExampleReport),
    ]);
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await _pullToRefresh(tester);

    expect(find.text(_unexpected.message), findsOneWidget);
    expect(
      find.bySemanticsLabel('На руки 3\u00A0315 тенге, 2\u00A0поездки'),
      findsOneWidget,
    );

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
        const Result.error(_unexpected),
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
        const Result.error(_notFound),
        Result.success(taskExampleReport),
        const Result.error(_unexpected),
        Result.success(oct2Report),
      ]),
    );
    await tester.pumpAndSettle();
    expect(inLiveRegion(tester, find.text(_notFound.message)), isTrue);

    await tester.tap(find.text('Повторить'));
    await tester.pumpAndSettle();
    await _pullToRefresh(tester);
    expect(inLiveRegion(tester, find.text(_unexpected.message)), isTrue);

    await tester.tap(find.byTooltip('Следующий день'));
    await tester.pump();
    expect(inLiveRegion(tester, find.text('Завтра, 2 октября')), isTrue);
  });

  testWidgets('the day title and «На руки» stop growing at 160%, the rest '
      'of the text grows freely', (tester) async {
    useSmallPhone(tester, textScale: 2);
    await pumpApp(
      tester,
      FakeTripsRepository.withReports({oct1: taskExampleReport}),
    );
    await tester.pumpAndSettle();

    double scaleOf(Finder text) =>
        (tester.widget<Text>(text).textScaler ??
                MediaQuery.textScalerOf(tester.element(text)))
            .scale(10) /
        10;
    expect(scaleOf(find.text('Сегодня, 1 октября')), 1.6);
    expect(scaleOf(find.text('3\u00A0315\u00A0₸')), 1.6);
    expect(scaleOf(find.text('Выручка')), 2);
  });

  for (final (scale, large) in [(1.4, false), (1.5, true)]) {
    testWidgets('from 150% text the title and the «+» of the add button '
        'give way (${scale}x)', (tester) async {
      tester.platformDispatcher.textScaleFactorTestValue = scale;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
      await pumpApp(tester, FakeTripsRepository.withReports({}));
      await tester.pumpAndSettle();

      final shown = large ? findsNothing : findsOneWidget;
      expect(
        find.descendant(of: _addTripButton, matching: find.byType(Icon)),
        shown,
      );
      expect(find.text('Дневник смен'), shown);
    });
  }

  for (final brightness in Brightness.values) {
    testWidgets('at large text «Сегодня» is a «Перейти к сегодня» button '
        'under the day in the ${brightness.name} theme', (tester) async {
      useSmallPhone(tester, brightness: brightness, textScale: 2);
      final repository = FakeTripsRepository.withReports({
        oct1: taskExampleReport,
      });
      await pumpApp(tester, repository);
      await tester.pumpAndSettle();
      expect(_goToTodayButton.hitTestable(), findsNothing);
      expect(find.bySemanticsLabel('Перейти к сегодня'), findsNothing);

      await tester.tap(find.byTooltip('Предыдущий день'));
      await tester.pumpAndSettle();

      expect(_todayButton, findsNothing);
      expect(_goToTodayButton.hitTestable(), findsOneWidget);
      expect(
        tester.getSemantics(_goToTodayButton),
        isSemantics(label: 'Перейти к сегодня', isButton: true),
      );
      expect(
        tester.getRect(_goToTodayButton).top,
        greaterThanOrEqualTo(
          tester.getRect(find.text('Вчера, 30 сентября')).bottom,
        ),
      );
      final colors = Theme.of(tester.element(_goToTodayButton)).colorScheme;
      final background = tester
          .widget<FilledButton>(_goToTodayButton)
          .style
          ?.backgroundColor
          ?.resolve({});
      expect(background, colors.secondaryContainer);

      await tester.tap(_goToTodayButton);
      await tester.pumpAndSettle();

      expect(find.text('Сегодня, 1 октября'), findsOneWidget);
      expect(_goToTodayButton.hitTestable(), findsNothing);
      expect(repository.requestedDays, [oct1, sep30, oct1]);
    });
  }

  for (final scale in [1.0, 1.45]) {
    testWidgets('a ten-digit trip amount at ${scale}x on a 320 dp phone '
        'breaks no word and shows whole', (tester) async {
      useSmallPhone(tester, textScale: scale);
      await pumpApp(
        tester,
        FakeTripsRepository.withReports({oct1: maxAmountReport}),
      );
      await tester.pumpAndSettle();

      final tile = find.byType(TripTile);
      await tester.scrollUntilVisible(tile, 100, scrollable: dayList);
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -100));
      await tester.pumpAndSettle();
      _expectWordsWhole(tester, tile);
      final amount = find.descendant(
        of: tile,
        matching: find.text('2\u00A0147\u00A0483\u00A0647\u00A0₸'),
      );
      _expectWholeInCard(tester, amount, 'the trip amount');
    });
  }

  for (final (width, scales) in [
    (320.0, [1.15, 1.35]),
    (360.0, [1.35, 1.45]),
  ]) {
    for (final scale in scales) {
      testWidgets('«Наличные» and «Карта» stay whole in the summary at '
          '${scale}x on a ${width.toInt()} dp phone', (tester) async {
        tester.view
          ..physicalSize = Size(width, 800)
          ..devicePixelRatio = 1;
        tester.platformDispatcher.textScaleFactorTestValue = scale;
        addTearDown(tester.view.reset);
        addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);
        await pumpApp(
          tester,
          FakeTripsRepository.withReports({oct1: taskExampleReport}),
        );
        await tester.pumpAndSettle();

        _expectWordsWhole(tester, find.byType(SummaryCard));
      });
    }
  }

  for (final brightness in Brightness.values) {
    testWidgets('on iOS every button press darkens by 8% of onSurface in the '
        '${brightness.name} theme', (tester) async {
      tester.platformDispatcher.platformBrightnessTestValue = brightness;
      addTearDown(tester.platformDispatcher.clearAllTestValues);
      await pumpApp(
        tester,
        FakeTripsRepository.withReports({
          oct1: taskExampleReport,
          oct2: oct2Report,
        }),
      );
      await tester.pumpAndSettle();
      final context = tester.element(_addTripButton);
      final expected = Theme.of(context).colorScheme.onSurface
          .withValues(alpha: 0.08);
      Color? pressed(ButtonStyle? style) =>
          style?.overlayColor?.resolve({WidgetState.pressed});

      expect(
        tester.widget<FilledButton>(_addTripButton).style,
        isNull,
        reason: 'the add button takes the theme style',
      );
      expect(pressed(FilledButtonTheme.of(context).style), expected);
      expect(
        pressed(
          tester
              .widget<TextButton>(
                find.ancestor(
                  of: find.text('Сегодня, 1 октября'),
                  matching: find.byType(TextButton),
                ),
              )
              .style,
        ),
        expected,
      );
      final arrow = tester.widget<IconButton>(
        find.widgetWithIcon(IconButton, CupertinoIcons.chevron_right),
      );
      expect(
        arrow.style?.overlayColor?.resolve({WidgetState.pressed}),
        expected,
      );
    }, variant: TargetPlatformVariant.only(TargetPlatform.iOS));
  }

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
        await tester.scrollUntilVisible(
          find.bySemanticsLabel('Комиссия 585 тенге'),
          100,
          scrollable: dayList,
        );
        await tester.drag(dayList, const Offset(0, 2000));
        await tester.pumpAndSettle();
        _expectSummaryOrder(tester, sideBySide: false);
        await tester.scrollUntilVisible(
          find.text('09:05\u00A0– 09:20'),
          100,
          scrollable: dayList,
        );
        expect(
          find.bySemanticsLabel(
            'С 09:05 до 09:20, наличные, 1\u00A0500 тенге, комиссия 225 тенге',
          ),
          findsOneWidget,
        );
      });

      testWidgets('a day with a trip past midnight', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          FakeTripsRepository.withReports({oct2: oct2Report}),
        );
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Следующий день'));
        await tester.pumpAndSettle();

        expect(find.text('Дневник смен'), findsNothing);
        expect(_goToTodayButton.hitTestable(), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('+1 день'),
          100,
          scrollable: dayList,
        );
        await tester.scrollUntilVisible(
          find.text('4\u00A0600\u00A0₸'),
          100,
          scrollable: dayList,
        );
        final times = tester.getRect(find.text('23:50\u00A0– 00:20'));
        final badge = tester.getRect(find.text('+1 день'));
        expect(
          badge.top,
          greaterThanOrEqualTo(times.bottom),
          reason: '«+1 день» takes its own line',
        );
        _expectWholeOnOneLine(tester, '4\u00A0600\u00A0₸');
      });

      testWidgets('a long day scrolls above the add button', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          FakeTripsRepository.withReports({oct1: longReport}),
        );
        await tester.pumpAndSettle();

        await tester.drag(
          find.byType(CustomScrollView),
          const Offset(0, -20000),
        );
        await tester.pumpAndSettle();

        final lastAmount = tester.getRect(find.text('2\u00A0100\u00A0₸'));
        expect(
          tester.getRect(_addTripButton).top - lastAmount.bottom,
          greaterThanOrEqualTo(16),
        );
      });

      testWidgets('seven-digit amounts shrink to fit instead of breaking', (
        tester,
      ) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          FakeTripsRepository.withReports({oct1: bigSumsReport}),
        );
        await tester.pumpAndSettle();

        for (final amount in [
          '1\u00A0452\u00A0432\u00A0₸',
          '217\u00A0865\u00A0₸',
          '1\u00A0234\u00A0567\u00A0₸',
          '652\u00A0432\u00A0₸',
          '800\u00A0000\u00A0₸',
        ]) {
          await tester.scrollUntilVisible(
            find.text(amount).first,
            100,
            scrollable: dayList,
          );
          _expectWholeOnOneLine(tester, amount);
        }
        await tester.scrollUntilVisible(
          find.text('10:00\u00A0– 11:30'),
          100,
          scrollable: dayList,
        );
        await tester.scrollUntilVisible(
          find.text('800\u00A0000\u00A0₸').last,
          100,
          scrollable: dayList,
        );
        _expectWholeOnOneLine(tester, '800\u00A0000\u00A0₸');
      });

      testWidgets('loading', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(
          tester,
          FakeTripsRepository((_) => Completer<Result<DayReport>>().future),
        );
        await tester.pump(const Duration(milliseconds: 300));
        await tester.pump(const Duration(milliseconds: 450));

        expect(find.bySemanticsLabel('Загрузка поездок'), findsOneWidget);

        await _waitPastSlowLoad(tester);

        expect(find.text(_serverWaking), findsOneWidget);
      });

      testWidgets('an empty day', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(tester, FakeTripsRepository.withReports({}));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('В этот день поездок нет'),
          100,
          scrollable: dayList,
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
        await _waitOutRetries(tester);

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
        await _pullToRefresh(tester, settle: false);
        await _waitPastSlowLoad(tester);

        expect(find.text(_serverWaking), findsOneWidget);

        await _waitOutRetries(tester);

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
