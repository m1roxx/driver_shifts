part of 'day_bloc.dart';

enum DayStatus { loading, success, failure }

@freezed
abstract class DayState with _$DayState {
  const factory DayState({
    required DateTime date,
    @Default(DayStatus.loading) DayStatus status,
    DayReport? report,
    Failure? failure,
    @Default(false) bool slow,
  }) = _DayState;
}
