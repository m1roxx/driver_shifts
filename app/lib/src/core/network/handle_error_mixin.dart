import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/network/api_error.dart';

mixin HandleErrorMixin {
  Future<Result<T>> handleError<T>(Future<T> Function() request) async {
    try {
      return Result.success(await request());
    } on DioException catch (error) {
      return Result.error(_failureOf(error));
    } on Object catch (error, stackTrace) {
      developer.log(
        'Unexpected error',
        name: 'repository',
        error: error,
        stackTrace: stackTrace,
      );
      return Result.error(
        Failure.unexpected(error: error, stackTrace: stackTrace),
      );
    }
  }
}

Failure _failureOf(DioException error) => switch (error.type) {
  DioExceptionType.connectionError => const Failure.connection(),
  DioExceptionType.connectionTimeout ||
  DioExceptionType.sendTimeout ||
  DioExceptionType.receiveTimeout ||
  DioExceptionType.transformTimeout => const Failure.timeout(),
  DioExceptionType.badResponse => _failureOfResponse(error.response),
  DioExceptionType.unknown
      when error.error is SocketException || error.error is HttpException =>
    const Failure.connection(),
  DioExceptionType.badCertificate ||
  DioExceptionType.cancel ||
  DioExceptionType.unknown => Failure.unexpected(
    error: error,
    stackTrace: error.stackTrace,
  ),
};

Failure _failureOfResponse(Response<Object?>? response) {
  final body = response?.data;
  return switch (response?.statusCode) {
    409 => Failure.conflict(
      serverMessage: ConflictErrorBody.tryParse(body)?.detail.message,
    ),
    422 => _validationFailure(ValidationErrorBody.tryParse(body)),
    final int statusCode => Failure.badResponse(statusCode: statusCode),
    null => const Failure.unexpected(),
  };
}

Failure _validationFailure(ValidationErrorBody? body) {
  final fieldErrors = <String, String>{};
  final formErrors = <String>[];
  for (final error in body?.detail ?? const <ValidationErrorItem>[]) {
    switch (error.field) {
      case final field?:
        fieldErrors.putIfAbsent(field, () => error.type);
      case null:
        formErrors.add(error.type);
    }
  }
  return Failure.validation(fieldErrors: fieldErrors, formErrors: formErrors);
}
