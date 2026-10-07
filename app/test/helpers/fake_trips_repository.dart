import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'day_reports.dart';
import 'period_reports.dart';

class FakeTripsRepository extends Fake implements TripsRepository {
  FakeTripsRepository(
    this.onGetDay, {
    this.onAddTrip = _saved,
    this.onGetPeriod = _emptyPeriod,
  });

  FakeTripsRepository.withReports(
    Map<DateTime, DayReport> reports, {
    Future<Result<Trip>> Function(Trip trip) onAddTrip = _saved,
  }) : this(
         (date) async => Result.success(reports[date] ?? emptyReport(date)),
         onAddTrip: onAddTrip,
         onGetPeriod: (start, end) async =>
             Result.success(periodReportOf(start, end, reports)),
       );

  final Future<Result<DayReport>> Function(DateTime date) onGetDay;
  final Future<Result<Trip>> Function(Trip trip) onAddTrip;
  final Future<Result<PeriodReport>> Function(DateTime start, DateTime end)
  onGetPeriod;
  final List<DateTime> requestedDays = [];
  final List<(DateTime, DateTime)> requestedPeriods = [];
  final List<Trip> addedTrips = [];

  static Future<Result<PeriodReport>> _emptyPeriod(
    DateTime start,
    DateTime end,
  ) async => Result.success(periodReportOf(start, end, const {}));

  static Future<Result<Trip>> _saved(Trip trip) async => Result.success(trip);

  @override
  Future<Result<DayReport>> getDay(DateTime date) {
    requestedDays.add(date);
    return onGetDay(date);
  }

  @override
  Future<Result<PeriodReport>> getPeriod(DateTime start, DateTime end) {
    requestedPeriods.add((start, end));
    return onGetPeriod(start, end);
  }

  @override
  Future<Result<Trip>> addTrip(Trip trip) {
    addedTrips.add(trip);
    return onAddTrip(trip);
  }
}
