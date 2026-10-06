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

@injectable
class DayBloc extends Bloc<DayEvent, DayState> {
  DayBloc(this._repository, DriverClock clock)
    : super(DayState(date: clock.today())) {
    on<DayEvent>(_onEvent, transformer: restartable());
  }

  final TripsRepository _repository;

  Future<void> _onEvent(DayEvent event, Emitter<DayState> emit) async {
    final date = switch (event) {
      DayChanged(:final date) => date,
      DayStarted() || DayRefreshRequested() => state.date,
    };
    emit(
      date == state.date
          ? state.copyWith(status: DayStatus.loading, failure: null)
          : DayState(date: date),
    );

    final result = await _repository.getDay(date);
    if (isClosed || emit.isDone) return;

    emit(switch (result) {
      SuccessResult(value: final report) => state.copyWith(
        status: DayStatus.success,
        report: report,
      ),
      ErrorResult(:final failure) => state.copyWith(
        status: DayStatus.failure,
        failure: failure,
      ),
    });
  }
}
