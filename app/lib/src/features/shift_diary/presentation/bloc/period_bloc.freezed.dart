// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$PeriodState {

 Period get period; PeriodStatus get status; PeriodReport? get report; Failure? get failure; bool get slow;
/// Create a copy of PeriodState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodStateCopyWith<PeriodState> get copyWith => _$PeriodStateCopyWithImpl<PeriodState>(this as PeriodState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as PeriodState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodState&&(identical(other.period, _this.period) || other.period == _this.period)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.report, _this.report) || other.report == _this.report)&&(identical(other.failure, _this.failure) || other.failure == _this.failure)&&(identical(other.slow, _this.slow) || other.slow == _this.slow));
}


@override
int get hashCode {
  final _this = this as PeriodState;
  return Object.hash(runtimeType,_this.period,_this.status,_this.report,_this.failure,_this.slow);
}

@override
String toString() {
  final _this = this as PeriodState;
  return 'PeriodState(period: ${_this.period}, status: ${_this.status}, report: ${_this.report}, failure: ${_this.failure}, slow: ${_this.slow})';
}


}

/// @nodoc
abstract mixin class $PeriodStateCopyWith<$Res>  {
  factory $PeriodStateCopyWith(PeriodState value, $Res Function(PeriodState) _then) = _$PeriodStateCopyWithImpl;
@useResult
$Res call({
 Period period, PeriodStatus status, PeriodReport? report, Failure? failure, bool slow
});


$PeriodCopyWith<$Res> get period;$PeriodReportCopyWith<$Res>? get report;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$PeriodStateCopyWithImpl<$Res>
    implements $PeriodStateCopyWith<$Res> {
  _$PeriodStateCopyWithImpl(this._self, this._then);

  final PeriodState _self;
  final $Res Function(PeriodState) _then;

/// Create a copy of PeriodState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? status = null,Object? report = freezed,Object? failure = freezed,Object? slow = null,}) {
  return _then(PeriodState(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as Period,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PeriodStatus,report: freezed == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as PeriodReport?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,slow: null == slow ? _self.slow : slow // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}
/// Create a copy of PeriodState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodCopyWith<$Res> get period {
  
  return $PeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of PeriodState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodReportCopyWith<$Res>? get report {
    if (_self.report == null) {
    return null;
  }

  return $PeriodReportCopyWith<$Res>(_self.report!, (value) {
    return _then(_self.copyWith(report: value));
  });
}/// Create a copy of PeriodState
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
}
}



/// @nodoc


class _PeriodState implements PeriodState {
  const _PeriodState({required this.period, this.status = PeriodStatus.loading, this.report, this.failure, this.slow = false});
  

@override final  Period period;
@override@JsonKey() final  PeriodStatus status;
@override final  PeriodReport? report;
@override final  Failure? failure;
@override@JsonKey() final  bool slow;

/// Create a copy of PeriodState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodStateCopyWith<_PeriodState> get copyWith => __$PeriodStateCopyWithImpl<_PeriodState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodState&&(identical(other.period, period) || other.period == period)&&(identical(other.status, status) || other.status == status)&&(identical(other.report, report) || other.report == report)&&(identical(other.failure, failure) || other.failure == failure)&&(identical(other.slow, slow) || other.slow == slow));
}


@override
int get hashCode {
    return Object.hash(runtimeType,period,status,report,failure,slow);
}

@override
String toString() {
    return 'PeriodState(period: $period, status: $status, report: $report, failure: $failure, slow: $slow)';
}


}

/// @nodoc
abstract mixin class _$PeriodStateCopyWith<$Res> implements $PeriodStateCopyWith<$Res> {
  factory _$PeriodStateCopyWith(_PeriodState value, $Res Function(_PeriodState) _then) = __$PeriodStateCopyWithImpl;
@override @useResult
$Res call({
 Period period, PeriodStatus status, PeriodReport? report, Failure? failure, bool slow
});


@override $PeriodCopyWith<$Res> get period;@override $PeriodReportCopyWith<$Res>? get report;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$PeriodStateCopyWithImpl<$Res>
    implements _$PeriodStateCopyWith<$Res> {
  __$PeriodStateCopyWithImpl(this._self, this._then);

  final _PeriodState _self;
  final $Res Function(_PeriodState) _then;

/// Create a copy of PeriodState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? status = null,Object? report = freezed,Object? failure = freezed,Object? slow = null,}) {
  return _then(_PeriodState(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as Period,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as PeriodStatus,report: freezed == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as PeriodReport?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,slow: null == slow ? _self.slow : slow // ignore: cast_nullable_to_non_nullable
as bool,
  ));
}

/// Create a copy of PeriodState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodCopyWith<$Res> get period {
  
  return $PeriodCopyWith<$Res>(_self.period, (value) {
    return _then(_self.copyWith(period: value));
  });
}/// Create a copy of PeriodState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodReportCopyWith<$Res>? get report {
    if (_self.report == null) {
    return null;
  }

  return $PeriodReportCopyWith<$Res>(_self.report!, (value) {
    return _then(_self.copyWith(report: value));
  });
}/// Create a copy of PeriodState
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
}
}

// dart format on
