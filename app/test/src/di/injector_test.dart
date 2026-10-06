import 'package:dio/dio.dart';
import 'package:driver_shifts/src/core/config/env.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/di/injector.dart';
import 'package:driver_shifts/src/features/shift_diary/data/repositories/trips_repository_impl.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/day_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(getIt.reset);

  test('builds the dependency graph from the given environment', () {
    configureDependencies(Env(apiBaseUrl: 'http://localhost:8000'));

    expect(getIt<Dio>().options.baseUrl, 'http://localhost:8000/api/v1');
    expect(getIt<DriverClock>(), same(getIt<DriverClock>()));
    expect(getIt<TripsRepository>(), isA<TripsRepositoryImpl>());
  });

  test('gives every screen its own DayBloc', () {
    configureDependencies(Env(apiBaseUrl: 'http://localhost:8000'));

    final first = getIt<DayBloc>();
    final second = getIt<DayBloc>();
    addTearDown(first.close);
    addTearDown(second.close);

    expect(first, isNot(same(second)));
  });
}
