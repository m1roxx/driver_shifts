import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

final class OffsetDateTimeConverter implements JsonConverter<DateTime, String> {
  const OffsetDateTimeConverter();

  @override
  DateTime fromJson(String json) {
    final instant = DateTime.parse(json);
    if (!instant.isUtc) {
      throw FormatException('Expected a timestamp with an offset', json);
    }
    return instant;
  }

  @override
  String toJson(DateTime instant) => instant.toUtc().toIso8601String();
}

final class CalendarDateConverter implements JsonConverter<DateTime, String> {
  const CalendarDateConverter();

  static final DateFormat _isoDate = DateFormat('yyyy-MM-dd');

  @override
  DateTime fromJson(String json) => _isoDate.parseStrict(json, true);

  @override
  String toJson(DateTime date) => _isoDate.format(date);
}
