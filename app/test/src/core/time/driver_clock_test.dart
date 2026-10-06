import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:flutter_test/flutter_test.dart';

DriverClock _clockAt(DateTime now) => DriverClock(now: () => now);

void main() {
  test('Asia/Almaty is UTC+05:00 on 2026-10-01: '
      'guards against a stale tz database', () {
    final almaty = DriverClock().inDriverZone(DateTime.utc(2026, 10, 1, 3, 10));

    expect(almaty.timeZoneOffset, const Duration(hours: 5));
    expect(almaty.hour, 8);
  });

  test('today is the date in Almaty, not in UTC or on the phone', () {
    final clock = _clockAt(DateTime.utc(2026, 10, 1, 19, 30));

    expect(clock.today(), DateTime.utc(2026, 10, 2));
  });

  test('today turns over at midnight in Almaty', () {
    expect(
      _clockAt(DateTime.utc(2026, 10, 2, 18, 59, 59)).today(),
      DateTime.utc(2026, 10, 2),
    );
    expect(
      _clockAt(DateTime.utc(2026, 10, 2, 19)).today(),
      DateTime.utc(2026, 10, 3),
    );
  });

  test('the day of a moment is its date in Almaty, not in UTC (D1)', () {
    final afterMidnight = DateTime.parse('2026-10-02T00:30:00+05:00');

    expect(afterMidnight.toUtc().day, 1);
    expect(DriverClock().dayOf(afterMidnight), DateTime.utc(2026, 10, 2));
  });

  test('a day after today is the next date when the phone leaves '
      'daylight saving time', () {
    final today = _clockAt(DateTime.utc(2026, 11, 1, 6)).today();
    final tomorrow = today.add(const Duration(days: 1));

    expect((tomorrow.year, tomorrow.month, tomorrow.day), (2026, 11, 2));
  });

  test('formats trip times on the Almaty clock whatever offset the API '
      'used', () {
    final clock = DriverClock();

    expect(
      clock.formatTime(DateTime.parse('2026-10-01T08:10:00+05:00')),
      '08:10',
    );
    expect(clock.formatTime(DateTime.parse('2026-10-01T03:10:00Z')), '08:10');
    expect(clock.formatTime(DateTime.parse('2026-10-01T19:30:00Z')), '00:30');
  });
}
