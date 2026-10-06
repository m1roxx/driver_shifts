import 'package:driver_shifts/src/features/shift_diary/domain/models/json_converters.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'trip.freezed.dart';
part 'trip.g.dart';

@freezed
abstract class Trip with _$Trip {
  const factory Trip({
    required String id,
    @OffsetDateTimeConverter() required DateTime start,
    @OffsetDateTimeConverter() required DateTime end,
    @WholeNumberConverter() required int amount,
    required PaymentMethod payment,
    @WholeNumberConverter() required int commission,
  }) = _Trip;

  factory Trip.fromJson(Map<String, dynamic> json) => _$TripFromJson(json);
}
