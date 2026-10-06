part of 'day_bloc.dart';

sealed class DayEvent {
  const DayEvent();
}

final class DayStarted extends DayEvent {
  const DayStarted();
}

final class DayChanged extends DayEvent {
  DayChanged(this.date)
    : assert(
        date == DateTime.utc(date.year, date.month, date.day),
        'DayChanged takes a calendar day, DateTime.utc(y, m, d): '
        'use DriverClock.dayOf for a moment such as trip.start',
      );

  final DateTime date;
}

final class DayRefreshRequested extends DayEvent {
  const DayRefreshRequested();
}
