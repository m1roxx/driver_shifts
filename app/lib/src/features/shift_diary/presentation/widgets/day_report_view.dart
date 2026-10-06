import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/empty_day_message.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/refresh_failure_banner.dart';
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
                Spacing.md,
                Spacing.md,
                0,
              ),
              sliver: SliverToBoxAdapter(
                child: RefreshFailureBanner(failure: failure, onRetry: onRetry),
              ),
            ),
          SliverPadding(
            padding: const EdgeInsets.all(Spacing.md),
            sliver: SliverToBoxAdapter(
              child: SummaryCard(summary: report.summary),
            ),
          ),
          if (trips.isEmpty)
            const SliverToBoxAdapter(child: EmptyDayMessage())
          else
            SliverList.builder(
              itemCount: trips.length,
              itemBuilder: (context, index) => TripTile(trip: trips[index]),
            ),
        ],
      ),
    );
  }
}
