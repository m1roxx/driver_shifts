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
    test('uses the server text for a conflict when there is one', () {
      expect(
        const Failure.conflict(serverMessage: 'Уже сохранена').message,
        'Уже сохранена',
      );
      expect(const Failure.conflict().message, isNotEmpty);
    });

    test('shows validation errors that belong to no field', () {
      expect(const Failure.validation(formErrors: ['a', 'b']).message, 'a\nb');
      expect(const Failure.validation().message, isNotEmpty);
    });
  });
}
