// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Period {

 PeriodKind get kind; DateTime get start;
/// Create a copy of Period
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodCopyWith<Period> get copyWith => _$PeriodCopyWithImpl<Period>(this as Period, _$identity);



@override
bool operator ==(Object other) {
  final _this = this as Period;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Period&&(identical(other.kind, _this.kind) || other.kind == _this.kind)&&(identical(other.start, _this.start) || other.start == _this.start));
}


@override
int get hashCode {
  final _this = this as Period;
  return Object.hash(runtimeType,_this.kind,_this.start);
}

@override
String toString() {
  final _this = this as Period;
  return 'Period(kind: ${_this.kind}, start: ${_this.start})';
}


}

/// @nodoc
abstract mixin class $PeriodCopyWith<$Res>  {
  factory $PeriodCopyWith(Period value, $Res Function(Period) _then) = _$PeriodCopyWithImpl;
@useResult
$Res call({
 PeriodKind kind, DateTime start
});




}
/// @nodoc
class _$PeriodCopyWithImpl<$Res>
    implements $PeriodCopyWith<$Res> {
  _$PeriodCopyWithImpl(this._self, this._then);

  final Period _self;
  final $Res Function(Period) _then;

/// Create a copy of Period
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? kind = null,Object? start = null,}) {
  return _then(Period(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PeriodKind,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}



/// @nodoc


class _Period extends Period {
   _Period({required this.kind, required this.start}): assert(start == DateTime.utc(start.year, start.month, start.day) && (kind == PeriodKind.week ? start.weekday == DateTime.monday : start.day == 1), 'A period starts on a Monday or on the 1st, DateTime.utc(y, m, d): use Period.containing'),super._();
  

@override final  PeriodKind kind;
@override final  DateTime start;

/// Create a copy of Period
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodCopyWith<_Period> get copyWith => __$PeriodCopyWithImpl<_Period>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _Period&&(identical(other.kind, kind) || other.kind == kind)&&(identical(other.start, start) || other.start == start));
}


@override
int get hashCode {
    return Object.hash(runtimeType,kind,start);
}

@override
String toString() {
    return 'Period(kind: $kind, start: $start)';
}


}

/// @nodoc
abstract mixin class _$PeriodCopyWith<$Res> implements $PeriodCopyWith<$Res> {
  factory _$PeriodCopyWith(_Period value, $Res Function(_Period) _then) = __$PeriodCopyWithImpl;
@override @useResult
$Res call({
 PeriodKind kind, DateTime start
});




}
/// @nodoc
class __$PeriodCopyWithImpl<$Res>
    implements _$PeriodCopyWith<$Res> {
  __$PeriodCopyWithImpl(this._self, this._then);

  final _Period _self;
  final $Res Function(_Period) _then;

/// Create a copy of Period
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? kind = null,Object? start = null,}) {
  return _then(_Period(
kind: null == kind ? _self.kind : kind // ignore: cast_nullable_to_non_nullable
as PeriodKind,start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
