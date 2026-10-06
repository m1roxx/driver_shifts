import 'dart:io';

import 'package:dio/dio.dart';
import 'package:driver_shifts/src/core/config/env.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/network/handle_error_mixin.dart';
import 'package:driver_shifts/src/core/network/http_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http_client_adapter.dart';

class _ProbeRepository with HandleErrorMixin {
  _ProbeRepository(this._dio);

  final Dio _dio;

  Future<Result<Object?>> getDay() => handleError(
    () async => (await _dio.get<Object?>('/days/2026-10-01')).data,
  );
}

Future<Failure> _failureFor(
  Future<ResponseBody> Function(RequestOptions options) respond,
) async {
  final dio = createHttpClient(Env(apiBaseUrl: 'http://localhost:8000'))
    ..httpClientAdapter = FakeHttpClientAdapter(respond);
  return switch (await _ProbeRepository(dio).getDay()) {
    ErrorResult(:final failure) => failure,
    final SuccessResult<Object?> result => fail('Expected a failure: $result'),
  };
}

void main() {
  group('HandleErrorMixin', () {
    test('returns the response data on success', () async {
      final dio = createHttpClient(Env(apiBaseUrl: 'http://localhost:8000'))
        ..httpClientAdapter = FakeHttpClientAdapter(
          (_) async => jsonResponse(200, {'date': '2026-10-01'}),
        );

      expect(
        await _ProbeRepository(dio).getDay(),
        const Result<Object?>.success({'date': '2026-10-01'}),
      );
    });

    test('maps a refused connection to ConnectionFailure', () async {
      final failure = await _failureFor(
        (options) async => throw DioException.connectionError(
          requestOptions: options,
          reason: 'Connection refused',
          error: const SocketException('Connection refused'),
        ),
      );

      expect(failure, const Failure.connection());
    });

    test(
      'maps a socket error Dio left unclassified to ConnectionFailure',
      () async {
        final failure = await _failureFor(
          (_) async => throw const SocketException('Connection reset by peer'),
        );

        expect(failure, const Failure.connection());
      },
    );

    test('maps connect and receive timeouts to TimeoutFailure', () async {
      const timeout = Duration(seconds: 10);
      final timeouts = [
        (RequestOptions options) => DioException.connectionTimeout(
          timeout: timeout,
          requestOptions: options,
        ),
        (RequestOptions options) => DioException.receiveTimeout(
          timeout: timeout,
          requestOptions: options,
        ),
      ];

      for (final timeoutFor in timeouts) {
        final failure = await _failureFor(
          (options) async => throw timeoutFor(options),
        );
        expect(failure, const Failure.timeout());
      }
    });

    test('maps 5xx to BadResponseFailure with the status code', () async {
      final failure = await _failureFor(
        (_) async => ResponseBody.fromString('Bad Gateway', 502),
      );

      expect(failure, const Failure.badResponse(statusCode: 502));
    });

    test('maps 409 to ConflictFailure with the server message', () async {
      final failure = await _failureFor(
        (_) async => jsonResponse(409, {
          'detail': {
            'code': 'trip_conflict',
            'message': 'Поездка с id t1 уже сохранена с другими данными',
          },
        }),
      );

      expect(
        failure,
        const Failure.conflict(
          serverMessage: 'Поездка с id t1 уже сохранена с другими данными',
        ),
      );
    });

    test('maps 422 to ValidationFailure with errors per field', () async {
      final failure = await _failureFor(
        (_) async => jsonResponse(422, {
          'detail': [
            {
              'loc': ['body', 'amount'],
              'msg': 'Input should be greater than 0',
              'type': 'greater_than',
            },
            {
              'loc': ['body', 'payment'],
              'msg': "Input should be 'cash' or 'card'",
              'type': 'enum',
            },
            {
              'loc': ['body'],
              'msg': 'Value error, end must be after start',
              'type': 'value_error',
            },
          ],
        }),
      );

      expect(
        failure,
        const Failure.validation(
          fieldErrors: {
            'amount': 'Input should be greater than 0',
            'payment': "Input should be 'cash' or 'card'",
          },
          formErrors: ['Value error, end must be after start'],
        ),
      );
    });

    test('keeps the failure kind when a 409 or 422 body is not '
        'the API shape', () async {
      final conflict = await _failureFor(
        (_) async => ResponseBody.fromString('<html>Conflict</html>', 409),
      );
      final validation = await _failureFor(
        (_) async => jsonResponse(422, {'detail': 'Unprocessable'}),
      );

      expect(conflict, const Failure.conflict());
      expect(validation, const Failure.validation());
    });

    test('maps any other exception to UnexpectedFailure', () async {
      final result = await _ProbeRepository(Dio())
          .handleError<Object?>(() async => throw const FormatException('bad'));

      expect(
        result,
        isA<ErrorResult<Object?>>().having(
          (result) => result.failure,
          'failure',
          isA<UnexpectedFailure>().having(
            (failure) => failure.error,
            'error',
            isA<FormatException>(),
          ),
        ),
      );
    });
  });
}
