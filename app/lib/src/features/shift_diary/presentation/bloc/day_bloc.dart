import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'day_bloc.freezed.dart';
part 'day_event.dart';
part 'day_state.dart';

class DayLoadTimings {
  const DayLoadTimings({
    this.slowAfter = const Duration(seconds: 3),
    this.retryEvery = const Duration(seconds: 5),
    this.retryFor = const Duration(seconds: 90),
  });

  final Duration slowAfter;
  final Duration retryEvery;
  final Duration retryFor;
}

@injectable
class DayBloc extends Bloc<DayEvent, DayState> {
  DayBloc(
    this._repository,
    DriverClock clock, {
    @ignoreParam this._timings = const DayLoadTimings(),
  }) : super(DayState(date: clock.today())) {
    on<DayEvent>(_onEvent, transformer: restartable());
  }

  final TripsRepository _repository;
  final DayLoadTimings _timings;
  final Set<Timer> _timers = {};

  Future<void> _onEvent(DayEvent event, Emitter<DayState> emit) async {
    final date = switch (event) {
      DayChanged(:final date) => date,
      DayStarted() || DayRefreshRequested() => state.date,
    };
    emit(
      date == state.date
          ? state.copyWith(
              status: DayStatus.loading,
              failure: null,
              slow: false,
            )
          : DayState(date: date),
    );

    final slow = _after(_timings.slowAfter, () {
      if (!emit.isDone) emit(state.copyWith(slow: true));
    });
    var retrying = true;
    final deadline = _after(_timings.retryFor, () => retrying = false);
    try {
      while (true) {
        final result = await _repository.getDay(date);
        if (isClosed || emit.isDone) return;

        switch (result) {
          case SuccessResult(value: final report):
            emit(
              state.copyWith(
                status: DayStatus.success,
                report: report,
                slow: false,
              ),
            );
            return;
          case ErrorResult(:final failure)
              when !failure.isTransient || !retrying:
            emit(
              state.copyWith(
                status: DayStatus.failure,
                failure: failure,
                slow: false,
              ),
            );
            return;
          case ErrorResult():
            await _pause(_timings.retryEvery);
            if (isClosed || emit.isDone) return;
        }
      }
    } finally {
      _cancel(slow);
      _cancel(deadline);
    }
  }

  Timer _after(Duration delay, void Function() callback) {
    late final Timer timer;
    timer = Timer(delay, () {
      _timers.remove(timer);
      callback();
    });
    _timers.add(timer);
    return timer;
  }

  void _cancel(Timer timer) {
    timer.cancel();
    _timers.remove(timer);
  }

  Future<void> _pause(Duration delay) {
    final done = Completer<void>();
    _after(delay, done.complete);
    return done.future;
  }

  @override
  Future<void> close() {
    for (final timer in _timers) {
      timer.cancel();
    }
    _timers.clear();
    return super.close();
  }
}
