import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
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
    return MergeSemantics(
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: Spacing.md,
          vertical: Spacing.sm,
        ),
        child: Row(
          children: [
            Icon(switch (trip.payment) {
              PaymentMethod.cash => Icons.payments_outlined,
              PaymentMethod.card => Icons.credit_card_outlined,
            }, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: Spacing.md),
            Expanded(
              child: Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: Spacing.md,
                runSpacing: Spacing.xs,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ShiftDiaryStrings.tripTimes(start, end),
                        style: textTheme.bodyLarge?.merge(
                          AppTextStyles.tabularFigures,
                        ),
                        semanticsLabel: ShiftDiaryStrings.spokenTripTimes(
                          start,
                          end,
                        ),
                      ),
                      Text(
                        ShiftDiaryStrings.payment(trip.payment),
                        style: textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  MoneyText(trip.amount, style: textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
