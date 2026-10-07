part of 'period_bloc.dart';

sealed class PeriodEvent {
  const PeriodEvent();
}

final class PeriodChanged extends PeriodEvent {
  const PeriodChanged(this.period);

  final Period period;
}

final class PeriodRefreshRequested extends PeriodEvent {
  const PeriodRefreshRequested();
}
