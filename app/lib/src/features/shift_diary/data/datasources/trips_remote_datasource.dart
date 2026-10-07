import 'package:dio/dio.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:injectable/injectable.dart';
import 'package:retrofit/retrofit.dart';

part 'trips_remote_datasource.g.dart';

@lazySingleton
@RestApi()
abstract class TripsRemoteDataSource {
  @factoryMethod
  factory TripsRemoteDataSource(Dio dio) = _TripsRemoteDataSource;

  @GET('/days/{date}')
  Future<DayReport> getDay(@Path() String date);

  @POST('/trips')
  Future<Trip> addTrip(@Body() Trip trip);
}
