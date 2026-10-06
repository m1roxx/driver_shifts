// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DayReport _$DayReportFromJson(Map<String, dynamic> json) => _DayReport(
  date: const CalendarDateConverter().fromJson(json['date'] as String),
  summary: DaySummary.fromJson(json['summary'] as Map<String, dynamic>),
  trips: (json['trips'] as List<dynamic>)
      .map((e) => Trip.fromJson(e as Map<String, dynamic>))
      .toList(),
);

Map<String, dynamic> _$DayReportToJson(_DayReport instance) =>
    <String, dynamic>{
      'date': const CalendarDateConverter().toJson(instance.date),
      'summary': instance.summary,
      'trips': instance.trips,
    };
