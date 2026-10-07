import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/radii.dart';
import 'package:driver_shifts/src/core/theme/sizes.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/empty_day_message.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/failure_banner.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/summary_card.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/trip_tile.dart';
import 'package:flutter/material.dart';

class DayReportView extends StatelessWidget {
  const DayReportView({
    super.key,
    required this.report,
    required this.refreshFailure,
    required this.onRefresh,
    required this.onRetry,
    required this.refreshIndicatorKey,
  });

  final DayReport report;
  final Failure? refreshFailure;
  final RefreshCallback onRefresh;
  final VoidCallback onRetry;
  final GlobalKey<RefreshIndicatorState> refreshIndicatorKey;

  @override
  Widget build(BuildContext context) {
    final trips = report.trips;
    return RefreshIndicator.adaptive(
      key: refreshIndicatorKey,
      onRefresh: onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          if (refreshFailure case final failure?)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(
                Spacing.md,
                0,
                Spacing.md,
                Spacing.md,
              ),
              sliver: SliverToBoxAdapter(
                child: FailureBanner(failure: failure, onRetry: onRetry),
              ),
            ),
          if (trips.isEmpty)
            const SliverToBoxAdapter(child: EmptyDayMessage())
          else ...[
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              sliver: SliverToBoxAdapter(
                child: SummaryCard(summary: report.summary),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
              sliver: SliverMainAxisGroup(
                slivers: [
                  const SliverToBoxAdapter(child: _TripsHeader()),
                  _TripList(trips: trips),
                ],
              ),
            ),
          ],
          const SliverPadding(padding: EdgeInsets.only(bottom: Spacing.md)),
        ],
      ),
    );
  }
}

class _TripsHeader extends StatelessWidget {
  const _TripsHeader();

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
          ShiftDiaryStrings.tripsCount,
          style: AppTextStyles.medium(theme.textTheme.labelLarge)
              ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
        ),
      ),
    );
  }
}

class _TripList extends StatelessWidget {
  const _TripList({required this.trips});

  final List<Trip> trips;

  @override
  Widget build(BuildContext context) {
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.large)),
      ),
      sliver: SliverList.separated(
        itemCount: trips.length,
        itemBuilder: (context, index) =>
            TripTile(key: ValueKey(trips[index].id), trip: trips[index]),
        separatorBuilder: (context, index) => Divider(
          indent: TextScale.isLarge(context)
              ? Spacing.md
              : Sizes.tripDividerIndent,
        ),
      ),
    );
  }
}
