// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'add_trip_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$TripDraft {

 DateTime get startDay; DateTime get endDay; ClockTime? get startTime; ClockTime? get endTime; int? get amount; int? get commission; PaymentMethod? get payment;
/// Create a copy of TripDraft
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$TripDraftCopyWith<TripDraft> get copyWith => _$TripDraftCopyWithImpl<TripDraft>(this as TripDraft, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as TripDraft;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is TripDraft&&(identical(other.startDay, _this.startDay) || other.startDay == _this.startDay)&&(identical(other.endDay, _this.endDay) || other.endDay == _this.endDay)&&(identical(other.startTime, _this.startTime) || other.startTime == _this.startTime)&&(identical(other.endTime, _this.endTime) || other.endTime == _this.endTime)&&(identical(other.amount, _this.amount) || other.amount == _this.amount)&&(identical(other.commission, _this.commission) || other.commission == _this.commission)&&(identical(other.payment, _this.payment) || other.payment == _this.payment));
}


@override
int get hashCode {
  final _this = this as TripDraft;
  return Object.hash(runtimeType,_this.startDay,_this.endDay,_this.startTime,_this.endTime,_this.amount,_this.commission,_this.payment);
}

@override
String toString() {
  final _this = this as TripDraft;
  return 'TripDraft(startDay: ${_this.startDay}, endDay: ${_this.endDay}, startTime: ${_this.startTime}, endTime: ${_this.endTime}, amount: ${_this.amount}, commission: ${_this.commission}, payment: ${_this.payment})';
}


}

/// @nodoc
abstract mixin class $TripDraftCopyWith<$Res>  {
  factory $TripDraftCopyWith(TripDraft value, $Res Function(TripDraft) _then) = _$TripDraftCopyWithImpl;
@useResult
$Res call({
 DateTime startDay, DateTime endDay, ClockTime? startTime, ClockTime? endTime, int? amount, int? commission, PaymentMethod? payment
});




}
/// @nodoc
class _$TripDraftCopyWithImpl<$Res>
    implements $TripDraftCopyWith<$Res> {
  _$TripDraftCopyWithImpl(this._self, this._then);

  final TripDraft _self;
  final $Res Function(TripDraft) _then;

/// Create a copy of TripDraft
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? startDay = null,Object? endDay = null,Object? startTime = freezed,Object? endTime = freezed,Object? amount = freezed,Object? commission = freezed,Object? payment = freezed,}) {
  return _then(TripDraft(
startDay: null == startDay ? _self.startDay : startDay // ignore: cast_nullable_to_non_nullable
as DateTime,endDay: null == endDay ? _self.endDay : endDay // ignore: cast_nullable_to_non_nullable
as DateTime,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as ClockTime?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as ClockTime?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,commission: freezed == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as PaymentMethod?,
  ));
}

}



/// @nodoc


class _TripDraft implements TripDraft {
  const _TripDraft({required this.startDay, required this.endDay, this.startTime, this.endTime, this.amount, this.commission, this.payment});
  

@override final  DateTime startDay;
@override final  DateTime endDay;
@override final  ClockTime? startTime;
@override final  ClockTime? endTime;
@override final  int? amount;
@override final  int? commission;
@override final  PaymentMethod? payment;

/// Create a copy of TripDraft
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$TripDraftCopyWith<_TripDraft> get copyWith => __$TripDraftCopyWithImpl<_TripDraft>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _TripDraft&&(identical(other.startDay, startDay) || other.startDay == startDay)&&(identical(other.endDay, endDay) || other.endDay == endDay)&&(identical(other.startTime, startTime) || other.startTime == startTime)&&(identical(other.endTime, endTime) || other.endTime == endTime)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.commission, commission) || other.commission == commission)&&(identical(other.payment, payment) || other.payment == payment));
}


@override
int get hashCode {
    return Object.hash(runtimeType,startDay,endDay,startTime,endTime,amount,commission,payment);
}

@override
String toString() {
    return 'TripDraft(startDay: $startDay, endDay: $endDay, startTime: $startTime, endTime: $endTime, amount: $amount, commission: $commission, payment: $payment)';
}


}

