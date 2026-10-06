// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_bloc.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$DayState {

 DateTime get date; DayStatus get status; DayReport? get report; Failure? get failure;
/// Create a copy of DayState
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayStateCopyWith<DayState> get copyWith => _$DayStateCopyWithImpl<DayState>(this as DayState, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as DayState;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayState&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.status, _this.status) || other.status == _this.status)&&(identical(other.report, _this.report) || other.report == _this.report)&&(identical(other.failure, _this.failure) || other.failure == _this.failure));
}


@override
int get hashCode {
  final _this = this as DayState;
  return Object.hash(runtimeType,_this.date,_this.status,_this.report,_this.failure);
}

@override
String toString() {
  final _this = this as DayState;
  return 'DayState(date: ${_this.date}, status: ${_this.status}, report: ${_this.report}, failure: ${_this.failure})';
}


}

/// @nodoc
abstract mixin class $DayStateCopyWith<$Res>  {
  factory $DayStateCopyWith(DayState value, $Res Function(DayState) _then) = _$DayStateCopyWithImpl;
@useResult
$Res call({
 DateTime date, DayStatus status, DayReport? report, Failure? failure
});


$DayReportCopyWith<$Res>? get report;$FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class _$DayStateCopyWithImpl<$Res>
    implements $DayStateCopyWith<$Res> {
  _$DayStateCopyWithImpl(this._self, this._then);

  final DayState _self;
  final $Res Function(DayState) _then;

/// Create a copy of DayState
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? status = null,Object? report = freezed,Object? failure = freezed,}) {
  return _then(DayState(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DayStatus,report: freezed == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as DayReport?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}
/// Create a copy of DayState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayReportCopyWith<$Res>? get report {
    if (_self.report == null) {
    return null;
  }

  return $DayReportCopyWith<$Res>(_self.report!, (value) {
    return _then(_self.copyWith(report: value));
  });
}/// Create a copy of DayState
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


class _DayState implements DayState {
  const _DayState({required this.date, this.status = DayStatus.loading, this.report, this.failure});
  

@override final  DateTime date;
@override@JsonKey() final  DayStatus status;
@override final  DayReport? report;
@override final  Failure? failure;

/// Create a copy of DayState
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayStateCopyWith<_DayState> get copyWith => __$DayStateCopyWithImpl<_DayState>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayState&&(identical(other.date, date) || other.date == date)&&(identical(other.status, status) || other.status == status)&&(identical(other.report, report) || other.report == report)&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,date,status,report,failure);
}

@override
String toString() {
    return 'DayState(date: $date, status: $status, report: $report, failure: $failure)';
}


}

/// @nodoc
abstract mixin class _$DayStateCopyWith<$Res> implements $DayStateCopyWith<$Res> {
  factory _$DayStateCopyWith(_DayState value, $Res Function(_DayState) _then) = __$DayStateCopyWithImpl;
@override @useResult
$Res call({
 DateTime date, DayStatus status, DayReport? report, Failure? failure
});


@override $DayReportCopyWith<$Res>? get report;@override $FailureCopyWith<$Res>? get failure;

}
/// @nodoc
class __$DayStateCopyWithImpl<$Res>
    implements _$DayStateCopyWith<$Res> {
  __$DayStateCopyWithImpl(this._self, this._then);

  final _DayState _self;
  final $Res Function(_DayState) _then;

/// Create a copy of DayState
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? status = null,Object? report = freezed,Object? failure = freezed,}) {
  return _then(_DayState(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as DayStatus,report: freezed == report ? _self.report : report // ignore: cast_nullable_to_non_nullable
as DayReport?,failure: freezed == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure?,
  ));
}

/// Create a copy of DayState
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DayReportCopyWith<$Res>? get report {
    if (_self.report == null) {
    return null;
  }

  return $DayReportCopyWith<$Res>(_self.report!, (value) {
    return _then(_self.copyWith(report: value));
  });
}/// Create a copy of DayState
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
