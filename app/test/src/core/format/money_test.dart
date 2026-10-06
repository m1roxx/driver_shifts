import 'package:driver_shifts/src/core/format/money.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('groups thousands and keeps the tenge sign on the same line', () {
    expect(formatTenge(2400), '2\u00A0400\u00A0₸');
  });

  test('formats the day summary amounts from the task', () {
    expect([3900, 585, 3315, 1500].map(formatTenge), [
      '3\u00A0900\u00A0₸',
      '585\u00A0₸',
      '3\u00A0315\u00A0₸',
      '1\u00A0500\u00A0₸',
    ]);
  });

  test('formats zero and millions', () {
    expect(formatTenge(0), '0\u00A0₸');
    expect(formatTenge(1234567), '1\u00A0234\u00A0567\u00A0₸');
  });

  test('spells the currency out for screen readers', () {
    expect(spokenTenge(3900), '3\u00A0900 тенге');
  });
}
