part of 'period_bloc.dart';

enum PeriodStatus { loading, success, failure }

@freezed
abstract class PeriodState with _$PeriodState {
  const factory PeriodState({
    required Period period,
    @Default(PeriodStatus.loading) PeriodStatus status,
    PeriodReport? report,
    Failure? failure,
    @Default(false) bool slow,
  }) = _PeriodState;
}
