// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'trip.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Trip _$TripFromJson(Map<String, dynamic> json) => _Trip(
  id: json['id'] as String,
  start: const OffsetDateTimeConverter().fromJson(json['start'] as String),
  end: const OffsetDateTimeConverter().fromJson(json['end'] as String),
  amount: (json['amount'] as num).toInt(),
  payment: $enumDecode(_$PaymentMethodEnumMap, json['payment']),
  commission: (json['commission'] as num).toInt(),
);

Map<String, dynamic> _$TripToJson(_Trip instance) => <String, dynamic>{
  'id': instance.id,
  'start': const OffsetDateTimeConverter().toJson(instance.start),
  'end': const OffsetDateTimeConverter().toJson(instance.end),
  'amount': instance.amount,
  'payment': _$PaymentMethodEnumMap[instance.payment]!,
  'commission': instance.commission,
};

const _$PaymentMethodEnumMap = {
  PaymentMethod.cash: 'cash',
  PaymentMethod.card: 'card',
};
