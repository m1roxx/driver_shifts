import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/payment_method.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/trip.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/add_trip_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';

final DateTime _oct3 = DateTime.utc(2026, 10, 3);

final DriverClock _clock = DriverClock(now: () => DateTime.utc(2026, 10, 7, 6));

DriverClock _clockAt(DateTime instant) => DriverClock(now: () => instant);

final TripDraft _eveningDraft = TripDraft(
  startDay: oct1,
  endDay: oct1,
  startTime: (hour: 18, minute: 40),
  endTime: (hour: 19, minute: 5),
  amount: 1000,
  commission: 150,
  payment: PaymentMethod.cash,
);

final Trip _eveningTrip = eveningTrip.copyWith(id: 'trip-1');

const List<TripEdited> _eveningEdits = [
  TripStartTimeChanged((hour: 18, minute: 40)),
  TripEndTimeChanged((hour: 19, minute: 5)),
  TripAmountChanged(1000),
  TripCommissionChanged(150),
  TripPaymentChanged(PaymentMethod.cash),
];

AddTripBloc _bloc(
  FakeTripsRepository repository, {
  DateTime? day,
  DriverClock? clock,
}) {
  var opened = 0;
  return AddTripBloc(
    repository,
    clock ?? _clock,
    day: day ?? oct1,
    newTripId: () => 'trip-${++opened}',
  );
}

FakeTripsRepository _answering(List<Result<Trip>> responses) =>
    FakeTripsRepository.withReports(
      {},
      onAddTrip: (_) async {
        return responses.removeAt(0);
      },
    );

AddTripState _filled({
  TripDraft? draft,
  AddTripStatus status = AddTripStatus.editing,
  Map<TripField, TripFieldError> fieldErrors = const {},
  Failure? failure,
  Trip? trip,
}) => AddTripState(
  tripId: 'trip-1',
  draft: draft ?? _eveningDraft,
  status: status,
  fieldErrors: fieldErrors,
  failure: failure,
  trip: trip,
);

