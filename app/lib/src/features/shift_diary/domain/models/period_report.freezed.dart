// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'period_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PeriodReport {

@CalendarDateConverter() DateTime get start;@CalendarDateConverter() DateTime get end; DaySummary get summary; List<DayTotal> get days;
/// Create a copy of PeriodReport
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodReportCopyWith<PeriodReport> get copyWith => _$PeriodReportCopyWithImpl<PeriodReport>(this as PeriodReport, _$identity);

  /// Serializes this PeriodReport to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PeriodReport;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodReport&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.days, _this.days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PeriodReport;
  return Object.hash(runtimeType,_this.start,_this.end,_this.summary,const DeepCollectionEquality().hash(_this.days));
}

@override
String toString() {
  final _this = this as PeriodReport;
  return 'PeriodReport(start: ${_this.start}, end: ${_this.end}, summary: ${_this.summary}, days: ${_this.days})';
}


}

/// @nodoc
abstract mixin class $PeriodReportCopyWith<$Res>  {
  factory $PeriodReportCopyWith(PeriodReport value, $Res Function(PeriodReport) _then) = _$PeriodReportCopyWithImpl;
@useResult
$Res call({
@CalendarDateConverter() DateTime start,@CalendarDateConverter() DateTime end, DaySummary summary, List<DayTotal> days
});


$DaySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$PeriodReportCopyWithImpl<$Res>
    implements $PeriodReportCopyWith<$Res> {
  _$PeriodReportCopyWithImpl(this._self, this._then);

  final PeriodReport _self;
  final $Res Function(PeriodReport) _then;

/// Create a copy of PeriodReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? summary = null,Object? days = null,}) {
  return _then(PeriodReport(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DaySummary,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<DayTotal>,
  ));
}
/// Create a copy of PeriodReport
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

class _PeriodReport implements PeriodReport {
  const _PeriodReport({@CalendarDateConverter() required this.start, @CalendarDateConverter() required this.end, required this.summary, required  List<DayTotal> days}): _days = days;
  factory _PeriodReport.fromJson(Map<String, dynamic> json) => _$PeriodReportFromJson(json);

@override@CalendarDateConverter() final  DateTime start;
@override@CalendarDateConverter() final  DateTime end;
@override final  DaySummary summary;
 final  List<DayTotal> _days;
@override List<DayTotal> get days {
  if (_days is EqualUnmodifiableListView) return _days;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_days);
}


/// Create a copy of PeriodReport
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodReportCopyWith<_PeriodReport> get copyWith => __$PeriodReportCopyWithImpl<_PeriodReport>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodReportToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodReport&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.days, _days));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,start,end,summary,const DeepCollectionEquality().hash(_days));
}

@override
String toString() {
    return 'PeriodReport(start: $start, end: $end, summary: $summary, days: $days)';
}


}

/// @nodoc
abstract mixin class _$PeriodReportCopyWith<$Res> implements $PeriodReportCopyWith<$Res> {
  factory _$PeriodReportCopyWith(_PeriodReport value, $Res Function(_PeriodReport) _then) = __$PeriodReportCopyWithImpl;
@override @useResult
$Res call({
@CalendarDateConverter() DateTime start,@CalendarDateConverter() DateTime end, DaySummary summary, List<DayTotal> days
});


@override $DaySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$PeriodReportCopyWithImpl<$Res>
    implements _$PeriodReportCopyWith<$Res> {
  __$PeriodReportCopyWithImpl(this._self, this._then);

  final _PeriodReport _self;
  final $Res Function(_PeriodReport) _then;

/// Create a copy of PeriodReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? summary = null,Object? days = null,}) {
  return _then(_PeriodReport(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DaySummary,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<DayTotal>,
  ));
}

/// Create a copy of PeriodReport
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
mixin _$DayTotal {

@CalendarDateConverter() DateTime get date; DaySummary get summary;
/// Create a copy of DayTotal
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DayTotalCopyWith<DayTotal> get copyWith => _$DayTotalCopyWithImpl<DayTotal>(this as DayTotal, _$identity);

  /// Serializes this DayTotal to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as DayTotal;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DayTotal&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.summary, _this.summary) || other.summary == _this.summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as DayTotal;
  return Object.hash(runtimeType,_this.date,_this.summary);
}

@override
String toString() {
  final _this = this as DayTotal;
  return 'DayTotal(date: ${_this.date}, summary: ${_this.summary})';
}


}

/// @nodoc
abstract mixin class $DayTotalCopyWith<$Res>  {
  factory $DayTotalCopyWith(DayTotal value, $Res Function(DayTotal) _then) = _$DayTotalCopyWithImpl;
@useResult
$Res call({
@CalendarDateConverter() DateTime date, DaySummary summary
});


$DaySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class _$DayTotalCopyWithImpl<$Res>
    implements $DayTotalCopyWith<$Res> {
  _$DayTotalCopyWithImpl(this._self, this._then);

  final DayTotal _self;
  final $Res Function(DayTotal) _then;

/// Create a copy of DayTotal
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? summary = null,}) {
  return _then(DayTotal(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DaySummary,
  ));
}
/// Create a copy of DayTotal
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

class _DayTotal implements DayTotal {
  const _DayTotal({@CalendarDateConverter() required this.date, required this.summary});
  factory _DayTotal.fromJson(Map<String, dynamic> json) => _$DayTotalFromJson(json);

@override@CalendarDateConverter() final  DateTime date;
@override final  DaySummary summary;

/// Create a copy of DayTotal
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DayTotalCopyWith<_DayTotal> get copyWith => __$DayTotalCopyWithImpl<_DayTotal>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DayTotalToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _DayTotal&&(identical(other.date, date) || other.date == date)&&(identical(other.summary, summary) || other.summary == summary));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,summary);
}

@override
String toString() {
    return 'DayTotal(date: $date, summary: $summary)';
}


}

/// @nodoc
abstract mixin class _$DayTotalCopyWith<$Res> implements $DayTotalCopyWith<$Res> {
  factory _$DayTotalCopyWith(_DayTotal value, $Res Function(_DayTotal) _then) = __$DayTotalCopyWithImpl;
@override @useResult
$Res call({
@CalendarDateConverter() DateTime date, DaySummary summary
});


@override $DaySummaryCopyWith<$Res> get summary;

}
/// @nodoc
class __$DayTotalCopyWithImpl<$Res>
    implements _$DayTotalCopyWith<$Res> {
  __$DayTotalCopyWithImpl(this._self, this._then);

  final _DayTotal _self;
  final $Res Function(_DayTotal) _then;

/// Create a copy of DayTotal
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? summary = null,}) {
  return _then(_DayTotal(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DaySummary,
  ));
}

/// Create a copy of DayTotal
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
