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
    switch (period.kind) {
      case PeriodKind.month:
        return toBeginningOfSentenceCase(
          DateFormat('LLLL y', locale).format(period.start),
          locale,
        );
      case PeriodKind.week:
        final range = _weekRange(period, today, locale);
        return period.contains(today)
            ? ShiftDiaryStrings.currentWeek(range)
            : range;
    }
  }

  static String _weekRange(Period week, DateTime today, String locale) {
    final start = week.start;
    final end = week.end;
    String dayAndMonth(DateTime day) =>
        DateFormat.MMMd(locale).format(day).replaceAll('.', '');
    final sameYear = start.year == end.year;
    final startText = switch ((sameYear, start.month == end.month)) {
      (true, true) => '${start.day}',
      (true, false) => dayAndMonth(start),
      (false, _) => '${dayAndMonth(start)} ${start.year}',
    };
    final endText = sameYear && end.year == today.year
        ? dayAndMonth(end)
        : '${dayAndMonth(end)} ${end.year}';
    return ShiftDiaryStrings.weekRange(startText, endText);
  }
}

class _PeriodTitle extends StatelessWidget {
  const _PeriodTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.titleLarge?.copyWith(
      fontWeight: FontWeight.w600,
      color: theme.colorScheme.onSurface,
    );
    final textScaler = TextScale.headline(context);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: Sizes.touchTarget),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Spacing.sm),
        child: Center(
          child: Semantics(
            header: true,
            liveRegion: true,
            label: title,
            excludeSemantics: true,
            child: LayoutBuilder(
              builder: (context, constraints) {
                Text text(String title) => Text(
                  title,
                  textAlign: TextAlign.center,
                  textScaler: textScaler,
                  style: style,
                );
                if (_longestWord(context, style, textScaler) <=
                    constraints.maxWidth) {
                  return text(title);
                }
                return FittedBox(
                  fit: BoxFit.scaleDown,
                  child: text(title.replaceAll(', ', ',\n')),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  double _longestWord(
    BuildContext context,
    TextStyle? style,
    TextScaler textScaler,
  ) {
    final painter = TextPainter(
      text: TextSpan(text: title, style: style),
      textDirection: Directionality.of(context),
      textScaler: textScaler,
    )..layout();
    try {
      return painter.minIntrinsicWidth;
    } finally {
      painter.dispose();
    }
  }
}