/// @nodoc
abstract mixin class _$TripDraftCopyWith<$Res> implements $TripDraftCopyWith<$Res> {
  factory _$TripDraftCopyWith(_TripDraft value, $Res Function(_TripDraft) _then) = __$TripDraftCopyWithImpl;
@override @useResult
$Res call({
 DateTime startDay, DateTime endDay, ClockTime? startTime, ClockTime? endTime, int? amount, int? commission, PaymentMethod? payment
});




}
/// @nodoc
class __$TripDraftCopyWithImpl<$Res>
    implements _$TripDraftCopyWith<$Res> {
  __$TripDraftCopyWithImpl(this._self, this._then);

  final _TripDraft _self;
  final $Res Function(_TripDraft) _then;

/// Create a copy of TripDraft
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? startDay = null,Object? endDay = null,Object? startTime = freezed,Object? endTime = freezed,Object? amount = freezed,Object? commission = freezed,Object? payment = freezed,}) {
  return _then(_TripDraft(
startDay: null == startDay ? _self.startDay : startDay // ignore: cast_nullable_to_non_nullable
as DateTime,endDay: null == endDay ? _self.endDay : endDay // ignore: cast_nullable_to_non_nullable
as DateTime,startTime: freezed == startTime ? _self.startTime : startTime // ignore: cast_nullable_to_non_nullable
as ClockTime?,endTime: freezed == endTime ? _self.endTime : endTime // ignore: cast_nullable_to_non_nullable
as ClockTime?,amount: freezed == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as int?,commission: freezed == commission ? _self.commission : commission // ignore: cast_nullable_to_non_nullable
as int?,payment: freezed == payment ? _self.payment : payment // ignore: cast_nullable_to_non_nullable
as PaymentMethod?,
  ));
}


}

/// @nodoc
mixin _$AddTripState {

 String get tripId; TripDraft get draft; AddTripStatus get status; Map<TripField, TripFieldError> get fieldErrors; Failure? get failure; Trip? get trip;
/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$AddTripStateCopyWith<AddTripState> get copyWith => _$AddTripStateCopyWithImpl<AddTripState>(this as AddTripState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as AddTripState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is AddTripState&&(identical(other.tripId, _this.tripId) || other.tripId == _this.tripId)&&(identical(other.draft, _this.draft) || other.draft == _this.draft)&&(identical(other.status, _this.status) || other.status == _this.status)&&const DeepCollectionEquality().equals(other.fieldErrors, _this.fieldErrors)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.trip, _this.trip) || other.trip == _this.trip));
}


@override
int get hashCode {
  final _this = this as AddTripState;
  return Object.hash(runtimeType,_this.tripId,_this.draft,_this.status,const DeepCollectionEquality().hash(_this.fieldErrors),_this.failure,_this.trip);
}

@override
String toString() {
  final _this = this as AddTripState;
  return 'AddTripState(tripId: ${_this.tripId}, draft: ${_this.draft}, status: ${_this.status}, fieldErrors: ${_this.fieldErrors}, failure: ${_this.failure}, trip: ${_this.trip})';
}


}

