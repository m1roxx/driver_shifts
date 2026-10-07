import 'dart:async';
import 'dart:math';

import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/motion.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/add_trip_bloc.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_picker.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/failure_banner.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/field_error.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_field.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/next_day_badge.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/time_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

class AddTripSheet extends StatelessWidget {
  const AddTripSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<AddTripBloc>();
    final state = context.watch<AddTripBloc>().state;
    final draft = state.draft;
    final editable = state.editable;
    final submitting = state.status == AddTripStatus.submitting;
    String? errorOf(TripField field) => switch (state.fieldErrors[field]) {
      final error? => ShiftDiaryStrings.fieldError(field, error),
      null => null,
    };
    return BlocListener<AddTripBloc, AddTripState>(
      listenWhen: (previous, current) =>
          previous.status != current.status &&
          current.status == AddTripStatus.failure,
      listener: (context, state) => unawaited(HapticFeedback.heavyImpact()),
      child: PopScope(
        canPop: !submitting,
        child: Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.viewInsetsOf(context).bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _Header(closable: !submitting),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Opacity(
                        opacity: editable ? 1 : Opacities.locked,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  _MomentField(
                                    label: ShiftDiaryStrings.start,
                                    day: draft.startDay,
                                    time: draft.startTime,
                                    initialTime: draft.startTime,
                                    nextDay: false,
                                    errorText: errorOf(TripField.start),
                                    enabled: editable,
                                    onDayChanged: (day) =>
                                        bloc.add(TripStartDayChanged(day)),
                                    onTimeChanged: (time) =>
                                        bloc.add(TripStartTimeChanged(time)),
                                  ),
                                  const Divider(indent: Spacing.md),
                                  _MomentField(
                                    label: ShiftDiaryStrings.end,
                                    day: draft.endDay,
                                    time: draft.endTime,
                                    initialTime:
                                        draft.endTime ?? draft.startTime,
                                    nextDay:
                                        draft.endDay ==
                                        draft.startDay.add(
                                          const Duration(days: 1),
                                        ),
                                    errorText: errorOf(TripField.end),
                                    enabled: editable,
                                    onDayChanged: (day) =>
                                        bloc.add(TripEndDayChanged(day)),
                                    onTimeChanged: (time) =>
                                        bloc.add(TripEndTimeChanged(time)),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Spacing.md),
                            Card(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  MoneyField(
                                    label: ShiftDiaryStrings.amount,
                                    errorText: errorOf(TripField.amount),
                                    enabled: editable,
                                    textInputAction: TextInputAction.next,
                                    onChanged: (amount) =>
                                        bloc.add(TripAmountChanged(amount)),
                                  ),
                                  const Divider(indent: Spacing.md),
                                  MoneyField(
                                    label: ShiftDiaryStrings.commission,
                                    errorText: errorOf(TripField.commission),
                                    enabled: editable,
                                    textInputAction: TextInputAction.done,
                                    onChanged: (commission) => bloc.add(
                                      TripCommissionChanged(commission),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: Spacing.lg),
                            _PaymentField(
                              payment: draft.payment,
                              errorText: errorOf(TripField.payment),
                              enabled: editable,
                              onChanged: (payment) =>
                                  bloc.add(TripPaymentChanged(payment)),
                            ),
                          ],
                        ),
                      ),
                      AnimatedSize(
                        duration: Motion.of(context, Motion.resize),
                        curve: Motion.curve,
                        alignment: Alignment.topCenter,
                        child: switch (state) {
                          AddTripState(
                            status: AddTripStatus.failure,
                            :final failure?,
                          ) =>
                            Padding(
                              padding: const EdgeInsets.only(top: Spacing.md),
                              child: FailureBanner(failure: failure),
                            ),
                          _ => const SizedBox(width: double.infinity),
                        },
                      ),
                    ],
                  ),
                ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: const EdgeInsets.all(Spacing.md),
                  child: _SubmitButton(
                    state: state,
                    onSubmit: () => bloc.add(const TripSubmitted()),
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
    return Padding(
      padding: const EdgeInsets.only(top: Spacing.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: Sizes.toolbar),
        child: Row(
          children: [
            const SizedBox(width: Sizes.touchTarget),
            Expanded(
              child: Semantics(
                header: true,
                child: Text(
                  ShiftDiaryStrings.newTrip,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.strong(
                    Theme.of(context).textTheme.titleMedium,
                  ),
                ),
              ),
            ),
            IconButton(
              tooltip: ShiftDiaryStrings.close,
              onPressed: closable ? () => Navigator.maybePop(context) : null,
              icon: Icon(AppIcons.of(context).close),
            ),
          ],
        ),
      ),
    );
  }
}

enum _SubmitKind { save, retry, saving, close }

