import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/waking_server_loader.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:injectable/injectable.dart';

part 'period_bloc.freezed.dart';
part 'period_event.dart';
part 'period_state.dart';

@injectable
class PeriodBloc extends Bloc<PeriodEvent, PeriodState> {
  PeriodBloc(
    this._repository,
    DriverClock clock, {
    @ignoreParam WakingServerTimings timings = const WakingServerTimings(),
  }) : _loader = WakingServerLoader(timings),
       super(
         PeriodState(period: Period.containing(PeriodKind.week, clock.today())),
       ) {
    on<PeriodEvent>(_onEvent, transformer: restartable());
  }

  final TripsRepository _repository;
  final WakingServerLoader _loader;

  Future<void> _onEvent(PeriodEvent event, Emitter<PeriodState> emit) async {
    final period = switch (event) {
      PeriodChanged(:final period) => period,
      PeriodRefreshRequested() => state.period,
    };
    emit(
      period == state.period
          ? state.copyWith(
              status: PeriodStatus.loading,
              failure: null,
              slow: false,
            )
          : PeriodState(period: period),
    );

    final result = await _loader.load(
      () => _repository.getPeriod(period.start, period.end),
      cancelled: () => isClosed || emit.isDone,
      onSlow: () => emit(state.copyWith(slow: true)),
    );
    if (result == null || isClosed || emit.isDone) return;
    emit(switch (result) {
      SuccessResult(value: final report) => state.copyWith(
        status: PeriodStatus.success,
        report: report,
        slow: false,
      ),
      ErrorResult(:final failure) => state.copyWith(
        status: PeriodStatus.failure,
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
