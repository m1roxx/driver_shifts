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
      stats: PeriodStats.fromJson(json['stats'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$PeriodReportToJson(_PeriodReport instance) =>
    <String, dynamic>{
      'start': const CalendarDateConverter().toJson(instance.start),
      'end': const CalendarDateConverter().toJson(instance.end),
      'summary': instance.summary,
      'days': instance.days,
      'stats': instance.stats,
    };

_DayTotal _$DayTotalFromJson(Map<String, dynamic> json) => _DayTotal(
  date: const CalendarDateConverter().fromJson(json['date'] as String),
  summary: DaySummary.fromJson(json['summary'] as Map<String, dynamic>),
);

Map<String, dynamic> _$DayTotalToJson(_DayTotal instance) => <String, dynamic>{
  'date': const CalendarDateConverter().toJson(instance.date),
  'summary': instance.summary,
};

_PeriodStats _$PeriodStatsFromJson(Map<String, dynamic> json) => _PeriodStats(
  averageTrip: _$JsonConverterFromJson<num, int>(
    json['average_trip'],
    const WholeNumberConverter().fromJson,
  ),
  netPerHour: _$JsonConverterFromJson<num, int>(
    json['net_per_hour'],
    const WholeNumberConverter().fromJson,
  ),
  bestDay: json['best_day'] == null
      ? null
      : BestDay.fromJson(json['best_day'] as Map<String, dynamic>),
);

Map<String, dynamic> _$PeriodStatsToJson(_PeriodStats instance) =>
    <String, dynamic>{
      'average_trip': _$JsonConverterToJson<num, int>(
        instance.averageTrip,
        const WholeNumberConverter().toJson,
      ),
      'net_per_hour': _$JsonConverterToJson<num, int>(
        instance.netPerHour,
        const WholeNumberConverter().toJson,
      ),
      'best_day': instance.bestDay,
    };

Value? _$JsonConverterFromJson<Json, Value>(
  Object? json,
  Value? Function(Json json) fromJson,
) => json == null ? null : fromJson(json as Json);

Json? _$JsonConverterToJson<Json, Value>(
  Value? value,
  Json? Function(Value value) toJson,
) => value == null ? null : toJson(value);

_BestDay _$BestDayFromJson(Map<String, dynamic> json) => _BestDay(
  date: const CalendarDateConverter().fromJson(json['date'] as String),
  net: const WholeNumberConverter().fromJson(json['net'] as num),
);

Map<String, dynamic> _$BestDayToJson(_BestDay instance) => <String, dynamic>{
  'date': const CalendarDateConverter().toJson(instance.date),
  'net': const WholeNumberConverter().toJson(instance.net),
};
