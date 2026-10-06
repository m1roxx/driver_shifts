import 'package:dio/dio.dart';
import 'package:driver_shifts/src/core/config/env.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/di/injector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  tearDown(getIt.reset);

  test('builds the dependency graph from the given environment', () {
    configureDependencies(Env(apiBaseUrl: 'http://localhost:8000'));

    expect(getIt<Dio>().options.baseUrl, 'http://localhost:8000/api/v1');
    expect(getIt<DriverClock>(), same(getIt<DriverClock>()));
  });
}
