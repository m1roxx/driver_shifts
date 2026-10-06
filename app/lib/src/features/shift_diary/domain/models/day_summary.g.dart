// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'day_summary.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_DaySummary _$DaySummaryFromJson(Map<String, dynamic> json) => _DaySummary(
  tripsCount: (json['trips_count'] as num).toInt(),
  revenue: (json['revenue'] as num).toInt(),
  commission: (json['commission'] as num).toInt(),
  net: (json['net'] as num).toInt(),
  byPayment: PaymentBreakdown.fromJson(
    json['by_payment'] as Map<String, dynamic>,
  ),
);

Map<String, dynamic> _$DaySummaryToJson(_DaySummary instance) =>
    <String, dynamic>{
      'trips_count': instance.tripsCount,
      'revenue': instance.revenue,
      'commission': instance.commission,
      'net': instance.net,
      'by_payment': instance.byPayment,
    };

_PaymentBreakdown _$PaymentBreakdownFromJson(Map<String, dynamic> json) =>
    _PaymentBreakdown(
      cash: (json['cash'] as num).toInt(),
      card: (json['card'] as num).toInt(),
    );

Map<String, dynamic> _$PaymentBreakdownToJson(_PaymentBreakdown instance) =>
    <String, dynamic>{'cash': instance.cash, 'card': instance.card};
