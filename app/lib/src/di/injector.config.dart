// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format width=80

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes

import 'package:dio/dio.dart' as _i361;
import 'package:driver_shifts/src/core/config/env.dart' as _i129;
import 'package:driver_shifts/src/core/network/http_client.dart' as _i533;
import 'package:driver_shifts/src/core/time/driver_clock.dart' as _i333;
import 'package:driver_shifts/src/features/shift_diary/data/datasources/trips_remote_datasource.dart'
    as _i646;
import 'package:driver_shifts/src/features/shift_diary/data/repositories/trips_repository_impl.dart'
    as _i507;
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart'
    as _i427;
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/day_bloc.dart'
    as _i752;
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/period_bloc.dart'
    as _i710;
import 'package:get_it/get_it.dart' as _i174;
import 'package:injectable/injectable.dart' as _i526;

extension GetItInjectableX on _i174.GetIt {
  // initializes the registration of main-scope dependencies inside of GetIt
  _i174.GetIt init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) {
    final gh = _i526.GetItHelper(this, environment, environmentFilter);
    final httpClientModule = _$HttpClientModule();
    gh.lazySingleton<_i333.DriverClock>(() => _i333.DriverClock());
    gh.lazySingleton<_i361.Dio>(() => httpClientModule.dio(gh<_i129.Env>()));
    gh.lazySingleton<_i646.TripsRemoteDataSource>(
      () => _i646.TripsRemoteDataSource(gh<_i361.Dio>()),
    );
    gh.lazySingleton<_i427.TripsRepository>(
      () => _i507.TripsRepositoryImpl(gh<_i646.TripsRemoteDataSource>()),
    );
    gh.factory<_i752.DayBloc>(
      () => _i752.DayBloc(gh<_i427.TripsRepository>(), gh<_i333.DriverClock>()),
    );
    gh.factory<_i710.PeriodBloc>(
      () => _i710.PeriodBloc(
        gh<_i427.TripsRepository>(),
        gh<_i333.DriverClock>(),
      ),
    );
    return this;
  }
}

class _$HttpClientModule extends _i533.HttpClientModule {}
