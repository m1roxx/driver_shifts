import 'package:bloc/bloc.dart';
import 'package:bloc_concurrency/bloc_concurrency.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/repositories/trips_repository.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'add_trip_bloc.freezed.dart';
part 'add_trip_event.dart';
part 'add_trip_state.dart';

const int _maxAmount = 2147483647;

class AddTripBloc extends Bloc<AddTripEvent, AddTripState> {
  AddTripBloc(
    this._repository,
    this._clock, {
    required DateTime day,
    String Function()? newTripId,
  }) : assert(_isCalendarDay(day), _calendarDayHint),
       super(
         AddTripState(
           tripId: newTripId?.call() ?? const Uuid().v7(),
           draft: TripDraft(startDay: day, endDay: day),
         ),
       ) {
    on<TripEdited>(_onEdited);
    on<TripSubmitted>(_onSubmitted, transformer: droppable());
  }

  final TripsRepository _repository;
  final DriverClock _clock;

  void _onEdited(TripEdited event, Emitter<AddTripState> emit) {
    if (!state.editable) return;
    final draft = state.draft;
    final (edited, field) = switch (event) {
      TripStartDayChanged(:final day) => (
        draft.copyWith(
          startDay: day,
          endDay: draft.endDay.add(day.difference(draft.startDay)),
        ),
        TripField.start,
      ),
      TripStartTimeChanged(:final time) => (
        draft.copyWith(startTime: time),
        TripField.start,
      ),
      TripEndDayChanged(:final day) => (
        draft.copyWith(endDay: day, endDayPicked: true),
        TripField.end,
      ),
      TripEndTimeChanged(:final time) => (
        draft.copyWith(endTime: time),
        TripField.end,
      ),
      TripAmountChanged(:final amount) => (
        draft.copyWith(amount: amount),
        TripField.amount,
      ),
      TripCommissionChanged(:final commission) => (
        draft.copyWith(commission: commission),
        TripField.commission,
      ),
      TripPaymentChanged(:final payment) => (
        draft.copyWith(payment: payment),
        TripField.payment,
      ),
    };
    emit(
      state.copyWith(
        draft: _withEndDay(edited),
        fieldErrors: _errorsAfterEditing(field),
      ),
    );
  }

  Map<TripField, TripFieldError> _errorsAfterEditing(TripField field) {
    final errors = Map.of(state.fieldErrors)..remove(field);
    final dependent = switch (field) {
      TripField.start => (TripField.end, TripFieldError.notAfterStart),
      TripField.amount => (TripField.commission, TripFieldError.aboveAmount),
      TripField.end || TripField.commission || TripField.payment => null,
    };
    if (dependent case (final field, final error) when errors[field] == error) {
      errors.remove(field);
    }
    return errors;
  }

  Future<void> _onSubmitted(
    TripSubmitted event,
    Emitter<AddTripState> emit,
  ) async {
    if (!state.editable) return;
    final problems = _problemsOf(state.draft);
    final trip = problems.isEmpty ? _tripOf(state.draft) : null;
    if (trip == null) {
      if (state.failure != null) {
        emit(state.copyWith(status: AddTripStatus.editing, failure: null));
      }
      emit(
        state.copyWith(
          status: AddTripStatus.failure,
          fieldErrors: {...state.fieldErrors, ...problems},
          failure: const Failure.validation(),
        ),
      );
      return;
    }
    emit(
      state.copyWith(
        status: AddTripStatus.submitting,
        failure: null,
        trip: trip,
      ),
    );
    final result = await _repository.addTrip(trip);
    if (isClosed || emit.isDone) return;
    emit(switch (result) {
      SuccessResult(value: final saved) => state.copyWith(
        status: AddTripStatus.success,
        trip: saved,
      ),
      ErrorResult(failure: final ValidationFailure failure) => state.copyWith(
        status: AddTripStatus.failure,
        fieldErrors: _fieldErrorsOf(failure),
        failure: failure,
      ),
      ErrorResult(:final failure) => state.copyWith(
        status: AddTripStatus.failure,
        failure: failure,
      ),
    });
  }

  DateTime? _momentOf(DateTime day, ClockTime? time) => switch (time) {
    (:final hour, :final minute) => _clock.momentAt(
      day,
      hour: hour,
      minute: minute,
    ),
    null => null,
  };

  Map<TripField, TripFieldError> _problemsOf(TripDraft draft) {
    final start = _momentOf(draft.startDay, draft.startTime);
    final end = _momentOf(draft.endDay, draft.endTime);
    final TripDraft(:amount, :commission, :payment) = draft;
    return {
      if (start == null) TripField.start: TripFieldError.missing,
      if (end == null)
        TripField.end: TripFieldError.missing
      else if (start != null && !end.isAfter(start))
        TripField.end: TripFieldError.notAfterStart,
      if (amount == null)
        TripField.amount: TripFieldError.missing
      else if (amount <= 0)
        TripField.amount: TripFieldError.notPositive
      else if (amount > _maxAmount)
        TripField.amount: TripFieldError.tooLarge,
      if (commission == null)
        TripField.commission: TripFieldError.missing
      else if (commission < 0)
        TripField.commission: TripFieldError.negative
      else if (amount != null && commission > amount)
        TripField.commission: TripFieldError.aboveAmount,
      if (payment == null) TripField.payment: TripFieldError.missing,
    };
  }

  Trip? _tripOf(TripDraft draft) => switch (draft) {
    TripDraft(
      :final startDay,
      :final endDay,
      startTime: final startTime?,
      endTime: final endTime?,
      amount: final amount?,
      commission: final commission?,
      payment: final payment?,
    ) =>
      Trip(
        id: state.tripId,
        start: _clock.momentAt(
          startDay,
          hour: startTime.hour,
          minute: startTime.minute,
        ),
        end: _clock.momentAt(
          endDay,
          hour: endTime.hour,
          minute: endTime.minute,
        ),
        amount: amount,
        payment: payment,
        commission: commission,
      ),
    _ => null,
  };
}

TripDraft _withEndDay(TripDraft draft) {
  if (draft.endDayPicked) return draft;
  final endsNextDay = switch ((draft.startTime, draft.endTime)) {
    (final start?, final end?) =>
      end.hour < start.hour ||
          (end.hour == start.hour && end.minute < start.minute),
    _ => false,
  };
  return draft.copyWith(
    endDay: endsNextDay
        ? draft.startDay.add(const Duration(days: 1))
        : draft.startDay,
  );
}

Map<TripField, TripFieldError> _fieldErrorsOf(ValidationFailure failure) {
  final fields = TripField.values.asNameMap();
  return {
    for (final MapEntry(key: name, value: type) in failure.fieldErrors.entries)
      ?fields[name]: _fieldErrorOf(type),
  };
}

TripFieldError _fieldErrorOf(String type) => switch (type) {
  'missing' => TripFieldError.missing,
  'end_not_after_start' => TripFieldError.notAfterStart,
  'greater_than' => TripFieldError.notPositive,
  'less_than_equal' => TripFieldError.tooLarge,
  'greater_than_equal' => TripFieldError.negative,
  'commission_above_amount' => TripFieldError.aboveAmount,
  _ => TripFieldError.invalid,
};
