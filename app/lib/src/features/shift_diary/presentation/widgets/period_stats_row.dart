import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_measure.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
import 'package:flutter/material.dart';

class PeriodStatsRow extends StatelessWidget {
  const PeriodStatsRow({super.key, required this.stats});

  final PeriodStats stats;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toLanguageTag();
    final PeriodStats(:averageTrip, :netPerHour, :bestDay) = stats;
    final tiles = [
      if (averageTrip != null)
        _StatTile(
          label: ShiftDiaryStrings.averageTrip,
          amount: averageTrip,
          spoken: ShiftDiaryStrings.spokenMoney(
            ShiftDiaryStrings.averageTrip,
            averageTrip,
          ),
        ),
      if (netPerHour != null)
        _StatTile(
          label: ShiftDiaryStrings.netPerHour,
          amount: netPerHour,
          spoken: ShiftDiaryStrings.spokenMoney(
            ShiftDiaryStrings.netPerHour,
            netPerHour,
          ),
        ),
      if (bestDay != null)
        _StatTile(
          label: ShiftDiaryStrings.bestDay,
          amount: bestDay.net,
          caption: ShiftDiaryStrings.shortDayOf(bestDay.date, locale),
          spoken: ShiftDiaryStrings.spokenBestDay(
            ShiftDiaryStrings.dayOfPeriod(bestDay.date, locale),
            bestDay.net,
          ),
        ),
    ];
    if (tiles.isEmpty) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final width =
            (constraints.maxWidth - Spacing.sm * (tiles.length - 1)) /
            tiles.length;
        final inRow =
            !TextScale.isLarge(context) &&
            tiles.every((tile) => tile.fitsIn(context, width));
        if (!inRow) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.sm,
            children: tiles,
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            spacing: Spacing.sm,
            children: [for (final tile in tiles) Expanded(child: tile)],
          ),
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    required this.label,
    required this.amount,
    required this.spoken,
    this.caption,
  });

  static const EdgeInsets _padding = EdgeInsets.all(Spacing.sml);

  final String label;
  final int amount;
  final String spoken;
  final String? caption;

  static TextStyle? _labelStyle(BuildContext context) {
    final theme = Theme.of(context);
    return AppTextStyles.medium(theme.textTheme.labelMedium)
        ?.copyWith(color: theme.colorScheme.onSurfaceVariant);
  }

  static TextStyle? _captionStyle(BuildContext context) {
    final theme = Theme.of(context);
    return theme.textTheme.bodySmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
  }

  bool fitsIn(BuildContext context, double width) {
    final room = width - _padding.horizontal;
    final caption = this.caption;
    return TextMeasure.width(
              context,
              label,
              _labelStyle(context),
              longestWord: true,
            ) <=
            room &&
        (caption == null ||
            TextMeasure.width(
                  context,
                  caption,
                  _captionStyle(context),
                  longestWord: true,
                ) <=
                room);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final caption = this.caption;
    return Semantics(
      container: true,
      label: spoken,
      excludeSemantics: true,
      child: Card(
        child: Padding(
          padding: _padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            spacing: Spacing.xxs,
            children: [
              Text(label, style: _labelStyle(context)),
              MoneyText(
                amount,
                style: AppTextStyles.strong(textTheme.titleMedium),
              ),
              if (caption != null) Text(caption, style: _captionStyle(context)),
            ],
          ),
        ),
      ),
    );
  }
}
