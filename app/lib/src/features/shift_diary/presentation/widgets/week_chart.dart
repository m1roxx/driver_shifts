import 'dart:math';

import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
import 'package:flutter/material.dart';

class WeekChart extends StatelessWidget {
  const WeekChart({
    super.key,
    required this.days,
    required this.bestDay,
    required this.today,
    required this.onDaySelected,
  });

  final List<DayTotal> days;
  final BestDay? bestDay;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bestDay = this.bestDay;
    final bestIndex = bestDay == null || bestDay.date.isAfter(today)
        ? -1
        : days.indexWhere((total) => total.date == bestDay.date);
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          Spacing.sm,
          Spacing.md,
          Spacing.sm,
          Spacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bestDay != null && bestIndex >= 0)
              ExcludeSemantics(
                child: Align(
                  alignment: Alignment(
                    -1 + 2 * (bestIndex + 0.5) / days.length,
                    0,
                  ),
                  child: MoneyText(
                    bestDay.net,
                    style: AppTextStyles.strong(theme.textTheme.labelLarge)
                        ?.copyWith(color: theme.colorScheme.primary),
                  ),
                ),
              ),
            const SizedBox(height: Spacing.xs),
            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                for (final (index, total) in days.indexed)
                  Expanded(
                    child: _DayBar(
                      total: total,
                      share: bestDay == null || bestDay.net == 0
                          ? 0
                          : min(1, total.summary.net / bestDay.net),
                      best: index == bestIndex,
                      ahead: total.date.isAfter(today),
                      today: total.date == today,
                      onTap: () => onDaySelected(total.date),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DayBar extends StatelessWidget {
  const _DayBar({
    required this.total,
    required this.share,
    required this.best,
    required this.ahead,
    required this.today,
    required this.onTap,
  });

  final DayTotal total;
  final double share;
  final bool best;
  final bool ahead;
  final bool today;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final summary = total.summary;
    final labelStyle = today
        ? AppTextStyles.strong(theme.textTheme.labelMedium)
        : theme.textTheme.labelMedium?.copyWith(color: colors.onSurfaceVariant);
    const corner = BorderRadius.all(Radius.circular(Radii.small));
    final column = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: Sizes.chartBar,
          height: Sizes.weekChart,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.surfaceContainerHighest,
              borderRadius: corner,
            ),
            child: ahead
                ? null
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: SizedBox(
                      width: double.infinity,
                      height: max(Sizes.chartStub, share * Sizes.weekChart),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: switch ((best, summary.tripsCount)) {
                            (true, _) => colors.primary,
                            (false, 0) => colors.outlineVariant,
                            (false, _) => colors.primaryContainer,
                          },
                          borderRadius: corner,
                        ),
                      ),
                    ),
                  ),
          ),
        ),
        const SizedBox(height: Spacing.xs),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            ShiftDiaryStrings.weekdayOf(total.date, locale, short: true),
            style: labelStyle,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
    final padded = Padding(
      padding: const EdgeInsets.symmetric(vertical: Spacing.xs),
      child: column,
    );
    if (ahead) return ExcludeSemantics(child: padded);
    return Semantics(
      container: true,
      button: true,
      label: ShiftDiaryStrings.spokenPeriodDay(
        ShiftDiaryStrings.dayOfPeriod(total.date, locale),
        summary.tripsCount,
        summary.net,
      ),
      hint: ShiftDiaryStrings.openDay,
      onTap: onTap,
      excludeSemantics: true,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.medium)),
        child: padded,
      ),
    );
  }
}
