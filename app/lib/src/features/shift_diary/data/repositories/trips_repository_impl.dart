import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/network/handle_error_mixin.dart';
import 'package:driver_shifts/src/features/shift_diary/data/datasources/trips_remote_datasource.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/json_converters.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:injectable/injectable.dart';

@LazySingleton(as: TripsRepository)
class TripsRepositoryImpl with HandleErrorMixin implements TripsRepository {
  TripsRepositoryImpl(this._remote);

  final TripsRemoteDataSource _remote;

  @override
  Future<Result<DayReport>> getDay(DateTime date) => handleError(
    () => _remote.getDay(const CalendarDateConverter().toJson(date)),
  );

  @override
  Future<Result<PeriodReport>> getPeriod(DateTime start, DateTime end) =>
      handleError(
        () => _remote.getPeriod(
          const CalendarDateConverter().toJson(start),
          const CalendarDateConverter().toJson(end),
        ),
      );

  @override
  Future<Result<Trip>> addTrip(Trip trip) =>
      handleError(() => _remote.addTrip(trip));
}
