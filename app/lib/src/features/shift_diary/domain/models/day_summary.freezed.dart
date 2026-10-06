// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_summary.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DaySummary {

@WholeNumberConverter() int get tripsCount;@WholeNumberConverter() int get revenue;@WholeNumberConverter() int get commission;@WholeNumberConverter() int get net; PaymentBreakdown get byPayment;
/// Create a copy of DaySummary
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DaySummaryCopyWith<DaySummary> get copyWith => _$DaySummaryCopyWithImpl<DaySummary>(this as DaySummary, _$identity);

  /// Serializes this DaySummary to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DaySummary;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DaySummary&&(identical(other.tripsCount, _this.tripsCount) || other.tripsCount == _this.tripsCount)&&(identical(other.revenue, _this.revenue) || other.revenue == _this.revenue)&&(identical(other.commission, _this.commission) || other.commission == _this.commission)&&(identical(other.net, _this.net) || other.net == _this.net)&&(identical(other.byPayment, _this.byPayment) || other.byPayment == _this.byPayment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DaySummary;
  return Object.hash(runtimeType,_this.tripsCount,_this.revenue,_this.commission,_this.net,_this.byPayment);
}

@override
String toString() {
  final _this = this as DaySummary;
  return 'DaySummary(tripsCount: ${_this.tripsCount}, revenue: ${_this.revenue}, commission: ${_this.commission}, net: ${_this.net}, byPayment: ${_this.byPayment})';
}


}

/// @nodoc
abstract mixin class $DaySummaryCopyWith<$Res>  {
  factory $DaySummaryCopyWith(DaySummary value, $Res Function(DaySummary) _then) = _$DaySummaryCopyWithImpl;
@useResult
$Res call({
@WholeNumberConverter() int tripsCount,@WholeNumberConverter() int revenue,@WholeNumberConverter() int commission,@WholeNumberConverter() int net, PaymentBreakdown byPayment
});


$PaymentBreakdownCopyWith<$Res> get byPayment;

}
/// @nodoc
class _$DaySummaryCopyWithImpl<$Res>
    implements $DaySummaryCopyWith<$Res> {
  _$DaySummaryCopyWithImpl(this._self, this._then);

  final DaySummary _self;
  final $Res Function(DaySummary) _then;

/// Create a copy of DaySummary
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripsCount = null,Object? revenue = null,Object? commission = null,Object? net = null,Object? byPayment = null,}) {
  return _then(DaySummary(
tripsCount: null == tripsCount ? _self.tripsCount : tripsCount // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,byPayment: null == byPayment ? _self.byPayment : byPayment // ignore: cast_nullable_to_non_nullable
as PaymentBreakdown,
  ));
}
/// Create a copy of DaySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentBreakdownCopyWith<$Res> get byPayment {
  
  return $PaymentBreakdownCopyWith<$Res>(_self.byPayment, (value) {
    return _then(_self.copyWith(byPayment: value));
  });
}
}



/// @nodoc
@JsonSerializable()

class _DaySummary implements DaySummary {
  const _DaySummary({@WholeNumberConverter() required this.tripsCount, @WholeNumberConverter() required this.revenue, @WholeNumberConverter() required this.commission, @WholeNumberConverter() required this.net, required this.byPayment});
  factory _DaySummary.fromJson(Map<String, dynamic> json) => _$DaySummaryFromJson(json);

@override@WholeNumberConverter() final  int tripsCount;
@override@WholeNumberConverter() final  int revenue;
@override@WholeNumberConverter() final  int commission;
@override@WholeNumberConverter() final  int net;
@override final  PaymentBreakdown byPayment;

/// Create a copy of DaySummary
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DaySummaryCopyWith<_DaySummary> get copyWith => __$DaySummaryCopyWithImpl<_DaySummary>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DaySummaryToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DaySummary&&(identical(other.tripsCount, tripsCount) || other.tripsCount == tripsCount)&&(identical(other.revenue, revenue) || other.revenue == revenue)&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.net, net) || other.net == net)&&(identical(other.byPayment, byPayment) || other.byPayment == byPayment));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,tripsCount,revenue,commission,net,byPayment);
}

@override
String toString() {
    return 'DaySummary(tripsCount: $tripsCount, revenue: $revenue, commission: $commission, net: $net, byPayment: $byPayment)';
}


}

