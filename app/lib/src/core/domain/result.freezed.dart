// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint, type=warning, deprecated_member_use, deprecated_member_use_from_same_package
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$Result<T> {





@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is Result<T>);
}


@override
int get hashCode => runtimeType.hashCode;

@override
String toString() {
    return 'Result<$T>()';
}


}

/// @nodoc
class $ResultCopyWith<T,$Res>  {
$ResultCopyWith(Result<T> _, $Res Function(Result<T>) __);
}



/// @nodoc


class SuccessResult<T> implements Result<T> {
  const SuccessResult(this.value);
  

 final  T value;

/// Create a copy of Result
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SuccessResultCopyWith<T, SuccessResult<T>> get copyWith => _$SuccessResultCopyWithImpl<T, SuccessResult<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is SuccessResult<T>&&const DeepCollectionEquality().equals(other.value, value));
}


@override
int get hashCode {
    return Object.hash(runtimeType,const DeepCollectionEquality().hash(value));
}

@override
String toString() {
    return 'Result<$T>.success(value: $value)';
}


}

/// @nodoc
abstract mixin class $SuccessResultCopyWith<T,$Res> implements $ResultCopyWith<T, $Res> {
  factory $SuccessResultCopyWith(SuccessResult<T> value, $Res Function(SuccessResult<T>) _then) = _$SuccessResultCopyWithImpl;
@useResult
$Res call({
 T value
});




}
/// @nodoc
class _$SuccessResultCopyWithImpl<T,$Res>
    implements $SuccessResultCopyWith<T, $Res> {
  _$SuccessResultCopyWithImpl(this._self, this._then);

  final SuccessResult<T> _self;
  final $Res Function(SuccessResult<T>) _then;

/// Create a copy of Result
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? value = freezed,}) {
  return _then(SuccessResult<T>(
freezed == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as T,
  ));
}


}

/// @nodoc


class ErrorResult<T> implements Result<T> {
  const ErrorResult(this.failure);
  

 final  Failure failure;

/// Create a copy of Result
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$ErrorResultCopyWith<T, ErrorResult<T>> get copyWith => _$ErrorResultCopyWithImpl<T, ErrorResult<T>>(this, _$identity);



@override
bool operator ==(Object other) {
    return identical(this, other) || (other.runtimeType == runtimeType&&other is ErrorResult<T>&&(identical(other.failure, failure) || other.failure == failure));
}


@override
int get hashCode {
    return Object.hash(runtimeType,failure);
}

@override
String toString() {
    return 'Result<$T>.error(failure: $failure)';
}


}

/// @nodoc
abstract mixin class $ErrorResultCopyWith<T,$Res> implements $ResultCopyWith<T, $Res> {
  factory $ErrorResultCopyWith(ErrorResult<T> value, $Res Function(ErrorResult<T>) _then) = _$ErrorResultCopyWithImpl;
@useResult
$Res call({
 Failure failure
});


$FailureCopyWith<$Res> get failure;

}
/// @nodoc
class _$ErrorResultCopyWithImpl<T,$Res>
    implements $ErrorResultCopyWith<T, $Res> {
  _$ErrorResultCopyWithImpl(this._self, this._then);

  final ErrorResult<T> _self;
  final $Res Function(ErrorResult<T>) _then;

/// Create a copy of Result
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') $Res call({Object? failure = null,}) {
  return _then(ErrorResult<T>(
null == failure ? _self.failure : failure // ignore: cast_nullable_to_non_nullable
as Failure,
  ));
}

/// Create a copy of Result
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$FailureCopyWith<$Res> get failure {
  
  return $FailureCopyWith<$Res>(_self.failure, (value) {
    return _then(_self.copyWith(failure: value));
  });
}
}

// dart format on
