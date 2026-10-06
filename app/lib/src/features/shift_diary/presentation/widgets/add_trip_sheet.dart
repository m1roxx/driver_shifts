import 'dart:math';

import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/add_trip_bloc.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_picker.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/failure_banner.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_field.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AddTripSheet extends StatelessWidget {
  const AddTripSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AddTripBloc>();
    final state = context.watch<AddTripBloc>().state;
    final draft = state.draft;
    final editable = state.status != AddTripStatus.submitting;
    String? errorOf(TripField field) => switch (state.fieldErrors[field]) {
      final error? => ShiftDiaryStrings.fieldError(field, error),
      null => null,
    };
    return PopScope(
      canPop: editable,
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Spacing.md,
            Spacing.sm,
            Spacing.md,
            Spacing.md,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(closable: editable),
              const SizedBox(height: Spacing.md),
              _MomentField(
                label: ShiftDiaryStrings.start,
                day: draft.startDay,
                time: draft.startTime,
                initialTime: draft.startTime,
                errorText: errorOf(TripField.start),
                enabled: editable,
                onDayChanged: (day) => bloc.add(TripStartDayChanged(day)),
                onTimeChanged: (time) => bloc.add(TripStartTimeChanged(time)),
              ),
              const SizedBox(height: Spacing.md),
              _MomentField(
                label: ShiftDiaryStrings.end,
                day: draft.endDay,
                time: draft.endTime,
                initialTime: draft.endTime ?? draft.startTime,
                errorText: errorOf(TripField.end),
                enabled: editable,
                onDayChanged: (day) => bloc.add(TripEndDayChanged(day)),
                onTimeChanged: (time) => bloc.add(TripEndTimeChanged(time)),
              ),
              const SizedBox(height: Spacing.md),
              MoneyField(
                label: ShiftDiaryStrings.amount,
                errorText: errorOf(TripField.amount),
                enabled: editable,
                textInputAction: TextInputAction.next,
                onChanged: (amount) => bloc.add(TripAmountChanged(amount)),
              ),
              const SizedBox(height: Spacing.md),
              MoneyField(
                label: ShiftDiaryStrings.commission,
                errorText: errorOf(TripField.commission),
                enabled: editable,
                textInputAction: TextInputAction.done,
                onChanged: (commission) =>
                    bloc.add(TripCommissionChanged(commission)),
              ),
              const SizedBox(height: Spacing.md),
              _PaymentField(
                payment: draft.payment,
                errorText: errorOf(TripField.payment),
                enabled: editable,
                onChanged: (payment) => bloc.add(TripPaymentChanged(payment)),
              ),
              const SizedBox(height: Spacing.lg),
              if (state case AddTripState(
                status: AddTripStatus.failure,
                :final failure?,
              )) ...[
                FailureBanner(failure: failure),
                const SizedBox(height: Spacing.md),
              ],
              FilledButton(
                onPressed: editable
                    ? () => bloc.add(const TripSubmitted())
                    : null,
                child: editable
                    ? Text(
                        state.canRetry
                            ? ShiftDiaryStrings.retry
                            : ShiftDiaryStrings.save,
                      )
                    : Builder(
                        builder: (context) => Semantics(
                          label: ShiftDiaryStrings.saving,
                          child: SizedBox.square(
                            dimension: IconTheme.of(context).size,
                            child: const CircularProgressIndicator.adaptive(),
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.closable});

  final bool closable;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Semantics(
            header: true,
            child: Text(
              ShiftDiaryStrings.newTrip,
              style: Theme.of(context).textTheme.titleLarge,
            ),
          ),
        ),
        IconButton(
          tooltip: ShiftDiaryStrings.close,
          onPressed: closable ? () => Navigator.maybePop(context) : null,
          icon: const Icon(Icons.close),
        ),
      ],
    );
  }
}

