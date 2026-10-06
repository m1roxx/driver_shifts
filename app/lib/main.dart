import 'package:driver_shifts/src/app.dart';
import 'package:driver_shifts/src/core/config/env.dart';
import 'package:driver_shifts/src/di/injector.dart';
import 'package:flutter/widgets.dart';

void main() {
  configureDependencies(Env.fromDartDefines());
  runApp(const DriverShiftsApp());
}
