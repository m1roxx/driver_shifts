import 'dart:async';

import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/theme/app_text_styles.dart';
import 'package:driver_shifts/src/core/theme/motion.dart';
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

class DayReportView extends StatefulWidget {
  const DayReportView({
    super.key,
    required this.report,
    required this.refreshFailure,
    required this.savedTripId,
    required this.onRefresh,
  });

  final DayReport report;
  final Failure? refreshFailure;
  final String? savedTripId;
  final RefreshCallback onRefresh;

  @override
  State<DayReportView> createState() => _DayReportViewState();
}

class _DayReportViewState extends State<DayReportView> {
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
    final DayReportView(:report, :refreshFailure, :savedTripId) = widget;
    final trips = report.trips;
    return RefreshIndicator.adaptive(
      key: _refreshIndicator,
      onRefresh: widget.onRefresh,
      child: CustomScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        slivers: [
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: Spacing.md),
            sliver: SliverToBoxAdapter(
              child: AnimatedSize(
                duration: Motion.of(context, Motion.resize),
                curve: Motion.curve,
                alignment: Alignment.topCenter,
                child: switch (refreshFailure) {
                  final failure? => Padding(
                    padding: const EdgeInsets.only(bottom: Spacing.md),
                    child: FailureBanner(failure: failure, onRetry: _retry),
                  ),
                  null => const SizedBox(width: double.infinity),
                },
              ),
            ),
          ),
          if (trips.isEmpty)
            const SliverFillRemaining(
              hasScrollBody: false,
              child: Center(child: EmptyDayMessage()),
            )
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
                  _TripList(trips: trips, savedTripId: savedTripId),
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
  const _TripList({required this.trips, required this.savedTripId});

  final List<Trip> trips;
  final String? savedTripId;

  @override
  Widget build(BuildContext context) {
    return DecoratedSliver(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: const BorderRadius.all(Radius.circular(Radii.large)),
      ),
      sliver: SliverList.separated(
        itemCount: trips.length,
        itemBuilder: (context, index) {
          final trip = trips[index];
          const corner = Radius.circular(Radii.large);
          return _NewTripHighlight(
            key: ValueKey(trip.id),
            highlighted: trip.id == savedTripId,
            borderRadius: BorderRadius.vertical(
              top: index == 0 ? corner : Radius.zero,
              bottom: index == trips.length - 1 ? corner : Radius.zero,
            ),
            child: TripTile(trip: trip),
          );
        },
        separatorBuilder: (context, index) => Divider(
          indent: TextScale.isLarge(context)
              ? Spacing.md
              : Sizes.tripDividerIndent,
        ),
      ),
    );
  }
}

class _NewTripHighlight extends StatefulWidget {
  const _NewTripHighlight({
    super.key,
    required this.highlighted,
    required this.borderRadius,
    required this.child,
  });

  final bool highlighted;
  final BorderRadius borderRadius;
  final Widget child;

  @override
  State<_NewTripHighlight> createState() => _NewTripHighlightState();
}

class _NewTripHighlightState extends State<_NewTripHighlight>
    with SingleTickerProviderStateMixin {
  late final AnimationController _fade = AnimationController(
    vsync: this,
    duration: Motion.newTripHighlight,
    value: widget.highlighted ? 0 : 1,
  );

  @override
  void initState() {
    super.initState();
    if (widget.highlighted) unawaited(_fade.forward());
  }

  @override
  void dispose() {
    _fade.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = ColorTween(
      begin: theme.colorScheme.secondaryContainer,
      end: theme.cardTheme.color,
    ).animate(_fade);
    return AnimatedBuilder(
      animation: colors,
      builder: (context, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: _fade.isCompleted ? null : colors.value,
          borderRadius: widget.borderRadius,
        ),
        child: child,
      ),
      child: widget.child,
    );
  }
}
