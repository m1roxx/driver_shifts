import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/core/theme/motion.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
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
    final previous = _ArrowButton(
      tooltip: ShiftDiaryStrings.previousDay,
      icon: AppIcons.of(context).previousDay,
      onPressed: () => onChanged(date.subtract(const Duration(days: 1))),
    );
    final next = _ArrowButton(
      tooltip: ShiftDiaryStrings.nextDay,
      icon: AppIcons.of(context).nextDay,
      onPressed: () => onChanged(date.add(const Duration(days: 1))),
    );
    final title = _DayTitle(
      title: _dayTitle(Localizations.localeOf(context).toLanguageTag()),
      onPressed: () => _pickDay(context),
    );
    if (!TextScale.isLarge(context)) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.xs,
          Spacing.xs,
          Spacing.xs,
          Spacing.sm,
        ),
        child: Row(
          children: [
            previous,
            Expanded(child: Center(child: title)),
            next,
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.xs,
        Spacing.sm,
        Spacing.xs,
        Spacing.sm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          title,
          Row(
            children: [
              previous,
              Expanded(
                child: Center(
                  child: TodayButton(
                    visible: date != today,
                    onPressed: () => onChanged(today),
                  ),
                ),
              ),
              next,
            ],
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
      title: ShiftDiaryStrings.pickDate,
      initialDate: date,
      today: today,
    );
    if (picked != null && picked != date) onChanged(picked);
  }
}

class TodayButton extends StatelessWidget {
  const TodayButton({
    super.key,
    required this.visible,
    required this.onPressed,
  });

  final bool visible;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return AnimatedOpacity(
      opacity: visible ? 1 : 0,
      duration: Motion.of(context, Motion.fast),
      child: IgnorePointer(
        ignoring: !visible,
        child: ExcludeSemantics(
          excluding: !visible,
          child: TextButton(
            onPressed: onPressed,
            style: TextButton.styleFrom(
              minimumSize: const Size.square(Sizes.touchTarget),
              textStyle: textTheme.bodyLarge?.copyWith(
                fontWeight: FontWeight.w500,
              ),
            ),
            child: const Text(ShiftDiaryStrings.today),
          ),
        ),
      ),
    );
  }
}

class _ArrowButton extends StatelessWidget {
  const _ArrowButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: Theme.of(context).colorScheme.primary,
      iconSize: AppIcons.of(context).dayArrowSize,
      icon: Icon(icon),
    );
  }
}

class _DayTitle extends StatelessWidget {
  const _DayTitle({required this.title, required this.onPressed});

  final String title;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Tooltip(
      message: ShiftDiaryStrings.pickDate,
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: theme.colorScheme.onSurface,
          iconColor: theme.colorScheme.onSurfaceVariant,
          iconSize: Sizes.icon,
          minimumSize: const Size.square(Sizes.touchTarget),
          padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
          textStyle: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        icon: Icon(AppIcons.of(context).expand),
        iconAlignment: IconAlignment.end,
        label: Semantics(
          header: true,
          liveRegion: true,
          child: Text(
            title,
            textAlign: TextAlign.center,
            textScaler: TextScale.headline(context),
          ),
        ),
      ),
    );
  }
}
