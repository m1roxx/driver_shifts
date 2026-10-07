import 'dart:async';

import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_skeleton.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/diary_mode_segments.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_day_tile.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_report_view.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_stats_row.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_switcher.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/sliding_segmented_control.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/summary_card.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/trip_tile.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/week_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';
import '../../../../../helpers/period_reports.dart';
import '../../../../../helpers/pump_app.dart';
import '../../../../../helpers/semantics.dart';
import '../../../../../helpers/text_layout.dart';

final DateTime _oct31 = DateTime.utc(2026, 10, 31);

DateTime _friday() => DateTime.utc(2026, 10, 2, 12);

String _nb(String text) => text.replaceAll(' ', ' ');

String _range(String start, String end) => '${_nb(start)} –⁠ ${_nb(end)}';

final String _thisSeedWeek = 'Эта неделя, ${_range('28 сент', '4 окт')}';

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

Finder _title(String title) => find.descendant(
  of: find.byType(PeriodSwitcher),
  matching: find.bySemanticsLabel(title),
);

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
    .widget<SlidingSegmentedControl<DiaryMode>>(
      find.byType(SlidingSegmentedControl<DiaryMode>),
    )
    .selected;

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

Finder _bar(String spokenStart) => find.descendant(
  of: find.byType(WeekChart),
  matching: find.bySemanticsLabel(RegExp('^$spokenStart')),
);

Finder _fillsIn(Finder within, Color color) => find.descendant(
  of: within,
  matching: find.byWidgetPredicate(
    (widget) =>
        widget is DecoratedBox &&
        widget.decoration is BoxDecoration &&
        (widget.decoration as BoxDecoration).color == color,
  ),
);

Future<void> _scrollTo(WidgetTester tester, Finder finder) async {
  await tester.scrollUntilVisible(finder, 100, scrollable: _periodList);
  await tester.pumpAndSettle();
}

