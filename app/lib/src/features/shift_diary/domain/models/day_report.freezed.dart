// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'day_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$DayReport {

@CalendarDateConverter() DateTime get date; DaySummary get summary; List<Trip> get trips;
/// Create a copy of DayReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayReportCopyWith<DayReport> get copyWith => _$DayReportCopyWithImpl<DayReport>(this as DayReport, _$identity);

  /// Serializes this DayReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DayReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayReport&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.trips, _this.trips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DayReport;
  return Object.hash(runtimeType,_this.date,_this.summary,const DeepCollectionEquality().hash(_this.trips));
}

@override
String toString() {
  final _this = this as DayReport;
  return 'DayReport(date: ${_this.date}, summary: ${_this.summary}, trips: ${_this.trips})';
}


}

/// @nodoc
abstract mixin class $DayReportCopyWith<$Res>  {
  factory $DayReportCopyWith(DayReport value, $Res Function(DayReport) _then) = _$DayReportCopyWithImpl;
@useResult
$Res call({
@CalendarDateConverter() DateTime date, DaySummary summary, List<Trip> trips
});


$DaySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$DayReportCopyWithImpl<$Res>
    implements $DayReportCopyWith<$Res> {
  _$DayReportCopyWithImpl(this._self, this._then);

  final DayReport _self;
  final $Res Function(DayReport) _then;

/// Create a copy of DayReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? summary = null,Object? trips = null,}) {
  return _then(DayReport(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DaySummary,trips: null == trips ? _self.trips : trips // ignore: cast_nullable_to_non_nullable
as List<Trip>,
  ));
}
/// Create a copy of DayReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DaySummaryCopyWith<$Res> get summary {
  
  return $DaySummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}



/// @nodoc
@JsonSerializable()

class _DayReport implements DayReport {
  const _DayReport({@CalendarDateConverter() required this.date, required this.summary, required  List<Trip> trips}): _trips = trips;
  factory _DayReport.fromJson(Map<String, dynamic> json) => _$DayReportFromJson(json);

@override@CalendarDateConverter() final  DateTime date;
@override final  DaySummary summary;
 final  List<Trip> _trips;
@override List<Trip> get trips {
  if (_trips is EqualUnmodifiableListView) return _trips;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_trips);
}


/// Create a copy of DayReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayReportCopyWith<_DayReport> get copyWith => __$DayReportCopyWithImpl<_DayReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayReportToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayReport&&(identical(other.date, date) || other.date == date)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.trips, _trips));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,summary,const DeepCollectionEquality().hash(_trips));
}

@override
String toString() {
    return 'DayReport(date: $date, summary: $summary, trips: $trips)';
}


}

/// @nodoc
abstract mixin class _$DayReportCopyWith<$Res> implements $DayReportCopyWith<$Res> {
  factory _$DayReportCopyWith(_DayReport value, $Res Function(_DayReport) _then) = __$DayReportCopyWithImpl;
@override @useResult
$Res call({
@CalendarDateConverter() DateTime date, DaySummary summary, List<Trip> trips
});


@override $DaySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$DayReportCopyWithImpl<$Res>
    implements _$DayReportCopyWith<$Res> {
  __$DayReportCopyWithImpl(this._self, this._then);

  final _DayReport _self;
  final $Res Function(_DayReport) _then;

/// Create a copy of DayReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? summary = null,Object? trips = null,}) {
  return _then(_DayReport(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DaySummary,trips: null == trips ? _self._trips : trips // ignore: cast_nullable_to_non_nullable
as List<Trip>,
  ));
}

/// Create a copy of DayReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$DaySummaryCopyWith<$Res> get summary {
  
  return $DaySummaryCopyWith<$Res>(_self.summary, (value) {
    return _then(_self.copyWith(summary: value));
  });
}
}

// dart format on
