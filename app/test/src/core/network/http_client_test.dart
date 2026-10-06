import 'package:driver_shifts/src/core/config/env.dart';
import 'package:driver_shifts/src/core/network/http_client.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fake_http_client_adapter.dart';

void main() {
  test('sends requests under /api/v1 of the configured host', () async {
    final adapter = FakeHttpClientAdapter(
      (_) async => jsonResponse(200, <String, Object?>{}),
    );
    final dio = createHttpClient(Env(apiBaseUrl: 'http://10.0.2.2:8000'))
      ..httpClientAdapter = adapter;

    await dio.get<Object?>('/days/2026-10-01');

    expect(
      adapter.requests.single.uri,
      Uri.parse('http://10.0.2.2:8000/api/v1/days/2026-10-01'),
    );
  });
}
