part of 'add_trip_bloc.dart';

typedef ClockTime = ({int hour, int minute});

enum AddTripStatus { editing, submitting, success, failure }

enum TripField { start, end, amount, commission, payment }

enum TripFieldError {
  missing,
  notAfterStart,
  notPositive,
  tooLarge,
  negative,
  aboveAmount,
  invalid,
}

@freezed
abstract class TripDraft with _$TripDraft {
  const factory TripDraft({
    required DateTime startDay,
    required DateTime endDay,
    ClockTime? startTime,
    ClockTime? endTime,
    int? amount,
    int? commission,
    PaymentMethod? payment,
  }) = _TripDraft;
}

@freezed
abstract class AddTripState with _$AddTripState {
  const factory AddTripState({
    required String tripId,
    required TripDraft draft,
    @Default(AddTripStatus.editing) AddTripStatus status,
    @Default(<TripField, TripFieldError>{})
    Map<TripField, TripFieldError> fieldErrors,
    Failure? failure,
    Trip? trip,
  }) = _AddTripState;

  const AddTripState._();

  bool get canRetry =>
      status == AddTripStatus.failure && (failure?.isTransient ?? false);
}
