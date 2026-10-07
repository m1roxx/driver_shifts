import 'dart:async';

import 'package:driver_shifts/src/core/theme/app_icons.dart';
import 'package:driver_shifts/src/core/theme/motion.dart';
import 'package:driver_shifts/src/core/theme/spacing.dart';
import 'package:driver_shifts/src/core/theme/text_scale.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/add_trip_bloc.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/day_bloc.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/shift_diary_strings.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/add_trip_sheet.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_failure_view.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_pages.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_report_view.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_skeleton.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_switcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShiftDiaryScreen extends StatefulWidget {
  const ShiftDiaryScreen({super.key});

  @override
  State<ShiftDiaryScreen> createState() => _ShiftDiaryScreenState();
}

class _ShiftDiaryScreenState extends State<ShiftDiaryScreen> {
  static final DateTime _firstDay = DateTime.utc(1, 1, 2);
  static final int _pageCount =
      DateTime.utc(9999, 12, 30).difference(_firstDay).inDays + 1;
  static const double _settledPage = 1e-6;

  late final DriverClock _clock = context.read<DriverClock>();
  late final AppLifecycleListener _lifecycle;
  late final PageController _pages;
  final _contentBelow = ValueNotifier(false);
  late DateTime _today;
  late DateTime _shownDay;
  late int _lastPage;
  ({int page, DateTime day})? _standIn;
  var _warping = false;
  Timer? _nextDay;
  String? _savedTripId;

  @override
  void initState() {
    super.initState();
    _today = _clock.today();
    _shownDay = context.read<DayBloc>().state.date;
    _lastPage = _pageOf(_shownDay);
    _pages = PageController(initialPage: _lastPage);
    _lifecycle = AppLifecycleListener(onResume: _updateToday);
    _scheduleNextDay();
  }

  @override
  void dispose() {
    _nextDay?.cancel();
    _lifecycle.dispose();
    _pages.dispose();
    _contentBelow.dispose();
    super.dispose();
  }

  void _scheduleNextDay() {
    _nextDay?.cancel();
    _nextDay = Timer(_clock.untilTomorrow(), _updateToday);
  }

  void _updateToday() {
    _scheduleNextDay();
    final today = _clock.today();
    if (today != _today) setState(() => _today = today);
  }

  int _pageOf(DateTime day) => day.difference(_firstDay).inDays;

