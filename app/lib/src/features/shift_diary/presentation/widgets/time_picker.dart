import 'package:driver_shifts/src/core/theme/picker_metrics.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/add_trip_bloc.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/cupertino_picker_sheet.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<ClockTime?> showClockTimePicker(
  BuildContext context, {
  required ClockTime initialTime,
}) => switch (Theme.of(context).platform) {
  TargetPlatform.iOS ||
  TargetPlatform.macOS => _showCupertinoTimePicker(context, initialTime),
  TargetPlatform.android ||
  TargetPlatform.fuchsia ||
  TargetPlatform.linux ||
  TargetPlatform.windows => _showMaterialTimePicker(context, initialTime),
};

Future<ClockTime?> _showCupertinoTimePicker(
  BuildContext context,
  ClockTime initialTime,
) async {
  final initialDateTime = DateTime(
    2000,
    1,
    1,
    initialTime.hour,
    initialTime.minute,
  );
  final picked = await showCupertinoPickerSheet(
    context,
    initialDateTime: initialDateTime,
    picker: (onChanged) => CupertinoDatePicker(
      mode: CupertinoDatePickerMode.time,
      use24hFormat: true,
      initialDateTime: initialDateTime,
      onDateTimeChanged: onChanged,
    ),
  );
  return picked == null ? null : (hour: picked.hour, minute: picked.minute);
}

Future<ClockTime?> _showMaterialTimePicker(
  BuildContext context,
  ClockTime initialTime,
) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(hour: initialTime.hour, minute: initialTime.minute),
    builder: (context, dialog) => MediaQuery(
      data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
      child: MediaQuery.withClampedTextScaling(
        maxScaleFactor: PickerMetrics.maxDialogTextScale,
        child: dialog!,
      ),
    ),
  );
  return picked == null ? null : (hour: picked.hour, minute: picked.minute);
}
