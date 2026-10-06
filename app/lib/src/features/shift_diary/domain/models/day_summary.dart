import 'package:driver_shifts/src/features/shift_diary/domain/models/json_converters.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_summary.freezed.dart';
part 'day_summary.g.dart';

@freezed
abstract class DaySummary with _$DaySummary {
  const factory DaySummary({
    @WholeNumberConverter() required int tripsCount,
    @WholeNumberConverter() required int revenue,
    @WholeNumberConverter() required int commission,
    @WholeNumberConverter() required int net,
    required PaymentBreakdown byPayment,
  }) = _DaySummary;

  factory DaySummary.fromJson(Map<String, dynamic> json) =>
      _$DaySummaryFromJson(json);
}

@freezed
abstract class PaymentBreakdown with _$PaymentBreakdown {
  const factory PaymentBreakdown({
    @WholeNumberConverter() required int cash,
    @WholeNumberConverter() required int card,
  }) = _PaymentBreakdown;

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) =>
      _$PaymentBreakdownFromJson(json);
}