  DateTime _dayAt(int page) => switch (_standIn) {
    (page: final standInPage, :final day) when standInPage == page => day,
    _ => _firstDay.add(Duration(days: page)),
  };

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final shownDay = _shownDay;
    return Scaffold(
      appBar: TextScale.isLarge(context)
          ? null
          : AppBar(
              title: Semantics(
                header: true,
                child: const Text(ShiftDiaryStrings.title),
              ),
              actions: [
                TodayButton(
                  visible: shownDay != today,
                  onPressed: () => _changeDay(today),
                ),
                const SizedBox(width: Spacing.xs),
              ],
            ),
      bottomNavigationBar: _AddTripBar(
        contentBelow: _contentBelow,
        onPressed: _addTrip,
      ),
      body: SafeArea(
        child: Column(
          children: [
            DaySwitcher(date: shownDay, today: today, onChanged: _changeDay),
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
      ),
    );
  }

  Widget _buildPage(BuildContext context, int page) {
    final day = _dayAt(page);
    return NotificationListener<ScrollMetricsNotification>(
      onNotification: (notification) =>
          _watchContentBelow(day, notification.depth, notification.metrics),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) =>
            _watchContentBelow(day, notification.depth, notification.metrics),
        child: _DayPage(
          key: ValueKey(day),
          day: day,
          savedTripId: _savedTripId,
          onRefresh: _refresh,
          onRetry: _retry,
        ),
      ),
    );
  }

  bool _followPages(ScrollNotification notification) {
    if (notification case ScrollNotification(
      depth: 0,
      metrics: PageMetrics(:final page?),
    )) {
      _followPage(page, settled: notification is ScrollEndNotification);
    }
    return false;
  }

  void _followPage(double page, {required bool settled}) {
    final nearest = page.round();
    if (nearest != _lastPage) {
      _lastPage = nearest;
      if (!_warping) _showDay(_dayAt(nearest));
    }
    if (settled && !_warping && (page - nearest).abs() < _settledPage) {
      _settle(nearest);
    }
  }

  void _settle(int page) {
    final day = _firstDay.add(Duration(days: page));
    if (_standIn != null) setState(() => _standIn = null);
    _showDay(day);
    final dayBloc = context.read<DayBloc>();
    if (dayBloc.state.date != day) dayBloc.add(DayChanged(day));
  }

  void _showDay(DateTime day) {
    if (day == _shownDay) return;
    unawaited(HapticFeedback.selectionClick());
    setState(() {
      _shownDay = day;
      _savedTripId = null;
    });
  }

  void _changeDay(DateTime day) {
    final page = _pageOf(day);
    if (page < 0 || page >= _pageCount) return;
    _showDay(day);
    _turnTo(page);
  }

  void _turnTo(int page) {
    if (MediaQuery.disableAnimationsOf(context)) {
      _pages.jumpToPage(page);
      return;
    }
    final from = _pages.page ?? page.toDouble();
    if ((page - from).abs() >= 2) {
      final next = page > from ? page - 1 : page + 1;
      final leaving = _dayAt(from.round());
      setState(() => _standIn = (page: next, day: leaving));
      _warping = true;
      try {
        _pages.jumpToPage(next);
      } finally {
        _warping = false;
      }
    }
    unawaited(
      _pages.animateToPage(
        page,
        duration: Motion.daySwitch,
        curve: Motion.curve,
      ),
    );
  }

  bool _watchContentBelow(DateTime day, int depth, ScrollMetrics metrics) {
    if (depth != 0 || metrics.axis != Axis.vertical) return false;
    if (day != context.read<DayBloc>().state.date) return false;
    final below = metrics.extentAfter > 0;
    final scheduler = SchedulerBinding.instance;
    if (scheduler.schedulerPhase == SchedulerPhase.persistentCallbacks) {
      scheduler.addPostFrameCallback((_) {
        if (mounted) _contentBelow.value = below;
      });
    } else {
      _contentBelow.value = below;
    }
    return false;
  }

  Future<void> _addTrip() async {
    final dayBloc = context.read<DayBloc>();
    final addTripBloc = AddTripBloc(
      context.read<TripsRepository>(),
      _clock,
      day: dayBloc.state.date,
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => BlocProvider.value(
        value: addTripBloc,
        child: BlocListener<AddTripBloc, AddTripState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == AddTripStatus.success,
          listener: (context, state) {
            if (state.trip case final trip?) {
              Navigator.pop(context);
              unawaited(HapticFeedback.lightImpact());
              _announceSaved();
              setState(() => _savedTripId = trip.id);
              _showDayOf(trip, dayBloc);
            }
          },
          child: const AddTripSheet(),
        ),
      ),
    );
    if (addTripBloc.state.unconfirmedTrip case final trip?) {
      _showDayOf(trip, dayBloc);
    }
    unawaited(addTripBloc.close());
  }

  void _announceSaved() {
    if (!mounted || !MediaQuery.supportsAnnounceOf(context)) return;
    unawaited(
      SemanticsService.sendAnnouncement(
        View.of(context),
        ShiftDiaryStrings.tripSaved,
        Directionality.of(context),
      ),
    );
  }

  void _showDayOf(Trip trip, DayBloc dayBloc) {
    final day = _clock.dayOf(trip.start);
    if (day == dayBloc.state.date) {
      dayBloc.add(const DayRefreshRequested());
    } else {
      setState(() => _shownDay = day);
      _turnTo(_pageOf(day));
    }
  }

  Future<void> _refresh() async {
    final bloc = context.read<DayBloc>()..add(const DayRefreshRequested());
    await bloc.stream.firstWhere(
      (state) => state.status != DayStatus.loading,
      orElse: () => bloc.state,
    );
  }

  void _retry() => context.read<DayBloc>().add(const DayRefreshRequested());
}

class _DayPage extends StatelessWidget {
  const _DayPage({
    super.key,
    required this.day,
    required this.savedTripId,
    required this.onRefresh,
    required this.onRetry,
  });

  final DateTime day;
  final String? savedTripId;
  final RefreshCallback onRefresh;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DayBloc>().state;
    return switch (state) {
      DayState(:final date) when date != day => const DaySkeleton(),
      DayState(:final report?) => DayReportView(
        report: report,
        refreshFailure: state.failure,
        slow: state.slow,
        savedTripId: savedTripId,
        onRefresh: onRefresh,
      ),
      DayState(status: DayStatus.failure, :final failure?) => DayFailureView(
        failure: failure,
        onRetry: onRetry,
      ),
      DayState(:final slow) => DaySkeleton(slow: slow),
    };
  }
}

class _AddTripBar extends StatelessWidget {
  const _AddTripBar({required this.contentBelow, required this.onPressed});

  final ValueListenable<bool> contentBelow;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    const label = Text(ShiftDiaryStrings.addTrip, textAlign: TextAlign.center);
    return ValueListenableBuilder(
      valueListenable: contentBelow,
      builder: (context, below, child) => DecoratedBox(
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor,
          border: Border(
            top: BorderSide(
              color: below
                  ? theme.colorScheme.outlineVariant
                  : Colors.transparent,
            ),
          ),
        ),
        child: child,
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: Spacing.md,
            vertical: Spacing.sm,
          ),
          child: TextScale.isLarge(context)
              ? FilledButton(onPressed: onPressed, child: label)
              : FilledButton.icon(
                  onPressed: onPressed,
                  icon: Icon(AppIcons.of(context).add),
                  label: label,
                ),
        ),
      ),
    );
  }
}
