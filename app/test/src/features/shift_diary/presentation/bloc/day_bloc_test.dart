import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:driver_shifts/src/core/domain/result.dart';
import 'package:driver_shifts/src/core/error/failure.dart';
import 'package:driver_shifts/src/core/time/driver_clock.dart';
import 'package:driver_shifts/src/features/shift_diary/domain/models/day_report.dart';
import 'package:driver_shifts/src/features/shift_diary/presentation/bloc/day_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../../helpers/day_reports.dart';
import '../../../../../helpers/fake_trips_repository.dart';

void main() {
  final clock = DriverClock(now: () => DateTime.utc(2026, 9, 30, 20));
  late FakeTripsRepository repository;

  setUp(() {
    repository = FakeTripsRepository.withReports({
      oct1: taskExampleReport,
      oct2: oct2Report,
    });
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
    'shows the failure when the day does not load',
    build: () {
      repository = FakeTripsRepository(
        (_) async => const Result.error(Failure.connection()),
      );
      return DayBloc(repository, clock);
    },
    act: (bloc) => bloc.add(const DayStarted()),
    expect: () => [
      DayState(date: oct1),
      DayState(
        date: oct1,
        status: DayStatus.failure,
        failure: const Failure.connection(),
      ),
    ],
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
        (_) async => const Result.error(Failure.timeout()),
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
        failure: const Failure.timeout(),
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
}
