import 'dart:math';

import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_measure.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
import 'package:flutter/material.dart';

class PeriodDayTile extends StatelessWidget {
  const PeriodDayTile({
    super.key,
    required this.total,
    required this.maxNet,
    required this.borderRadius,
    required this.onTap,
  });

  final DayTotal total;
  final int maxNet;
  final BorderRadius borderRadius;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final secondary = theme.colorScheme.onSurfaceVariant;
    final summary = total.summary;
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayText = ShiftDiaryStrings.dayOfPeriod(total.date, locale);
    final narrowerDayTexts = [
      ShiftDiaryStrings.dayOfPeriod(total.date, locale, shortWeekday: true),
      ShiftDiaryStrings.dayOfPeriod(
        total.date,
        locale,
        shortWeekday: true,
        keepTogether: false,
      ),
    ];
    final countText = summary.tripsCount == 0
        ? ShiftDiaryStrings.noTripsOnDay
        : ShiftDiaryStrings.tripsCountOf(summary.tripsCount);
    final dayStyle = textTheme.bodyLarge;
    final countStyle = textTheme.bodyMedium?.copyWith(color: secondary);
    final amountStyle = AppTextStyles.strong(textTheme.bodyLarge)
        ?.copyWith(color: summary.tripsCount == 0 ? secondary : null);
    final amount = MoneyText(summary.net, style: amountStyle);
    return Semantics(
      container: true,
      button: true,
      label: ShiftDiaryStrings.spokenPeriodDay(
        dayText,
        summary.tripsCount,
        summary.net,
      ),
      hint: ShiftDiaryStrings.openDay,
      onTap: onTap,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: onTap,
          borderRadius: borderRadius,
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.tripRow),
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: Spacing.md,
                vertical: Spacing.sml,
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  double longestWord(String text, TextStyle? style) =>
                      TextMeasure.width(
                        context,
                        text,
                        style,
                        longestWord: true,
                      );
                  final shownDayText = [dayText, ...narrowerDayTexts]
                      .firstWhere(
                        (text) =>
                            longestWord(text, dayStyle) <= constraints.maxWidth,
                        orElse: () => narrowerDayTexts.last,
                      );
                  final texts = Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(shownDayText, style: dayStyle),
                      Text(countText, style: countStyle),
                    ],
                  );
                  final middle = max(
                    longestWord(shownDayText, dayStyle),
                    longestWord(countText, countStyle),
                  );
                  final amountWidth = TextMeasure.width(
                    context,
                    formatTenge(summary.net),
                    amountStyle,
                  );
                  final room = constraints.maxWidth - Spacing.md;
                  final inRow =
                      !TextScale.isLarge(context) &&
                      middle + amountWidth <= room;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    spacing: Spacing.sm,
                    children: [
                      if (inRow)
                        Row(
                          children: [
                            Expanded(child: texts),
                            const SizedBox(width: Spacing.md),
                            ConstrainedBox(
                              constraints: BoxConstraints(
                                maxWidth: room - middle,
                              ),
                              child: amount,
                            ),
                          ],
                        )
                      else ...[
                        texts,
                        amount,
                      ],
                      _NetBar(
                        share: maxNet > 0 ? min(1, summary.net / maxNet) : 0,
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NetBar extends StatelessWidget {
  const _NetBar({required this.share});

  final double share;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(Radii.small)),
      child: SizedBox(
        height: Sizes.netBar,
        child: ColoredBox(
          color: colors.surfaceContainerHighest,
          child: FractionallySizedBox(
            alignment: AlignmentDirectional.centerStart,
            widthFactor: share,
            child: ColoredBox(color: colors.primary),
          ),
        ),
      ),
    );
  }
}