/// @nodoc
abstract mixin class _$DaySummaryCopyWith<$Res> implements $DaySummaryCopyWith<$Res> {
  factory _$DaySummaryCopyWith(_DaySummary value, $Res Function(_DaySummary) _then) = __$DaySummaryCopyWithImpl;
@override @useResult
$Res call({
@WholeNumberConverter() int tripsCount,@WholeNumberConverter() int revenue,@WholeNumberConverter() int commission,@WholeNumberConverter() int net, PaymentBreakdown byPayment
});


@override $PaymentBreakdownCopyWith<$Res> get byPayment;

}
/// @nodoc
class __$DaySummaryCopyWithImpl<$Res>
    implements _$DaySummaryCopyWith<$Res> {
  __$DaySummaryCopyWithImpl(this._self, this._then);

  final _DaySummary _self;
  final $Res Function(_DaySummary) _then;

/// Create a copy of DaySummary
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripsCount = null,Object? revenue = null,Object? commission = null,Object? net = null,Object? byPayment = null,}) {
  return _then(_DaySummary(
tripsCount: null == tripsCount ? _self.tripsCount : tripsCount // ignore: cast_nullable_to_non_nullable
as int,revenue: null == revenue ? _self.revenue : revenue // ignore: cast_nullable_to_non_nullable
as int,commission: null == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,byPayment: null == byPayment ? _self.byPayment : byPayment // ignore: cast_nullable_to_non_nullable
as PaymentBreakdown,
  ));
}

/// Create a copy of DaySummary
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PaymentBreakdownCopyWith<$Res> get byPayment {
  
  return $PaymentBreakdownCopyWith<$Res>(_self.byPayment, (value) {
    return _then(_self.copyWith(byPayment: value));
  });
}
}


/// @nodoc
mixin _$PaymentBreakdown {

@WholeNumberConverter() int get cash;@WholeNumberConverter() int get card;
/// Create a copy of PaymentBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PaymentBreakdownCopyWith<PaymentBreakdown> get copyWith => _$PaymentBreakdownCopyWithImpl<PaymentBreakdown>(this as PaymentBreakdown, _$identity);

  /// Serializes this PaymentBreakdown to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PaymentBreakdown;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PaymentBreakdown&&(identical(other.cash, _this.cash) || other.cash == _this.cash)&&(identical(other.card, _this.card) || other.card == _this.card));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PaymentBreakdown;
  return Object.hash(runtimeType,_this.cash,_this.card);
}

@override
String toString() {
  final _this = this as PaymentBreakdown;
  return 'PaymentBreakdown(cash: ${_this.cash}, card: ${_this.card})';
}


}

/// @nodoc
abstract mixin class $PaymentBreakdownCopyWith<$Res>  {
  factory $PaymentBreakdownCopyWith(PaymentBreakdown value, $Res Function(PaymentBreakdown) _then) = _$PaymentBreakdownCopyWithImpl;
@useResult
$Res call({
@WholeNumberConverter() int cash,@WholeNumberConverter() int card
});




}
/// @nodoc
class _$PaymentBreakdownCopyWithImpl<$Res>
    implements $PaymentBreakdownCopyWith<$Res> {
  _$PaymentBreakdownCopyWithImpl(this._self, this._then);

  final PaymentBreakdown _self;
  final $Res Function(PaymentBreakdown) _then;

/// Create a copy of PaymentBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? cash = null,Object? card = null,}) {
  return _then(PaymentBreakdown(
cash: null == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as int,card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc
@JsonSerializable()

class _PaymentBreakdown implements PaymentBreakdown {
  const _PaymentBreakdown({@WholeNumberConverter() required this.cash, @WholeNumberConverter() required this.card});
  factory _PaymentBreakdown.fromJson(Map<String, dynamic> json) => _$PaymentBreakdownFromJson(json);

@override@WholeNumberConverter() final  int cash;
@override@WholeNumberConverter() final  int card;

/// Create a copy of PaymentBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PaymentBreakdownCopyWith<_PaymentBreakdown> get copyWith => __$PaymentBreakdownCopyWithImpl<_PaymentBreakdown>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PaymentBreakdownToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PaymentBreakdown&&(identical(other.cash, cash) || other.cash == cash)&&(identical(other.card, card) || other.card == card));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,cash,card);
}

@override
String toString() {
    return 'PaymentBreakdown(cash: $cash, card: $card)';
}


}

/// @nodoc
abstract mixin class _$PaymentBreakdownCopyWith<$Res> implements $PaymentBreakdownCopyWith<$Res> {
  factory _$PaymentBreakdownCopyWith(_PaymentBreakdown value, $Res Function(_PaymentBreakdown) _then) = __$PaymentBreakdownCopyWithImpl;
@override @useResult
$Res call({
@WholeNumberConverter() int cash,@WholeNumberConverter() int card
});




}
/// @nodoc
class __$PaymentBreakdownCopyWithImpl<$Res>
    implements _$PaymentBreakdownCopyWith<$Res> {
  __$PaymentBreakdownCopyWithImpl(this._self, this._then);

  final _PaymentBreakdown _self;
  final $Res Function(_PaymentBreakdown) _then;

/// Create a copy of PaymentBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? cash = null,Object? card = null,}) {
  return _then(_PaymentBreakdown(
cash: null == cash ? _self.cash : cash // ignore: cast_nullable_to_non_nullable
as int,card: null == card ? _self.card : card // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
