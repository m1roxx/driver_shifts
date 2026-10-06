import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final DateTime _firstDay = DateTime.utc(2000);
final DateTime _lastDay = DateTime.utc(2100);
const double _cupertinoPickerHeight = 216;
const double _maxCalendarTextScale = 1.5;

Future<DateTime?> showDayPicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime today,
}) async {
  final picker = switch (Theme.of(context).platform) {
    TargetPlatform.iOS ||
    TargetPlatform.macOS => _showCupertinoDayPicker(context, initialDate),
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: initialDate.isBefore(_firstDay) ? initialDate : _firstDay,
      lastDate: initialDate.isAfter(_lastDay) ? initialDate : _lastDay,
      currentDate: today,
      builder: (context, dialog) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: _maxCalendarTextScale,
        child: dialog!,
      ),
    ),
  };
  final picked = await picker;
  return picked == null
      ? null
      : DateTime.utc(picked.year, picked.month, picked.day);
}

Future<DateTime?> _showCupertinoDayPicker(
  BuildContext context,
  DateTime initialDate,
) {
  var selected = initialDate;
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
          SizedBox(
            height: _cupertinoPickerHeight,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: initialDate,
              onDateTimeChanged: (date) => selected = date,
            ),
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
