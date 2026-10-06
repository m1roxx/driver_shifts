import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';

abstract interface class TripsRepository {
  Future<Result<DayReport>> getDay(DateTime date);
}
