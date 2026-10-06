import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:driver_shifts/src/core/config/env.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/network/http_client.dart';
import 'package:driver_shifts/src/features/shift_diary/data/datasources/trips_remote_datasource.dart';
import 'package:driver_shifts/src/features/shift_diary/data/repositories/trips_repository_impl.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
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
