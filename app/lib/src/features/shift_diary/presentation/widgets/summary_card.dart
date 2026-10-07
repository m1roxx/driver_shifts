import 'dart:math';

import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_measure.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_summary.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/payment_avatar.dart';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _Net(net: summary.net, tripsCount: summary.tripsCount),
          const Divider(indent: Spacing.md),
          _MoneyRow(label: ShiftDiaryStrings.revenue, amount: summary.revenue),
          _PaymentSplit(byPayment: summary.byPayment),
          const Divider(indent: Spacing.md),
          _MoneyRow(
            label: ShiftDiaryStrings.commission,
            amount: summary.commission,
          ),
        ],
      ),
    );
  }
}

class _MoneyRow extends StatelessWidget {
  const _MoneyRow({required this.label, required this.amount});

  final String label;
  final int amount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = theme.textTheme.bodyLarge;
    return Semantics(
      container: true,
      label: ShiftDiaryStrings.spokenMoney(label, amount),
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
            children: [
              Text(
                label,
                style: style?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              MoneyText(amount, style: style),
            ],
          ),
        ),
      ),
    );
  }
}

class _Net extends StatelessWidget {
  const _Net({required this.net, required this.tripsCount});

  final int net;
  final int tripsCount;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final secondary = theme.colorScheme.onSurfaceVariant;
    return Semantics(
      container: true,
      label: ShiftDiaryStrings.spokenNet(net, tripsCount),
      excludeSemantics: true,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              ShiftDiaryStrings.net,
              style: AppTextStyles.medium(textTheme.labelLarge)
                  ?.copyWith(color: secondary),
            ),
            const SizedBox(height: Spacing.xxs),
            MoneyText(
              net,
              style: AppTextStyles.heroAmount(textTheme),
              textScaler: TextScale.headline(context),
            ),
            const SizedBox(height: Spacing.xxs),
            Text(
              ShiftDiaryStrings.tripsCountOf(tripsCount),
              style: textTheme.bodyMedium?.copyWith(color: secondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PaymentSplit extends StatelessWidget {
  const _PaymentSplit({required this.byPayment});

  final PaymentBreakdown byPayment;

  @override
  Widget build(BuildContext context) {
    const underRevenue = EdgeInsets.fromLTRB(
      Spacing.md,
      0,
      Spacing.md,
      Spacing.sml,
    );
    final cash = _PaymentAmount(
      method: PaymentMethod.cash,
      amount: byPayment.cash,
      padding: underRevenue,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        if (TextScale.isLarge(context) ||
            !_labelsFitInHalf(context, constraints.maxWidth)) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              cash,
              const Divider(indent: Spacing.md),
              _PaymentAmount(
                method: PaymentMethod.card,
                amount: byPayment.card,
                padding: const EdgeInsets.symmetric(
                  horizontal: Spacing.md,
                  vertical: Spacing.sml,
                ),
              ),
            ],
          );
        }
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: cash),
              const VerticalDivider(endIndent: Spacing.sml),
              Expanded(
                child: _PaymentAmount(
                  method: PaymentMethod.card,
                  amount: byPayment.card,
                  padding: underRevenue,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  bool _labelsFitInHalf(BuildContext context, double width) {
    final style = AppTextStyles.medium(Theme.of(context).textTheme.labelLarge);
    final widest = PaymentMethod.values
        .map(
          (method) => TextMeasure.width(
            context,
            ShiftDiaryStrings.payment(method),
            style,
          ),
        )
        .reduce(max);
    final divider = Theme.of(context).dividerTheme.space ?? 0;
    final half = (width - divider) / 2;
    return 2 * Spacing.md + Sizes.smallAvatar + Spacing.sm + widest <= half;
  }
}

class _PaymentAmount extends StatelessWidget {
  const _PaymentAmount({
    required this.method,
    required this.amount,
    required this.padding,
  });

  final PaymentMethod method;
  final int amount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    final label = ShiftDiaryStrings.payment(method);
    return Semantics(
      container: true,
      label: ShiftDiaryStrings.spokenMoney(label, amount),
      excludeSemantics: true,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                PaymentAvatar(method, small: true),
                const SizedBox(width: Spacing.sm),
                Flexible(
                  child: Text(
                    label,
                    style: AppTextStyles.medium(textTheme.labelLarge)
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
            const SizedBox(height: Sizes.amountGap),
            MoneyText(amount, style: textTheme.bodyLarge),
          ],
        ),
      ),
    );
  }
}
