part of 'day_bloc.dart';

sealed class DayEvent {
  const DayEvent();
}

final class DayStarted extends DayEvent {
  const DayStarted();
}

final class DayChanged extends DayEvent {
  const DayChanged(this.date);

  final DateTime date;
}

final class DayRefreshRequested extends DayEvent {
  const DayRefreshRequested();
}
