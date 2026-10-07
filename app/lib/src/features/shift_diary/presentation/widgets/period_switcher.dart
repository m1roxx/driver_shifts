import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_switcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PeriodSwitcher extends StatelessWidget {
  const PeriodSwitcher({
    super.key,
    required this.period,
    required this.today,
    required this.onChanged,
  });

  final Period period;
  final DateTime today;
  final ValueChanged<Period> onChanged;

  @override
  Widget build(BuildContext context) {
    final icons = AppIcons.of(context);
    final previous = SwitcherArrow(
      tooltip: ShiftDiaryStrings.previousPeriod(period.kind),
      icon: icons.previousDay,
      onPressed: () => onChanged(period.previous),
    );
    final next = SwitcherArrow(
      tooltip: ShiftDiaryStrings.nextPeriod(period.kind),
      icon: icons.nextDay,
      onPressed: () => onChanged(period.next),
    );
    final title = _PeriodTitle(
      periodTitle(
        period,
        today,
        Localizations.localeOf(context).toLanguageTag(),
      ),
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
            Expanded(child: title),
            next,
          ],
        ),
      );
    }
    final current = Period.containing(period.kind, today);
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
                    visible: period != current,
                    prominent: true,
                    onPressed: () => onChanged(current),
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

  static String periodTitle(Period period, DateTime today, String locale) {
    if (period.contains(today)) {
      return ShiftDiaryStrings.currentPeriod(period.kind);
    }
    switch (period.kind) {
      case PeriodKind.month:
        return toBeginningOfSentenceCase(
          DateFormat('LLLL y', locale).format(period.start),
          locale,
        );
      case PeriodKind.week:
        final start = period.start;
        final end = period.end;
        String dayAndMonth(DateTime day) =>
            DateFormat.MMMd(locale).format(day).replaceAll('.', '');
        if (start.year != end.year) {
          return ShiftDiaryStrings.weekRange(
            '${dayAndMonth(start)} ${start.year}',
            '${dayAndMonth(end)} ${end.year}',
          );
        }
        return ShiftDiaryStrings.weekRange(
          dayAndMonth(start),
          end.year == today.year
              ? dayAndMonth(end)
              : '${dayAndMonth(end)} ${end.year}',
        );
    }
  }
}

class _PeriodTitle extends StatelessWidget {
  const _PeriodTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        child: Center(
          child: Semantics(
            header: true,
            liveRegion: true,
            child: Text(
              title,
              textAlign: TextAlign.center,
              textScaler: TextScale.headline(context),
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