/// @nodoc
abstract mixin class $AddTripStateCopyWith<$Res>  {
  factory $AddTripStateCopyWith(AddTripState value, $Res Function(AddTripState) _then) = _$AddTripStateCopyWithImpl;
@useResult
$Res call({
 String tripId, TripDraft draft, AddTripStatus status, Map<TripField, TripFieldError> fieldErrors, Failure? failure, Trip? trip
});


$TripDraftCopyWith<$Res> get draft;$FailureCopyWith<$Res>? get failure;$TripCopyWith<$Res>? get trip;

}
/// @nodoc
class _$AddTripStateCopyWithImpl<$Res>
    implements $AddTripStateCopyWith<$Res> {
  _$AddTripStateCopyWithImpl(this._self, this._then);

  final AddTripState _self;
  final $Res Function(AddTripState) _then;

/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? tripId = null,Object? draft = null,Object? status = null,Object? fieldErrors = null,Object? failure = freezed,Object? trip = freezed,}) {
  return _then(AddTripState(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as TripDraft,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AddTripStatus,fieldErrors: null == fieldErrors ? _self.fieldErrors : fieldErrors // ignore: cast_nullable_to_non_nullable
as Map<TripField, TripFieldError>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,trip: freezed == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip?,
  ));
}
/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripDraftCopyWith<$Res> get draft {
  
  return $TripDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res>? get trip {
    if (_self.trip == null) {
    return null;
  }

  return $TripCopyWith<$Res>(_self.trip!, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}



/// @nodoc


class _AddTripState extends AddTripState {
  const _AddTripState({required this.tripId, required this.draft, this.status = AddTripStatus.editing,  Map<TripField, TripFieldError> fieldErrors = const <TripField, TripFieldError>{}, this.failure, this.trip}): _fieldErrors = fieldErrors,super._();
  

@override final  String tripId;
@override final  TripDraft draft;
@override@JsonKey() final  AddTripStatus status;
 final  Map<TripField, TripFieldError> _fieldErrors;
@override@JsonKey() Map<TripField, TripFieldError> get fieldErrors {
  if (_fieldErrors is EqualUnmodifiableMapView) return _fieldErrors;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableMapView(_fieldErrors);
}

@override final  Failure? failure;
@override final  Trip? trip;

/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$AddTripStateCopyWith<_AddTripState> get copyWith => __$AddTripStateCopyWithImpl<_AddTripState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _AddTripState&&(identical(other.tripId, tripId) || other.tripId == tripId)&&(identical(other.draft, draft) || other.draft == draft)&&(identical(other.status, status) || other.status == status)&&const DeepCollectionEquality().equals(other.fieldErrors, _fieldErrors)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.trip, trip) || other.trip == trip));
}


@override
int get hashCode {
    return Object.hash(runtimeType,tripId,draft,status,const DeepCollectionEquality().hash(_fieldErrors),failure,trip);
}

@override
String toString() {
    return 'AddTripState(tripId: $tripId, draft: $draft, status: $status, fieldErrors: $fieldErrors, failure: $failure, trip: $trip)';
}


}

/// @nodoc
abstract mixin class _$AddTripStateCopyWith<$Res> implements $AddTripStateCopyWith<$Res> {
  factory _$AddTripStateCopyWith(_AddTripState value, $Res Function(_AddTripState) _then) = __$AddTripStateCopyWithImpl;
@override @useResult
$Res call({
 String tripId, TripDraft draft, AddTripStatus status, Map<TripField, TripFieldError> fieldErrors, Failure? failure, Trip? trip
});


@override $TripDraftCopyWith<$Res> get draft;@override $FailureCopyWith<$Res>? get failure;@override $TripCopyWith<$Res>? get trip;

}
/// @nodoc
class __$AddTripStateCopyWithImpl<$Res>
    implements _$AddTripStateCopyWith<$Res> {
  __$AddTripStateCopyWithImpl(this._self, this._then);

  final _AddTripState _self;
  final $Res Function(_AddTripState) _then;

/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? tripId = null,Object? draft = null,Object? status = null,Object? fieldErrors = null,Object? failure = freezed,Object? trip = freezed,}) {
  return _then(_AddTripState(
tripId: null == tripId ? _self.tripId : tripId // ignore: cast_nullable_to_non_nullable
as String,draft: null == draft ? _self.draft : draft // ignore: cast_nullable_to_non_nullable
as TripDraft,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as AddTripStatus,fieldErrors: null == fieldErrors ? _self._fieldErrors : fieldErrors // ignore: cast_nullable_to_non_nullable
as Map<TripField, TripFieldError>,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,trip: freezed == trip ? _self.trip : trip // ignore: cast_nullable_to_non_nullable
as Trip?,
  ));
}

/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripDraftCopyWith<$Res> get draft {
  
  return $TripDraftCopyWith<$Res>(_self.draft, (value) {
    return _then(_self.copyWith(draft: value));
  });
}/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res>? get failure {
    if (_self.failure == null) {
    return null;
  }

  return $FailureCopyWith<$Res>(_self.failure!, (value) {
    return _then(_self.copyWith(failure: value));
  });
}/// Create a copy of AddTripState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$TripCopyWith<$Res>? get trip {
    if (_self.trip == null) {
    return null;
  }

  return $TripCopyWith<$Res>(_self.trip!, (value) {
    return _then(_self.copyWith(trip: value));
  });
}
}

// dart format on
