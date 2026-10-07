import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';

abstract interface class TripsRepository {
  Future<Result<DayReport>> getDay(DateTime date);

  Future<Result<PeriodReport>> getPeriod(DateTime start, DateTime end);

  Future<Result<Trip>> addTrip(Trip trip);
}