class _SubmitButton extends StatelessWidget {
  const _SubmitButton({required this.state, required this.onSubmit});

  final AddTripState state;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final kind = switch (state) {
      AddTripState(conflicted: true) => _SubmitKind.close,
      AddTripState(status: AddTripStatus.submitting || AddTripStatus.success) =>
        _SubmitKind.saving,
      AddTripState(canRetry: true) => _SubmitKind.retry,
      AddTripState() => _SubmitKind.save,
    };
    final label = switch (kind) {
      _SubmitKind.save => ShiftDiaryStrings.save,
      _SubmitKind.retry => ShiftDiaryStrings.retry,
      _SubmitKind.saving => ShiftDiaryStrings.saving,
      _SubmitKind.close => ShiftDiaryStrings.close,
    };
    final leading = switch (kind) {
      _SubmitKind.retry => Icon(AppIcons.of(context).retry),
      _SubmitKind.saving => const SizedBox.square(
        dimension: Sizes.smallIcon,
        child: CircularProgressIndicator.adaptive(),
      ),
      _SubmitKind.save || _SubmitKind.close => null,
    };
    return FilledButton(
      onPressed: switch (kind) {
        _SubmitKind.save || _SubmitKind.retry => onSubmit,
        _SubmitKind.close => () => Navigator.maybePop(context),
        _SubmitKind.saving => null,
      },
      style: FilledButton.styleFrom(
        disabledBackgroundColor: colors.secondaryContainer,
        disabledForegroundColor: colors.onSecondaryContainer,
      ),
      child: AnimatedSwitcher(
        duration: Motion.of(context, Motion.fast),
        child: Semantics(
          key: ValueKey(kind),
          liveRegion: kind == _SubmitKind.saving,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (leading != null) ...[
                leading,
                const SizedBox(width: Spacing.sm),
              ],
              Flexible(child: Text(label, textAlign: TextAlign.center)),
            ],
          ),
        ),
      ),
    );
  }
}

class _MomentField extends StatelessWidget {
  const _MomentField({
    required this.label,
    required this.day,
    required this.time,
    required this.initialTime,
    required this.nextDay,
    required this.errorText,
    required this.enabled,
    required this.onDayChanged,
    required this.onTimeChanged,
  });

  final String label;
  final DateTime day;
  final ClockTime? time;
  final ClockTime? initialTime;
  final bool nextDay;
  final String? errorText;
  final bool enabled;
  final ValueChanged<DateTime> onDayChanged;
  final ValueChanged<ClockTime> onTimeChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final icons = AppIcons.of(context);
    final clock = context.read<DriverClock>();
    final locale = Localizations.localeOf(context).toLanguageTag();
    final errorText = this.errorText;
    final dayText = day.year == clock.today().year
        ? DateFormat.MMMMd(locale).format(day)
        : DateFormat.yMMMMd(locale).format(day);
    final timeText = switch (time) {
      (:final hour, :final minute) => ShiftDiaryStrings.clockTime(hour, minute),
      null => null,
    };
    final title = ExcludeSemantics(
      child: Wrap(
        spacing: Spacing.sm,
        runSpacing: Spacing.xs,
        crossAxisAlignment: WrapCrossAlignment.center,
        children: [
          Text(
            label,
            style: theme.textTheme.bodyLarge?.copyWith(
              color: errorText == null ? colors.onSurface : colors.error,
            ),
          ),
          AnimatedSwitcher(
            duration: Motion.of(context, Motion.fast),
            child: nextDay ? const NextDayBadge() : const SizedBox.shrink(),
          ),
        ],
      ),
    );
    final pickers = Wrap(
      spacing: Spacing.sm,
      children: [
        _PickerButton(
          icon: icons.date,
          text: dayText,
          semanticsLabel: ShiftDiaryStrings.spokenDay(
            label,
            dayText,
            nextDay: nextDay,
          ),
          onPressed: enabled ? () => _pickDay(context, clock) : null,
        ),
        _PickerButton(
          icon: icons.time,
          text: timeText ?? ShiftDiaryStrings.time,
          placeholder: timeText == null,
          semanticsLabel: ShiftDiaryStrings.spokenTime(label, timeText),
          onPressed: enabled ? () => _pickTime(context, clock) : null,
        ),
      ],
    );
    return Semantics(
      container: true,
      label: label,
      hint: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: Sizes.formRow),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                Spacing.xs,
                Spacing.sm,
                Spacing.xs,
              ),
              child: TextScale.isLarge(context)
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(top: Spacing.xs),
                          child: title,
                        ),
                        pickers,
                      ],
                    )
                  : Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: Spacing.sm,
                      children: [title, pickers],
                    ),
            ),
          ),
          if (errorText != null) FieldError(errorText),
        ],
      ),
    );
  }

  Future<void> _pickDay(BuildContext context, DriverClock clock) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final picked = await showDayPicker(
      context,
      title: label,
      initialDate: day,
      today: clock.today(),
    );
    if (picked != null && picked != day) onDayChanged(picked);
  }

  Future<void> _pickTime(BuildContext context, DriverClock clock) async {
    FocusManager.instance.primaryFocus?.unfocus();
    final now = clock.now();
    final picked = await showClockTimePicker(
      context,
      title: label,
      initialTime: initialTime ?? (hour: now.hour, minute: now.minute),
    );
    if (picked != null) onTimeChanged(picked);
  }
}

