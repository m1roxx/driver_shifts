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

@CalendarDateConverter() DateTime get start;@CalendarDateConverter() DateTime get end; DaySummary get summary; List<DayTotal> get days; PeriodStats get stats;
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
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodReport&&(identical(other.start, _this.start) || other.start == _this.start)&&(identical(other.end, _this.end) || other.end == _this.end)&&(identical(other.summary, _this.summary) || other.summary == _this.summary)&&const DeepCollectionEquality().equals(other.days, _this.days)&&(identical(other.stats, _this.stats) || other.stats == _this.stats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PeriodReport;
  return Object.hash(runtimeType,_this.start,_this.end,_this.summary,const DeepCollectionEquality().hash(_this.days),_this.stats);
}

@override
String toString() {
  final _this = this as PeriodReport;
  return 'PeriodReport(start: ${_this.start}, end: ${_this.end}, summary: ${_this.summary}, days: ${_this.days}, stats: ${_this.stats})';
}


}

/// @nodoc
abstract mixin class $PeriodReportCopyWith<$Res>  {
  factory $PeriodReportCopyWith(PeriodReport value, $Res Function(PeriodReport) _then) = _$PeriodReportCopyWithImpl;
@useResult
$Res call({
@CalendarDateConverter() DateTime start,@CalendarDateConverter() DateTime end, DaySummary summary, List<DayTotal> days, PeriodStats stats
});


$DaySummaryCopyWith<$Res> get summary;$PeriodStatsCopyWith<$Res> get stats;

}
/// @nodoc
class _$PeriodReportCopyWithImpl<$Res>
    implements $PeriodReportCopyWith<$Res> {
  _$PeriodReportCopyWithImpl(this._self, this._then);

  final PeriodReport _self;
  final $Res Function(PeriodReport) _then;

/// Create a copy of PeriodReport
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? start = null,Object? end = null,Object? summary = null,Object? days = null,Object? stats = null,}) {
  return _then(PeriodReport(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DaySummary,days: null == days ? _self.days : days // ignore: cast_nullable_to_non_nullable
as List<DayTotal>,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as PeriodStats,
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
}/// Create a copy of PeriodReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStatsCopyWith<$Res> get stats {
  
  return $PeriodStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
  });
}
}



/// @nodoc
@JsonSerializable()

class _PeriodReport implements PeriodReport {
  const _PeriodReport({@CalendarDateConverter() required this.start, @CalendarDateConverter() required this.end, required this.summary, required  List<DayTotal> days, required this.stats}): _days = days;
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

@override final  PeriodStats stats;

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
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodReport&&(identical(other.start, start) || other.start == start)&&(identical(other.end, end) || other.end == end)&&(identical(other.summary, summary) || other.summary == summary)&&const DeepCollectionEquality().equals(other.days, _days)&&(identical(other.stats, stats) || other.stats == stats));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,start,end,summary,const DeepCollectionEquality().hash(_days),stats);
}

@override
String toString() {
    return 'PeriodReport(start: $start, end: $end, summary: $summary, days: $days, stats: $stats)';
}


}

