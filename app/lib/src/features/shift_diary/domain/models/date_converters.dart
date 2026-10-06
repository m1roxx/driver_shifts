import 'package:intl/intl.dart';
import 'package:json_annotation/json_annotation.dart';

final class OffsetDateTimeConverter implements JsonConverter<DateTime, String> {
  const OffsetDateTimeConverter();

  static final RegExp _offset = RegExp(r'(Z|[+-]\d{2}(:?\d{2})?)$');

  @override
  DateTime fromJson(String json) {
    if (!_offset.hasMatch(json)) {
      throw FormatException('Expected a timestamp with an offset', json);
    }
    return DateTime.parse(json);
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
