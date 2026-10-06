import 'package:driver_shifts/src/core/config/env.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('accepts an http(s) base URL', () {
    expect(
      Env(apiBaseUrl: 'http://10.0.2.2:8000').apiBaseUrl,
      Uri.parse('http://10.0.2.2:8000'),
    );
    expect(
      Env(apiBaseUrl: 'https://api.example.com').apiBaseUrl.host,
      'api.example.com',
    );
  });

  test('fails fast when API_BASE_URL is missing or not an http(s) URL', () {
    for (final value in ['', 'localhost:8000', '10.0.2.2:8000', 'ftp://h']) {
      expect(() => Env(apiBaseUrl: value), throwsArgumentError, reason: value);
    }
  });
}
