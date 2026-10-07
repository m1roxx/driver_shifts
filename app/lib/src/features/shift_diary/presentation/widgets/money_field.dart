import 'dart:math';

import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/field_error.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

final RegExp _nonDigits = RegExp(r'\D');
final RegExp _neitherDigitNorSpace = RegExp(r'[^\d\s]');
final RegExp _leadingZeros = RegExp('^0+(?=.)');

class MoneyField extends StatelessWidget {
  const MoneyField({
    super.key,
    required this.label,
    required this.errorText,
    required this.enabled,
    required this.onChanged,
    this.textInputAction,
  });

  final String label;
  final String? errorText;
  final bool enabled;
  final ValueChanged<int?> onChanged;
  final TextInputAction? textInputAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final errorText = this.errorText;
    final large = TextScale.isLarge(context);
    final title = ExcludeSemantics(
      child: Text(
        label,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: errorText == null ? colors.onSurface : colors.error,
        ),
      ),
    );
    final field = Semantics(
      label: ShiftDiaryStrings.inTenge(label),
      hint: errorText,
      child: TextField(
        enabled: enabled,
        keyboardType: TextInputType.number,
        textInputAction: textInputAction,
        textAlign: TextAlign.end,
        inputFormatters: const [GroupedDigitsFormatter()],
        style: AppTextStyles.strong(theme.textTheme.bodyLarge)
            ?.merge(AppTextStyles.tabularFigures),
        decoration: InputDecoration(
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(vertical: Spacing.sm),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(
              color: colors.primary,
              width: Sizes.focusLine,
            ),
          ),
          hint: const ExcludeSemantics(
            child: Text(ShiftDiaryStrings.zero, textAlign: TextAlign.end),
          ),
          hintStyle: theme.textTheme.bodyLarge?.copyWith(
            color: colors.onSurfaceVariant,
          ),
          suffixText: '\u00A0${ShiftDiaryStrings.tengeSign}',
        ),
        onChanged: (text) =>
            onChanged(int.tryParse(text.replaceAll(_nonDigits, ''))),
        onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(minHeight: Sizes.formRow),
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: Spacing.md,
              vertical: Spacing.sm,
            ),
            child: large
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [title, field],
                  )
                : Row(
                    children: [
                      title,
                      const SizedBox(width: Spacing.md),
                      Expanded(child: field),
                    ],
                  ),
          ),
        ),
        if (errorText != null) FieldError(errorText),
      ],
    );
  }
}

class GroupedDigitsFormatter extends TextInputFormatter {
  const GroupedDigitsFormatter({this.maxDigits = 10});

  final int maxDigits;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (_neitherDigitNorSpace.hasMatch(newValue.text)) return oldValue;
    var text = newValue.text;
    var cursor = newValue.selection.isValid
        ? newValue.selection.end
        : text.length;
    if (_backspacedSeparator(oldValue, newValue) && cursor > 0) {
      text = text.replaceRange(cursor - 1, cursor, '');
      cursor -= 1;
    }
    final digits = text.replaceAll(_nonDigits, '');
    if (digits.isEmpty) {
      return const TextEditingValue(
        selection: TextSelection.collapsed(offset: 0),
      );
    }
    final significant = digits.replaceFirst(_leadingZeros, '');
    if (significant.length > maxDigits) return oldValue;
    final digitsBeforeCursor = max(
      0,
      text.substring(0, cursor).replaceAll(_nonDigits, '').length -
          (digits.length - significant.length),
    );
    final formatted = groupDigits(int.parse(significant));
    var offset = 0;
    for (var seen = 0; seen < digitsBeforeCursor; offset++) {
      if (!_nonDigits.hasMatch(formatted[offset])) seen++;
    }
    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: offset),
    );
  }

  bool _backspacedSeparator(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final cursor = newValue.selection.end;
    return newValue.selection.isCollapsed &&
        oldValue.selection.isCollapsed &&
        oldValue.selection.end == cursor + 1 &&
        oldValue.text.length == newValue.text.length + 1 &&
        _nonDigits.hasMatch(oldValue.text[cursor]) &&
        oldValue.text.replaceRange(cursor, cursor + 1, '') == newValue.text;
  }
}
