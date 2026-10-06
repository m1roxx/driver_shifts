import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/network/handle_error_mixin.dart';
import 'package:driver_shifts/src/features/shift_diary/data/datasources/trips_remote_datasource.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/date_converters.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
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
}
