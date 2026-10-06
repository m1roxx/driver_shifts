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

    test('keeps only whole tenge: anything but digits is dropped (D3)', () {
      expect(_edit(_typed('24'), _typed('24.5')), _typed('245'));
      expect(_edit(_typed(''), _typed('-1')), _typed('1'));
      expect(_edit(_typed('2'), _typed('2a')), _typed('2'));
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
}