void main() {
  group('the mode switch', () {
    testWidgets('takes the place of the title in the app bar and opens on '
        'the day', (tester) async {
      await pumpApp(tester, _seedRepository());
      await tester.pumpAndSettle();

      expect(_selectedMode(tester), DiaryMode.day);
      expect(
        find.descendant(
          of: find.byType(AppBar),
          matching: find.byType(DiaryModeSegments),
        ),
        findsOneWidget,
      );
      expect(find.text('Дневник смен'), findsNothing);
      expect(find.text('Сегодня, 1 октября'), findsOneWidget);
    });

    testWidgets('slides its thumb to the chosen mode with a selection click, '
        'and reads each mode as a selectable button', (tester) async {
      final semantics = tester.ensureSemantics();
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
      await pumpApp(tester, _seedRepository());
      await tester.pumpAndSettle();
      Alignment thumb() =>
          tester.widget<AnimatedAlign>(find.byType(AnimatedAlign)).alignment
              as Alignment;
      expect(thumb().x, -1);

      await _choose(tester, 'Неделя');

      expect(thumb().x, 0);
      expect(haptics, contains('HapticFeedbackType.selectionClick'));
      final week = tester.getSemantics(find.bySemanticsLabel('Неделя'));
      final day = tester.getSemantics(find.bySemanticsLabel('День'));
      expect(
        week,
        isSemantics(
          isButton: true,
          isSelected: true,
          isInMutuallyExclusiveGroup: true,
        ),
      );
      expect(day, isSemantics(isButton: true, isSelected: false));

      haptics.clear();
      await _choose(tester, 'Неделя');
      expect(haptics, isEmpty);
      semantics.dispose();
    });

    for (final brightness in Brightness.values) {
      testWidgets('at 200% on 320 dp in the ${brightness.name} theme gets its '
          'own row, grows and keeps words whole', (tester) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(tester, _seedRepository());
        await tester.pumpAndSettle();

        expect(find.byType(AppBar), findsNothing);
        final control = find.byType(SlidingSegmentedControl<DiaryMode>);
        expect(
          tester.getSize(control).height,
          greaterThan(Sizes.segmentedControl),
        );
        expect(
          tester.getRect(control).bottom,
          lessThanOrEqualTo(
            tester.getRect(find.text('Сегодня, 1 октября')).top,
          ),
        );
        expectWordsWhole(tester, control);
        await _choose(tester, 'Месяц');
        expect(_selectedMode(tester), DiaryMode.month);
      });
    }
  });

  group('a week', () {
    testWidgets('shows the server summary, its stats and a bar for every day '
        'from Monday to Sunday', (tester) async {
      _useTallPhone(tester);
      final repository = _seedRepository();
      await pumpApp(tester, repository, now: _friday);
      await tester.pumpAndSettle();

      await _choose(tester, 'Неделя');

      expect(_selectedMode(tester), DiaryMode.week);
      expect(_title(_thisSeedWeek), findsOneWidget);
      expect(repository.requestedPeriods, [(sep28, oct4)]);
      expect(
        find.bySemanticsLabel('На руки 17 884 тенге, 9 поездок'),
        findsOneWidget,
      );
      expect(find.byType(SummaryCard), findsOneWidget);
      for (final weekday in ['Пн', 'Вт', 'Ср', 'Чт', 'Пт', 'Сб', 'Вс']) {
        expect(
          find.descendant(
            of: find.byType(WeekChart),
            matching: find.text(weekday),
          ),
          findsOneWidget,
        );
      }
      expect(find.byType(PeriodDayTile), findsNothing);
      expect(find.text('Добавить поездку'), findsOneWidget);
    });

    testWidgets('highlights the best day with its amount, scales the others '
        'to it and leaves the days ahead empty', (tester) async {
      _useTallPhone(tester);
      await pumpApp(tester, _seedRepository(), now: _friday);
      await tester.pumpAndSettle();
      await _choose(tester, 'Неделя');
      final colors = Theme.of(tester.element(find.byType(WeekChart)))
          .colorScheme;

      final friday = _bar('Пятница, 2');
      expect(_fillsIn(friday, colors.primary), findsOneWidget);
      expect(_fillsIn(find.byType(WeekChart), colors.primary), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(WeekChart),
          matching: find.text(_nb('7 259 ₸')),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(_fillsIn(friday, colors.primary)).height,
        Sizes.weekChart,
      );
      expect(
        tester
            .getSize(_fillsIn(_bar('Четверг, 1'), colors.primaryContainer))
            .height,
        closeTo(3315 / 7259 * Sizes.weekChart, 0.01),
      );
      expect(
        tester
            .getSize(_fillsIn(_bar('Понедельник'), colors.outlineVariant))
            .height,
        Sizes.chartStub,
      );
      expect(_bar('Суббота'), findsNothing);
      expect(_bar('Воскресенье'), findsNothing);
      expect(
        _fillsIn(find.byType(WeekChart), colors.surfaceContainerHighest),
        findsNWidgets(7),
      );
      expect(
        _fillsIn(find.byType(WeekChart), colors.primaryContainer),
        findsNWidgets(2),
      );
    });

    testWidgets('a bar is read as one phrase and opens its day', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      final repository = _seedRepository();
      await pumpApp(tester, repository, now: _friday);
      await tester.pumpAndSettle();
      await _choose(tester, 'Неделя');

      final thursday = _bar('Четверг, 1');
      await _scrollTo(tester, thursday);
      final node = tester.getSemantics(thursday);
      expect(node.label, 'Четверг, 1 октября: 2 поездки, на руки 3 315 тенге');
      expect(node.flagsCollection.isButton, isTrue);

      await tester.tap(thursday);
      await tester.pumpAndSettle();

      expect(_selectedMode(tester), DiaryMode.day);
      expect(find.text('Вчера, 1 октября'), findsOneWidget);
      expect(repository.requestedDays.last, oct1);
      expect(find.byType(TripTile), findsWidgets);
      semantics.dispose();
    });

    testWidgets('a week still ahead shows the empty period without stats', (
      tester,
    ) async {
      await pumpApp(tester, _seedRepository());
      await tester.pumpAndSettle();
      await _choose(tester, 'Неделя');

      await tester.tap(find.byTooltip('Следующая неделя'));
      await tester.pumpAndSettle();

      expect(_title(_range('5', '11 окт')), findsOneWidget);
      expect(find.text('За эту неделю поездок нет'), findsOneWidget);
      expect(find.byType(WeekChart), findsNothing);
      expect(find.byType(PeriodStatsRow), findsNothing);
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
      expect(_title(_range('21', '27 сент')), findsOneWidget);
      expect(repository.requestedPeriods.last, (
        DateTime.utc(2026, 9, 21),
        DateTime.utc(2026, 9, 27),
      ));
      expect(find.text('За эту неделю поездок нет'), findsOneWidget);

      await tester.tap(todayButton);
      await tester.pumpAndSettle();
      expect(_title(_thisSeedWeek), findsOneWidget);

      await tester.fling(
        find.byType(PeriodReportView),
        const Offset(-300, 0),
        1000,
      );
      await tester.pumpAndSettle();
      expect(_title(_range('5', '11 окт')), findsOneWidget);
      expect(repository.requestedPeriods.last, (
        DateTime.utc(2026, 10, 5),
        DateTime.utc(2026, 10, 11),
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
      expect(_title(_range('28 дек 2026', '3 янв 2027')), findsOneWidget);
    });

    testWidgets('screen readers hear the new period in a live region', (
      tester,
    ) async {
      final semantics = tester.ensureSemantics();
      await pumpApp(tester, _seedRepository());
      await tester.pumpAndSettle();
      await _choose(tester, 'Неделя');

      expect(inLiveRegion(tester, _title(_thisSeedWeek)), isTrue);
      expect(find.bySemanticsLabel(_thisSeedWeek), findsOneWidget);
      semantics.dispose();
    });
  });

  group('stats', () {
    testWidgets('show the server values under the summary', (tester) async {
      tester.view
        ..physicalSize = const Size(800, 2400)
        ..devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await pumpApp(tester, _seedRepository(), now: _friday);
      await tester.pumpAndSettle();
      await _choose(tester, 'Неделя');

      final average = find.bySemanticsLabel('Средний чек 2 338 тенге');
      final perHour = find.bySemanticsLabel('В час в поездках 4 727 тенге');
      final best = find.bySemanticsLabel(
        'Лучший день: Пятница, 2 октября, на руки 7 259 тенге',
      );
      expect(average, findsOneWidget);
      expect(perHour, findsOneWidget);
      expect(best, findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(PeriodStatsRow),
          matching: find.text('Пт, 2 окт'),
        ),
        findsOneWidget,
      );
      expect(
        tester.getRect(find.byType(SummaryCard)).bottom,
        lessThanOrEqualTo(tester.getRect(average).top),
      );
      expect(tester.getRect(perHour).top, tester.getRect(average).top);
      expect(tester.getRect(best).top, tester.getRect(average).top);
    });

    for (final brightness in Brightness.values) {
      testWidgets('stack at 200% on 320 dp in the ${brightness.name} theme', (
        tester,
      ) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(tester, _seedRepository(), now: _friday);
        await tester.pumpAndSettle();
        await _choose(tester, 'Неделя');

        final average = find.bySemanticsLabel(RegExp('^Средний чек'));
        final perHour = find.bySemanticsLabel(RegExp('^В час в поездках'));
        final best = find.bySemanticsLabel(RegExp('^Лучший день'));
        await _scrollTo(tester, best);
        expectWordsWhole(tester, find.byType(PeriodStatsRow));
        expect(
          tester.getRect(perHour).top,
          greaterThanOrEqualTo(tester.getRect(average).bottom),
        );
        expect(
          tester.getRect(best).top,
          greaterThanOrEqualTo(tester.getRect(perHour).bottom),
        );
      });
    }
  });

  group('a month', () {
    testWidgets('lists only the days with trips, named by month and year', (
      tester,
    ) async {
      _useTallPhone(tester);
      final repository = _seedRepository();
      await pumpApp(tester, repository);
      await tester.pumpAndSettle();

      await _choose(tester, 'Месяц');

      expect(find.text('Октябрь 2026'), findsOneWidget);
      expect(repository.requestedPeriods, [(oct1, _oct31)]);
      expect(_rowDays(tester), [oct1, oct2]);
      expect(find.byType(WeekChart), findsNothing);
      expect(
        find.bySemanticsLabel('На руки 10 574 тенге, 5 поездок'),
        findsOneWidget,
      );
    });

    testWidgets('scales the row bars to the best day of the server', (
      tester,
    ) async {
      _useTallPhone(tester);
      await pumpApp(tester, _seedRepository());
      await tester.pumpAndSettle();
      await _choose(tester, 'Месяц');

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
    });

    testWidgets('a row is read as one phrase and opens its day', (
      tester,
    ) async {
      final repository = _seedRepository();
      await pumpApp(tester, repository);
      await tester.pumpAndSettle();
      await _choose(tester, 'Месяц');

      final row = find.bySemanticsLabel(RegExp('^Пятница, 2'));
      await _scrollTo(tester, row);
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(_selectedMode(tester), DiaryMode.day);
      expect(find.text('Завтра, 2 октября'), findsOneWidget);
      expect(repository.requestedDays.last, oct2);
    });

    testWidgets('a month ahead is empty', (tester) async {
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

    for (final scale in [1.0, 1.3, 1.45]) {
      testWidgets('rows keep their words whole at ${scale}x on a 320 dp '
          'phone', (tester) async {
        useSmallPhone(tester, textScale: scale);
        final reports = <DateTime, DayReport>{
          for (var day = 27; day <= 30; day++)
            DateTime.utc(2026, 9, day): taskExampleReport.copyWith(
              date: DateTime.utc(2026, 9, day),
            ),
        };
        await pumpApp(tester, FakeTripsRepository.withReports(reports));
        await tester.pumpAndSettle();
        await _choose(tester, 'Месяц');
        await tester.tap(find.byTooltip('Предыдущий месяц'));
        await tester.pumpAndSettle();

        for (final day in reports.keys) {
          final row = find.byWidgetPredicate(
            (widget) => widget is PeriodDayTile && widget.total.date == day,
          );
          await _scrollTo(tester, row);
          expectWordsWhole(tester, row);
        }
      });
    }
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

  for (final brightness in Brightness.values) {
    group('at 200% text in the ${brightness.name} theme on a small phone', () {
      Future<void> pumpMode(
        WidgetTester tester,
        FakeTripsRepository repository, {
        String mode = 'Неделя',
        bool settle = true,
        DateTime Function()? now,
      }) async {
        useSmallPhone(tester, brightness: brightness, textScale: 2);
        await pumpApp(tester, repository, now: now);
        await tester.pumpAndSettle();
        await tester.tap(find.text(mode));
        if (settle) await tester.pumpAndSettle();
      }

      testWidgets('this week turns back into a list of days up to today', (
        tester,
      ) async {
        await pumpMode(tester, _seedRepository());

        expect(
          Theme.of(tester.element(find.byType(SummaryCard)))
              .colorScheme
              .brightness,
          brightness,
        );
        expectWordsWhole(tester, _title(_thisSeedWeek));
        expect(find.byType(WeekChart), findsNothing);
        await _scrollTo(tester, find.bySemanticsLabel(RegExp('^Четверг')));
        expect(_rowDays(tester), contains(oct1));
        expect(_rowDays(tester), isNot(contains(oct2)));
      });

      testWidgets('a past week lists all seven days', (tester) async {
        await pumpMode(
          tester,
          _seedRepository(),
          now: () => DateTime.utc(2026, 10, 7, 6),
        );
        await tester.tap(find.byTooltip('Предыдущая неделя'));
        await tester.pumpAndSettle();

        expectWordsWhole(tester, _title(_range('28 сент', '4 окт')));
        final sunday = find.byWidgetPredicate(
          (widget) => widget is PeriodDayTile && widget.total.date == oct4,
        );
        await _scrollTo(tester, sunday);
        expect(_rowDays(tester), contains(oct4));

        await tester.tap(find.text('Перейти к сегодня'));
        await tester.pumpAndSettle();
        expect(_title('Эта неделя, ${_range('5', '11 окт')}'), findsOneWidget);
      });

      testWidgets('a month with ten-digit sums', (tester) async {
        await pumpMode(
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
        await _scrollTo(tester, last);
        expect(_rowDays(tester), contains(oct2));
      });

      testWidgets('loading and an error', (tester) async {
        final responses = <Completer<Result<PeriodReport>>>[];
        await pumpMode(
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
