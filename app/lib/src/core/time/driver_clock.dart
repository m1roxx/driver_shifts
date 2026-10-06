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

  DateTime today() {
    final now = inDriverZone(_now());
    return DateTime.utc(now.year, now.month, now.day);
  }

  String formatTime(DateTime instant) =>
      _hoursMinutes.format(inDriverZone(instant));
}
