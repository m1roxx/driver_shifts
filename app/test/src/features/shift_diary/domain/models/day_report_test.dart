import 'dart:convert';

import 'package:driver_shifts/src/features/shift_diary/domain/models/date_converters.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';

Map<String, Object?> _tripJson({
  String start = '2026-10-01T08:10:00+05:00',
  String end = '2026-10-01T08:32:00+05:00',
}) => {
  'id': 't1',
  'start': start,
  'end': end,
  'amount': 2400,
  'payment': 'card',
  'commission': 360,
};

void main() {
  test('parses the day example from docs/api.md', () {
    final json = jsonDecode(apiDayExample) as Map<String, dynamic>;

    expect(DayReport.fromJson(json), taskExampleReport);
  });

  test('reads trip times as instants, whatever offset the API used', () {
    final almaty = Trip.fromJson(_tripJson());
    final utc = Trip.fromJson(
      _tripJson(start: '2026-10-01T03:10:00Z', end: '2026-10-01T03:32:00Z'),
    );

    expect(utc, almaty);
    expect(almaty.start, DateTime.utc(2026, 10, 1, 3, 10));
  });

  test('rejects a trip time without an offset, a bare date included', () {
    for (final start in ['2026-10-01T08:10:00', '2026-10-01']) {
      expect(
        () => Trip.fromJson(_tripJson(start: start)),
        throwsFormatException,
        reason: start,
      );
    }
  });

  test('keeps the report date as a calendar date', () {
    const converter = CalendarDateConverter();

    expect(converter.fromJson('2026-10-01'), oct1);
    expect(converter.toJson(oct1), '2026-10-01');
    expect(() => converter.fromJson('2026-10-01T00:00'), throwsFormatException);
  });
}