void main() {
  late FakeTripsRepository repository;

  setUp(() {
    repository = FakeTripsRepository.withReports({});
  });

  group('opening the form', () {
    test('creates the trip id once and starts both times on the shown '
        'day', () {
      final bloc = _bloc(repository, day: oct2);
      addTearDown(bloc.close);

      expect(
        bloc.state,
        AddTripState(
          tripId: 'trip-1',
          draft: TripDraft(startDay: oct2, endDay: oct2),
        ),
      );
    });

    test('the trip id is a UUIDv7 by default (D7)', () {
      final bloc = AddTripBloc(repository, _clock, day: oct1);
      addTearDown(bloc.close);

      expect(
        bloc.state.tripId,
        matches(
          RegExp(
            '^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
    });

    final todayOpenings = <String, (DateTime, ClockTime?, ClockTime?)>{
      'today ends the trip at the current minute and starts it 20 minutes '
          'earlier': (
        DateTime.utc(2026, 10, 1, 13, 7, 42),
        (hour: 17, minute: 47),
        (hour: 18, minute: 7),
      ),
      'today at 00:20 starts the trip at midnight': (
        DateTime.utc(2026, 9, 30, 19, 20),
        (hour: 0, minute: 0),
        (hour: 0, minute: 20),
      ),
      'today before 00:20 leaves both times empty instead of starting the '
          'trip on the day before': (
        DateTime.utc(2026, 9, 30, 19, 19, 59),
        null,
        null,
      ),
    };
    for (final MapEntry(key: name, value: (now, startTime, endTime))
        in todayOpenings.entries) {
      test(name, () {
        final bloc = _bloc(repository, clock: _clockAt(now));
        addTearDown(bloc.close);

        expect(
          bloc.state.draft,
          TripDraft(
            startDay: oct1,
            endDay: oct1,
            startTime: startTime,
            endTime: endTime,
          ),
        );
      });
    }

    test('another day leaves both times empty, and the end picker opens 15 '
        'minutes after the start once it is set', () async {
      final bloc = _bloc(
        repository,
        clock: _clockAt(DateTime.utc(2026, 10, 2, 13)),
      );
      addTearDown(bloc.close);
      expect(bloc.state.draft, TripDraft(startDay: oct1, endDay: oct1));
      expect(bloc.state.endPickerTime, isNull);

      bloc.add(const TripStartTimeChanged((hour: 23, minute: 50)));
      await pumpEventQueue();

      expect(bloc.state.draft.endTime, isNull);
      expect(bloc.state.endPickerTime, (hour: 0, minute: 5));
    });

    test('the end picker opens at the end once the end is set', () {
      expect(_filled().endPickerTime, (hour: 19, minute: 5));
    });

    test('takes only a calendar day', () {
      expect(
        () => AddTripBloc(repository, _clock, day: DateTime(2026, 10)),
        throwsA(isA<AssertionError>()),
      );
      expect(
        () => TripStartDayChanged(DateTime.utc(2026, 10, 1, 19)),
        throwsA(isA<AssertionError>()),
      );
    });
  });

  group('checks the form before sending', () {
    blocTest<AddTripBloc, AddTripState>(
      'shows every empty field and sends nothing',
      build: () => _bloc(repository),
      act: (bloc) => bloc.add(const TripSubmitted()),
      expect: () => [
        AddTripState(
          tripId: 'trip-1',
          draft: TripDraft(startDay: oct1, endDay: oct1),
          status: AddTripStatus.invalid,
          fieldErrors: const {
            TripField.start: TripFieldError.missing,
            TripField.end: TripFieldError.missing,
            TripField.amount: TripFieldError.missing,
            TripField.commission: TripFieldError.missing,
            TripField.payment: TripFieldError.missing,
          },
        ),
      ],
      verify: (_) => expect(repository.addedTrips, isEmpty),
    );

    final invalidDrafts = <String, (TripDraft, Map<TripField, TripFieldError>)>{
      'an end at the start': (
        _eveningDraft.copyWith(endTime: (hour: 18, minute: 40)),
        {TripField.end: TripFieldError.notAfterStart},
      ),
      'an end on the day before': (
        _eveningDraft.copyWith(endDay: sep30),
        {TripField.end: TripFieldError.notAfterStart},
      ),
      'a zero amount below the commission': (
        _eveningDraft.copyWith(amount: 0),
        {
          TripField.amount: TripFieldError.notPositive,
          TripField.commission: TripFieldError.aboveAmount,
        },
      ),
      'an amount over the Postgres integer': (
        _eveningDraft.copyWith(amount: 2147483648),
        {TripField.amount: TripFieldError.tooLarge},
      ),
      'a commission above the amount': (
        _eveningDraft.copyWith(commission: 1001),
        {TripField.commission: TripFieldError.aboveAmount},
      ),
    };
    for (final MapEntry(key: name, value: (draft, errors))
        in invalidDrafts.entries) {
      blocTest<AddTripBloc, AddTripState>(
        name,
        build: () => _bloc(repository),
        seed: () => _filled(draft: draft),
        act: (bloc) => bloc.add(const TripSubmitted()),
        expect: () => [
          _filled(
            draft: draft,
            status: AddTripStatus.invalid,
            fieldErrors: errors,
          ),
        ],
        verify: (_) => expect(repository.addedTrips, isEmpty),
      );
    }

    blocTest<AddTripBloc, AddTripState>(
      'accepts a commission equal to the amount and a trip over midnight '
      'that ends on the next day (D2)',
      build: () => _bloc(repository),
      seed: () => _filled(
        draft: TripDraft(
          startDay: oct2,
          endDay: _oct3,
          startTime: (hour: 23, minute: 50),
          endTime: (hour: 0, minute: 20),
          amount: 4600,
          commission: 4600,
          payment: PaymentMethod.card,
        ),
      ),
      act: (bloc) => bloc.add(const TripSubmitted()),
      skip: 2,
      verify: (_) => expect(repository.addedTrips, [
        Trip(
          id: 'trip-1',
          start: DateTime.utc(2026, 10, 2, 18, 50),
          end: DateTime.utc(2026, 10, 2, 19, 20),
          amount: 4600,
          payment: PaymentMethod.card,
          commission: 4600,
        ),
      ]),
    );
  });

  group('sending', () {
    blocTest<AddTripBloc, AddTripState>(
      'sends the trip with its times on the Almaty clock and keeps the '
      'stored trip',
      build: () => _bloc(repository),
      act: (bloc) {
        _eveningEdits.forEach(bloc.add);
        bloc.add(const TripSubmitted());
      },
      skip: _eveningEdits.length,
      expect: () => [
        _filled(status: AddTripStatus.submitting, trip: _eveningTrip),
        _filled(status: AddTripStatus.success, trip: _eveningTrip),
      ],
      verify: (_) => expect(repository.addedTrips, [_eveningTrip]),
    );

    blocTest<AddTripBloc, AddTripState>(
      'a retry after a timeout sends the same trip id (D7)',
      build: () {
        repository = _answering([
          const Result.error(Failure.timeout()),
          Result.success(_eveningTrip),
        ]);
        return _bloc(repository);
      },
      act: (bloc) async {
        _eveningEdits.forEach(bloc.add);
        bloc.add(const TripSubmitted());
        await pumpEventQueue();
        expect(bloc.state.canRetry, isTrue);
        bloc.add(const TripSubmitted());
      },
      skip: _eveningEdits.length,
      expect: () => [
        _filled(status: AddTripStatus.submitting, trip: _eveningTrip),
        _filled(
          status: AddTripStatus.failure,
          failure: const Failure.timeout(),
          trip: _eveningTrip,
        ),
        _filled(status: AddTripStatus.submitting, trip: _eveningTrip),
        _filled(status: AddTripStatus.success, trip: _eveningTrip),
      ],
      verify: (_) => expect(repository.addedTrips.map((trip) => trip.id), [
        'trip-1',
        'trip-1',
      ]),
    );

    blocTest<AddTripBloc, AddTripState>(
      'keeps the trip id when the driver edits the form after a lost '
      'connection, so a trip saved before gets 409, not a twin (D4, D7)',
      build: () {
        repository = _answering([
          const Result.error(Failure.connection()),
          const Result.error(Failure.conflict()),
        ]);
        return _bloc(repository);
      },
      seed: _filled,
      act: (bloc) async {
        bloc.add(const TripSubmitted());
        await pumpEventQueue();
        bloc
          ..add(const TripAmountChanged(1200))
          ..add(const TripSubmitted());
      },
      skip: 3,
      expect: () => [
        _filled(
          draft: _eveningDraft.copyWith(amount: 1200),
          status: AddTripStatus.submitting,
          trip: _eveningTrip.copyWith(amount: 1200),
        ),
        _filled(
          draft: _eveningDraft.copyWith(amount: 1200),
          status: AddTripStatus.failure,
          failure: const Failure.conflict(),
          trip: _eveningTrip.copyWith(amount: 1200),
        ),
      ],
      verify: (bloc) {
        expect(repository.addedTrips.map((trip) => (trip.id, trip.amount)), [
          ('trip-1', 1000),
          ('trip-1', 1200),
        ]);
        expect(bloc.state.canRetry, isFalse);
        expect(bloc.state.conflicted, isTrue);
      },
    );

    blocTest<AddTripBloc, AddTripState>(
      'after 409 the form takes no more edits or submissions: the trip is '
      'already stored, and resending the id would only get 409 again',
      build: () => _bloc(repository),
      seed: () => _filled(
        status: AddTripStatus.failure,
        failure: const Failure.conflict(),
        trip: _eveningTrip,
      ),
      act: (bloc) => bloc
        ..add(const TripAmountChanged(1200))
        ..add(const TripSubmitted()),
      expect: () => <AddTripState>[],
      verify: (bloc) {
        expect(repository.addedTrips, isEmpty);
        expect(bloc.state.editable, isFalse);
      },
    );

    test('leaves the sent trip for the screen to check until it is '
        'confirmed stored, whatever came after the send', () {
      AddTripState failedWith(Failure failure) => _filled(
        status: AddTripStatus.failure,
        failure: failure,
        trip: _eveningTrip,
      );

      for (final failure in const [
        Failure.timeout(),
        Failure.connection(),
        Failure.conflict(),
        Failure.validation(),
        Failure.unexpected(),
      ]) {
        expect(
          failedWith(failure).unconfirmedTrip,
          _eveningTrip,
          reason: '$failure',
        );
      }
      expect(
        _filled(
          status: AddTripStatus.invalid,
          fieldErrors: const {TripField.amount: TripFieldError.missing},
          trip: _eveningTrip,
        ).unconfirmedTrip,
        _eveningTrip,
      );
      expect(
        _filled(
          status: AddTripStatus.success,
          trip: _eveningTrip,
        ).unconfirmedTrip,
        isNull,
      );
      expect(
        _filled(
          status: AddTripStatus.invalid,
          fieldErrors: const {TripField.amount: TripFieldError.missing},
        ).unconfirmedTrip,
        isNull,
        reason: 'nothing was sent',
      );
    });

    blocTest<AddTripBloc, AddTripState>(
      'a timeout, then an edit that fails the local check, keeps the sent '
      'trip for the screen to check and the same id for the next send '
      '(D7)',
      build: () {
        repository = _answering([
          const Result.error(Failure.timeout()),
          const Result.error(Failure.conflict()),
        ]);
        return _bloc(repository);
      },
      seed: _filled,
      act: (bloc) async {
        bloc.add(const TripSubmitted());
        await pumpEventQueue();
        bloc
          ..add(const TripAmountChanged(null))
          ..add(const TripSubmitted());
        await pumpEventQueue();
        expect(bloc.state.status, AddTripStatus.invalid);
        expect(bloc.state.canRetry, isFalse);
        expect(bloc.state.unconfirmedTrip, _eveningTrip);
        bloc
          ..add(const TripAmountChanged(1000))
          ..add(const TripSubmitted());
      },
      verify: (bloc) {
        expect(repository.addedTrips.map((trip) => trip.id), [
          'trip-1',
          'trip-1',
        ]);
        expect(bloc.state.conflicted, isTrue);
        expect(bloc.state.unconfirmedTrip, _eveningTrip);
      },
    );

    blocTest<AddTripBloc, AddTripState>(
      'puts 422 errors under their fields by type and keeps the rest for '
      'the form',
      build: () {
        repository = _answering([
          const Result.error(
            Failure.validation(
              fieldErrors: {
                'end': 'end_not_after_start',
                'commission': 'commission_above_amount',
                'amount': 'a_type_added_later',
                'id': 'string_pattern_mismatch',
              },
              formErrors: ['json_invalid'],
            ),
          ),
        ]);
        return _bloc(repository);
      },
      seed: _filled,
      act: (bloc) => bloc.add(const TripSubmitted()),
      skip: 1,
      expect: () => [
        _filled(
          status: AddTripStatus.failure,
          fieldErrors: const {
            TripField.end: TripFieldError.notAfterStart,
            TripField.commission: TripFieldError.aboveAmount,
            TripField.amount: TripFieldError.invalid,
          },
          failure: const Failure.validation(
            fieldErrors: {
              'end': 'end_not_after_start',
              'commission': 'commission_above_amount',
              'amount': 'a_type_added_later',
              'id': 'string_pattern_mismatch',
            },
            formErrors: ['json_invalid'],
          ),
          trip: _eveningTrip,
        ),
      ],
      verify: (bloc) => expect(bloc.state.canRetry, isFalse),
    );

    test('offers a retry only for failures that may pass next time (D7)', () {
      const transient = [
        Failure.connection(),
        Failure.timeout(),
        Failure.badResponse(statusCode: 503),
      ];
      const permanent = [
        Failure.conflict(),
        Failure.validation(),
        Failure.badResponse(statusCode: 400),
        Failure.unexpected(),
      ];

      for (final failure in transient) {
        expect(
          _filled(status: AddTripStatus.failure, failure: failure).canRetry,
          isTrue,
          reason: '$failure',
        );
      }
      for (final failure in permanent) {
        expect(
          _filled(status: AddTripStatus.failure, failure: failure).canRetry,
          isFalse,
          reason: '$failure',
        );
      }
    });

    group('while the trip is being sent', () {
      late Completer<Result<Trip>> response;

      setUp(() {
        response = Completer();
        repository = FakeTripsRepository.withReports(
          {},
          onAddTrip: (_) => response.future,
        );
      });

      blocTest<AddTripBloc, AddTripState>(
        'drops more taps on «Сохранить» (droppable)',
        build: () => _bloc(repository),
        seed: _filled,
        act: (bloc) async {
          bloc
            ..add(const TripSubmitted())
            ..add(const TripSubmitted())
            ..add(const TripSubmitted());
          await pumpEventQueue();
          response.complete(Result.success(_eveningTrip));
        },
        expect: () => [
          _filled(status: AddTripStatus.submitting, trip: _eveningTrip),
          _filled(status: AddTripStatus.success, trip: _eveningTrip),
        ],
        verify: (_) => expect(repository.addedTrips, [_eveningTrip]),
      );

      blocTest<AddTripBloc, AddTripState>(
        'ignores edits, so the form shows what was sent',
        build: () => _bloc(repository),
        seed: _filled,
        act: (bloc) async {
          bloc
            ..add(const TripSubmitted())
            ..add(const TripAmountChanged(5000))
            ..add(const TripPaymentChanged(PaymentMethod.card));
          await pumpEventQueue();
          response.complete(const Result.error(Failure.timeout()));
        },
        expect: () => [
          _filled(status: AddTripStatus.submitting, trip: _eveningTrip),
          _filled(
            status: AddTripStatus.failure,
            failure: const Failure.timeout(),
            trip: _eveningTrip,
          ),
        ],
      );

      test('a closed bloc emits nothing when the reply comes later (bloc '
          'itself drops emits after close)', () async {
        final bloc = _bloc(repository);
        final states = <AddTripState>[];
        final subscription = bloc.stream.listen(states.add);
        addTearDown(subscription.cancel);
        _eveningEdits.forEach(bloc.add);
        bloc.add(const TripSubmitted());
        await pumpEventQueue();
        expect(repository.addedTrips, [_eveningTrip]);

        await bloc.close();
        response.complete(Result.success(_eveningTrip));
        await pumpEventQueue();

        expect(
          states.last,
          _filled(status: AddTripStatus.submitting, trip: _eveningTrip),
        );
      });
    });

    blocTest<AddTripBloc, AddTripState>(
      'sends nothing more once the trip is saved',
      build: () => _bloc(repository),
      seed: () => _filled(status: AddTripStatus.success, trip: _eveningTrip),
      act: (bloc) => bloc
        ..add(const TripSubmitted())
        ..add(const TripAmountChanged(5000)),
      expect: () => <AddTripState>[],
      verify: (_) => expect(repository.addedTrips, isEmpty),
    );
  });

  group('editing', () {
    blocTest<AddTripBloc, AddTripState>(
      'moving the start day moves the end day with it, so a trip over '
      'midnight keeps ending on the next day',
      build: () => _bloc(repository),
      act: (bloc) => bloc
        ..add(TripEndDayChanged(oct2))
        ..add(TripStartDayChanged(oct2)),
      expect: () => [
        AddTripState(
          tripId: 'trip-1',
          draft: TripDraft(startDay: oct1, endDay: oct2, endDayPicked: true),
        ),
        AddTripState(
          tripId: 'trip-1',
          draft: TripDraft(startDay: oct2, endDay: _oct3, endDayPicked: true),
        ),
      ],
    );

    blocTest<AddTripBloc, AddTripState>(
      'an end time before the start time ends on the next day, until the '
      'driver picks the end day (D2)',
      build: () => _bloc(repository),
      act: (bloc) => bloc
        ..add(const TripStartTimeChanged((hour: 23, minute: 50)))
        ..add(const TripEndTimeChanged((hour: 0, minute: 20)))
        ..add(TripStartDayChanged(oct2))
        ..add(const TripEndTimeChanged((hour: 23, minute: 55)))
        ..add(const TripEndTimeChanged((hour: 23, minute: 50)))
        ..add(TripEndDayChanged(oct2))
        ..add(const TripEndTimeChanged((hour: 0, minute: 20))),
      expect: () => [
        for (final endDay in [oct1, oct2, _oct3, oct2, oct2, oct2, oct2])
          isA<AddTripState>().having(
            (state) => state.draft.endDay,
            'end day',
            endDay,
          ),
      ],
    );

    TripDraft timed(
      ClockTime startTime,
      ClockTime endTime, {
      DateTime? endDay,
      bool endDayPicked = false,
    }) => _eveningDraft.copyWith(
      startTime: startTime,
      endTime: endTime,
      endDay: endDay ?? oct1,
      endDayPicked: endDayPicked,
    );

    final startMoves = <String, (TripDraft, TripEdited, (DateTime, ClockTime))>{
      'a later start moves the end by as much, like iOS Calendar': (
        timed((hour: 18, minute: 5), (hour: 18, minute: 25)),
        const TripStartTimeChanged((hour: 18, minute: 8)),
        (oct1, (hour: 18, minute: 28)),
      ),
      'an earlier start moves the end back by as much': (
        timed((hour: 18, minute: 5), (hour: 18, minute: 25)),
        const TripStartTimeChanged((hour: 17, minute: 0)),
        (oct1, (hour: 17, minute: 20)),
      ),
      'a start moved late in the evening carries the end over '
          'midnight': (
        timed((hour: 23, minute: 0), (hour: 23, minute: 30)),
        const TripStartTimeChanged((hour: 23, minute: 45)),
        (oct2, (hour: 0, minute: 15)),
      ),
      'a start moved back before midnight brings the end back to its '
          'day': (
        timed((hour: 23, minute: 50), (hour: 0, minute: 20), endDay: oct2),
        const TripStartTimeChanged((hour: 22, minute: 0)),
        (oct1, (hour: 22, minute: 30)),
      ),
      'a new start day takes the end with it': (
        timed((hour: 23, minute: 50), (hour: 0, minute: 20), endDay: oct2),
        TripStartDayChanged(oct2),
        (_oct3, (hour: 0, minute: 20)),
      ),
      'an end day picked by the driver moves with the start too': (
        timed(
          (hour: 10, minute: 0),
          (hour: 9, minute: 0),
          endDay: _oct3,
          endDayPicked: true,
        ),
        const TripStartTimeChanged((hour: 11, minute: 0)),
        (_oct3, (hour: 10, minute: 0)),
      ),
    };
    for (final MapEntry(key: name, value: (draft, edit, (endDay, endTime)))
        in startMoves.entries) {
      blocTest<AddTripBloc, AddTripState>(
        '$name: the trip keeps its duration',
        build: () => _bloc(repository),
        seed: () => _filled(draft: draft),
        act: (bloc) => bloc.add(edit),
        expect: () => [
          isA<AddTripState>()
              .having((state) => state.draft.endDay, 'end day', endDay)
              .having((state) => state.draft.endTime, 'end time', endTime)
              .having(
                (state) => state.draft.endDayPicked,
                'end day picked',
                draft.endDayPicked,
              ),
        ],
      );
    }

    blocTest<AddTripBloc, AddTripState>(
      'a start moved from the same time as the end leaves the end where it '
      'is and fails the check, never a 23 h 57 min trip (D2)',
      build: () => _bloc(repository),
      seed: () =>
          _filled(draft: timed((hour: 18, minute: 5), (hour: 18, minute: 5))),
      act: (bloc) => bloc
        ..add(const TripStartTimeChanged((hour: 18, minute: 8)))
        ..add(const TripSubmitted()),
      skip: 1,
      expect: () => [
        _filled(
          draft: timed((hour: 18, minute: 8), (hour: 18, minute: 5)),
          status: AddTripStatus.invalid,
          fieldErrors: const {TripField.end: TripFieldError.notAfterStart},
        ),
      ],
      verify: (_) => expect(repository.addedTrips, isEmpty),
    );

    blocTest<AddTripBloc, AddTripState>(
      'a start set after an end that came first leaves the end on its day: '
      'only an end time the driver sets goes to the next day',
      build: () => _bloc(repository),
      act: (bloc) => bloc
        ..add(const TripEndTimeChanged((hour: 19, minute: 5)))
        ..add(const TripStartTimeChanged((hour: 20, minute: 0))),
      skip: 1,
      expect: () => [
        AddTripState(
          tripId: 'trip-1',
          draft: TripDraft(
            startDay: oct1,
            endDay: oct1,
            startTime: (hour: 20, minute: 0),
            endTime: (hour: 19, minute: 5),
          ),
        ),
      ],
    );

    blocTest<AddTripBloc, AddTripState>(
      'the form opened today keeps the 20-minute trip when the driver moves '
      'the start',
      build: () =>
          _bloc(repository, clock: _clockAt(DateTime.utc(2026, 10, 1, 13, 7))),
      act: (bloc) =>
          bloc.add(const TripStartTimeChanged((hour: 8, minute: 10))),
      expect: () => [
        AddTripState(
          tripId: 'trip-1',
          draft: TripDraft(
            startDay: oct1,
            endDay: oct1,
            startTime: (hour: 8, minute: 10),
            endTime: (hour: 8, minute: 30),
          ),
        ),
      ],
    );

    blocTest<AddTripBloc, AddTripState>(
      'the same time at both ends stays on one day, so the form says the end '
      'is not after the start instead of making a 24-hour trip',
      build: () => _bloc(repository),
      act: (bloc) {
        _eveningEdits.forEach(bloc.add);
        bloc
          ..add(const TripEndTimeChanged((hour: 18, minute: 40)))
          ..add(const TripSubmitted());
      },
      skip: _eveningEdits.length + 1,
      expect: () => [
        _filled(
          draft: _eveningDraft.copyWith(endTime: (hour: 18, minute: 40)),
          status: AddTripStatus.invalid,
          fieldErrors: const {TripField.end: TripFieldError.notAfterStart},
        ),
      ],
    );

    blocTest<AddTripBloc, AddTripState>(
      'a second «Сохранить» with the same errors reports them again, so the '
      'sheet can react to it',
      build: () => _bloc(repository),
      act: (bloc) => bloc
        ..add(const TripSubmitted())
        ..add(const TripSubmitted()),
      expect: () => [
        for (final status in [
          AddTripStatus.invalid,
          AddTripStatus.editing,
          AddTripStatus.invalid,
        ])
          isA<AddTripState>().having((s) => s.status, 'status', status),
      ],
      verify: (_) => expect(repository.addedTrips, isEmpty),
    );

    blocTest<AddTripBloc, AddTripState>(
      'an edit after 422 drops the banner, clears the error of its field '
      'and the errors that depend on it, and keeps the others',
      build: () => _bloc(repository),
      seed: () => _filled(
        status: AddTripStatus.failure,
        fieldErrors: const {
          TripField.end: TripFieldError.notAfterStart,
          TripField.commission: TripFieldError.aboveAmount,
          TripField.payment: TripFieldError.invalid,
        },
        failure: const Failure.validation(),
        trip: _eveningTrip,
      ),
      act: (bloc) => bloc
        ..add(const TripStartTimeChanged((hour: 18, minute: 0)))
        ..add(const TripAmountChanged(2000)),
      expect: () => [
        _filled(
          draft: _eveningDraft.copyWith(
            startTime: (hour: 18, minute: 0),
            endTime: (hour: 18, minute: 25),
          ),
          fieldErrors: const {
            TripField.commission: TripFieldError.aboveAmount,
            TripField.payment: TripFieldError.invalid,
          },
          trip: _eveningTrip,
        ),
        _filled(
          draft: _eveningDraft.copyWith(
            startTime: (hour: 18, minute: 0),
            endTime: (hour: 18, minute: 25),
            amount: 2000,
          ),
          fieldErrors: const {TripField.payment: TripFieldError.invalid},
          trip: _eveningTrip,
        ),
      ],
    );

    blocTest<AddTripBloc, AddTripState>(
      'an edit after a timeout keeps the failure and «Повторить» with the '
      'same id (D7)',
      build: () => _bloc(repository),
      seed: () => _filled(
        status: AddTripStatus.failure,
        failure: const Failure.timeout(),
        trip: _eveningTrip,
      ),
      act: (bloc) => bloc.add(const TripAmountChanged(1200)),
      expect: () => [
        _filled(
          draft: _eveningDraft.copyWith(amount: 1200),
          status: AddTripStatus.failure,
          failure: const Failure.timeout(),
          trip: _eveningTrip,
        ),
      ],
      verify: (bloc) => expect(bloc.state.canRetry, isTrue),
    );

    blocTest<AddTripBloc, AddTripState>(
      'a local check after a timeout replaces its failure with the field '
      'errors: they are what is wrong now',
      build: () => _bloc(repository),
      seed: () => _filled(
        status: AddTripStatus.failure,
        failure: const Failure.timeout(),
        trip: _eveningTrip,
      ),
      act: (bloc) => bloc
        ..add(const TripAmountChanged(null))
        ..add(const TripSubmitted()),
      skip: 1,
      expect: () => [
        _filled(
          draft: _eveningDraft.copyWith(amount: null),
          status: AddTripStatus.invalid,
          fieldErrors: const {TripField.amount: TripFieldError.missing},
          trip: _eveningTrip,
        ),
      ],
    );

    blocTest<AddTripBloc, AddTripState>(
      'a new start keeps an end that is still missing',
      build: () => _bloc(repository),
      act: (bloc) => bloc
        ..add(const TripSubmitted())
        ..add(const TripStartTimeChanged((hour: 8, minute: 0))),
      skip: 1,
      expect: () => [
        isA<AddTripState>().having(
          (state) => state.fieldErrors.keys,
          'fields with errors',
          [
            TripField.end,
            TripField.amount,
            TripField.commission,
            TripField.payment,
          ],
        ),
      ],
    );
  });
}
