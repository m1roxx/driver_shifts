import 'package:driver_shifts/src/core/format/money.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_summary.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/metric_grid.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/money_text.dart';
import 'package:flutter/material.dart';

class SummaryCard extends StatelessWidget {
  const SummaryCard({super.key, required this.summary});

  final DaySummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(Spacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.end,
              spacing: Spacing.md,
              runSpacing: Spacing.md,
              children: [
                Semantics(
                  container: true,
                  label: '${ShiftDiaryStrings.net} ${spokenTenge(summary.net)}',
                  excludeSemantics: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ShiftDiaryStrings.net,
                        style: textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      MoneyText(summary.net, style: textTheme.headlineLarge),
                    ],
                  ),
                ),
                _Metric(
                  label: ShiftDiaryStrings.tripsCount,
                  value: '${summary.tripsCount}',
                  spokenValue: '${summary.tripsCount}',
                ),
              ],
            ),
            const SizedBox(height: Spacing.md),
            MetricGrid(
              children: [
                _Metric.money(
                  label: ShiftDiaryStrings.revenue,
                  amount: summary.revenue,
                ),
                _Metric.money(
                  label: ShiftDiaryStrings.commission,
                  amount: summary.commission,
                ),
                _Metric.money(
                  label: ShiftDiaryStrings.payment(PaymentMethod.cash),
                  amount: summary.byPayment.cash,
                ),
                _Metric.money(
                  label: ShiftDiaryStrings.payment(PaymentMethod.card),
                  amount: summary.byPayment.card,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({
    required this.label,
    required this.value,
    required this.spokenValue,
  });

  _Metric.money({required String label, required int amount})
    : this(
        label: label,
        value: formatTenge(amount),
        spokenValue: spokenTenge(amount),
      );

  final String label;
  final String value;
  final String spokenValue;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textTheme = theme.textTheme;
    return Semantics(
      container: true,
      label: '$label $spokenValue',
      excludeSemantics: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: textTheme.labelLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: Spacing.xs),
          Text(
            value,
            style: textTheme.titleLarge?.merge(AppTextStyles.tabularFigures),
          ),
        ],
      ),
    );
  }
}
