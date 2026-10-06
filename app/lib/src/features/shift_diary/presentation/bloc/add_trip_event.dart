part of 'add_trip_bloc.dart';

sealed class AddTripEvent {
  const AddTripEvent();
}

sealed class TripEdited extends AddTripEvent {
  const TripEdited();
}

final class TripStartDayChanged extends TripEdited {
  TripStartDayChanged(this.day) : assert(_isCalendarDay(day), _calendarDayHint);

  final DateTime day;
}

final class TripStartTimeChanged extends TripEdited {
  const TripStartTimeChanged(this.time);

  final ClockTime time;
}

final class TripEndDayChanged extends TripEdited {
  TripEndDayChanged(this.day) : assert(_isCalendarDay(day), _calendarDayHint);

  final DateTime day;
}

final class TripEndTimeChanged extends TripEdited {
  const TripEndTimeChanged(this.time);

  final ClockTime time;
}

final class TripAmountChanged extends TripEdited {
  const TripAmountChanged(this.amount);

  final int? amount;
}

final class TripCommissionChanged extends TripEdited {
  const TripCommissionChanged(this.commission);

  final int? commission;
}

final class TripPaymentChanged extends TripEdited {
  const TripPaymentChanged(this.payment);

  final PaymentMethod? payment;
}

final class TripSubmitted extends AddTripEvent {
  const TripSubmitted();
}

bool _isCalendarDay(DateTime day) =>
    day == DateTime.utc(day.year, day.month, day.day);

const String _calendarDayHint =
    'A trip form day is a calendar day, DateTime.utc(y, m, d)';
