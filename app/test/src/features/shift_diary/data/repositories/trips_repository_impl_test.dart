import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:driver_shifts/src/core/config/env.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/network/http_client.dart';
import 'package:driver_shifts/src/features/shift_diary/data/datasources/trips_remote_datasource.dart';
import 'package:driver_shifts/src/features/shift_diary/data/repositories/trips_repository_impl.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_http_client_adapter.dart';

TripsRepositoryImpl _repositoryWith(FakeHttpClientAdapter adapter) {
  final dio = createHttpClient(Env(apiBaseUrl: 'http://localhost:8000'))
    ..httpClientAdapter = adapter;
  return TripsRepositoryImpl(TripsRemoteDataSource(dio));
}

void main() {
  test('asks for the day by its date and returns the report', () async {
    final adapter = FakeHttpClientAdapter(
      (_) async => jsonResponse(200, jsonDecode(apiDayExample)),
    );

    final result = await _repositoryWith(adapter).getDay(oct1);

    expect(result, Result.success(taskExampleReport));
    expect(
      adapter.requests.single.uri,
      Uri.parse('http://localhost:8000/api/v1/days/2026-10-01'),
    );
  });

  test('returns a failure instead of throwing when the server is '
      'unreachable', () async {
    final adapter = FakeHttpClientAdapter(
      (options) async => throw DioException.connectionError(
        requestOptions: options,
        reason: 'Connection refused',
      ),
    );

    expect(
      await _repositoryWith(adapter).getDay(oct1),
      const Result<DayReport>.error(Failure.connection()),
    );
  });

  group('addTrip', () {
    test('posts the whole trip with its id and times in UTC and returns the '
        'stored trip', () async {
      final adapter = FakeHttpClientAdapter(
        (_) async => jsonResponse(201, jsonDecode(apiEveningTripExample)),
      );

      final result = await _repositoryWith(adapter).addTrip(eveningTrip);

      expect(result, Result.success(eveningTrip));
      final request = adapter.requests.single;
      expect(request.method, 'POST');
      expect(request.uri, Uri.parse('http://localhost:8000/api/v1/trips'));
      expect(request.data, {
        'id': eveningTripId,
        'start': '2026-10-01T13:40:00.000Z',
        'end': '2026-10-01T14:05:00.000Z',
        'amount': 1000,
        'payment': 'cash',
        'commission': 150,
      });
    });

    test('treats 200 for a repeat like 201 for a new trip (D4)', () async {
      final adapter = FakeHttpClientAdapter(
        (_) async => jsonResponse(200, jsonDecode(apiEveningTripExample)),
      );

      expect(
        await _repositoryWith(adapter).addTrip(eveningTrip),
        Result.success(eveningTrip),
      );
    });

    test('returns 409 and 422 as failures that are not retried', () async {
      final responses = [
        jsonResponse(409, {
          'detail': {
            'code': 'trip_conflict',
            'message':
                'Поездка с id $eveningTripId уже сохранена с другими '
                'данными',
          },
        }),
        jsonResponse(422, {
          'detail': [
            {
              'type': 'commission_above_amount',
              'loc': ['body', 'commission'],
              'msg': 'Commission should not exceed the amount',
            },
          ],
        }),
      ];
      final repository = _repositoryWith(
        FakeHttpClientAdapter((_) async => responses.removeAt(0)),
      );

      final conflict = await repository.addTrip(eveningTrip);
      final validation = await repository.addTrip(eveningTrip);

      expect(conflict, const Result<Trip>.error(Failure.conflict()));
      expect(
        validation,
        const Result<Trip>.error(
          Failure.validation(
            fieldErrors: {'commission': 'commission_above_amount'},
          ),
        ),
      );
      for (final result in [conflict, validation]) {
        expect((result as ErrorResult<Trip>).failure.isTransient, isFalse);
      }
    });
  });

  test('returns UnexpectedFailure when the body breaks the contract', () async {
    final body = jsonDecode(apiDayExample) as Map<String, dynamic>;
    final trip = (body['trips'] as List<dynamic>).first as Map<String, dynamic>;
    trip['start'] = '2026-10-01T08:10:00';
    final adapter = FakeHttpClientAdapter((_) async => jsonResponse(200, body));

    final result = await _repositoryWith(adapter).getDay(oct1);

    expect(
      result,
      isA<ErrorResult<Object?>>().having(
        (result) => result.failure,
        'failure',
        isA<UnexpectedFailure>(),
      ),
    );
  });
}
