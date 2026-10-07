import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_measure.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
import 'package:flutter/material.dart';

class PeriodStatsSection extends StatelessWidget {
  const PeriodStatsSection({super.key, required this.stats});

  final PeriodStats stats;

  static const double _columnGap = Spacing.sml;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final PeriodStats(:averageTrip, :netPerHour, :bestDay) = stats;
    final items = [
      if (averageTrip != null)
        _Stat(
          label: ShiftDiaryStrings.averageTrip,
          amount: averageTrip,
          caption: ShiftDiaryStrings.perTrip,
          spoken: ShiftDiaryStrings.spokenMoney(
            ShiftDiaryStrings.averageTrip,
            averageTrip,
          ),
        ),
      if (netPerHour != null)
        _Stat(
          label: ShiftDiaryStrings.perHour,
          amount: netPerHour,
          caption: ShiftDiaryStrings.inTrips,
          spoken: ShiftDiaryStrings.spokenMoney(
            ShiftDiaryStrings.netPerHour,
            netPerHour,
          ),
        ),
      if (bestDay != null)
        _Stat(
          label: ShiftDiaryStrings.bestDay,
          amount: bestDay.net,
          caption: ShiftDiaryStrings.shortDayOf(bestDay.date, locale),
          spoken: ShiftDiaryStrings.spokenBestDay(
            ShiftDiaryStrings.dayOfPeriod(bestDay.date, locale),
            bestDay.net,
          ),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final column =
            (constraints.maxWidth -
                2 * Spacing.md -
                _columnGap * (items.length - 1)) /
            items.length;
        final inColumns =
            !TextScale.isLarge(context) &&
            items.every((item) => item.fitsOneLine(context, column));
        if (!inColumns) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final (index, item) in items.indexed) ...[
                if (index > 0) const Divider(indent: Spacing.md),
                _StatRow(item),
              ],
            ],
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sml,
          ),
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final (index, item) in items.indexed) ...[
                  if (index > 0) const VerticalDivider(width: _columnGap),
                  Expanded(child: _StatColumn(item)),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _Stat {
  const _Stat({
    required this.label,
    required this.amount,
    required this.caption,
    required this.spoken,
  });

  final String label;
  final int amount;
  final String caption;
  final String spoken;

  static TextStyle? labelStyle(BuildContext context) {
    final theme = Theme.of(context);
    return AppTextStyles.medium(theme.textTheme.labelMedium)
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant, letterSpacing: 0);
  }

  static TextStyle? captionStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  static TextStyle? amountStyle(BuildContext context) =>
      AppTextStyles.strong(Theme.of(context).textTheme.bodyLarge);

  bool fitsOneLine(BuildContext context, double width) =>
      TextMeasure.width(context, label, labelStyle(context)) <= width &&
      TextMeasure.width(context, caption, captionStyle(context)) <= width;
}

class _StatColumn extends StatelessWidget {
  const _StatColumn(this.stat);

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: stat.spoken,
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            stat.label,
            style: _Stat.labelStyle(context),
            maxLines: 1,
            softWrap: false,
          ),
          const SizedBox(height: Sizes.amountGap),
          MoneyText(stat.amount, style: _Stat.amountStyle(context)),
          Text(
            stat.caption,
            style: _Stat.captionStyle(context),
            maxLines: 1,
            softWrap: false,
          ),
        ],
      ),
    );
  }
}

class _StatRow extends StatelessWidget {
  const _StatRow(this.stat);

  final _Stat stat;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: stat.spoken,
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.summaryRow),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sml,
          ),
          child: Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: Spacing.md,
            runSpacing: Spacing.xs,
            children: [
              Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(stat.label, style: _Stat.labelStyle(context)),
                  Text(stat.caption, style: _Stat.captionStyle(context)),
                ],
              ),
              MoneyText(stat.amount, style: _Stat.amountStyle(context)),
            ],
          ),
        ),
      ),
    );
  }
}
