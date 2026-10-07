import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/waking_server_loader.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'day_bloc.freezed.dart';
part 'day_event.dart';
part 'day_state.dart';

@injectable
class DayBloc extends Bloc<DayEvent, DayState> {
  DayBloc(
    this._repository,
    DriverClock clock, {
    @ignoreParam WakingServerTimings timings = const WakingServerTimings(),
  }) : _loader = WakingServerLoader(timings),
       super(DayState(date: clock.today())) {
    on<DayEvent>(_onEvent, transformer: restartable());
  }

  final TripsRepository _repository;
  final WakingServerLoader _loader;

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

    final result = await _loader.load(
      () => _repository.getDay(date),
      cancelled: () => isClosed || emit.isDone,
      onSlow: () => emit(state.copyWith(slow: true)),
    );
    if (result == null || isClosed || emit.isDone) return;
    emit(switch (result) {
      SuccessResult(value: final report) => state.copyWith(
        status: DayStatus.success,
        report: report,
        slow: false,
      ),
      ErrorResult(:final failure) => state.copyWith(
        status: DayStatus.failure,
        failure: failure,
        slow: false,
      ),
    });
  }

  @override
  Future<void> close() {
    _loader.dispose();
    return super.close();
  }
}
