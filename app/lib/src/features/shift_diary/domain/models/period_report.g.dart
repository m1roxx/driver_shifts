// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'period_report.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PeriodReport _$PeriodReportFromJson(Map<String, dynamic> json) =>
    _PeriodReport(
      start: const CalendarDateConverter().fromJson(json['start'] as String),
      end: const CalendarDateConverter().fromJson(json['end'] as String),
      summary: DaySummary.fromJson(json['summary'] as Map<String, dynamic>),
      days: (json['days'] as List<dynamic>)
          .map((e) => DayTotal.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PeriodReportToJson(_PeriodReport instance) =>
    <String, dynamic>{
      'start': const CalendarDateConverter().toJson(instance.start),
      'end': const CalendarDateConverter().toJson(instance.end),
      'summary': instance.summary,
      'days': instance.days,
    };

_DayTotal _$DayTotalFromJson(Map<String, dynamic> json) => _DayTotal(
  date: const CalendarDateConverter().fromJson(json['date'] as String),
  summary: DaySummary.fromJson(json['summary'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DayTotalToJson(_DayTotal instance) => <String, dynamic>{
  'date': const CalendarDateConverter().toJson(instance.date),
  'summary': instance.summary,
};
