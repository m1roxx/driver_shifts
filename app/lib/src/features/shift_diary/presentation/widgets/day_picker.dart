import 'package:driver_shifts/src/core/theme/picker_metrics.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/cupertino_picker_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

final DateTime _firstDay = DateTime.utc(2000);
final DateTime _lastDay = DateTime.utc(2100, 12, 31);

Future<DateTime?> showDayPicker(
  BuildContext context, {
  required String title,
  required DateTime initialDate,
  required DateTime today,
}) async {
  final firstDate = initialDate.isBefore(_firstDay) ? initialDate : _firstDay;
  final lastDate = initialDate.isAfter(_lastDay) ? initialDate : _lastDay;
  final picker = switch (Theme.of(context).platform) {
    TargetPlatform.iOS || TargetPlatform.macOS => _showCupertinoDayPicker(
      context,
      title: title,
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
        maxScaleFactor: PickerMetrics.maxDialogTextScale,
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
  required String title,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) {
  DateTime local(DateTime day) => DateTime(day.year, day.month, day.day);
  return showCupertinoPickerSheet(
    context,
    title: title,
    initialDateTime: local(initialDate),
    picker: (onChanged) => CupertinoDatePicker(
      mode: CupertinoDatePickerMode.date,
      initialDateTime: local(initialDate),
      minimumDate: local(firstDate),
      maximumDate: local(lastDate),
      minimumYear: firstDate.year,
      maximumYear: lastDate.year,
      onDateTimeChanged: onChanged,
    ),
  );
}
