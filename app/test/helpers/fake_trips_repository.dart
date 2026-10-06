import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import 'day_reports.dart';

class FakeTripsRepository extends Fake implements TripsRepository {
  FakeTripsRepository(this.onGetDay);

  FakeTripsRepository.withReports(Map<DateTime, DayReport> reports)
    : this((date) async => Result.success(reports[date] ?? emptyReport(date)));

  final Future<Result<DayReport>> Function(DateTime date) onGetDay;
  final List<DateTime> requestedDays = [];

  @override
  Future<Result<DayReport>> getDay(DateTime date) {
    requestedDays.add(date);
    return onGetDay(date);
  }
}
