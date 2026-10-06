import 'dart:async';

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
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class ShiftDiaryScreen extends StatefulWidget {
  const ShiftDiaryScreen({super.key});

  @override
  State<ShiftDiaryScreen> createState() => _ShiftDiaryScreenState();
}

class _ShiftDiaryScreenState extends State<ShiftDiaryScreen> {
  final _refreshIndicatorKey = GlobalKey<RefreshIndicatorState>();
  late final DriverClock _clock = context.read<DriverClock>();
  late final AppLifecycleListener _lifecycle;
  late DateTime _today;
  Timer? _nextDay;

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
      appBar: AppBar(
        title: const Text(ShiftDiaryStrings.title),
        actions: [
          IconButton(
            tooltip: ShiftDiaryStrings.today,
            onPressed: date == today ? null : () => _changeDay(today),
            icon: const Icon(Icons.today),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        tooltip: ShiftDiaryStrings.addTrip,
        onPressed: _addTrip,
        child: const Icon(Icons.add),
      ),
      body: SafeArea(
        child: Column(
          children: [
            DaySwitcher(date: date, today: today, onChanged: _changeDay),
            Expanded(
              child: _DaySwipeDetector(
                onPrevious: () =>
                    _changeDay(date.subtract(const Duration(days: 1))),
                onNext: () => _changeDay(date.add(const Duration(days: 1))),
                child: BlocBuilder<DayBloc, DayState>(
                  builder: (context, state) => switch (state) {
                    DayState(:final report?) => DayReportView(
                      report: report,
                      refreshFailure: state.failure,
                      onRefresh: _refresh,
                      onRetry: _retry,
                      onAddTrip: _addTrip,
                      refreshIndicatorKey: _refreshIndicatorKey,
                    ),
                    DayState(status: DayStatus.failure, :final failure?) =>
                      DayFailureView(failure: failure, onRetry: _retry),
                    DayState() => const DaySkeleton(),
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _changeDay(DateTime date) {
    unawaited(HapticFeedback.selectionClick());
    context.read<DayBloc>().add(DayChanged(date));
  }

  Future<void> _addTrip() {
    final dayBloc = context.read<DayBloc>();
    final repository = context.read<TripsRepository>();
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      enableDrag: false,
      builder: (context) => BlocProvider(
        create: (_) => AddTripBloc(repository, _clock, day: dayBloc.state.date),
        child: BlocListener<AddTripBloc, AddTripState>(
          listenWhen: (previous, current) =>
              previous.status != current.status &&
              current.status == AddTripStatus.success,
          listener: (context, state) {
            if (state.trip case final trip?) {
              _onTripSaved(context, trip, dayBloc);
            }
          },
          child: const AddTripSheet(),
        ),
      ),
    );
  }

  void _onTripSaved(BuildContext sheetContext, Trip trip, DayBloc dayBloc) {
    Navigator.pop(sheetContext);
    unawaited(HapticFeedback.lightImpact());
    final day = _clock.dayOf(trip.start);
    dayBloc.add(
      day == dayBloc.state.date ? const DayRefreshRequested() : DayChanged(day),
    );
  }

  Future<void> _refresh() async {
    final bloc = context.read<DayBloc>()..add(const DayRefreshRequested());
    await bloc.stream.firstWhere(
      (state) => state.status != DayStatus.loading,
      orElse: () => bloc.state,
    );
  }

  void _retry() {
    final refreshIndicator = _refreshIndicatorKey.currentState;
    if (refreshIndicator != null) {
      unawaited(refreshIndicator.show());
    } else {
      context.read<DayBloc>().add(const DayRefreshRequested());
    }
  }
}

class _DaySwipeDetector extends StatelessWidget {
  const _DaySwipeDetector({
    required this.onPrevious,
    required this.onNext,
    required this.child,
  });

  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      excludeFromSemantics: true,
      onHorizontalDragEnd: (details) {
        final velocity = details.primaryVelocity ?? 0;
        if (velocity > kMinFlingVelocity) {
          onPrevious();
        } else if (velocity < -kMinFlingVelocity) {
          onNext();
        }
      },
      child: child,
    );
  }
}
