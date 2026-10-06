import 'package:driver_shifts/src/core/theme/picker_metrics.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final DateTime _firstDay = DateTime.utc(2000);
final DateTime _lastDay = DateTime.utc(2100, 12, 31);

Future<DateTime?> showDayPicker(
  BuildContext context, {
  required DateTime initialDate,
  required DateTime today,
}) async {
  final firstDate = initialDate.isBefore(_firstDay) ? initialDate : _firstDay;
  final lastDate = initialDate.isAfter(_lastDay) ? initialDate : _lastDay;
  final picker = switch (Theme.of(context).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => _showCupertinoDayPicker(
      context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
    ),
    TargetPlatform.android ||
    TargetPlatform.fuchsia ||
    TargetPlatform.linux ||
    TargetPlatform.windows => showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: firstDate,
      lastDate: lastDate,
      currentDate: today,
      builder: (context, dialog) => MediaQuery.withClampedTextScaling(
        maxScaleFactor: PickerMetrics.maxCalendarTextScale,
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
  BuildContext context, {
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  DateTime local(DateTime day) => DateTime(day.year, day.month, day.day);
  var selected = local(initialDate);
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
            height: PickerMetrics.wheelHeight,
            child: CupertinoDatePicker(
              mode: CupertinoDatePickerMode.date,
              initialDateTime: selected,
              minimumDate: local(firstDate),
              maximumDate: local(lastDate),
              minimumYear: firstDate.year,
              maximumYear: lastDate.year,
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
