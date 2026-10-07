import 'dart:async';

import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_skeleton.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/diary_mode_segments.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_day_tile.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_report_view.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/summary_card.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/trip_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';
import '../../../../../helpers/period_reports.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/semantics.dart';
import '../../../../../helpers/text_layout.dart';

final DateTime _oct31 = DateTime.utc(2026, 10, 31);

FakeTripsRepository _seedRepository() {
  final reports = {oct1: taskExampleReport, oct2: oct2Report};
  return FakeTripsRepository(
    (date) async => Result.success(reports[date] ?? emptyReport(date)),
    onGetPeriod: (start, end) async => Result.success(
      start == sep28 && end == oct4
          ? seedWeekReport
          : periodReportOf(start, end, reports),
    ),
  );
}

Finder get _periodList => find
    .descendant(
      of: find.byType(PeriodReportView),
      matching: find.byType(Scrollable),
    )
    .first;

Future<void> _choose(WidgetTester tester, String mode) async {
  await tester.tap(
    find.descendant(
      of: find.byType(DiaryModeSegments),
      matching: find.text(mode),
    ),
  );
  await tester.pumpAndSettle();
}

DiaryMode _selectedMode(WidgetTester tester) => tester
    .widget<SegmentedButton<DiaryMode>>(find.byType(SegmentedButton<DiaryMode>))
    .selected
    .single;

