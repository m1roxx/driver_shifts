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
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_report_view.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_skeleton.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/widgets/day_switcher.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShiftDiaryScreen extends StatefulWidget {
  const ShiftDiaryScreen({super.key});

  @override
  State<ShiftDiaryScreen> createState() => _ShiftDiaryScreenState();
}

class _ShiftDiaryScreenState extends State<ShiftDiaryScreen> {
  late final DriverClock _clock = context.read<DriverClock>();
  late final AppLifecycleListener _lifecycle;
  final _contentBelow = ValueNotifier(false);
  late DateTime _today;
  Timer? _nextDay;
  var _forward = true;
  String? _savedTripId;

  @override
  void initState() {
    super.initState();
    _today = _clock.today();
    _lifecycle = AppLifecycleListener(onResume: _updateToday);
    _scheduleNextDay();
  }

  @override
  void dispose() {
    _nextDay?.cancel();
    _lifecycle.dispose();
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

  @override
  Widget build(BuildContext context) {
    final today = _today;
    final date = context.select((DayBloc bloc) => bloc.state.date);
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
                  visible: date != today,
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
            DaySwitcher(date: date, today: today, onChanged: _changeDay),
            Expanded(
              child: NotificationListener<ScrollMetricsNotification>(
                onNotification: (notification) => _watchContentBelow(
                  notification.depth,
                  notification.metrics,
                ),
                child: NotificationListener<ScrollNotification>(
                  onNotification: (notification) => _watchContentBelow(
                    notification.depth,
                    notification.metrics,
                  ),
                  child: _DaySwipeDetector(
                    onPrevious: () =>
                        _changeDay(date.subtract(const Duration(days: 1))),
                    onNext: () => _changeDay(date.add(const Duration(days: 1))),
                    child: BlocBuilder<DayBloc, DayState>(
                      builder: (context, state) => _DayTransition(
                        day: state.date,
                        forward: _forward,
                        child: switch (state) {
                          DayState(:final report?) => DayReportView(
                            report: report,
                            refreshFailure: state.failure,
                            savedTripId: _savedTripId,
                            onRefresh: _refresh,
                          ),
                          DayState(
                            status: DayStatus.failure,
                            :final failure?,
                          ) =>
                            DayFailureView(failure: failure, onRetry: _retry),
                          DayState() => const DaySkeleton(),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _watchContentBelow(int depth, ScrollMetrics metrics) {
    if (depth == 0 && metrics.axis == Axis.vertical) {
      _contentBelow.value = metrics.extentAfter > 0;
    }
    return false;
  }

  void _changeDay(DateTime date) {
    unawaited(HapticFeedback.selectionClick());
    final dayBloc = context.read<DayBloc>();
    setState(() {
      _forward = date.isAfter(dayBloc.state.date);
      _savedTripId = null;
    });
    dayBloc.add(DayChanged(date));
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
      enableDrag: false,
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
      setState(() => _forward = day.isAfter(dayBloc.state.date));
      dayBloc.add(DayChanged(day));
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

class _DayTransition extends StatelessWidget {
  const _DayTransition({
    required this.day,
    required this.forward,
    required this.child,
  });

  final DateTime day;
  final bool forward;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final reduced = MediaQuery.disableAnimationsOf(context);
    final shift = forward ? Motion.dayShift : -Motion.dayShift;
    return AnimatedSwitcher(
      duration: reduced ? Motion.reduced : Motion.daySwitch,
      switchInCurve: Motion.curve,
      switchOutCurve: Motion.curve,
      layoutBuilder: (current, previous) =>
          Stack(fit: StackFit.expand, children: [...previous, ?current]),
      transitionBuilder: (child, animation) {
        final faded = FadeTransition(opacity: animation, child: child);
        if (reduced) return faded;
        return AnimatedBuilder(
          animation: animation,
          builder: (context, child) {
            final leaving = animation.status == AnimationStatus.reverse;
            return Transform.translate(
              offset: Offset(
                (1 - animation.value) * (leaving ? -shift : shift),
                0,
              ),
              child: child,
            );
          },
          child: faded,
        );
      },
      child: KeyedSubtree(key: ValueKey(day), child: child),
    );
  }
}

class _DaySwipeDetector extends StatefulWidget {
  const _DaySwipeDetector({
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  State<_DaySwipeDetector> createState() => _DaySwipeDetectorState();
}

class _DaySwipeDetectorState extends State<_DaySwipeDetector>
    with SingleTickerProviderStateMixin {
  late final AnimationController _settle = AnimationController(
    vsync: this,
    duration: Motion.swipeBack,
  )..addListener(_followSettle);
  Animation<double>? _settling;
  double _offset = 0;

  @override
  void dispose() {
    _settle.dispose();
    super.dispose();
  }

  void _followSettle() {
    if (_settling case final settling?) {
      setState(() => _offset = settling.value);
    }
  }

  void _drag(DragUpdateDetails details) {
    _settle.stop();
    setState(() => _offset += details.primaryDelta ?? 0);
  }

  void _release(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final threshold = (context.size?.width ?? 0) * Motion.swipeCommitFraction;
    final fling = velocity.abs() > kMinFlingVelocity;
    if ((fling && velocity > 0) || (!fling && _offset > threshold)) {
      _jumpBack();
      widget.onPrevious();
    } else if ((fling && velocity < 0) || (!fling && _offset < -threshold)) {
      _jumpBack();
      widget.onNext();
    } else {
      _slideBack();
    }
  }

  void _jumpBack() {
    _settle.stop();
    setState(() => _offset = 0);
  }

  void _slideBack() {
    if (MediaQuery.disableAnimationsOf(context)) {
      _jumpBack();
      return;
    }
    _settling = Tween<double>(
      begin: _offset,
      end: 0,
    ).animate(CurvedAnimation(parent: _settle, curve: Motion.curve));
    unawaited(_settle.forward(from: 0));
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onHorizontalDragUpdate: _drag,
      onHorizontalDragEnd: _release,
      onHorizontalDragCancel: _slideBack,
      child: Transform.translate(
        offset: Offset(_offset, 0),
        child: widget.child,
      ),
    );
  }
}
