// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DaySummary _$DaySummaryFromJson(Map<String, dynamic> json) => _DaySummary(
  tripsCount: const WholeNumberConverter().fromJson(json['trips_count'] as num),
  revenue: const WholeNumberConverter().fromJson(json['revenue'] as num),
  commission: const WholeNumberConverter().fromJson(json['commission'] as num),
  net: const WholeNumberConverter().fromJson(json['net'] as num),
  byPayment: PaymentBreakdown.fromJson(
    json['by_payment'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$DaySummaryToJson(_DaySummary instance) =>
    <String, dynamic>{
      'trips_count': const WholeNumberConverter().toJson(instance.tripsCount),
      'revenue': const WholeNumberConverter().toJson(instance.revenue),
      'commission': const WholeNumberConverter().toJson(instance.commission),
      'net': const WholeNumberConverter().toJson(instance.net),
      'by_payment': instance.byPayment,
    };

_PaymentBreakdown _$PaymentBreakdownFromJson(Map<String, dynamic> json) =>
    _PaymentBreakdown(
      cash: const WholeNumberConverter().fromJson(json['cash'] as num),
      card: const WholeNumberConverter().fromJson(json['card'] as num),
    );

Map<String, dynamic> _$PaymentBreakdownToJson(_PaymentBreakdown instance) =>
    <String, dynamic>{
      'cash': const WholeNumberConverter().toJson(instance.cash),
      'card': const WholeNumberConverter().toJson(instance.card),
    };
