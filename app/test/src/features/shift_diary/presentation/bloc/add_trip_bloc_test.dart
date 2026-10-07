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

final DriverClock _clock = DriverClock(now: () => DateTime.utc(2026, 10, 1, 6));

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

AddTripBloc _bloc(FakeTripsRepository repository, {DateTime? day}) {
  var opened = 0;
  return AddTripBloc(
    repository,
    _clock,
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
          status: AddTripStatus.failure,
          fieldErrors: const {
            TripField.start: TripFieldError.missing,
            TripField.end: TripFieldError.missing,
            TripField.amount: TripFieldError.missing,
            TripField.commission: TripFieldError.missing,
            TripField.payment: TripFieldError.missing,
          },
          failure: const Failure.validation(),
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
            status: AddTripStatus.failure,
            fieldErrors: errors,
            failure: const Failure.validation(),
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
          endDay: DateTime.utc(2026, 10, 3),
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

    test('leaves the sent trip for the screen to check only when it may '
        'be stored: after a transient failure or 409', () {
      AddTripState failedWith(Failure failure) => _filled(
        status: AddTripStatus.failure,
        failure: failure,
        trip: _eveningTrip,
      );

      expect(failedWith(const Failure.timeout()).unconfirmedTrip, _eveningTrip);
      expect(
        failedWith(const Failure.connection()).unconfirmedTrip,
        _eveningTrip,
      );
      expect(
        failedWith(const Failure.conflict()).unconfirmedTrip,
        _eveningTrip,
      );
      expect(failedWith(const Failure.validation()).unconfirmedTrip, isNull);
      expect(failedWith(const Failure.unexpected()).unconfirmedTrip, isNull);
      expect(
        _filled(
          status: AddTripStatus.success,
          trip: _eveningTrip,
        ).unconfirmedTrip,
        isNull,
      );
    });

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
          draft: TripDraft(
            startDay: oct2,
            endDay: DateTime.utc(2026, 10, 3),
            endDayPicked: true,
          ),
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
        for (final endDay in [
          oct1,
          oct2,
          DateTime.utc(2026, 10, 3),
          oct2,
          oct2,
          oct2,
          oct2,
        ])
          isA<AddTripState>().having(
            (state) => state.draft.endDay,
            'end day',
            endDay,
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
          status: AddTripStatus.failure,
          fieldErrors: const {TripField.end: TripFieldError.notAfterStart},
          failure: const Failure.validation(),
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
        isA<AddTripState>().having(
          (s) => s.status,
          'status',
          AddTripStatus.failure,
        ),
        isA<AddTripState>().having(
          (s) => s.status,
          'status',
          AddTripStatus.editing,
        ),
        isA<AddTripState>().having(
          (s) => s.status,
          'status',
          AddTripStatus.failure,
        ),
      ],
      verify: (_) => expect(repository.addedTrips, isEmpty),
    );

    blocTest<AddTripBloc, AddTripState>(
      'an edit clears the error of its field and the errors that depend '
      'on it, and keeps the others',
      build: () => _bloc(repository),
      seed: () => _filled(
        status: AddTripStatus.failure,
        fieldErrors: const {
          TripField.end: TripFieldError.notAfterStart,
          TripField.commission: TripFieldError.aboveAmount,
          TripField.payment: TripFieldError.invalid,
        },
        failure: const Failure.validation(),
      ),
      act: (bloc) => bloc
        ..add(const TripStartTimeChanged((hour: 18, minute: 0)))
        ..add(const TripAmountChanged(2000)),
      expect: () => [
        _filled(
          draft: _eveningDraft.copyWith(startTime: (hour: 18, minute: 0)),
          status: AddTripStatus.failure,
          fieldErrors: const {
            TripField.commission: TripFieldError.aboveAmount,
            TripField.payment: TripFieldError.invalid,
          },
          failure: const Failure.validation(),
        ),
        _filled(
          draft: _eveningDraft.copyWith(
            startTime: (hour: 18, minute: 0),
            amount: 2000,
          ),
          status: AddTripStatus.failure,
          fieldErrors: const {TripField.payment: TripFieldError.invalid},
          failure: const Failure.validation(),
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