/// @nodoc
abstract mixin class _$PeriodReportCopyWith<$Res> implements $PeriodReportCopyWith<$Res> {
  factory _$PeriodReportCopyWith(_PeriodReport value, $Res Function(_PeriodReport) _then) = __$PeriodReportCopyWithImpl;
@override @useResult
$Res call({
@CalendarDateConverter() DateTime start,@CalendarDateConverter() DateTime end, DaySummary summary, List<DayTotal> days, PeriodStats stats
});


@override $DaySummaryCopyWith<$Res> get summary;@override $PeriodStatsCopyWith<$Res> get stats;

}
/// @nodoc
class __$PeriodReportCopyWithImpl<$Res>
    implements _$PeriodReportCopyWith<$Res> {
  __$PeriodReportCopyWithImpl(this._self, this._then);

  final _PeriodReport _self;
  final $Res Function(_PeriodReport) _then;

/// Create a copy of PeriodReport
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? start = null,Object? end = null,Object? summary = null,Object? days = null,Object? stats = null,}) {
  return _then(_PeriodReport(
start: null == start ? _self.start : start // ignore: cast_nullable_to_non_nullable
as DateTime,end: null == end ? _self.end : end // ignore: cast_nullable_to_non_nullable
as DateTime,summary: null == summary ? _self.summary : summary // ignore: cast_nullable_to_non_nullable
as DaySummary,days: null == days ? _self._days : days // ignore: cast_nullable_to_non_nullable
as List<DayTotal>,stats: null == stats ? _self.stats : stats // ignore: cast_nullable_to_non_nullable
as PeriodStats,
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
}/// Create a copy of PeriodReport
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$PeriodStatsCopyWith<$Res> get stats {
  
  return $PeriodStatsCopyWith<$Res>(_self.stats, (value) {
    return _then(_self.copyWith(stats: value));
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


/// @nodoc
mixin _$PeriodStats {

@WholeNumberConverter() int? get averageTrip;@WholeNumberConverter() int? get netPerHour; BestDay? get bestDay;
/// Create a copy of PeriodStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeriodStatsCopyWith<PeriodStats> get copyWith => _$PeriodStatsCopyWithImpl<PeriodStats>(this as PeriodStats, _$identity);

  /// Serializes this PeriodStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as PeriodStats;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeriodStats&&(identical(other.averageTrip, _this.averageTrip) || other.averageTrip == _this.averageTrip)&&(identical(other.netPerHour, _this.netPerHour) || other.netPerHour == _this.netPerHour)&&(identical(other.bestDay, _this.bestDay) || other.bestDay == _this.bestDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as PeriodStats;
  return Object.hash(runtimeType,_this.averageTrip,_this.netPerHour,_this.bestDay);
}

@override
String toString() {
  final _this = this as PeriodStats;
  return 'PeriodStats(averageTrip: ${_this.averageTrip}, netPerHour: ${_this.netPerHour}, bestDay: ${_this.bestDay})';
}


}

/// @nodoc
abstract mixin class $PeriodStatsCopyWith<$Res>  {
  factory $PeriodStatsCopyWith(PeriodStats value, $Res Function(PeriodStats) _then) = _$PeriodStatsCopyWithImpl;
@useResult
$Res call({
@WholeNumberConverter() int? averageTrip,@WholeNumberConverter() int? netPerHour, BestDay? bestDay
});


$BestDayCopyWith<$Res>? get bestDay;

}
/// @nodoc
class _$PeriodStatsCopyWithImpl<$Res>
    implements $PeriodStatsCopyWith<$Res> {
  _$PeriodStatsCopyWithImpl(this._self, this._then);

  final PeriodStats _self;
  final $Res Function(PeriodStats) _then;

/// Create a copy of PeriodStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? averageTrip = freezed,Object? netPerHour = freezed,Object? bestDay = freezed,}) {
  return _then(PeriodStats(
averageTrip: freezed == averageTrip ? _self.averageTrip : averageTrip // ignore: cast_nullable_to_non_nullable
as int?,netPerHour: freezed == netPerHour ? _self.netPerHour : netPerHour // ignore: cast_nullable_to_non_nullable
as int?,bestDay: freezed == bestDay ? _self.bestDay : bestDay // ignore: cast_nullable_to_non_nullable
as BestDay?,
  ));
}
/// Create a copy of PeriodStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BestDayCopyWith<$Res>? get bestDay {
    if (_self.bestDay == null) {
    return null;
  }

  return $BestDayCopyWith<$Res>(_self.bestDay!, (value) {
    return _then(_self.copyWith(bestDay: value));
  });
}
}



/// @nodoc
@JsonSerializable()

class _PeriodStats implements PeriodStats {
  const _PeriodStats({@WholeNumberConverter() required this.averageTrip, @WholeNumberConverter() required this.netPerHour, required this.bestDay});
  factory _PeriodStats.fromJson(Map<String, dynamic> json) => _$PeriodStatsFromJson(json);

@override@WholeNumberConverter() final  int? averageTrip;
@override@WholeNumberConverter() final  int? netPerHour;
@override final  BestDay? bestDay;

/// Create a copy of PeriodStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeriodStatsCopyWith<_PeriodStats> get copyWith => __$PeriodStatsCopyWithImpl<_PeriodStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeriodStatsToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeriodStats&&(identical(other.averageTrip, averageTrip) || other.averageTrip == averageTrip)&&(identical(other.netPerHour, netPerHour) || other.netPerHour == netPerHour)&&(identical(other.bestDay, bestDay) || other.bestDay == bestDay));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,averageTrip,netPerHour,bestDay);
}

@override
String toString() {
    return 'PeriodStats(averageTrip: $averageTrip, netPerHour: $netPerHour, bestDay: $bestDay)';
}


}

/// @nodoc
abstract mixin class _$PeriodStatsCopyWith<$Res> implements $PeriodStatsCopyWith<$Res> {
  factory _$PeriodStatsCopyWith(_PeriodStats value, $Res Function(_PeriodStats) _then) = __$PeriodStatsCopyWithImpl;
@override @useResult
$Res call({
@WholeNumberConverter() int? averageTrip,@WholeNumberConverter() int? netPerHour, BestDay? bestDay
});


@override $BestDayCopyWith<$Res>? get bestDay;

}
/// @nodoc
class __$PeriodStatsCopyWithImpl<$Res>
    implements _$PeriodStatsCopyWith<$Res> {
  __$PeriodStatsCopyWithImpl(this._self, this._then);

  final _PeriodStats _self;
  final $Res Function(_PeriodStats) _then;

/// Create a copy of PeriodStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? averageTrip = freezed,Object? netPerHour = freezed,Object? bestDay = freezed,}) {
  return _then(_PeriodStats(
averageTrip: freezed == averageTrip ? _self.averageTrip : averageTrip // ignore: cast_nullable_to_non_nullable
as int?,netPerHour: freezed == netPerHour ? _self.netPerHour : netPerHour // ignore: cast_nullable_to_non_nullable
as int?,bestDay: freezed == bestDay ? _self.bestDay : bestDay // ignore: cast_nullable_to_non_nullable
as BestDay?,
  ));
}

/// Create a copy of PeriodStats
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$BestDayCopyWith<$Res>? get bestDay {
    if (_self.bestDay == null) {
    return null;
  }

  return $BestDayCopyWith<$Res>(_self.bestDay!, (value) {
    return _then(_self.copyWith(bestDay: value));
  });
}
}


