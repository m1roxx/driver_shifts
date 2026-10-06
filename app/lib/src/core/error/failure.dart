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
