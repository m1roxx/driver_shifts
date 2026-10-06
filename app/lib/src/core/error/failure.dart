import 'dart:developer' as developer;
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/network/api_error.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'failure.freezed.dart';

@freezed
sealed class Failure with _$Failure {
  const Failure._();

  const factory Failure.connection() = ConnectionFailure;

  const factory Failure.timeout() = TimeoutFailure;

  const factory Failure.validation({
    @Default(<String, String>{}) Map<String, String> fieldErrors,
    @Default(<String>[]) List<String> formErrors,
  }) = ValidationFailure;

  const factory Failure.conflict({String? serverMessage}) = ConflictFailure;

  const factory Failure.badResponse({required int statusCode}) =
      BadResponseFailure;

  const factory Failure.unexpected({Object? error, StackTrace? stackTrace}) =
      UnexpectedFailure;

  bool get isTransient => switch (this) {
    ConnectionFailure() || TimeoutFailure() => true,
    BadResponseFailure(:final statusCode) => statusCode >= 500,
    ValidationFailure() || ConflictFailure() || UnexpectedFailure() => false,
  };

  String get message => switch (this) {
    ConnectionFailure() =>
      'Нет связи с сервером. Проверьте интернет и повторите.',
    TimeoutFailure() => 'Сервер не ответил вовремя. Повторите попытку.',
    ValidationFailure(:final formErrors) when formErrors.isNotEmpty =>
      formErrors.join('\n'),
    ValidationFailure() => 'Проверьте данные поездки.',
    ConflictFailure(:final serverMessage) =>
      serverMessage ?? 'Поездка с этим id уже сохранена с другими данными.',
    BadResponseFailure(:final statusCode) when statusCode >= 500 =>
      'Сервер временно недоступен. Повторите попытку.',
    BadResponseFailure(:final statusCode) =>
      'Сервер отклонил запрос (код $statusCode).',
    UnexpectedFailure() => 'Что-то пошло не так. Повторите попытку.',
  };
}

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
        fieldErrors.putIfAbsent(field, () => error.msg);
      case null:
        formErrors.add(error.msg);
    }
  }
  return Failure.validation(fieldErrors: fieldErrors, formErrors: formErrors);
}
