import 'dart:math';

import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_measure.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/later_day_badge.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/payment_avatar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class TripTile extends StatelessWidget {
  const TripTile({super.key, required this.trip});

  final Trip trip;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final clock = context.read<DriverClock>();
    final start = clock.formatTime(trip.start);
    final end = clock.formatTime(trip.end);
    final laterDays = clock.daysLater(trip.start, trip.end);
    final timesText = ShiftDiaryStrings.tripTimes(start, end);
    final timesStyle = textTheme.bodyLarge?.merge(AppTextStyles.tabularFigures);
    final paymentText = ShiftDiaryStrings.tripPayment(trip.payment);
    final commissionText = ShiftDiaryStrings.tripCommission(trip.commission);
    final detailsStyle = textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final amountStyle = AppTextStyles.strong(textTheme.bodyLarge)
        ?.merge(AppTextStyles.tabularFigures);
    final times = Text(timesText, style: timesStyle);
    final details = Wrap(
      spacing: Spacing.xs,
      children: [
        Text(paymentText, style: detailsStyle),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: AlignmentDirectional.centerStart,
          child: Text(
            commissionText,
            style: detailsStyle,
            maxLines: 1,
            softWrap: false,
          ),
        ),
      ],
    );
    final amount = MoneyText(
      trip.amount,
      style: AppTextStyles.strong(textTheme.bodyLarge),
    );
    return Semantics(
      container: true,
      label: ShiftDiaryStrings.spokenTrip(
        times: laterDays > 0
            ? ShiftDiaryStrings.spokenTripTimesLater(start, end, laterDays)
            : ShiftDiaryStrings.spokenTripTimes(start, end),
        method: trip.payment,
        amount: trip.amount,
        commissionAmount: trip.commission,
      ),
      excludeSemantics: true,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.tripRow),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final middle = [
                TextMeasure.width(
                  context,
                  timesText,
                  timesStyle,
                  longestWord: true,
                ),
                TextMeasure.width(context, paymentText, detailsStyle),
                TextMeasure.width(context, commissionText, detailsStyle),
              ].reduce(max);
              final amountWidth = TextMeasure.width(
                context,
                formatTenge(trip.amount),
                amountStyle,
              );
              final beside =
                  constraints.maxWidth - Sizes.tripAvatar - 2 * Spacing.md;
              final inRow =
                  !TextScale.isLarge(context) && middle + amountWidth <= beside;
              if (!inRow) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.xs,
                  children: [
                    times,
                    if (laterDays > 0) LaterDayBadge(laterDays),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PaymentAvatar(trip.payment, small: true),
                        const SizedBox(width: Spacing.sm),
                        Expanded(child: details),
                      ],
                    ),
                    amount,
                  ],
                );
              }
              return Row(
                children: [
                  PaymentAvatar(trip.payment),
                  const SizedBox(width: Spacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: Spacing.sm,
                          runSpacing: Spacing.xxs,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            times,
                            if (laterDays > 0) LaterDayBadge(laterDays),
                          ],
                        ),
                        details,
                      ],
                    ),
                  ),
                  const SizedBox(width: Spacing.md),
                  ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: beside - middle),
                    child: amount,
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}
