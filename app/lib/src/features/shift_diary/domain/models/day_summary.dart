import 'package:freezed_annotation/freezed_annotation.dart';

part 'day_summary.freezed.dart';
part 'day_summary.g.dart';

@freezed
abstract class DaySummary with _$DaySummary {
  const factory DaySummary({
    required int tripsCount,
    required int revenue,
    required int commission,
    required int net,
    required PaymentBreakdown byPayment,
  }) = _DaySummary;

  factory DaySummary.fromJson(Map<String, dynamic> json) =>
      _$DaySummaryFromJson(json);
}

@freezed
abstract class PaymentBreakdown with _$PaymentBreakdown {
  const factory PaymentBreakdown({required int cash, required int card}) =
      _PaymentBreakdown;

  factory PaymentBreakdown.fromJson(Map<String, dynamic> json) =>
      _$PaymentBreakdownFromJson(json);
}
