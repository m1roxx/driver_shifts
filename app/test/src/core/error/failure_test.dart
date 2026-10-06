import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Failure.isTransient', () {
    test('is true only for no connection, timeouts and 5xx (D7)', () {
      const transient = [
        Failure.connection(),
        Failure.timeout(),
        Failure.badResponse(statusCode: 500),
        Failure.badResponse(statusCode: 503),
      ];
      const permanent = [
        Failure.validation(),
        Failure.conflict(),
        Failure.badResponse(statusCode: 400),
        Failure.badResponse(statusCode: 404),
        Failure.badResponse(statusCode: 429),
        Failure.unexpected(),
      ];

      for (final failure in transient) {
        expect(failure.isTransient, isTrue, reason: '$failure');
      }
      for (final failure in permanent) {
        expect(failure.isTransient, isFalse, reason: '$failure');
      }
    });
  });

  group('Failure.message', () {
    test('tells the driver what a conflict means, without a trip id to '
        'read aloud', () {
      expect(
        const Failure.conflict().message,
        'Эта поездка уже сохранена — с данными первой отправки. '
        'Проверьте её в списке.',
      );
    });

    test('shows a validation failure in its own words, not by API types', () {
      const failures = [
        Failure.validation(),
        Failure.validation(fieldErrors: {'amount': 'greater_than'}),
        Failure.validation(formErrors: ['json_invalid']),
      ];

      for (final failure in failures) {
        expect(
          failure.message,
          'Проверьте данные поездки.',
          reason: '$failure',
        );
      }
    });
  });
}
