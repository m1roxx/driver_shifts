import 'package:driver_shifts/src/features/shift_diary/domain/models/day_summary.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/json_converters.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_report.freezed.dart';
part 'day_report.g.dart';

@freezed
abstract class DayReport with _$DayReport {
  const factory DayReport({
    @CalendarDateConverter() required DateTime date,
    required DaySummary summary,
    required List<Trip> trips,
  }) = _DayReport;

  factory DayReport.fromJson(Map<String, dynamic> json) =>
      _$DayReportFromJson(json);
}