class _PickerButton extends StatelessWidget {
  const _PickerButton({
    required this.icon,
    required this.text,
    required this.semanticsLabel,
    required this.onPressed,
    this.placeholder = false,
  });

  final IconData icon;
  final String text;
  final String semanticsLabel;
  final VoidCallback? onPressed;
  final bool placeholder;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final foreground = placeholder ? colors.onSurfaceVariant : colors.onSurface;
    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        backgroundColor: colors.surfaceContainerHighest,
        disabledBackgroundColor: colors.surfaceContainerHighest,
        foregroundColor: foreground,
        disabledForegroundColor: foreground,
        iconColor: colors.onSurfaceVariant,
        disabledIconColor: colors.onSurfaceVariant,
        minimumSize: const Size(Sizes.pickerButton, Sizes.pickerButton),
        tapTargetSize: MaterialTapTargetSize.padded,
        padding: const EdgeInsets.symmetric(
          horizontal: Sizes.pickerButtonPadding,
        ),
        iconSize: Sizes.smallIcon,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(Radii.medium)),
        ),
        textStyle: theme.textTheme.bodyLarge?.merge(
          AppTextStyles.tabularFigures,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon),
          const SizedBox(width: Sizes.iconGap),
          Flexible(child: Text(text, semanticsLabel: semanticsLabel)),
        ],
      ),
    );
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
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final payment = this.payment;
    final errorText = this.errorText;
    final segmentStyle = AppTextStyles.strong(theme.textTheme.labelLarge);
    final segmentForeground = WidgetStateProperty.resolveWith(
      (states) => states.contains(WidgetState.selected)
          ? colors.onSecondaryContainer
          : colors.onSurface,
    );
    return Semantics(
      container: true,
      label: ShiftDiaryStrings.paymentMethod,
      hint: errorText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Spacing.md,
              0,
              Spacing.md,
              Spacing.sm,
            ),
            child: ExcludeSemantics(
              child: Text(
                ShiftDiaryStrings.paymentMethod,
                style: AppTextStyles.medium(theme.textTheme.labelLarge)
                    ?.copyWith(
                      color: errorText == null
                          ? colors.onSurfaceVariant
                          : colors.error,
                    ),
              ),
            ),
          ),
          LayoutBuilder(
            builder: (context, constraints) {
              final inRow =
                  !TextScale.isLarge(context) &&
                  _labelsFitInRow(context, constraints.maxWidth, segmentStyle);
              return SegmentedButton<PaymentMethod>(
                direction: inRow ? Axis.horizontal : Axis.vertical,
                expandedInsets: inRow ? EdgeInsets.zero : null,
                style:
                    SegmentedButton.styleFrom(
                      minimumSize: const Size.square(Sizes.touchTarget),
                      textStyle: segmentStyle,
                    ).copyWith(
                      side: WidgetStatePropertyAll(
                        BorderSide(color: colors.outline),
                      ),
                      backgroundColor: WidgetStateProperty.resolveWith(
                        (states) => states.contains(WidgetState.selected)
                            ? colors.secondaryContainer
                            : null,
                      ),
                      foregroundColor: segmentForeground,
                      iconColor: segmentForeground,
                    ),
                segments: [
                  for (final method in PaymentMethod.values)
                    ButtonSegment(
                      value: method,
                      icon: Icon(switch (method) {
                        PaymentMethod.cash => AppIcons.cash,
                        PaymentMethod.card => AppIcons.card,
                      }),
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
          if (errorText != null) ...[
            const SizedBox(height: Spacing.sm),
            FieldError(errorText),
          ],
        ],
      ),
    );
  }

  bool _labelsFitInRow(BuildContext context, double width, TextStyle? style) {
    final painter = TextPainter(
      textDirection: Directionality.of(context),
      textScaler: MediaQuery.textScalerOf(context),
      maxLines: 1,
    );
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
      final icon = MediaQuery.textScalerOf(context).scale(Sizes.smallIcon);
      return widest + icon + Spacing.sm + 2 * Spacing.md <= segmentWidth;
    } finally {
      painter.dispose();
    }
  }
}
