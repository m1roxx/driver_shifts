import 'package:injectable/injectable.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

final tz.Location _driverLocation = () {
  tzdata.initializeTimeZones();
  return tz.getLocation('Asia/Almaty');
}();

final DateFormat _hoursMinutes = DateFormat('HH:mm');

@lazySingleton
class DriverClock {
  DriverClock({@ignoreParam DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final DateTime Function() _now;

  DateTime inDriverZone(DateTime instant) =>
      tz.TZDateTime.from(instant, _driverLocation);

  DateTime dayOf(DateTime instant) {
    final local = inDriverZone(instant);
    return DateTime.utc(local.year, local.month, local.day);
  }

  bool endsOnLaterDay(DateTime start, DateTime end) =>
      dayOf(end).isAfter(dayOf(start));

  DateTime today() => dayOf(_now());

  DateTime now() => inDriverZone(_now());

  DateTime momentAt(DateTime day, {required int hour, required int minute}) {
    final local = tz.TZDateTime(
      _driverLocation,
      day.year,
      day.month,
      day.day,
      hour,
      minute,
    );
    return DateTime.fromMicrosecondsSinceEpoch(
      local.microsecondsSinceEpoch,
      isUtc: true,
    );
  }

  Duration untilTomorrow() {
    final now = _now();
    final local = inDriverZone(now);
    final tomorrow = tz.TZDateTime(
      _driverLocation,
      local.year,
      local.month,
      local.day + 1,
    );
    return tomorrow.difference(now);
  }

  String formatTime(DateTime instant) =>
      _hoursMinutes.format(inDriverZone(instant));
}
