import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
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
    final clock = context.read<DriverClock>();
    final start = clock.formatTime(trip.start);
    final end = clock.formatTime(trip.end);
    return MergeSemantics(
      child: ListTile(
        leading: Icon(switch (trip.payment) {
          PaymentMethod.cash => Icons.payments_outlined,
          PaymentMethod.card => Icons.credit_card_outlined,
        }),
        title: Text(
          ShiftDiaryStrings.tripTimes(start, end),
          style: AppTextStyles.tabularFigures,
          semanticsLabel: ShiftDiaryStrings.spokenTripTimes(start, end),
        ),
        subtitle: Text(ShiftDiaryStrings.payment(trip.payment)),
        trailing: MoneyText(
          trip.amount,
          style: Theme.of(context).textTheme.titleMedium,
        ),
      ),
    );
  }
}
