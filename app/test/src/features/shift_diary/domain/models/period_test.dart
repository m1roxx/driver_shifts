import 'dart:convert';

import 'package:driver_shifts/src/features/shift_diary/domain/models/day_summary.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/period_reports.dart';

Period _week(int year, int month, int day) =>
    Period.containing(PeriodKind.week, DateTime.utc(year, month, day));

Period _month(int year, int month) =>
    Period.containing(PeriodKind.month, DateTime.utc(year, month, 17));

void main() {
  group('a week', () {
    test('runs from Monday to Sunday', () {
      for (var day = 28; day <= 34; day++) {
        final week = _week(2026, 9, day);
        expect(week.start, DateTime.utc(2026, 9, 28), reason: '$day');
        expect(week.end, DateTime.utc(2026, 10, 4), reason: '$day');
      }
    });

    test('crosses a year and steps by seven days', () {
      final week = _week(2026, 12, 31);

      expect(week.start, DateTime.utc(2026, 12, 28));
      expect(week.end, DateTime.utc(2027, 1, 3));
      expect(week.next.start, DateTime.utc(2027, 1, 4));
      expect(week.previous.start, DateTime.utc(2026, 12, 21));
      expect(week.next.periodsSince(week.previous), 2);
    });
  });

  group('a month', () {
    test('is its calendar month, a leap February included', () {
      expect(_month(2028, 2).start, DateTime.utc(2028, 2));
      expect(_month(2028, 2).end, DateTime.utc(2028, 2, 29));
      expect(_month(2026, 2).end, DateTime.utc(2026, 2, 28));
      expect(_month(2026, 10).end, DateTime.utc(2026, 10, 31));
    });

    test('steps across a year', () {
      expect(_month(2026, 12).next, _month(2027, 1));
      expect(_month(2027, 1).previous, _month(2026, 12));
      expect(_month(2027, 2).periodsSince(_month(2026, 11)), 3);
    });
  });

  test('takes only a period start, so a day goes through '
      'Period.containing', () {
    expect(
      () => Period(kind: PeriodKind.week, start: DateTime.utc(2026, 10, 7)),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => Period(kind: PeriodKind.month, start: DateTime.utc(2026, 10, 2)),
      throwsA(isA<AssertionError>()),
    );
    expect(
      () => Period(kind: PeriodKind.month, start: DateTime(2026, 10)),
      throwsA(isA<AssertionError>()),
    );
  });

  test('pages stay within the days the API accepts', () {
    for (final kind in PeriodKind.values) {
      expect(Period.first(kind).start.isBefore(DateTime.utc(1, 1, 2)), isFalse);
      expect(
        Period.last(kind).end.isAfter(DateTime.utc(9999, 12, 30)),
        isFalse,
      );
    }
    expect(Period.first(PeriodKind.month).start, DateTime.utc(1, 2));
    expect(Period.last(PeriodKind.month).end, DateTime.utc(9999, 11, 30));
  });

  test('a form opens on today inside the period, otherwise on its first '
      'day', () {
    final week = _week(2026, 10, 1);

    expect(week.dayFor(DateTime.utc(2026, 10, 2)), DateTime.utc(2026, 10, 2));
    expect(week.dayFor(DateTime.utc(2026, 10, 7)), sep28);
    expect(week.contains(oct4), isTrue);
    expect(week.contains(DateTime.utc(2026, 10, 5)), isFalse);
  });

  group('a period report', () {
    test('parses the week example from docs/api.md', () {
      final json = jsonDecode(apiWeekExample) as Map<String, dynamic>;

      expect(PeriodReport.fromJson(json), seedWeekReport);
    });

    test('rejects fractional money in a day instead of rounding it (D3)', () {
      final json = jsonDecode(apiWeekExample) as Map<String, dynamic>;
      final days = json['days'] as List<dynamic>;
      final day = days[2] as Map<String, dynamic>;
      final summary = day['summary'] as Map<String, dynamic>;

      expect(
        () => PeriodReport.fromJson({
          ...json,
          'days': [
            {
              ...day,
              'summary': {...summary, 'net': 6035.5},
            },
          ],
        }),
        throwsFormatException,
      );
      expect(
        () => DaySummary.fromJson({...summary, 'trips_count': 3.0}),
        throwsFormatException,
      );
    });
  });
}