/// @nodoc
mixin _$BestDay {

@CalendarDateConverter() DateTime get date;@WholeNumberConverter() int get net;
/// Create a copy of BestDay
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$BestDayCopyWith<BestDay> get copyWith => _$BestDayCopyWithImpl<BestDay>(this as BestDay, _$identity);

  /// Serializes this BestDay to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  final _this = this as BestDay;
  return identical(this, other) || (other.runtimeType == runtimeType&&other is BestDay&&(identical(other.date, _this.date) || other.date == _this.date)&&(identical(other.net, _this.net) || other.net == _this.net));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
  final _this = this as BestDay;
  return Object.hash(runtimeType,_this.date,_this.net);
}

@override
String toString() {
  final _this = this as BestDay;
  return 'BestDay(date: ${_this.date}, net: ${_this.net})';
}


}

/// @nodoc
abstract mixin class $BestDayCopyWith<$Res>  {
  factory $BestDayCopyWith(BestDay value, $Res Function(BestDay) _then) = _$BestDayCopyWithImpl;
@useResult
$Res call({
@CalendarDateConverter() DateTime date,@WholeNumberConverter() int net
});




}
/// @nodoc
class _$BestDayCopyWithImpl<$Res>
    implements $BestDayCopyWith<$Res> {
  _$BestDayCopyWithImpl(this._self, this._then);

  final BestDay _self;
  final $Res Function(BestDay) _then;

/// Create a copy of BestDay
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? net = null,}) {
  return _then(BestDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}



/// @nodoc
@JsonSerializable()

class _BestDay implements BestDay {
  const _BestDay({@CalendarDateConverter() required this.date, @WholeNumberConverter() required this.net});
  factory _BestDay.fromJson(Map<String, dynamic> json) => _$BestDayFromJson(json);

@override@CalendarDateConverter() final  DateTime date;
@override@WholeNumberConverter() final  int net;

/// Create a copy of BestDay
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$BestDayCopyWith<_BestDay> get copyWith => __$BestDayCopyWithImpl<_BestDay>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$BestDayToJson(this, );
}

@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is _BestDay&&(identical(other.date, date) || other.date == date)&&(identical(other.net, net) || other.net == net));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode {
    return Object.hash(runtimeType,date,net);
}

@override
String toString() {
    return 'BestDay(date: $date, net: $net)';
}


}

/// @nodoc
abstract mixin class _$BestDayCopyWith<$Res> implements $BestDayCopyWith<$Res> {
  factory _$BestDayCopyWith(_BestDay value, $Res Function(_BestDay) _then) = __$BestDayCopyWithImpl;
@override @useResult
$Res call({
@CalendarDateConverter() DateTime date,@WholeNumberConverter() int net
});




}
/// @nodoc
class __$BestDayCopyWithImpl<$Res>
    implements _$BestDayCopyWith<$Res> {
  __$BestDayCopyWithImpl(this._self, this._then);

  final _BestDay _self;
  final $Res Function(_BestDay) _then;

/// Create a copy of BestDay
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? net = null,}) {
  return _then(_BestDay(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as DateTime,net: null == net ? _self.net : net // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
