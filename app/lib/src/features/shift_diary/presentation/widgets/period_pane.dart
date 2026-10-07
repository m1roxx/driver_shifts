import 'dart:async';

import 'package:driver_shifts/src/core/theme/motion.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/period_bloc.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_failure_view.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_pages.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_skeleton.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_report_view.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/period_switcher.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class PeriodPane extends StatefulWidget {
  const PeriodPane({
    super.key,
    required this.initialPeriod,
    required this.today,
    required this.onDaySelected,
    required this.onScrollMetrics,
  });

  final Period initialPeriod;
  final DateTime today;
  final ValueChanged<DateTime> onDaySelected;
  final void Function(int depth, ScrollMetrics metrics) onScrollMetrics;

  @override
  State<PeriodPane> createState() => _PeriodPaneState();
}

class _PeriodPaneState extends State<PeriodPane> {
  static const double _settledPage = 1e-6;

  late final Period _first = Period.first(widget.initialPeriod.kind);
  late final int _pageCount =
      Period.last(widget.initialPeriod.kind).periodsSince(_first) + 1;
  late final PageController _pages;
  late Period _shown = widget.initialPeriod;
  late int _lastPage;

  @override
  void initState() {
    super.initState();
    _lastPage = _pageOf(_shown);
    _pages = PageController(initialPage: _lastPage);
  }

  @override
  void dispose() {
    _pages.dispose();
    super.dispose();
  }

  int _pageOf(Period period) => period.periodsSince(_first);

  Period _periodAt(int page) => _first.shifted(page);

  @override
  Widget build(BuildContext context) {
    return BlocListener<PeriodBloc, PeriodState>(
      listenWhen: (previous, current) => previous.period != current.period,
      listener: (context, state) {
        if (state.period.kind == _first.kind &&
            _pages.hasClients &&
            _pages.page?.round() != _pageOf(state.period)) {
          _turnTo(state.period);
        }
      },
      child: Column(
        children: [
          PeriodSwitcher(
            period: _shown,
            today: widget.today,
            onChanged: _turnTo,
          ),
          Expanded(
            child: NotificationListener<ScrollNotification>(
              onNotification: _followPages,
              child: DayPages(
                controller: _pages,
                pageCount: _pageCount,
                pageBuilder: _buildPage,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPage(BuildContext context, int page) {
    final period = _periodAt(page);
    bool watch(int depth, ScrollMetrics metrics) {
      if (period == context.read<PeriodBloc>().state.period) {
        widget.onScrollMetrics(depth, metrics);
      }
      return false;
    }

    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) =>
          watch(notification.depth, notification.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) =>
            watch(notification.depth, notification.metrics),
        child: _PeriodPage(
          key: ValueKey(period),
          period: period,
          today: widget.today,
          onRefresh: _refresh,
          onDaySelected: widget.onDaySelected,
        ),
      ),
    );
  }

  bool _followPages(ScrollNotification notification) {
    if (notification case ScrollNotification(
      depth: 0,
      metrics: PageMetrics(:final page?),
    )) {
      final nearest = page.round();
      if (nearest != _lastPage) {
        _lastPage = nearest;
        _show(_periodAt(nearest));
      }
      if (notification is ScrollEndNotification &&
          (page - nearest).abs() < _settledPage) {
        final bloc = context.read<PeriodBloc>();
        final period = _periodAt(nearest);
        if (bloc.state.period != period) bloc.add(PeriodChanged(period));
      }
    }
    return false;
  }

  void _show(Period period) {
    if (period == _shown) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() => _shown = period);
  }

  void _turnTo(Period period) {
    final page = _pageOf(period);
    if (page < 0 || page >= _pageCount) return;
    _show(period);
    final from = _pages.page ?? page.toDouble();
    if (MediaQuery.disableAnimationsOf(context) || (page - from).abs() >= 2) {
      _pages.jumpToPage(page);
      return;
    }
    unawaited(
      _pages.animateToPage(
        page,
        duration: Motion.daySwitch,
        curve: Motion.curve,
      ),
    );
  }

  Future<void> _refresh() async {
    final bloc = context.read<PeriodBloc>()
      ..add(const PeriodRefreshRequested());
    await bloc.stream.firstWhere(
      (state) => state.status != PeriodStatus.loading,
      orElse: () => bloc.state,
    );
  }
}

class _PeriodPage extends StatelessWidget {
  const _PeriodPage({
    super.key,
    required this.period,
    required this.today,
    required this.onRefresh,
    required this.onDaySelected,
  });

  final Period period;
  final DateTime today;
  final RefreshCallback onRefresh;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<PeriodBloc>().state;
    return switch (state) {
      PeriodState(period: final shown) when shown != period =>
        const DaySkeleton(),
      PeriodState(:final report?) => PeriodReportView(
        kind: period.kind,
        report: report,
        today: today,
        refreshFailure: state.failure,
        slow: state.slow,
        onRefresh: onRefresh,
        onDaySelected: onDaySelected,
      ),
      PeriodState(status: PeriodStatus.failure, :final failure?) =>
        DayFailureView(
          title: ShiftDiaryStrings.periodLoadFailedTitle,
          failure: failure,
          onRetry: () =>
              context.read<PeriodBloc>().add(const PeriodRefreshRequested()),
        ),
      PeriodState(:final slow) => DaySkeleton(slow: slow),
    };
  }
}
