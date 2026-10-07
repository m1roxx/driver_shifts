import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/period_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/period_bloc.dart';
import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';
import '../../../../../helpers/period_reports.dart';

const Failure _notFound = Failure.badResponse(statusCode: 404);

final Period _seedWeek = Period.containing(PeriodKind.week, oct1);
final Period _october = Period.containing(PeriodKind.month, oct1);
final Period _nextWeek = _seedWeek.next;

void main() {
  final clock = DriverClock(now: () => DateTime.utc(2026, 9, 30, 20));
  late FakeTripsRepository repository;
  final octoberReport = periodReportOf(_october.start, _october.end, {
    oct1: taskExampleReport,
    oct2: oct2Report,
  });
  final nextWeekReport = periodReportOf(_nextWeek.start, _nextWeek.end, {});

  Future<Result<PeriodReport>> answer(DateTime start, DateTime end) async =>
      Result.success(
        start == _seedWeek.start
            ? seedWeekReport
            : start == _october.start
            ? octoberReport
            : nextWeekReport,
      );

  setUp(() {
    repository = FakeTripsRepository(
      (date) async => Result.success(emptyReport(date)),
      onGetPeriod: answer,
    );
  });

  test('opens on the week of today in Almaty with nothing loaded yet', () {
    final bloc = PeriodBloc(repository, clock);
    addTearDown(bloc.close);

    expect(bloc.state, PeriodState(period: _seedWeek));
    expect(repository.requestedPeriods, isEmpty);
  });

  blocTest<PeriodBloc, PeriodState>(
    'loads a week by its Monday and Sunday',
    build: () => PeriodBloc(repository, clock),
    act: (bloc) => bloc.add(PeriodChanged(_seedWeek)),
    expect: () => [
      PeriodState(period: _seedWeek),
      PeriodState(
        period: _seedWeek,
        status: PeriodStatus.success,
        report: seedWeekReport,
      ),
    ],
    verify: (_) => expect(repository.requestedPeriods, [(sep28, oct4)]),
  );

  blocTest<PeriodBloc, PeriodState>(
    'loads a month by its first and last day and drops the week shown before',
    build: () => PeriodBloc(repository, clock),
    seed: () => PeriodState(
      period: _seedWeek,
      status: PeriodStatus.success,
      report: seedWeekReport,
    ),
    act: (bloc) => bloc.add(PeriodChanged(_october)),
    expect: () => [
      PeriodState(period: _october),
      PeriodState(
        period: _october,
        status: PeriodStatus.success,
        report: octoberReport,
      ),
    ],
    verify: (_) => expect(repository.requestedPeriods, [
      (DateTime.utc(2026, 10), DateTime.utc(2026, 10, 31)),
    ]),
  );

  blocTest<PeriodBloc, PeriodState>(
    'keeps the report on screen while a refresh loads and when it fails',
    build: () {
      repository = FakeTripsRepository(
        (date) async => Result.success(emptyReport(date)),
        onGetPeriod: (_, _) async => const Result.error(_notFound),
      );
      return PeriodBloc(repository, clock);
    },
    seed: () => PeriodState(
      period: _seedWeek,
      status: PeriodStatus.success,
      report: seedWeekReport,
    ),
    act: (bloc) => bloc.add(const PeriodRefreshRequested()),
    expect: () => [
      PeriodState(period: _seedWeek, report: seedWeekReport),
      PeriodState(
        period: _seedWeek,
        status: PeriodStatus.failure,
        report: seedWeekReport,
        failure: _notFound,
      ),
    ],
  );

  blocTest<PeriodBloc, PeriodState>(
    'shows only the last period when periods are switched faster than they '
    'load',
    build: () {
      final responses = {
        _seedWeek.start: Completer<Result<PeriodReport>>(),
        _nextWeek.start: Completer<Result<PeriodReport>>(),
      };
      repository = FakeTripsRepository(
        (date) async => Result.success(emptyReport(date)),
        onGetPeriod: (start, _) => responses[start]!.future,
      );
      scheduleMicrotask(() async {
        await pumpEventQueue();
        responses[_nextWeek.start]!.complete(Result.success(nextWeekReport));
        await pumpEventQueue();
        responses[_seedWeek.start]!.complete(Result.success(seedWeekReport));
      });
      return PeriodBloc(repository, clock);
    },
    act: (bloc) => bloc
      ..add(PeriodChanged(_seedWeek))
      ..add(PeriodChanged(_nextWeek)),
    wait: const Duration(milliseconds: 10),
    expect: () => [
      PeriodState(period: _seedWeek),
      PeriodState(period: _nextWeek),
      PeriodState(
        period: _nextWeek,
        status: PeriodStatus.success,
        report: nextWeekReport,
      ),
    ],
  );

  group('while a sleeping server wakes up', () {
    List<PeriodState> watch(PeriodBloc bloc) {
      final states = <PeriodState>[];
      bloc.stream.listen(states.add);
      return states;
    }

    void closeAll(FakeAsync async, PeriodBloc bloc) {
      unawaited(bloc.close());
      async.flushMicrotasks();
      expect(async.pendingTimers, isEmpty);
    }

    test('marks the load as slow after 3 s and retries transient failures '
        'every 5 s until the period loads', () {
      fakeAsync((async) {
        final answers = <Result<PeriodReport>>[
          const Result.error(Failure.connection()),
          const Result.error(Failure.badResponse(statusCode: 502)),
          Result.success(seedWeekReport),
        ];
        repository = FakeTripsRepository(
          (date) async => Result.success(emptyReport(date)),
          onGetPeriod: (_, _) async => answers.removeAt(0),
        );
        final bloc = PeriodBloc(repository, clock);
        final states = watch(bloc);

        bloc.add(PeriodChanged(_seedWeek));
        async.elapse(const Duration(milliseconds: 2999));
        expect(states, [PeriodState(period: _seedWeek)]);
        async.elapse(const Duration(milliseconds: 1));
        expect(states.last, PeriodState(period: _seedWeek, slow: true));

        async.elapse(const Duration(seconds: 7));
        expect(
          states.last,
          PeriodState(
            period: _seedWeek,
            status: PeriodStatus.success,
            report: seedWeekReport,
          ),
        );
        expect(repository.requestedPeriods, hasLength(3));
        closeAll(async, bloc);
      });
    });

    test('gives up 90 s after the load started and shows the failure', () {
      fakeAsync((async) {
        repository = FakeTripsRepository(
          (date) async => Result.success(emptyReport(date)),
          onGetPeriod: (_, _) async => const Result.error(Failure.timeout()),
        );
        final bloc = PeriodBloc(repository, clock);
        final states = watch(bloc);

        bloc.add(PeriodChanged(_seedWeek));
        async.elapse(const Duration(seconds: 89));
        expect(states.last, PeriodState(period: _seedWeek, slow: true));

        async.elapse(const Duration(seconds: 6));
        expect(
          states.last,
          PeriodState(
            period: _seedWeek,
            status: PeriodStatus.failure,
            failure: const Failure.timeout(),
          ),
        );
        final requests = repository.requestedPeriods.length;
        async.elapse(const Duration(minutes: 5));
        expect(repository.requestedPeriods, hasLength(requests));
        closeAll(async, bloc);
      });
    });

    test('shows a failure that a retry would not fix at once', () {
      fakeAsync((async) {
        repository = FakeTripsRepository(
          (date) async => Result.success(emptyReport(date)),
          onGetPeriod: (_, _) async => const Result.error(_notFound),
        );
        final bloc = PeriodBloc(repository, clock);
        final states = watch(bloc);

        bloc.add(PeriodChanged(_seedWeek));
        async.flushMicrotasks();

        expect(states.last.failure, _notFound);
        expect(repository.requestedPeriods, hasLength(1));
        closeAll(async, bloc);
      });
    });

    test('a period switch stops retrying the previous period', () {
      fakeAsync((async) {
        repository = FakeTripsRepository(
          (date) async => Result.success(emptyReport(date)),
          onGetPeriod: (start, _) async => start == _seedWeek.start
              ? const Result.error(Failure.connection())
              : Result.success(octoberReport),
        );
        final bloc = PeriodBloc(repository, clock);
        final states = watch(bloc);

        bloc.add(PeriodChanged(_seedWeek));
        async.elapse(const Duration(seconds: 7));
        bloc.add(PeriodChanged(_october));
        async.elapse(const Duration(minutes: 5));

        expect(repository.requestedPeriods.map((period) => period.$1), [
          sep28,
          sep28,
          _october.start,
        ]);
        expect(
          states.last,
          PeriodState(
            period: _october,
            status: PeriodStatus.success,
            report: octoberReport,
          ),
        );
        closeAll(async, bloc);
      });
    });
  });
}
