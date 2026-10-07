import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const GroupedDigitsFormatter _formatter = GroupedDigitsFormatter();

TextEditingValue _typed(String text, {int? cursor}) => TextEditingValue(
  text: text,
  selection: TextSelection.collapsed(offset: cursor ?? text.length),
);

TextEditingValue _edit(TextEditingValue oldValue, TextEditingValue newValue) =>
    _formatter.formatEditUpdate(oldValue, newValue);

void main() {
  group('GroupedDigitsFormatter', () {
    test('groups thousands as the summary does', () {
      expect(_edit(_typed('240'), _typed('2400')), _typed('2\u00A0400'));
      expect(
        _edit(_typed('1\u00A0234\u00A0567'), _typed('1\u00A0234\u00A05678')),
        _typed('12\u00A0345\u00A0678'),
      );
    });

    test('refuses a point, a comma, a minus or a letter instead of '
        'changing the amount (D3)', () {
      final amount = _typed('2\u00A0400');

      for (final typed in [
        '2\u00A0400.5',
        '2\u00A0400,50',
        '-2\u00A0400',
        '2\u00A0400a',
      ]) {
        expect(_edit(amount, _typed(typed)), amount, reason: typed);
      }
      expect(_edit(_typed(''), _typed('1500,5')), _typed(''));
      expect(_edit(_typed(''), _typed('-150')), _typed(''));
    });

    test('takes pasted digits with ordinary spaces', () {
      expect(_edit(_typed(''), _typed('2 400')), _typed('2\u00A0400'));
    });

    test('drops leading zeros but keeps a single zero', () {
      expect(_edit(_typed(''), _typed('0')), _typed('0'));
      expect(_edit(_typed('0'), _typed('05')), _typed('5'));
    });

    test('empties the field when the last digit is deleted', () {
      expect(_edit(_typed('5'), _typed('')), _typed(''));
    });

    test('keeps the cursor next to the same digit', () {
      expect(
        _edit(
          _typed('2\u00A0400', cursor: 1),
          _typed('25\u00A0400', cursor: 2),
        ),
        _typed('25\u00A0400', cursor: 2),
      );
      expect(
        _edit(_typed('240', cursor: 1), _typed('2940', cursor: 2)),
        _typed('2\u00A0940', cursor: 3),
      );
    });

    test('backspace over a space deletes the digit before it', () {
      expect(
        _edit(_typed('12\u00A0400', cursor: 3), _typed('12400', cursor: 2)),
        _typed('1\u00A0400', cursor: 1),
      );
    });

    test('stops at ten digits', () {
      final full = _typed('1\u00A0234\u00A0567\u00A0890');

      expect(_edit(full, _typed('1\u00A0234\u00A0567\u00A08901')), full);
    });
  });

  testWidgets('reports whole tenge to the form and tells screen readers '
      'the amount is in tenge', (tester) async {
    int? amount;
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MoneyField(
            label: 'Сумма',
            errorText: null,
            enabled: true,
            onChanged: (value) => amount = value,
          ),
        ),
      ),
    );

    await tester.enterText(find.byType(TextField), '12400');
    await tester.pump();
    expect(find.text('12\u00A0400'), findsOneWidget);
    expect(amount, 12400);
    expect(
      tester.getSemantics(find.byType(EditableText)),
      isSemantics(label: 'Сумма в тенге', value: '12\u00A0400'),
    );

    await tester.enterText(find.byType(TextField), '');
    expect(amount, isNull);
  });

  testWidgets('an empty field shows only the tenge sign, no grey 0 that '
      'reads as a value', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Material(
          child: MoneyField(
            label: 'Комиссия',
            errorText: 'Введите комиссию, если её нет — 0',
            enabled: true,
            onChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('0'), findsNothing);
    expect(find.text(' ₸'), findsOneWidget);
    expect(
      tester.getSemantics(find.byType(EditableText)),
      isSemantics(
        label: 'Комиссия в тенге',
        hint: 'Введите комиссию, если её нет — 0',
      ),
    );
  });
}
