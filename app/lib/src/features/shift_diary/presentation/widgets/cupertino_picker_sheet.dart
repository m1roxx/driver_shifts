import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/picker_metrics.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<DateTime?> showCupertinoPickerSheet(
  BuildContext context, {
  required String title,
  required DateTime initialDateTime,
  required CupertinoDatePicker Function(ValueChanged<DateTime> onChanged)
  picker,
}) {
  var selected = initialDateTime;
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (context) => SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(Spacing.md, 0, Spacing.md, Spacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: AppTextStyles.strong(
                Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          SizedBox(
            height: PickerMetrics.wheelHeight,
            child: picker((value) => selected = value),
          ),
          const SizedBox(height: Spacing.md),
          FilledButton(
            onPressed: () => Navigator.pop(context, selected),
            child: const Text(ShiftDiaryStrings.done),
          ),
        ],
      ),
    ),
  );
}
