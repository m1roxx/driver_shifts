import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'day_reports.dart';

class FakeTripsRepository extends Fake implements TripsRepository {
  FakeTripsRepository(this.onGetDay, {this.onAddTrip = _saved});

  FakeTripsRepository.withReports(
    Map<DateTime, DayReport> reports, {
    Future<Result<Trip>> Function(Trip trip) onAddTrip = _saved,
  }) : this(
         (date) async => Result.success(reports[date] ?? emptyReport(date)),
         onAddTrip: onAddTrip,
       );

  final Future<Result<DayReport>> Function(DateTime date) onGetDay;
  final Future<Result<Trip>> Function(Trip trip) onAddTrip;
  final List<DateTime> requestedDays = [];
  final List<Trip> addedTrips = [];

  static Future<Result<Trip>> _saved(Trip trip) async => Result.success(trip);

  @override
  Future<Result<DayReport>> getDay(DateTime date) {
    requestedDays.add(date);
    return onGetDay(date);
  }

  @override
  Future<Result<Trip>> addTrip(Trip trip) {
    addedTrips.add(trip);
    return onAddTrip(trip);
  }
}
