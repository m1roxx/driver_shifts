import 'package:driver_shifts/src/features/shift_diary/domain/models/day_summary.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'period_report.freezed.dart';
part 'period_report.g.dart';

@freezed
abstract class PeriodReport with _$PeriodReport {
  const factory PeriodReport({
    @CalendarDateConverter() required DateTime start,
    @CalendarDateConverter() required DateTime end,
    required DaySummary summary,
    required List<DayTotal> days,
  }) = _PeriodReport;

  factory PeriodReport.fromJson(Map<String, dynamic> json) =>
      _$PeriodReportFromJson(json);
}

@freezed
abstract class DayTotal with _$DayTotal {
  const factory DayTotal({
    @CalendarDateConverter() required DateTime date,
    required DaySummary summary,
  }) = _DayTotal;

  factory DayTotal.fromJson(Map<String, dynamic> json) =>
      _$DayTotalFromJson(json);
}
