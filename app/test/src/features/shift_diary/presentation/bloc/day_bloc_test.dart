import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/day_bloc.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';

const Failure _notFound = Failure.badResponse(statusCode: 404);

void main() {
  final clock = DriverClock(now: () => DateTime.utc(2026, 9, 30, 20));
  late FakeTripsRepository repository;

  setUp(() {
    repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
      oct2: oct2Report,
    });
  });

  test('DayChanged takes only a calendar day, so a moment goes through '
      'DriverClock.dayOf', () {
    final tripStart = DateTime.parse('2026-10-02T00:30:00+05:00');

    expect(() => DayChanged(tripStart), throwsA(isA<AssertionError>()));
    expect(
      () => DayChanged(DateTime(2026, 10, 2)),
      throwsA(isA<AssertionError>()),
    );
    expect(DayChanged(clock.dayOf(tripStart)).date, oct2);
  });

  test('opens on today in Almaty with nothing loaded yet', () {
    final bloc = DayBloc(repository, clock);
    addTearDown(bloc.close);

    expect(bloc.state, DayState(date: oct1));
  });

  blocTest<DayBloc, DayState>(
    'loads today on start',
    build: () => DayBloc(repository, clock),
    act: (bloc) => bloc.add(const DayStarted()),
    expect: () => [
      DayState(date: oct1),
      DayState(
        date: oct1,
        status: DayStatus.success,
        report: taskExampleReport,
      ),
    ],
    verify: (_) => expect(repository.requestedDays, [oct1]),
  );

  blocTest<DayBloc, DayState>(
    'shows a failure that a retry would not fix at once',
    build: () {
      repository = FakeTripsRepository(
        (_) async => const Result.error(_notFound),
      );
      return DayBloc(repository, clock);
    },
    act: (bloc) => bloc.add(const DayStarted()),
    expect: () => [
      DayState(date: oct1),
      DayState(date: oct1, status: DayStatus.failure, failure: _notFound),
    ],
    verify: (_) => expect(repository.requestedDays, [oct1]),
  );

  blocTest<DayBloc, DayState>(
    'drops the report of the previous day while the next one loads',
    build: () => DayBloc(repository, clock),
    seed: () => DayState(
      date: oct1,
      status: DayStatus.success,
      report: taskExampleReport,
    ),
    act: (bloc) => bloc.add(DayChanged(oct2)),
    expect: () => [
      DayState(date: oct2),
      DayState(date: oct2, status: DayStatus.success, report: oct2Report),
    ],
  );

  blocTest<DayBloc, DayState>(
    'keeps the report on screen while a refresh loads and when it fails',
    build: () {
      repository = FakeTripsRepository(
        (_) async => const Result.error(_notFound),
      );
      return DayBloc(repository, clock);
    },
    seed: () => DayState(
      date: oct1,
      status: DayStatus.success,
      report: taskExampleReport,
    ),
    act: (bloc) => bloc.add(const DayRefreshRequested()),
    expect: () => [
      DayState(date: oct1, report: taskExampleReport),
      DayState(
        date: oct1,
        status: DayStatus.failure,
        report: taskExampleReport,
        failure: _notFound,
      ),
    ],
  );

  blocTest<DayBloc, DayState>(
    'clears the failure when a retry loads the day',
    build: () => DayBloc(repository, clock),
    seed: () => DayState(
      date: oct1,
      status: DayStatus.failure,
      failure: const Failure.timeout(),
    ),
    act: (bloc) => bloc.add(const DayRefreshRequested()),
    expect: () => [
      DayState(date: oct1),
      DayState(
        date: oct1,
        status: DayStatus.success,
        report: taskExampleReport,
      ),
    ],
  );

  group('when a newer request overtakes an older one', () {
    late Map<DateTime, Completer<Result<DayReport>>> responses;

    setUp(() {
      responses = {
        for (final day in [sep30, oct1, oct2]) day: Completer(),
      };
      repository = FakeTripsRepository((date) => responses[date]!.future);
    });

    blocTest<DayBloc, DayState>(
      'shows only the last day when days are switched faster than they load',
      build: () => DayBloc(repository, clock),
      act: (bloc) async {
        bloc
          ..add(DayChanged(sep30))
          ..add(DayChanged(oct2));
        await pumpEventQueue();
        responses[oct2]!.complete(Result.success(oct2Report));
        await pumpEventQueue();
        responses[sep30]!.complete(Result.success(emptyReport(sep30)));
        await pumpEventQueue();
      },
      expect: () => [
        DayState(date: sep30),
        DayState(date: oct2),
        DayState(date: oct2, status: DayStatus.success, report: oct2Report),
      ],
      verify: (_) => expect(repository.requestedDays, [sep30, oct2]),
    );

    blocTest<DayBloc, DayState>(
      'a refresh of the old day does not land on the day switched to',
      build: () => DayBloc(repository, clock),
      seed: () => DayState(
        date: oct1,
        status: DayStatus.success,
        report: taskExampleReport,
      ),
      act: (bloc) async {
        bloc
          ..add(const DayRefreshRequested())
          ..add(DayChanged(oct2));
        await pumpEventQueue();
        responses[oct2]!.complete(Result.success(oct2Report));
        await pumpEventQueue();
        responses[oct1]!.complete(Result.success(taskExampleReport));
        await pumpEventQueue();
      },
      expect: () => [
        DayState(date: oct1, report: taskExampleReport),
        DayState(date: oct2),
        DayState(date: oct2, status: DayStatus.success, report: oct2Report),
      ],
    );
  });

  group('while a sleeping server wakes up', () {
    List<DayState> watch(DayBloc bloc) {
      final states = <DayState>[];
      bloc.stream.listen(states.add);
      return states;
    }

    void closeAll(FakeAsync async, DayBloc bloc) {
      unawaited(bloc.close());
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    }

    test('marks the load as slow after 3 s', () {
      fakeAsync((async) {
        final bloc = DayBloc(
          FakeTripsRepository((_) => Completer<Result<DayReport>>().future),
          clock,
        );
        final states = watch(bloc);

        bloc.add(const DayStarted());
        async.elapse(const Duration(milliseconds: 2999));
        expect(states, [DayState(date: oct1)]);

        async.elapse(const Duration(milliseconds: 1));
        expect(states, [
          DayState(date: oct1),
          DayState(date: oct1, slow: true),
        ]);
        closeAll(async, bloc);
      });
    });

    test('retries connection failures, timeouts and 5xx every 5 s until '
        'the day loads', () {
      fakeAsync((async) {
        final answers = <Result<DayReport>>[
          const Result.error(Failure.connection()),
          const Result.error(Failure.timeout()),
          const Result.error(Failure.badResponse(statusCode: 503)),
          Result.success(taskExampleReport),
        ];
        repository = FakeTripsRepository((_) async => answers.removeAt(0));
        final bloc = DayBloc(repository, clock);
        final states = watch(bloc);

        bloc.add(const DayStarted());
        async.elapse(const Duration(seconds: 14));
        expect(repository.requestedDays, [oct1, oct1, oct1]);
        expect(states.last, DayState(date: oct1, slow: true));

        async.elapse(const Duration(seconds: 1));
        expect(states, [
          DayState(date: oct1),
          DayState(date: oct1, slow: true),
          DayState(
            date: oct1,
            status: DayStatus.success,
            report: taskExampleReport,
          ),
        ]);
        expect(repository.requestedDays, hasLength(4));
        closeAll(async, bloc);
      });
    });

    test('gives up 90 s after the load started and shows the failure', () {
      fakeAsync((async) {
        repository = FakeTripsRepository(
          (_) async => const Result.error(Failure.timeout()),
        );
        final bloc = DayBloc(repository, clock);
        final states = watch(bloc);

        bloc.add(const DayStarted());
        async.elapse(const Duration(seconds: 89));
        expect(states.last, DayState(date: oct1, slow: true));

        async.elapse(const Duration(seconds: 6));
        expect(
          states.last,
          DayState(
            date: oct1,
            status: DayStatus.failure,
            failure: const Failure.timeout(),
          ),
        );
        final requests = repository.requestedDays.length;
        async.elapse(const Duration(minutes: 5));
        expect(repository.requestedDays, hasLength(requests));
        closeAll(async, bloc);
      });
    });

    test('a day switch stops retrying the previous day', () {
      fakeAsync((async) {
        repository = FakeTripsRepository(
          (date) async => date == oct1
              ? const Result.error(Failure.connection())
              : Result.success(oct2Report),
        );
        final bloc = DayBloc(repository, clock);
        final states = watch(bloc);

        bloc.add(const DayStarted());
        async.elapse(const Duration(seconds: 7));
        bloc.add(DayChanged(oct2));
        async.elapse(const Duration(minutes: 5));

        expect(repository.requestedDays, [oct1, oct1, oct2]);
        expect(
          states.last,
          DayState(date: oct2, status: DayStatus.success, report: oct2Report),
        );
        closeAll(async, bloc);
      });
    });

    test('a refresh starts the 90 s over', () {
      fakeAsync((async) {
        repository = FakeTripsRepository(
          (_) async => const Result.error(Failure.connection()),
        );
        final bloc = DayBloc(repository, clock);
        final states = watch(bloc);

        bloc.add(const DayStarted());
        async.elapse(const Duration(seconds: 60));
        bloc.add(const DayRefreshRequested());
        async.elapse(const Duration(seconds: 2));
        expect(states.last, DayState(date: oct1));

        async.elapse(const Duration(seconds: 80));
        expect(states.last, DayState(date: oct1, slow: true));
        closeAll(async, bloc);
      });
    });
  });
}