class _MomentField extends StatelessWidget {
  const _MomentField({
    required this.label,
    required this.day,
    required this.time,
    required this.initialTime,
    required this.errorText,
    required this.enabled,
    required this.onDayChanged,
    required this.onTimeChanged,
  });

  final String label;
  final DateTime day;
  final ClockTime? time;
  final ClockTime? initialTime;
  final String? errorText;
  final bool enabled;
  final ValueChanged<DateTime> onDayChanged;
  final ValueChanged<ClockTime> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    final clock = context.read<DriverClock>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final dayText = day.year == clock.today().year
        ? DateFormat.MMMMd(locale).format(day)
        : DateFormat.yMMMMd(locale).format(day);
    final timeText = switch (time) {
      (:final hour, :final minute) => ShiftDiaryStrings.clockTime(hour, minute),
      null => null,
    };
    return InputDecorator(
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        enabled: enabled,
      ),
      child: Wrap(
        spacing: Spacing.sm,
        children: [
          TextButton.icon(
            onPressed: enabled ? () => _pickDay(context, clock) : null,
            icon: const Icon(Icons.event_outlined),
            label: Text(
              dayText,
              semanticsLabel: ShiftDiaryStrings.spokenDay(label, dayText),
            ),
          ),
          TextButton.icon(
            onPressed: enabled ? () => _pickTime(context, clock) : null,
            icon: const Icon(Icons.schedule),
            label: Text(
              timeText ?? ShiftDiaryStrings.time,
              style: const TextStyle().merge(AppTextStyles.tabularFigures),
              semanticsLabel: ShiftDiaryStrings.spokenTime(label, timeText),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDay(BuildContext context, DriverClock clock) async {
    final picked = await showDayPicker(
      context,
      initialDate: day,
      today: clock.today(),
    );
    if (picked != null && picked != day) onDayChanged(picked);
  }

  Future<void> _pickTime(BuildContext context, DriverClock clock) async {
    final now = clock.now();
    final picked = await showClockTimePicker(
      context,
      initialTime: initialTime ?? (hour: now.hour, minute: now.minute),
    );
    if (picked != null) onTimeChanged(picked);
  }
}

class _PaymentField extends StatelessWidget {
  const _PaymentField({
    required this.payment,
    required this.errorText,
    required this.enabled,
    required this.onChanged,
  });

  final PaymentMethod? payment;
  final String? errorText;
  final bool enabled;
  final ValueChanged<PaymentMethod?> onChanged;

  @override
  Widget build(BuildContext context) {
    final payment = this.payment;
    return InputDecorator(
      decoration: InputDecoration(
        labelText: ShiftDiaryStrings.paymentMethod,
        errorText: errorText,
        enabled: enabled,
        border: InputBorder.none,
        contentPadding: const EdgeInsets.only(top: Spacing.sm),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final inRow = _labelsFitInRow(context, constraints.maxWidth);
          return SegmentedButton<PaymentMethod>(
            direction: inRow ? Axis.horizontal : Axis.vertical,
            expandedInsets: inRow ? EdgeInsets.zero : null,
            segments: [
              for (final method in PaymentMethod.values)
                ButtonSegment(
                  value: method,
                  label: Text(ShiftDiaryStrings.payment(method)),
                ),
            ],
            selected: {?payment},
            emptySelectionAllowed: true,
            showSelectedIcon: false,
            onSelectionChanged: enabled
                ? (selected) => onChanged(selected.firstOrNull)
                : null,
          );
        },
      ),
    );
  }

  bool _labelsFitInRow(BuildContext context, double width) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
    final style = Theme.of(context).textTheme.labelLarge;
    try {
      final widest = PaymentMethod.values
          .map((method) {
            painter
              ..text = TextSpan(
                text: ShiftDiaryStrings.payment(method),
                style: style,
              )
              ..layout();
            return painter.width;
          })
          .reduce(max);
      final segmentWidth = width / PaymentMethod.values.length;
      return widest + 2 * Spacing.md <= segmentWidth;
    } finally {
      painter.dispose();
    }
  }
}
