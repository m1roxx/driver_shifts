import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'result.freezed.dart';

@freezed
sealed class Result<T> with _$Result<T> {
  const factory Result.success(T value) = SuccessResult<T>;
  const factory Result.error(Failure failure) = ErrorResult<T>;
}
