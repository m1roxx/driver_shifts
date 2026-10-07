import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/next_day_badge.dart';
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
    final nextDay = clock.endsOnLaterDay(trip.start, trip.end);
    final times = Text(
      ShiftDiaryStrings.tripTimes(start, end),
      style: textTheme.bodyLarge?.merge(AppTextStyles.tabularFigures),
    );
    final details = Text(
      ShiftDiaryStrings.tripDetails(trip.payment, trip.commission),
      style: textTheme.bodyMedium?.copyWith(
        color: theme.colorScheme.onSurfaceVariant,
      ),
    );
    final amount = MoneyText(
      trip.amount,
      style: AppTextStyles.strong(textTheme.bodyLarge),
    );
    return Semantics(
      container: true,
      label: ShiftDiaryStrings.spokenTrip(
        times: nextDay
            ? ShiftDiaryStrings.spokenTripTimesNextDay(start, end)
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
          child: TextScale.isLarge(context)
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  spacing: Spacing.xs,
                  children: [
                    times,
                    if (nextDay) const NextDayBadge(),
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
                )
              : Row(
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
                              if (nextDay) const NextDayBadge(),
                            ],
                          ),
                          details,
                        ],
                      ),
                    ),
                    const SizedBox(width: Spacing.md),
                    amount,
                  ],
                ),
        ),
      ),
    );
  }
}
