import 'package:driver_shifts/src/app.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/di/injector.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/day_bloc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> pumpApp(WidgetTester tester, TripsRepository repository) async {
  final clock = DriverClock(now: () => DateTime.utc(2026, 10, 1, 6));
  getIt
    ..registerSingleton<DriverClock>(clock)
    ..registerFactory<DayBloc>(() => DayBloc(repository, clock));
  addTearDown(getIt.reset);
  await tester.pumpWidget(const DriverShiftsApp());
}

void useSmallPhone(
  WidgetTester tester, {
  Brightness brightness = Brightness.light,
  double textScale = 1,
}) {
  tester.view
    ..physicalSize = const Size(320, 568)
    ..devicePixelRatio = 1;
  tester.platformDispatcher
    ..platformBrightnessTestValue = brightness
    ..textScaleFactorTestValue = textScale;
  addTearDown(tester.view.reset);
  addTearDown(tester.platformDispatcher.clearAllTestValues);
}
