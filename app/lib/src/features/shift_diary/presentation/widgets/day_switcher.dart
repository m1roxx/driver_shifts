import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class DaySwitcher extends StatelessWidget {
  const DaySwitcher({
    super.key,
    required this.date,
    required this.today,
    required this.onChanged,
  });

  final DateTime date;
  final DateTime today;
  final ValueChanged<DateTime> onChanged;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: Spacing.xs),
      child: Row(
        children: [
          IconButton(
            tooltip: ShiftDiaryStrings.previousDay,
            onPressed: () => onChanged(date.subtract(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_left),
          ),
          Expanded(
            child: Tooltip(
              message: ShiftDiaryStrings.pickDate,
              child: TextButton.icon(
                onPressed: () => _pickDay(context),
                style: TextButton.styleFrom(
                  textStyle: Theme.of(context).textTheme.titleMedium,
                ),
                icon: const Icon(Icons.calendar_today_outlined),
                label: Semantics(
                  liveRegion: true,
                  child: Text(_dayTitle(locale), textAlign: TextAlign.center),
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: ShiftDiaryStrings.nextDay,
            onPressed: () => onChanged(date.add(const Duration(days: 1))),
            icon: const Icon(Icons.chevron_right),
          ),
        ],
      ),
    );
  }

  String _dayTitle(String locale) {
    final weekday = switch (date.difference(today).inDays) {
      0 => ShiftDiaryStrings.today,
      -1 => ShiftDiaryStrings.yesterday,
      1 => ShiftDiaryStrings.tomorrow,
      _ => toBeginningOfSentenceCase(
        DateFormat.EEEE(locale).format(date),
        locale,
      ),
    };
    final dayAndMonth = date.year == today.year
        ? DateFormat.MMMMd(locale).format(date)
        : DateFormat.yMMMMd(locale).format(date);
    return '$weekday, $dayAndMonth';
  }

  Future<void> _pickDay(BuildContext context) async {
    final picked = await showDayPicker(
      context,
      initialDate: date,
      today: today,
    );
    if (picked != null && picked != date) onChanged(picked);
  }
}
