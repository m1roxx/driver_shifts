import 'dart:async';

import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/empty_day_message.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_day_tile.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_stats_section.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/refresh_status_sliver.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/summary_card.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/week_chart.dart';
import 'package:flutter/material.dart';

class PeriodReportView extends StatefulWidget {
  const PeriodReportView({
    super.key,
    required this.kind,
    required this.report,
    required this.today,
    required this.refreshFailure,
    required this.slow,
    required this.onRefresh,
    required this.onDaySelected,
  });

  final PeriodKind kind;
  final PeriodReport report;
  final DateTime today;
  final Failure? refreshFailure;
  final bool slow;
  final RefreshCallback onRefresh;
  final ValueChanged<DateTime> onDaySelected;

  @override
  State<PeriodReportView> createState() => _PeriodReportViewState();
}

class _PeriodReportViewState extends State<PeriodReportView> {
  final _refreshIndicator = GlobalKey<RefreshIndicatorState>();

  void _retry() {
    if (_refreshIndicator.currentState case final indicator?) {
      unawaited(indicator.show());
    } else {
      unawaited(widget.onRefresh());
    }
  }

  @override
  Widget build(BuildContext context) {
    final PeriodReportView(:kind, :report, :today) = widget;
    final days = switch (kind) {
      PeriodKind.week => [
        for (final total in report.days)
          if (!total.date.isAfter(today)) total,
      ],
      PeriodKind.month => [
        for (final total in report.days)
          if (total.summary.tripsCount > 0) total,
      ],
    };
    return RefreshIndicator.adaptive(
      key: _refreshIndicator,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          RefreshStatusSliver(
            failure: widget.refreshFailure,
            slow: widget.slow,
            onRetry: _retry,
          ),
          if (report.summary.tripsCount == 0)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: EmptyDayMessage(
                  title: ShiftDiaryStrings.noTripsInPeriod(kind),
                ),
              ),
            )
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              sliver: SliverToBoxAdapter(
                child: SummaryCard(
                  summary: report.summary,
                  footer: PeriodStatsSection(stats: report.stats),
                ),
              ),
            ),
            if (kind == PeriodKind.week && !TextScale.isLarge(context))
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _DaysHeader(),
                      WeekChart(
                        days: report.days,
                        bestDay: report.stats.bestDay,
                        today: today,
                        onDaySelected: widget.onDaySelected,
                      ),
                    ],
                  ),
                ),
              )
            else if (days.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
                sliver: SliverMainAxisGroup(
                  slivers: [
                    const SliverToBoxAdapter(child: _DaysHeader()),
                    _DayList(
                      days: days,
                      maxNet: report.stats.bestDay?.net ?? 0,
                      onDaySelected: widget.onDaySelected,
                    ),
                  ],
                ),
              ),
            const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.md)),
          ],
        ],
      ),
    );
  }
}

class _DaysHeader extends StatelessWidget {
  const _DaysHeader();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Spacing.md,
        Spacing.lg,
        Spacing.md,
        Spacing.sm,
      ),
      child: Semantics(
        header: true,
        child: Text(
          ShiftDiaryStrings.byDay,
          style: AppTextStyles.medium(theme.textTheme.labelLarge)
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _DayList extends StatelessWidget {
  const _DayList({
    required this.days,
    required this.maxNet,
    required this.onDaySelected,
  });

  final List<DayTotal> days;
  final int maxNet;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.large)),
      ),
      sliver: SliverList.separated(
        itemCount: days.length,
        itemBuilder: (context, index) {
          final total = days[index];
          const corner = Radius.circular(Radii.large);
          return PeriodDayTile(
            key: ValueKey(total.date),
            total: total,
            maxNet: maxNet,
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? corner : Radius.zero,
              bottom: index == days.length - 1 ? corner : Radius.zero,
            ),
            onTap: () => onDaySelected(total.date),
          );
        },
        separatorBuilder: (context, index) => const Divider(indent: Spacing.md),
      ),
    );
  }
}