void _useTallPhone(WidgetTester tester) {
  tester.view
    ..physicalSize = const Size(400, 2400)
    ..devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

List<DateTime> _rowDays(WidgetTester tester) => [
  for (final tile in tester.widgetList<PeriodDayTile>(
    find.byType(PeriodDayTile),
  ))
    tile.total.date,
];

void main() {
  testWidgets('«День · Неделя · Месяц» sits above the day, which stays the '
      'first mode', (tester) async {
    await pumpApp(tester, _seedRepository());
    await tester.pumpAndSettle();

    expect(_selectedMode(tester), DiaryMode.day);
    expect(find.text('День'), findsOneWidget);
    expect(find.text('Неделя'), findsOneWidget);
    expect(find.text('Месяц'), findsOneWidget);
    expect(
      tester.getRect(find.byType(DiaryModeSegments)).bottom,
      lessThanOrEqualTo(tester.getRect(find.text('Сегодня, 1 октября')).top),
    );
  });

  testWidgets('a week shows the server summary and every day from Monday to '
      'Sunday, empty days included', (tester) async {
    _useTallPhone(tester);
    final repository = _seedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await _choose(tester, 'Неделя');

    expect(_selectedMode(tester), DiaryMode.week);
    expect(find.text('Эта неделя'), findsOneWidget);
    expect(repository.requestedPeriods, [(sep28, oct4)]);
    expect(
      find.bySemanticsLabel('На руки 17 884 тенге, 9 поездок'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('Выручка 21 040 тенге'), findsOneWidget);
    expect(find.byType(SummaryCard), findsOneWidget);
    expect(_rowDays(tester), [
      for (var day = 28; day <= 34; day++) DateTime.utc(2026, 9, day),
    ]);
    expect(
      find.bySemanticsLabel(
        'Среда, 30 сентября: 3 поездки, на руки 6 035 тенге',
      ),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel(
        'Понедельник, 28 сентября: нет поездок, на руки 0 тенге',
      ),
      findsOneWidget,
    );
    expect(find.text('Добавить поездку'), findsOneWidget);
  });

  testWidgets('the net bars are the day net against the best day of the '
      'period', (tester) async {
    _useTallPhone(tester);
    await pumpApp(tester, _seedRepository());
    await tester.pumpAndSettle();
    await _choose(tester, 'Неделя');

    double barShare(DateTime day) => tester
        .widget<FractionallySizedBox>(
          find.descendant(
            of: find.byWidgetPredicate(
              (widget) => widget is PeriodDayTile && widget.total.date == day,
            ),
            matching: find.byType(FractionallySizedBox),
          ),
        )
        .widthFactor!;

    expect(barShare(oct2), 1);
    expect(barShare(oct1), closeTo(3315 / 7259, 1e-9));
    expect(barShare(sep28), 0);
  });

  testWidgets('a month lists only the days with trips', (tester) async {
    _useTallPhone(tester);
    final repository = _seedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();

    await _choose(tester, 'Месяц');

    expect(find.text('Этот месяц'), findsOneWidget);
    expect(repository.requestedPeriods, [(oct1, _oct31)]);
    expect(_rowDays(tester), [oct1, oct2]);
    expect(
      find.bySemanticsLabel('На руки 10 574 тенге, 5 поездок'),
      findsOneWidget,
    );
  });

  testWidgets('tapping a day opens it in the day mode', (tester) async {
    final repository = _seedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _choose(tester, 'Неделя');

    final row = find.bySemanticsLabel(RegExp('^Пятница, 2'));
    await tester.scrollUntilVisible(row, 100, scrollable: _periodList);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    expect(_selectedMode(tester), DiaryMode.day);
    expect(find.text('Завтра, 2 октября'), findsOneWidget);
    expect(repository.requestedDays.last, oct2);
    expect(find.byType(TripTile), findsWidgets);
    expect(
      find.bySemanticsLabel('На руки 7 259 тенге, 3 поездки'),
      findsOneWidget,
    );
  });

  testWidgets('going back to the day mode shows the day that was open, '
      'reloaded', (tester) async {
    final repository = _seedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await tester.tap(find.byTooltip('Следующий день'));
    await tester.pumpAndSettle();

    await _choose(tester, 'Неделя');
    await _choose(tester, 'Месяц');
    await _choose(tester, 'День');

    expect(find.text('Завтра, 2 октября'), findsOneWidget);
    expect(repository.requestedDays, [oct1, oct2, oct2]);
    expect(repository.requestedPeriods, [(sep28, oct4), (oct1, _oct31)]);
  });

  testWidgets('arrows and a swipe turn the weeks, and «Сегодня» brings back '
      'this week', (tester) async {
    final repository = _seedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _choose(tester, 'Неделя');
    final todayButton = find.widgetWithText(TextButton, 'Сегодня');
    expect(todayButton.hitTestable(), findsNothing);

    await tester.tap(find.byTooltip('Предыдущая неделя'));
    await tester.pumpAndSettle();
    expect(find.text('21 сент – 27 сент'), findsOneWidget);
    expect(repository.requestedPeriods.last, (
      DateTime.utc(2026, 9, 21),
      DateTime.utc(2026, 9, 27),
    ));
    expect(find.text('За эту неделю поездок нет'), findsOneWidget);

    await tester.tap(todayButton);
    await tester.pumpAndSettle();
    expect(find.text('Эта неделя'), findsOneWidget);

    await tester.fling(
      find.byType(PeriodReportView),
      const Offset(-300, 0),
      1000,
    );
    await tester.pumpAndSettle();
    expect(find.text('5 окт – 11 окт'), findsOneWidget);
    expect(repository.requestedPeriods.last, (
      DateTime.utc(2026, 10, 5),
      DateTime.utc(2026, 10, 11),
    ));
  });

  testWidgets('months are named by the month, with the year', (tester) async {
    final repository = _seedRepository();
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await _choose(tester, 'Месяц');

    await tester.tap(find.byTooltip('Следующий месяц'));
    await tester.pumpAndSettle();

    expect(find.text('Ноябрь 2026'), findsOneWidget);
    expect(find.text('За этот месяц поездок нет'), findsOneWidget);
    expect(repository.requestedPeriods.last, (
      DateTime.utc(2026, 11),
      DateTime.utc(2026, 11, 30),
    ));
  });

  testWidgets('a week across the new year names both years', (tester) async {
    await pumpApp(
      tester,
      _seedRepository(),
      now: () => DateTime.utc(2027, 1, 6, 6),
    );
    await tester.pumpAndSettle();
    await _choose(tester, 'Неделя');

    await tester.tap(find.byTooltip('Предыдущая неделя'));
    await tester.pumpAndSettle();
    expect(find.text('28 дек 2026 – 3 янв 2027'), findsOneWidget);
  });

  testWidgets('screen readers hear the new period and each day as one '
      'phrase', (tester) async {
    final semantics = tester.ensureSemantics();
    await pumpApp(tester, _seedRepository());
    await tester.pumpAndSettle();
    await _choose(tester, 'Неделя');

    expect(inLiveRegion(tester, find.text('Эта неделя')), isTrue);
    final row = find.bySemanticsLabel(RegExp('^Четверг, 1'));
    await tester.scrollUntilVisible(row, 100, scrollable: _periodList);
    final node = tester.getSemantics(row);
    expect(node.label, 'Четверг, 1 октября: 2 поездки, на руки 3 315 тенге');
    expect(node.flagsCollection.isButton, isTrue);
    semantics.dispose();
  });

  testWidgets('a slow period explains itself, retries, and offers a retry '
      'after 90 s', (tester) async {
    final repository = FakeTripsRepository(
      (date) async => Result.success(emptyReport(date)),
      onGetPeriod: (_, _) async => const Result.error(Failure.connection()),
    );
    await pumpApp(tester, repository);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Неделя'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(DaySkeleton), findsOneWidget);
    expect(
      find.text('Сервер просыпается после простоя — это занимает до минуты'),
      findsOneWidget,
    );

    await tester.pump(const Duration(seconds: 95));
    await tester.pumpAndSettle();
    expect(find.text('Не удалось загрузить сводку'), findsOneWidget);
    expect(find.text('Повторить'), findsOneWidget);
  });

  for (final scale in [1.0, 1.3, 1.45]) {
    testWidgets('day rows keep their words whole at ${scale}x on a 320 dp '
        'phone', (tester) async {
      useSmallPhone(tester, textScale: scale);
      await pumpApp(tester, _seedRepository());
      await tester.pumpAndSettle();
      await _choose(tester, 'Неделя');

      for (var day = 28; day <= 34; day++) {
        final row = find.byWidgetPredicate(
          (widget) =>
              widget is PeriodDayTile &&
              widget.total.date == DateTime.utc(2026, 9, day),
        );
        await tester.scrollUntilVisible(row, 100, scrollable: _periodList);
        await tester.pumpAndSettle();
        expectWordsWhole(tester, row);
      }
    });
  }

  for (final brightness in Brightness.values) {
    group('at 200% text in the ${brightness.name} theme on a small phone', () {
      Future<void> pumpWeek(
        WidgetTester tester,
        FakeTripsRepository repository, {
        String mode = 'Неделя',
        bool settle = true,
      }) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(tester, repository);
        await tester.pumpAndSettle();
        await tester.tap(find.text(mode));
        if (settle) await tester.pumpAndSettle();
      }

      testWidgets('a week with trips', (tester) async {
        await pumpWeek(tester, _seedRepository());

        expect(
          Theme.of(tester.element(find.byType(SummaryCard)))
              .colorScheme
              .brightness,
          brightness,
        );
        expectWordsWhole(tester, find.byType(DiaryModeSegments));
        expectWordsWhole(tester, find.text('Эта неделя'));
        await tester.scrollUntilVisible(
          find.bySemanticsLabel(RegExp('^Воскресенье')),
          100,
          scrollable: _periodList,
        );
        await tester.pumpAndSettle();
        expect(
          find.bySemanticsLabel(
            'Воскресенье, 4 октября: нет поездок, на руки 0 тенге',
          ),
          findsOneWidget,
        );
      });

      testWidgets('a past week has a «Перейти к сегодня» button', (
        tester,
      ) async {
        await pumpWeek(tester, _seedRepository());

        await tester.tap(find.byTooltip('Предыдущая неделя'));
        await tester.pumpAndSettle();
        expectWordsWhole(tester, find.text('21 сент – 27 сент'));
        expect(find.text('За эту неделю поездок нет'), findsOneWidget);

        await tester.tap(find.text('Перейти к сегодня'));
        await tester.pumpAndSettle();
        expect(find.text('Эта неделя'), findsOneWidget);
      });

      testWidgets('a month with seven-digit sums', (tester) async {
        await pumpWeek(
          tester,
          FakeTripsRepository.withReports({
            oct1: bigSumsReport,
            oct2: maxAmountReport.copyWith(date: oct2),
          }),
          mode: 'Месяц',
        );

        final last = find.byWidgetPredicate(
          (widget) => widget is PeriodDayTile && widget.total.date == oct2,
        );
        await tester.scrollUntilVisible(last, 100, scrollable: _periodList);
        await tester.pumpAndSettle();
        expect(_rowDays(tester), contains(oct2));
      });

      testWidgets('loading and an error', (tester) async {
        final responses = <Completer<Result<PeriodReport>>>[];
        await pumpWeek(
          tester,
          FakeTripsRepository(
            (date) async => Result.success(emptyReport(date)),
            onGetPeriod: (_, _) {
              final response = Completer<Result<PeriodReport>>();
              responses.add(response);
              return response.future;
            },
          ),
          settle: false,
        );
        await tester.pump(const Duration(seconds: 4));
        expect(find.byType(DaySkeleton), findsOneWidget);

        responses.last.complete(
          const Result.error(Failure.badResponse(statusCode: 404)),
        );
        await tester.pumpAndSettle();
        expect(find.text('Не удалось загрузить сводку'), findsOneWidget);
      });
    });
  }
}
